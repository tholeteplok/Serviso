-- Serviso 0015: view gabungan pendapatan WO + Penjualan Langsung.

-- Daily summary gabungan (tanpa ubah v_daily_summary existing untuk kompatibilitas)
create or replace view public.v_daily_summary_combined as
select
  date,
  sum(revenue) as revenue,
  sum(wo_done_count)::int as wo_done_count,
  sum(direct_sale_count)::int as direct_sale_count,
  sum(parts_out_qty) as parts_out_qty
from (
  select
    coalesce(wo.paid_at::date, wo.completed_at::date) as date,
    coalesce(sum(case when wo.paid_at is not null then wo.paid_amount else 0 end),0) as revenue,
    count(distinct wo.id)::int as wo_done_count,
    0 as direct_sale_count,
    coalesce(sum(wi.qty),0) as parts_out_qty
  from public.work_orders wo
  left join public.wo_items wi on wi.work_order_id=wo.id and wi.kind='part'
  where wo.status='selesai' and coalesce(wo.paid_at,wo.completed_at) is not null
  group by coalesce(wo.paid_at::date, wo.completed_at::date)
  union all
  select
    ds.paid_at::date as date,
    coalesce(sum(ds.paid_amount),0) as revenue,
    0 as wo_done_count,
    count(distinct ds.id)::int as direct_sale_count,
    coalesce(sum(dsi.qty),0) as parts_out_qty
  from public.direct_sales ds
  left join public.direct_sale_items dsi on dsi.direct_sale_id=ds.id and dsi.kind='part'
  where ds.paid_at is not null
  group by ds.paid_at::date
) combined
where date is not null
group by date
order by date desc;

-- Top parts gabungan (WO + Penjualan Langsung) — revenue pakai historis unit_price
create or replace view public.v_top_parts_combined as
select month_start, part_id, name, sum(qty_out) as qty_out, sum(revenue) as revenue
from (
  -- dari WO (sudah historis via 0013)
  select date_trunc('month', pm.created_at)::date as month_start, p.id as part_id, p.name,
         sum(pm.qty) as qty_out,
         coalesce(sum(wi.unit_price * pm.qty), sum(pm.qty * p.sell_price)) as revenue
  from public.part_movements pm
  join public.parts p on p.id=pm.part_id
  left join public.wo_items wi on wi.part_id=pm.part_id and wi.work_order_id=pm.ref_id and wi.kind='part'
  where pm.direction='out' and pm.ref_type='wo'
  group by 1,2,3
  union all
  select date_trunc('month', pm.created_at)::date, p.id, p.name,
         sum(pm.qty),
         sum(coalesce(dsi.unit_price, p.sell_price) * pm.qty)
  from public.part_movements pm
  join public.parts p on p.id=pm.part_id
  join public.direct_sale_items dsi on dsi.direct_sale_id=pm.ref_id and dsi.part_id=pm.part_id and dsi.kind='part'
  where pm.direction='out' and pm.ref_type='penjualan_langsung'
  group by 1,2,3
) u
group by month_start, part_id, name
order by month_start desc, qty_out desc;

grant select on public.v_daily_summary_combined to authenticated;
grant select on public.v_top_parts_combined to authenticated;
