-- Serviso 0008: agregasi harian revenue per metode pembayaran (cash/transfer/qris)
-- Sumber: work_orders.status='selesai', group by date + pay_method

create or replace view public.v_daily_summary_by_pay_method as
select
  coalesce(wo.paid_at::date, wo.completed_at::date, wo.updated_at::date) as date,
  wo.pay_method,
  coalesce(sum(wo.paid_amount), 0) as revenue,
  count(*)::int as wo_count
from public.work_orders wo
where wo.status = 'selesai'
group by coalesce(wo.paid_at::date, wo.completed_at::date, wo.updated_at::date), wo.pay_method
order by date desc, pay_method;

grant select on public.v_daily_summary_by_pay_method to authenticated;
