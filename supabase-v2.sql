-- =========================================================
--  Mora Studio · Cotizador 3D — ACTUALIZACIÓN v2
--  Pedidos, formas de pago y clientes
--  Pegar en Supabase > Editor SQL > New query > Run
--  (Se puede correr más de una vez sin problema)
-- =========================================================

-- ---------- Clientes ----------
create table if not exists public.clientes (
  id         uuid primary key default gen_random_uuid(),
  nombre     text not null,
  whatsapp   text,
  instagram  text,
  notas      text,
  created_at timestamptz default now()
);

-- ---------- Datos de pedido y pago en presupuestos ----------
alter table public.presupuestos
  add column if not exists cliente_id    uuid references public.clientes(id) on delete set null,
  add column if not exists fecha_entrega date,
  add column if not exists forma_pago    text,
  add column if not exists cobrado       numeric default 0;

alter table public.presupuestos drop constraint if exists presupuestos_forma_pago_check;
alter table public.presupuestos add constraint presupuestos_forma_pago_check
  check (forma_pago is null or forma_pago in ('mp_mili','mp_lucas','efectivo'));

-- Estados: pendiente (presupuestado) → aceptado (a fabricar) → produccion (imprimiendo)
--          → listo (para entregar) → entregado   |   rechazado
alter table public.presupuestos drop constraint if exists presupuestos_estado_check;
alter table public.presupuestos add constraint presupuestos_estado_check
  check (estado in ('pendiente','aceptado','produccion','listo','entregado','rechazado'));

create index if not exists presupuestos_estado_idx  on public.presupuestos (estado);
create index if not exists presupuestos_entrega_idx on public.presupuestos (fecha_entrega);

-- ---------- Seguridad ----------
alter table public.clientes enable row level security;
drop policy if exists "logueados" on public.clientes;
create policy "logueados" on public.clientes for all to authenticated using (true) with check (true);

-- ---------- Tiempo real ----------
do $$
begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'clientes') then
    alter publication supabase_realtime add table public.clientes;
  end if;
end $$;

-- ---------- Consultas útiles ----------
-- Cola de producción:
-- select fecha_entrega, cliente, pieza, cantidad, estado, horas, precio - cobrado as saldo
-- from presupuestos where estado in ('aceptado','produccion','listo')
-- order by fecha_entrega nulls last;
--
-- Cobrado por forma de pago:
-- select forma_pago, sum(cobrado) from presupuestos
-- where estado <> 'rechazado' group by 1;
