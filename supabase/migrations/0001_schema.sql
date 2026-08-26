-- Serviso 0001: enums, sequence + generator WO, tabel, index, trigger auth & updated_at.
-- Jalankan di SQL Editor Supabase sebelum 0002-0004.

create extension if not exists citext;

-- ===== Enum =====
create type public.user_role as enum ('admin', 'kasir');
create type public.wo_status as enum ('menunggu', 'dikerjakan', 'selesai', 'dibatalkan');
create type public.movement_direction as enum ('in', 'out', 'adjust');
create type public.movement_ref as enum ('pembelian', 'wo', 'koreksi', 'pembatalan');
create type public.pay_method as enum ('cash', 'transfer', 'qris');
create type public.wo_item_kind as enum ('part', 'jasa');
create type public.audit_action as enum ('insert', 'update', 'delete', 'login', 'logout');

-- ===== Penomoran WO (harus ada sebelum tabel work_orders: dipakai sebagai DEFAULT kolom) =====
create sequence public.wo_number_seq start 1;

create or replace function public.gen_wo_number()
returns text
language plpgsql
volatile
security invoker
set search_path = public
as $$
begin
  return 'WO-' || to_char(now(), 'YYMMDD') || '-' || lpad(nextval('wo_number_seq')::text, 3, '0');
end;
$$;

-- ===== Tabel =====
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username citext not null unique,
  email text,
  full_name text,
  phone text,
  role public.user_role not null default 'kasir',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Email login bersifat sintetis (auth.users.email = {username}@users.serviso.app,
-- dihitung client-side); kolom ini menyimpan email pemulihan ASLI dari metadata
-- undangan, hanya dipakai alur reset password sisi admin (Edge Function, Task 8).
comment on column public.profiles.email is
  'Email pemulihan asli (bukan email login); reset password via admin Edge Function.';

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  name text not null constraint customers_name_not_empty check (length(trim(name)) > 0),
  phone text,
  address text,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers (id) on delete restrict,
  plate_no text not null unique
    constraint vehicles_plate_no_normalized check (plate_no = upper(plate_no) and length(trim(plate_no)) > 0),
  brand text,
  model text,
  year int constraint vehicles_year_plausible check (year is null or year between 1900 and 2100),
  color text,
  created_at timestamptz not null default now()
);

create table public.parts (
  id uuid primary key default gen_random_uuid(),
  code text unique,
  name text not null constraint parts_name_not_empty check (length(trim(name)) > 0),
  unit text not null default 'pcs',
  -- numeric(12,2): stok pecahan sah (mis. 0.5 liter); movement qty numeric(10,2)
  -- masuk tanpa pembulatan; tetap tidak boleh minus.
  stock_qty numeric(12,2) not null default 0 constraint parts_stock_qty_nonnegative check (stock_qty >= 0),
  min_stock int not null default 0,
  cost_price numeric(14,2) not null default 0 constraint parts_cost_price_nonnegative check (cost_price >= 0),
  sell_price numeric(14,2) not null default 0 constraint parts_sell_price_nonnegative check (sell_price >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.part_movements (
  id uuid primary key default gen_random_uuid(),
  part_id uuid not null references public.parts (id) on delete restrict,
  direction public.movement_direction not null,
  qty numeric(10,2) not null
    constraint part_movements_qty_by_direction check (
      (direction in ('in', 'out') and qty > 0) or (direction = 'adjust' and qty <> 0)
    ),
  ref_type public.movement_ref not null,
  ref_id uuid,
  note text,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.work_orders (
  id uuid primary key default gen_random_uuid(),
  wo_number text not null unique default public.gen_wo_number(),
  vehicle_id uuid not null references public.vehicles (id) on delete restrict,
  status public.wo_status not null default 'menunggu',
  complaint text not null constraint work_orders_complaint_not_empty check (length(trim(complaint)) > 0),
  diagnosis text,
  technician_note text,
  odometer_in int constraint work_orders_odometer_nonnegative check (odometer_in is null or odometer_in >= 0),
  assigned_to uuid references public.profiles (id) on delete set null,
  paid_amount numeric(14,2) not null default 0
    constraint work_orders_paid_amount_nonnegative check (paid_amount >= 0),
  pay_method public.pay_method,
  started_at timestamptz,
  completed_at timestamptz,
  paid_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.wo_items (
  id uuid primary key default gen_random_uuid(),
  work_order_id uuid not null references public.work_orders (id) on delete cascade,
  kind public.wo_item_kind not null,
  part_id uuid references public.parts (id) on delete restrict,
  description text not null constraint wo_items_description_not_empty check (length(trim(description)) > 0),
  qty numeric(10,2) not null constraint wo_items_qty_positive check (qty > 0),
  unit_price numeric(14,2) not null constraint wo_items_unit_price_nonnegative check (unit_price >= 0),
  discount numeric(14,2) not null default 0 constraint wo_items_discount_nonnegative check (discount >= 0),
  constraint wo_items_kind_matches_part check ((kind = 'part' and part_id is not null) or kind = 'jasa')
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references public.profiles (id) on delete set null,
  action public.audit_action not null,
  table_name text,
  record_id text,
  old_data jsonb,
  new_data jsonb,
  created_at timestamptz not null default now()
);

create table public.app_settings (
  id int not null default 1 primary key constraint app_settings_single_row check (id = 1),
  shop_name text not null,
  address text,
  phone text,
  updated_at timestamptz not null default now()
);

-- ===== Index =====
create index idx_vehicles_customer on public.vehicles (customer_id);
create index idx_work_orders_status on public.work_orders (status);
create index idx_work_orders_vehicle on public.work_orders (vehicle_id);
create index idx_work_orders_created_desc on public.work_orders (created_at desc);
create index idx_part_movements_part_created_desc on public.part_movements (part_id, created_at desc);
create index idx_audit_logs_actor on public.audit_logs (actor_id);
create index idx_audit_logs_created_desc on public.audit_logs (created_at desc);
create index idx_audit_logs_table on public.audit_logs (table_name);

-- ===== Trigger pembuatan profil saat user auth dibuat =====
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
  v_email text;
  v_full_name text;
  v_role text;
begin
  v_username := coalesce(
    nullif(new.raw_user_meta_data ->> 'username', ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'user'
  );
  while exists (select 1 from public.profiles p where p.username = v_username) loop
    v_username := v_username || '_' || substr(md5(random()::text), 1, 4);
  end loop;
  -- auth.users.email adalah alamat sintetis; email pemulihan asli dikirim via
  -- metadata undangan (kunci 'email'). Fallback ke email auth bila metadata kosong.
  v_email := coalesce(nullif(new.raw_user_meta_data ->> 'email', ''), new.email);
  v_full_name := coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), v_username);
  v_role := coalesce(new.raw_user_meta_data ->> 'role', 'kasir');
  insert into public.profiles (id, username, email, full_name, role, is_active)
  values (
    new.id,
    v_username,
    v_email,
    v_full_name,
    case when v_role in ('admin', 'kasir') then v_role::public.user_role else 'kasir' end,
    true
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ===== Trigger updated_at otomatis =====
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger trg_customers_updated_at
before update on public.customers
for each row execute function public.set_updated_at();

create trigger trg_parts_updated_at
before update on public.parts
for each row execute function public.set_updated_at();

create trigger trg_work_orders_updated_at
before update on public.work_orders
for each row execute function public.set_updated_at();
