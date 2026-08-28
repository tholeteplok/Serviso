-- Serviso 0006: views agregasi laporan harian dan suku cadang terlaris.

create or replace view public.v_daily_summary as
select
  coalesce(wo.paid_at::date, wo.completed_at::date, wo.updated_at::date) as date,
  coalesce(sum(wo.paid_amount), 0) as revenue,
  count(distinct wo.id)::int as wo_done_count,
  coalesce(sum(wi.qty), 0) as parts_out_qty
from public.work_orders wo
left join public.wo_items wi on wi.work_order_id = wo.id and wi.kind = 'part'
where wo.status = 'selesai'
group by coalesce(wo.paid_at::date, wo.completed_at::date, wo.updated_at::date)
order by date desc;

create or replace view public.v_top_parts as
select
  date_trunc('month', pm.created_at)::date as month_start,
  p.id as part_id,
  p.name,
  sum(pm.qty) as qty_out,
  sum(pm.qty * p.sell_price) as revenue
from public.part_movements pm
join public.parts p on p.id = pm.part_id
where pm.direction = 'out' and pm.ref_type = 'wo'
group by date_trunc('month', pm.created_at)::date, p.id, p.name
order by month_start desc, qty_out desc;

grant select on public.v_daily_summary to authenticated;
grant select on public.v_top_parts to authenticated;
