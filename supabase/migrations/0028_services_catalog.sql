-- Migration 0028: services_catalog.sql
-- Master Data Katalog Jasa (Layanan & Tarif)

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid references public.shops(id) on delete cascade,
  name text not null constraint services_name_not_empty check (length(trim(name)) > 0),
  code text,
  price numeric(14,2) not null default 0 constraint services_price_nonnegative check (price >= 0),
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Index untuk percepatan query filter & search per toko
create index if not exists idx_services_shop_id on public.services(shop_id);
create index if not exists idx_services_name on public.services(name);

-- RLS
alter table public.services enable row level security;

-- Policy Select: Semua user terotentikasi di toko yang sama (termasuk kasir/teknisi untuk memilih saat transaksi)
create policy "services_select" on public.services
  for select to authenticated
  using (shop_id = public.current_shop_id() or public.is_platform_admin());

-- Policy Insert: Khusus Admin toko atau Platform Admin
create policy "services_insert" on public.services
  for insert to authenticated
  with check ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin());

-- Policy Update: Khusus Admin toko atau Platform Admin
create policy "services_update" on public.services
  for update to authenticated
  using ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin())
  with check (shop_id = public.current_shop_id());

-- Policy Delete: Khusus Admin toko atau Platform Admin
create policy "services_delete" on public.services
  for delete to authenticated
  using ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin());

-- Trigger set_shop_id otomatis dari session
create trigger set_shop_id_services
  before insert on public.services
  for each row
  execute function public.set_shop_id_from_session();

-- Trigger audit log
create trigger audit_services
  after insert or update or delete on public.services
  for each row
  execute function public.audit_trigger();

-- Permissions
revoke all privileges on table public.services from anon;
grant select, insert, update, delete on table public.services to authenticated;
grant all privileges on table public.services to service_role;
