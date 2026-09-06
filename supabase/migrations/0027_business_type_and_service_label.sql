-- Serviso 0027: Jenis Usaha (Business Type), service_label, dan customer_id pada work_orders

-- 1. Kunci business_type ke 3 nilai valid di tabel shops
alter table public.shops
  drop constraint if exists shops_business_type_check;

alter table public.shops
  add constraint shops_business_type_check
  check (business_type is null or business_type in ('barang', 'jasa', 'keduanya'));

-- Default untuk toko yang sudah ada (backward-compat, tidak ada yang NULL selamanya)
update public.shops set business_type = 'keduanya' where business_type is null;
alter table public.shops alter column business_type set default 'keduanya';
alter table public.shops alter column business_type set not null;

-- 2. vehicle_id jadi nullable, tambah service_label dan customer_id pada work_orders
alter table public.work_orders alter column vehicle_id drop not null;
alter table public.work_orders add column if not exists service_label text;
alter table public.work_orders add column if not exists customer_id uuid references public.customers(id) on delete restrict;

-- 3. Backfill customer_id untuk work_orders lama dari vehicles.customer_id
update public.work_orders wo
set customer_id = v.customer_id
from public.vehicles v
where wo.vehicle_id = v.id and wo.customer_id is null;

-- 4. Constraint target: salah satu wajib terisi (vehicle_id atau service_label)
alter table public.work_orders
  drop constraint if exists work_orders_target_check;

alter table public.work_orders
  add constraint work_orders_target_check
  check (vehicle_id is not null or service_label is not null);

-- 5. Index untuk customer_id pada work_orders
create index if not exists idx_work_orders_customer on public.work_orders(customer_id);

-- 6. Perbarui view v_transactions_history agar coalesce customer dan target
create or replace view public.v_transactions_history as
select
  wo.id as id,
  wo.wo_number as number,
  'wo'::text as type,
  wo.paid_amount as amount,
  wo.pay_method::text as pay_method,
  coalesce(wo.paid_at, wo.completed_at) as transacted_at,
  coalesce(v.plate_no, wo.service_label) as plate_no,
  c.name as customer_name,
  (select count(*) from public.wo_items wi where wi.work_order_id=wo.id)::int as item_count
from public.work_orders wo
left join public.vehicles v on v.id=wo.vehicle_id
left join public.customers c on c.id=coalesce(wo.customer_id, v.customer_id)
where wo.status='selesai' and coalesce(wo.paid_at, wo.completed_at) is not null
union all
select
  ds.id as id,
  ds.sale_number as number,
  'pl'::text as type,
  ds.paid_amount as amount,
  ds.pay_method::text as pay_method,
  ds.paid_at as transacted_at,
  null as plate_no,
  c.name as customer_name,
  (select count(*) from public.direct_sale_items dsi where dsi.direct_sale_id=ds.id)::int as item_count
from public.direct_sales ds
left join public.customers c on c.id=ds.customer_id
where ds.paid_at is not null
;

grant select on public.v_transactions_history to authenticated;
