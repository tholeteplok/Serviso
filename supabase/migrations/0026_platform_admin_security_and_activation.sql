-- Serviso 0026: Penguatan Keamanan Multi-Tenant & Aktivasi Toko

-- 1. Perbarui current_shop_id() dengan defense-in-depth:
-- Hanya kembalikan shop_id jika tabel shops memiliki is_active = true
create or replace function public.current_shop_id() returns uuid
language sql stable security definer set search_path = public as $$
  select p.shop_id
  from public.profiles p
  join public.shops s on s.id = p.shop_id
  where p.id = auth.uid() and s.is_active = true;
$$;

-- 2. RPC untuk aktivasi/penonaktifan toko oleh Platform Admin
create or replace function public.set_shop_active(p_shop_id uuid, p_is_active boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_platform_admin() then
    raise exception 'Akses ditolak. Hanya platform admin yang dapat mengubah status toko.';
  end if;

  update public.shops
  set is_active = p_is_active
  where id = p_shop_id;
end;
$$;

revoke execute on function public.set_shop_active(uuid, boolean) from public, anon;
grant execute on function public.set_shop_active(uuid, boolean) to authenticated, service_role;
