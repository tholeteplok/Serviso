-- Serviso 0019: Multi-Tenant RLS dan Triggers

-- 1. Helper Functions
create or replace function public.current_shop_id() returns uuid
language sql stable security definer set search_path = public as $$
  select shop_id from public.profiles where id = auth.uid();
$$;

create or replace function public.is_platform_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(is_platform_admin, false) from public.profiles where id = auth.uid();
$$;

-- 2. Trigger untuk otomatis set shop_id (defense in depth)
create or replace function public.set_shop_id_from_session()
returns trigger language plpgsql as $$
begin
  if auth.role() = 'authenticated' then
    new.shop_id := public.current_shop_id();
  end if;
  return new;
end;
$$;

-- Pasang trigger di semua tabel ber-shop_id
create trigger set_shop_id_profiles before insert on public.profiles for each row execute function public.set_shop_id_from_session();
create trigger set_shop_id_customers before insert on public.customers for each row execute function public.set_shop_id_from_session();
create trigger set_shop_id_vehicles before insert on public.vehicles for each row execute function public.set_shop_id_from_session();
create trigger set_shop_id_parts before insert on public.parts for each row execute function public.set_shop_id_from_session();
create trigger set_shop_id_part_movements before insert on public.part_movements for each row execute function public.set_shop_id_from_session();
create trigger set_shop_id_work_orders before insert on public.work_orders for each row execute function public.set_shop_id_from_session();
create trigger set_shop_id_wo_items before insert on public.wo_items for each row execute function public.set_shop_id_from_session();
create trigger set_shop_id_audit_logs before insert on public.audit_logs for each row execute function public.set_shop_id_from_session();
create trigger set_shop_id_debt_payments before insert on public.debt_payments for each row execute function public.set_shop_id_from_session();
create trigger set_shop_id_direct_sales before insert on public.direct_sales for each row execute function public.set_shop_id_from_session();
create trigger set_shop_id_direct_sale_items before insert on public.direct_sale_items for each row execute function public.set_shop_id_from_session();


-- 3. Hapus RLS Policy Lama
do $$
declare
  t text;
begin
  for t in select tablename from pg_tables where schemaname = 'public' loop
    execute 'drop policy if exists "' || t || '_select_authenticated" on public.' || t;
    execute 'drop policy if exists "' || t || '_insert_authenticated" on public.' || t;
    execute 'drop policy if exists "' || t || '_update_authenticated" on public.' || t;
    execute 'drop policy if exists "' || t || '_delete_admin" on public.' || t;
    execute 'drop policy if exists "' || t || '_update_admin" on public.' || t;
    execute 'drop policy if exists "' || t || '_insert_admin" on public.' || t;
  end loop;
end $$;

drop policy if exists "wo_items_insert_open_wo" on public.wo_items;
drop policy if exists "wo_items_update_open_wo" on public.wo_items;
drop policy if exists "wo_items_delete_open_wo" on public.wo_items;
drop policy if exists "profiles_update_self_limited" on public.profiles;

-- 4. RLS Policy Baru (Multi-Tenant)

-- Shops (Hanya Platform Admin yang bisa nulis, semua bisa baca)
alter table public.shops enable row level security;
create policy "shops_select" on public.shops for select to authenticated using (true);
create policy "shops_insert" on public.shops for insert to authenticated with check (public.is_platform_admin());
create policy "shops_update" on public.shops for update to authenticated using (public.is_platform_admin()) with check (public.is_platform_admin());

-- Profiles
create policy "profiles_select" on public.profiles for select to authenticated using (shop_id = public.current_shop_id() or public.is_platform_admin());
create policy "profiles_update_self" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "profiles_update_admin" on public.profiles for update to authenticated using ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin()) with check ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin());

-- Customers
create policy "customers_select" on public.customers for select to authenticated using (shop_id = public.current_shop_id() or public.is_platform_admin());
create policy "customers_insert" on public.customers for insert to authenticated with check (shop_id = public.current_shop_id());
create policy "customers_update" on public.customers for update to authenticated using (shop_id = public.current_shop_id()) with check (shop_id = public.current_shop_id());
create policy "customers_delete" on public.customers for delete to authenticated using ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin());

-- Vehicles
create policy "vehicles_select" on public.vehicles for select to authenticated using (shop_id = public.current_shop_id() or public.is_platform_admin());
create policy "vehicles_insert" on public.vehicles for insert to authenticated with check (shop_id = public.current_shop_id());
create policy "vehicles_update" on public.vehicles for update to authenticated using (shop_id = public.current_shop_id()) with check (shop_id = public.current_shop_id());
create policy "vehicles_delete" on public.vehicles for delete to authenticated using ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin());

-- Parts
create policy "parts_select" on public.parts for select to authenticated using (shop_id = public.current_shop_id() or public.is_platform_admin());
create policy "parts_insert" on public.parts for insert to authenticated with check (shop_id = public.current_shop_id());
create policy "parts_update" on public.parts for update to authenticated using (shop_id = public.current_shop_id()) with check (shop_id = public.current_shop_id());
create policy "parts_delete" on public.parts for delete to authenticated using ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin());

-- Part Movements
create policy "part_movements_select" on public.part_movements for select to authenticated using (shop_id = public.current_shop_id() or public.is_platform_admin());
create policy "part_movements_insert" on public.part_movements for insert to authenticated with check (shop_id = public.current_shop_id());

-- Work Orders
create policy "work_orders_select" on public.work_orders for select to authenticated using (shop_id = public.current_shop_id() or public.is_platform_admin());
create policy "work_orders_insert" on public.work_orders for insert to authenticated with check (shop_id = public.current_shop_id());
create policy "work_orders_update" on public.work_orders for update to authenticated using (shop_id = public.current_shop_id()) with check (shop_id = public.current_shop_id());
create policy "work_orders_delete" on public.work_orders for delete to authenticated using ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin());

-- WO Items
create policy "wo_items_select" on public.wo_items for select to authenticated using (shop_id = public.current_shop_id() or public.is_platform_admin());
create policy "wo_items_insert" on public.wo_items for insert to authenticated 
with check (shop_id = public.current_shop_id() and exists (select 1 from public.work_orders w where w.id = work_order_id and w.status in ('menunggu', 'dikerjakan')));
create policy "wo_items_update" on public.wo_items for update to authenticated 
using (shop_id = public.current_shop_id() and exists (select 1 from public.work_orders w where w.id = work_order_id and w.status in ('menunggu', 'dikerjakan'))) 
with check (shop_id = public.current_shop_id() and exists (select 1 from public.work_orders w where w.id = work_order_id and w.status in ('menunggu', 'dikerjakan')));
create policy "wo_items_delete" on public.wo_items for delete to authenticated 
using (shop_id = public.current_shop_id() and exists (select 1 from public.work_orders w where w.id = work_order_id and w.status in ('menunggu', 'dikerjakan')));

-- Direct Sales
create policy "direct_sales_select" on public.direct_sales for select to authenticated using (shop_id = public.current_shop_id() or public.is_platform_admin());
create policy "direct_sales_insert" on public.direct_sales for insert to authenticated with check (shop_id = public.current_shop_id());
create policy "direct_sales_update" on public.direct_sales for update to authenticated using (shop_id = public.current_shop_id()) with check (shop_id = public.current_shop_id());
create policy "direct_sales_delete" on public.direct_sales for delete to authenticated using ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin());

-- Direct Sale Items
create policy "direct_sale_items_select" on public.direct_sale_items for select to authenticated using (shop_id = public.current_shop_id() or public.is_platform_admin());
create policy "direct_sale_items_insert" on public.direct_sale_items for insert to authenticated with check (shop_id = public.current_shop_id());
create policy "direct_sale_items_update" on public.direct_sale_items for update to authenticated using ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin()) with check ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin());
create policy "direct_sale_items_delete" on public.direct_sale_items for delete to authenticated using ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin());

-- Audit Logs
create policy "audit_logs_select" on public.audit_logs for select to authenticated using ((public.is_admin() and shop_id = public.current_shop_id()) or public.is_platform_admin());


-- Debt Payments
create policy "debt_payments_select" on public.debt_payments for select to authenticated using (shop_id = public.current_shop_id() or public.is_platform_admin());
create policy "debt_payments_insert" on public.debt_payments for insert to authenticated with check (shop_id = public.current_shop_id());

