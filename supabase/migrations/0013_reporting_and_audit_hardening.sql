-- Serviso 0013: hardening pelaporan & audit

-- 1. Fix v_daily_summary: hilangkan fallback updated_at (misbucket),
--    revenue hanya dari yang sudah paid_at (bukan semua selesai), tak double-count.
create or replace view public.v_daily_summary as
select
  coalesce(wo.paid_at::date, wo.completed_at::date) as date,
  coalesce(sum(case when wo.paid_at is not null then wo.paid_amount else 0 end), 0) as revenue,
  count(distinct wo.id)::int as wo_done_count,
  coalesce(sum(wi.qty), 0) as parts_out_qty
from public.work_orders wo
left join public.wo_items wi on wi.work_order_id = wo.id and wi.kind = 'part'
where wo.status = 'selesai'
  and coalesce(wo.paid_at, wo.completed_at) is not null
group by coalesce(wo.paid_at::date, wo.completed_at::date)
order by date desc;

-- 2. Fix v_top_parts: pakai historis unit_price dari wo_items, bukan current sell_price
create or replace view public.v_top_parts as
select
  date_trunc('month', pm.created_at)::date as month_start,
  p.id as part_id,
  p.name,
  sum(pm.qty) as qty_out,
  -- revenue historis: qty * wo_items.unit_price (bukan p.sell_price saat ini)
  coalesce(sum(wi.unit_price * pm.qty), sum(pm.qty * p.sell_price)) as revenue
from public.part_movements pm
join public.parts p on p.id = pm.part_id
left join public.wo_items wi
  on wi.part_id = pm.part_id
  and wi.work_order_id = pm.ref_id
  and wi.kind = 'part'
where pm.direction = 'out' and pm.ref_type = 'wo'
group by date_trunc('month', pm.created_at)::date, p.id, p.name
order by month_start desc, qty_out desc;

grant select on public.v_daily_summary to authenticated;
grant select on public.v_top_parts to authenticated;

-- 3. Audit tambahan: app_settings & debt_payments (perubahan sensitif)
drop trigger if exists audit_app_settings on public.app_settings;
create trigger audit_app_settings
after insert or update or delete on public.app_settings
for each row execute function public.audit_trigger();

drop trigger if exists audit_debt_payments on public.debt_payments;
create trigger audit_debt_payments
after insert or update or delete on public.debt_payments
for each row execute function public.audit_trigger();
