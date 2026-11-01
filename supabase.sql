-- =========================================================
--  Mora Studio · Cotizador 3D — estructura de la base
--  Pegar todo en Supabase > SQL Editor > New query > Run
-- =========================================================

-- Valores generales (una sola fila, id = 1)
create table if not exists public.config (
  id        int primary key default 1 check (id = 1),
  kwh       numeric default 0,      -- precio del kWh
  hora      numeric default 0,      -- valor hora de trabajo
  diseno    numeric default 0,      -- valor hora de diseño
  merma     numeric default 10,     -- %
  margen    numeric default 40,     -- % ganancia sobre precio de venta
  comision  numeric default 0,      -- % Mercado Pago / plataforma
  redondeo  numeric default 100     -- redondear precio a múltiplos de...
);
insert into public.config (id) values (1) on conflict (id) do nothing;

create table if not exists public.filamentos (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null,
  color      text,
  precio     numeric not null,       -- precio del rollo
  peso       numeric default 1000,   -- gramos del rollo
  created_at timestamptz default now()
);

create table if not exists public.impresoras (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null,
  watts      numeric default 120,    -- consumo promedio
  precio     numeric default 0,      -- lo que costó
  vida       numeric default 5000,   -- vida útil en horas
  mant       numeric default 0,      -- mantenimiento $/hora
  created_at timestamptz default now()
);

create table if not exists public.presupuestos (
  id           uuid primary key default gen_random_uuid(),
  fecha        timestamptz default now(),
  cliente      text,
  pieza        text,
  cantidad     int default 1,
  impresora_id uuid references public.impresoras(id) on delete set null,
  horas        numeric default 0,
  trabajo_min  numeric default 0,
  diseno_min   numeric default 0,
  post         numeric default 0,
  empaque      numeric default 0,
  merma        numeric default 10,
  margen       numeric default 40,
  comision     numeric default 0,
  notas        text,
  estado       text default 'pendiente'
               check (estado in ('pendiente','aceptado','entregado','rechazado')),
  filamentos   jsonb default '[]',   -- [{filId, gramos}]
  resultado    jsonb default '{}',   -- desglose completo del cálculo
  precio       numeric,              -- copia para consultas/reportes
  costo        numeric,
  ganancia     numeric,
  creado_por   text default (auth.jwt() ->> 'email')
);
create index if not exists presupuestos_fecha_idx on public.presupuestos (fecha desc);

-- ---------- Seguridad: solo usuarias/os logueados ----------
alter table public.config       enable row level security;
alter table public.filamentos   enable row level security;
alter table public.impresoras   enable row level security;
alter table public.presupuestos enable row level security;

drop policy if exists "logueados" on public.config;
drop policy if exists "logueados" on public.filamentos;
drop policy if exists "logueados" on public.impresoras;
drop policy if exists "logueados" on public.presupuestos;

create policy "logueados" on public.config       for all to authenticated using (true) with check (true);
create policy "logueados" on public.filamentos   for all to authenticated using (true) with check (true);
create policy "logueados" on public.impresoras   for all to authenticated using (true) with check (true);
create policy "logueados" on public.presupuestos for all to authenticated using (true) with check (true);

-- ---------- Tiempo real: lo que carga una persona aparece en el otro dispositivo ----------
do $$
declare t text;
begin
  foreach t in array array['config','filamentos','impresoras','presupuestos'] loop
    if not exists (select 1 from pg_publication_tables
                   where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ---------- Consulta útil: ventas por mes ----------
-- select date_trunc('month', fecha) as mes, count(*), sum(precio) as vendido, sum(ganancia) as ganancia
-- from presupuestos where estado in ('aceptado','entregado') group by 1 order by 1 desc;
