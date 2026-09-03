-- Serviso 0024: Fix RLS Policy agar Admin Toko dapat memperbarui profil toko sendiri

-- 1. Perbarui policy update pada tabel shops
drop policy if exists "shops_update" on public.shops;

create policy "shops_update" on public.shops for update to authenticated
  using (
    (public.is_admin() and id = public.current_shop_id())
    or public.is_platform_admin()
  )
  with check (
    (public.is_admin() and id = public.current_shop_id())
    or public.is_platform_admin()
  );

-- 2. Pastikan tabel app_settings (legacy single-tenant fallback jika tabel ada) memiliki RLS yang aman
do $$
begin
  if to_regclass('public.app_settings') is not null then
    execute 'alter table public.app_settings enable row level security';
    execute 'drop policy if exists "app_settings_select" on public.app_settings';
    execute 'create policy "app_settings_select" on public.app_settings for select to authenticated using (true)';
    execute 'drop policy if exists "app_settings_update" on public.app_settings';
    execute 'create policy "app_settings_update" on public.app_settings for update to authenticated using (public.is_admin() or public.is_platform_admin()) with check (public.is_admin() or public.is_platform_admin())';
  end if;
end $$;
