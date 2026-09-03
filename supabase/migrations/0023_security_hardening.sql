-- Serviso 0023: Security Hardening (Search Path, Extensions, & RPC Execution Permissions)

-- 1. Pindahkan extension citext ke schema extensions jika ada
do $$
begin
  if exists (select 1 from pg_extension where extname = 'citext') then
    execute 'alter extension citext set schema extensions';
  end if;
exception when others then
  -- Abaikan jika schema extensions tidak tersedia
end $$;

-- 2. Hardening function set_shop_id_from_session dengan search_path tetap
create or replace function public.set_shop_id_from_session()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.role() = 'authenticated' then
    new.shop_id := public.current_shop_id();
  end if;
  return new;
end;
$$;

-- 3. Cabut hak eksekusi RPC dari Trigger Functions (hanya boleh dieksekusi oleh trigger internal database)
revoke execute on function public.check_price_update_is_admin() from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.set_shop_id_from_session() from public, anon, authenticated;

-- 4. Cabut hak eksekusi RLS Helpers dari anon/public (hanya untuk authenticated session)
revoke execute on function public.current_shop_id() from public, anon;
revoke execute on function public.is_platform_admin() from public, anon;
revoke execute on function public.is_admin() from public, anon;

-- Pastikan authenticated memiliki izin pada RLS helper
grant execute on function public.current_shop_id() to authenticated, service_role;
grant execute on function public.is_platform_admin() to authenticated, service_role;
grant execute on function public.is_admin() to authenticated, service_role;
