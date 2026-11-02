-- =========================================================
--  Mora Studio · Cotizador 3D — ACTUALIZACIÓN v3
--  Catálogo de productos
--  Pegar en Supabase > Editor SQL > New query > Run
-- =========================================================

create table if not exists public.productos (
  id           uuid primary key default gen_random_uuid(),
  nombre       text not null,
  categoria    text,
  impresora_id uuid references public.impresoras(id) on delete set null,
  filamentos   jsonb default '[]',   -- [{filId, gramos}] para 1 unidad
  horas        numeric default 0,    -- horas de impresión por unidad
  trabajo_min  numeric default 0,    -- minutos de trabajo por unidad
  diseno_min   numeric default 0,    -- minutos de diseño (una sola vez)
  post         numeric default 0,    -- postprocesado $ por unidad
  empaque      numeric default 0,    -- empaque $ por unidad
  notas        text,
  created_at   timestamptz default now()
);

alter table public.productos enable row level security;
drop policy if exists "logueados" on public.productos;
create policy "logueados" on public.productos for all to authenticated using (true) with check (true);

do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'productos') then
    alter publication supabase_realtime add table public.productos;
  end if;
end $$;
