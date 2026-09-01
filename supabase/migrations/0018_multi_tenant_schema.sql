-- Serviso 0018: Skema Multi-Tenant Dasar

-- 1. Tabel shops
create table public.shops (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null constraint shops_slug_format check (slug ~ '^[a-z0-9\-]+$'),
  name text not null,
  business_type text,
  address text,
  phone text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- 2. Tambah kolom di profiles
alter table public.profiles
  add column shop_id uuid references public.shops(id),
  add column is_platform_admin boolean not null default false;

-- 3. Tambah kolom di tabel tenant
alter table public.customers add column shop_id uuid references public.shops(id);
alter table public.vehicles add column shop_id uuid references public.shops(id);
alter table public.parts add column shop_id uuid references public.shops(id);
alter table public.part_movements add column shop_id uuid references public.shops(id);
alter table public.work_orders add column shop_id uuid references public.shops(id);
alter table public.wo_items add column shop_id uuid references public.shops(id);
alter table public.audit_logs add column shop_id uuid references public.shops(id);
alter table public.direct_sales add column shop_id uuid references public.shops(id);
alter table public.debt_payments add column shop_id uuid references public.shops(id);
alter table public.direct_sale_items add column shop_id uuid references public.shops(id);

-- 4. Migrasi / Backfill
do $$
declare
  v_default_shop_id uuid;
  v_shop_name text := 'Bengkel Default';
  v_address text := null;
  v_phone text := null;
begin
  -- Coba ambil data dari app_settings jika ada
  begin
    select shop_name, address, phone into v_shop_name, v_address, v_phone
    from public.app_settings
    where id = 1;
  exception when others then
    -- Abaikan jika tabel tidak ada
  end;

  -- Buat toko default
  insert into public.shops (slug, name, address, phone)
  values ('default', v_shop_name, v_address, v_phone)
  returning id into v_default_shop_id;

  -- Backfill semua tabel
  update public.profiles set shop_id = v_default_shop_id where is_platform_admin = false;
  update public.customers set shop_id = v_default_shop_id;
  update public.vehicles set shop_id = v_default_shop_id;
  update public.parts set shop_id = v_default_shop_id;
  update public.part_movements set shop_id = v_default_shop_id;
  update public.work_orders set shop_id = v_default_shop_id;
  update public.wo_items set shop_id = v_default_shop_id;
  update public.audit_logs set shop_id = v_default_shop_id;
  update public.direct_sales set shop_id = v_default_shop_id;
  update public.debt_payments set shop_id = v_default_shop_id;
  update public.direct_sale_items set shop_id = v_default_shop_id;

end $$;

-- 5. Scope ulang constraint unique
-- Profiles username
alter table public.profiles drop constraint profiles_username_key;
alter table public.profiles add constraint profiles_shop_id_username_key unique (shop_id, username);
create unique index profiles_username_platform_admin_idx on public.profiles (username) where shop_id is null;

-- Vehicles plate_no
alter table public.vehicles drop constraint vehicles_plate_no_key;
alter table public.vehicles add constraint vehicles_shop_id_plate_no_key unique (shop_id, plate_no);

-- Work Orders wo_number
alter table public.work_orders drop constraint work_orders_wo_number_key;
alter table public.work_orders add constraint work_orders_shop_id_wo_number_key unique (shop_id, wo_number);

-- Direct Sales sale_number
alter table public.direct_sales drop constraint direct_sales_sale_number_key;
alter table public.direct_sales add constraint direct_sales_shop_id_sale_number_key unique (shop_id, sale_number);

-- Parts code (kalau ada constraint unique global)
alter table public.parts drop constraint parts_code_key;
alter table public.parts add constraint parts_shop_id_code_key unique (shop_id, code);

-- 6. Deprecate app_settings (opsional drop, tapi baiknya drop view dependencies kalau ada)
drop table if exists public.app_settings cascade;


