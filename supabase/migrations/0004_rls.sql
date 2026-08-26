-- Serviso 0004: RLS, helper is_admin, policy, dan grants.
-- RLS adalah sumber kebenaran keamanan; grant kolom memperketat di atas policy baris.

-- ===== Helper role (security definer agar tidak rekursif dengan policy profiles) =====
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and is_active
  );
$$;

revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated, service_role;

-- ===== Aktifkan RLS =====
alter table public.profiles enable row level security;
alter table public.customers enable row level security;
alter table public.vehicles enable row level security;
alter table public.parts enable row level security;
alter table public.part_movements enable row level security;
alter table public.work_orders enable row level security;
alter table public.wo_items enable row level security;
alter table public.audit_logs enable row level security;
alter table public.app_settings enable row level security;

-- ===== Policy: profiles =====
create policy "profiles_select_authenticated" on public.profiles
for select to authenticated using (true);

create policy "profiles_update_self_limited" on public.profiles
for update to authenticated
using (id = auth.uid()) with check (id = auth.uid());

create policy "profiles_update_admin" on public.profiles
for update to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "profiles_insert_admin" on public.profiles
for insert to authenticated with check (public.is_admin());

create policy "profiles_delete_admin" on public.profiles
for delete to authenticated using (public.is_admin());

-- ===== Policy: customers =====
create policy "customers_select_authenticated" on public.customers
for select to authenticated using (true);

create policy "customers_insert_authenticated" on public.customers
for insert to authenticated with check (true);

create policy "customers_update_authenticated" on public.customers
for update to authenticated using (true) with check (true);

create policy "customers_delete_admin" on public.customers
for delete to authenticated using (public.is_admin());

-- ===== Policy: vehicles =====
create policy "vehicles_select_authenticated" on public.vehicles
for select to authenticated using (true);

create policy "vehicles_insert_authenticated" on public.vehicles
for insert to authenticated with check (true);

create policy "vehicles_update_authenticated" on public.vehicles
for update to authenticated using (true) with check (true);

create policy "vehicles_delete_admin" on public.vehicles
for delete to authenticated using (public.is_admin());

-- ===== Policy: parts =====
create policy "parts_select_authenticated" on public.parts
for select to authenticated using (true);

create policy "parts_insert_authenticated" on public.parts
for insert to authenticated with check (true);

create policy "parts_update_authenticated" on public.parts
for update to authenticated using (true) with check (true);

create policy "parts_delete_admin" on public.parts
for delete to authenticated using (public.is_admin());

-- ===== Policy: part_movements (kartu stok append-only; koreksi via baris baru, ref koreksi/adjust) =====
create policy "part_movements_select_authenticated" on public.part_movements
for select to authenticated using (true);

create policy "part_movements_insert_authenticated" on public.part_movements
for insert to authenticated with check (true);

-- ===== Policy: work_orders =====
create policy "work_orders_select_authenticated" on public.work_orders
for select to authenticated using (true);

create policy "work_orders_insert_authenticated" on public.work_orders
for insert to authenticated with check (true);

create policy "work_orders_update_authenticated" on public.work_orders
for update to authenticated using (true) with check (true);

create policy "work_orders_delete_admin" on public.work_orders
for delete to authenticated using (public.is_admin());

-- ===== Policy: wo_items (item hanya boleh berubah saat WO masih menunggu/dikerjakan) =====
create policy "wo_items_select_authenticated" on public.wo_items
for select to authenticated using (true);

create policy "wo_items_insert_open_wo" on public.wo_items
for insert to authenticated
with check (
  exists (
    select 1 from public.work_orders w
    where w.id = work_order_id and w.status in ('menunggu', 'dikerjakan')
  )
);

create policy "wo_items_update_open_wo" on public.wo_items
for update to authenticated
using (
  exists (
    select 1 from public.work_orders w
    where w.id = work_order_id and w.status in ('menunggu', 'dikerjakan')
  )
)
with check (
  exists (
    select 1 from public.work_orders w
    where w.id = work_order_id and w.status in ('menunggu', 'dikerjakan')
  )
);

create policy "wo_items_delete_open_wo" on public.wo_items
for delete to authenticated
using (
  exists (
    select 1 from public.work_orders w
    where w.id = work_order_id and w.status in ('menunggu', 'dikerjakan')
  )
);

-- ===== Policy: app_settings =====
create policy "app_settings_select_authenticated" on public.app_settings
for select to authenticated using (true);

create policy "app_settings_update_admin" on public.app_settings
for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- ===== Policy: audit_logs (baca admin saja; tanpa INSERT/UPDATE/DELETE untuk siapa pun) =====
create policy "audit_logs_select_admin" on public.audit_logs
for select to authenticated using (public.is_admin());

-- ===== Grants tabel =====
grant usage on schema public to anon, authenticated, service_role;

revoke all privileges on table public.profiles from anon;
revoke all privileges on table public.profiles from authenticated;
grant select on table public.profiles to authenticated;
grant update (full_name, phone) on table public.profiles to authenticated;
grant all privileges on table public.profiles to service_role;

revoke all privileges on table public.customers from anon;
revoke all privileges on table public.customers from authenticated;
grant select, insert, update, delete on table public.customers to authenticated;
grant all privileges on table public.customers to service_role;

revoke all privileges on table public.vehicles from anon;
revoke all privileges on table public.vehicles from authenticated;
grant select, insert, update, delete on table public.vehicles to authenticated;
grant all privileges on table public.vehicles to service_role;

-- stock_qty sengaja TIDAK bisa di-update lewat client: perubahan stok hanya via part_movements.
revoke all privileges on table public.parts from anon;
revoke all privileges on table public.parts from authenticated;
grant select, insert, delete on table public.parts to authenticated;
grant update (code, name, unit, min_stock, cost_price, sell_price) on table public.parts to authenticated;
grant all privileges on table public.parts to service_role;

-- Ledger kartu stok: append-only; hanya SELECT + INSERT bagi authenticated (tanpa UPDATE/DELETE).
revoke all privileges on table public.part_movements from anon;
revoke all privileges on table public.part_movements from authenticated;
grant select, insert on table public.part_movements to authenticated;
grant all privileges on table public.part_movements to service_role;

revoke all privileges on table public.work_orders from anon;
revoke all privileges on table public.work_orders from authenticated;
grant select, insert, update, delete on table public.work_orders to authenticated;
grant all privileges on table public.work_orders to service_role;

revoke all privileges on table public.wo_items from anon;
revoke all privileges on table public.wo_items from authenticated;
grant select, insert, update, delete on table public.wo_items to authenticated;
grant all privileges on table public.wo_items to service_role;

revoke all privileges on table public.app_settings from anon;
revoke all privileges on table public.app_settings from authenticated;
grant select, update on table public.app_settings to authenticated;
grant all privileges on table public.app_settings to service_role;

revoke all privileges on table public.audit_logs from anon;
revoke all privileges on table public.audit_logs from authenticated;
grant select on table public.audit_logs to authenticated;
grant all privileges on table public.audit_logs to service_role;

-- ===== Grants sequence & fungsi penomoran WO (dipakai DEFAULT saat insert work_orders) =====
revoke all privileges on sequence public.wo_number_seq from anon;
grant usage, select on sequence public.wo_number_seq to authenticated, service_role;

revoke execute on function public.gen_wo_number() from public, anon;
grant execute on function public.gen_wo_number() to authenticated, service_role;
