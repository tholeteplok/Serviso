-- Serviso 0017: history transaksi gabungan + revenue by pay_method gabungan

-- View transaksi harian detail (untuk drill-down Omset per tanggal)
create or replace view public.v_transactions_history as
select
  wo.id as id,
  wo.wo_number as number,
  'wo'::text as type,
  wo.paid_amount as amount,
  wo.pay_method::text as pay_method,
  coalesce(wo.paid_at, wo.completed_at) as transacted_at,
  v.plate_no as plate_no,
  c.name as customer_name,
  (select count(*) from public.wo_items wi where wi.work_order_id=wo.id)::int as item_count
from public.work_orders wo
left join public.vehicles v on v.id=wo.vehicle_id
left join public.customers c on c.id=v.customer_id
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

-- Revenue by pay_method gabungan
create or replace view public.v_daily_revenue_by_pay_method_combined as
select date, pay_method, sum(revenue) as revenue, sum(cnt)::int as wo_count
from (
  select coalesce(wo.paid_at::date, wo.completed_at::date) as date, wo.pay_method::text as pay_method, sum(wo.paid_amount) as revenue, count(*)::int as cnt
  from public.work_orders wo where wo.status='selesai' and coalesce(wo.paid_at, wo.completed_at) is not null group by 1,2
  union all
  select ds.paid_at::date as date, ds.pay_method::text as pay_method, sum(ds.paid_amount) as revenue, count(*)::int as cnt
  from public.direct_sales ds where ds.paid_at is not null group by 1,2
) u where date is not null group by date, pay_method
;

grant select on public.v_daily_revenue_by_pay_method_combined to authenticated;
