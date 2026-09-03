-- Serviso 0022: Remediasi Supabase Security Advisor (0010_security_definer_view)
-- Mengaktifkan security_invoker = true agar seluruh view mematuhi RLS user pemanggil (multi-tenant safe)

alter view if exists public.v_transactions_history set (security_invoker = true);
alter view if exists public.v_daily_revenue_by_pay_method_combined set (security_invoker = true);
alter view if exists public.v_daily_summary set (security_invoker = true);
alter view if exists public.v_top_parts set (security_invoker = true);
alter view if exists public.v_daily_summary_by_pay_method set (security_invoker = true);
alter view if exists public.v_low_stock_parts set (security_invoker = true);
alter view if exists public.v_daily_summary_combined set (security_invoker = true);
alter view if exists public.v_top_parts_combined set (security_invoker = true);
