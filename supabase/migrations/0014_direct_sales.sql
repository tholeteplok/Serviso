-- Serviso 0014: Modul Penjualan Langsung (Direct Sales) — Opsi B.
-- Tidak menyentuh work_orders; reuse sequence gen_wo_number dengan prefix PL-.

-- 0. Tambah value baru ke enum movement_ref (butuh commit terpisah, jadi pakai DO)
do $$ begin
  perform 1 from pg_enum where enumlabel='penjualan_langsung' and enumtypid='public.movement_ref'::regtype;
  if not found then
    alter type public.movement_ref add value 'penjualan_langsung';
  end if;
end $$;

-- 1. Generator nomor direct sale (reuse wo_number_seq untuk monotonic, prefix PL-)
create or replace function public.gen_sale_number()
returns text
language plpgsql
volatile
security invoker
set search_path = public
as $$
begin
  return 'PL-' || to_char(now(), 'YYMMDD') || '-' || lpad(nextval('public.wo_number_seq')::text, 3, '0');
end;
$$;

-- 2. Tabel header
create table if not exists public.direct_sales (
  id uuid primary key default gen_random_uuid(),
  sale_number text not null unique default public.gen_sale_number(),
  customer_id uuid references public.customers(id) on delete set null,
  cashier_id uuid not null references public.profiles(id) on delete restrict default auth.uid(),
  paid_amount numeric(14,2) not null default 0 check (paid_amount >= 0),
  pay_method public.pay_method,
  paid_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_direct_sales_customer on public.direct_sales(customer_id);
create index if not exists idx_direct_sales_created_desc on public.direct_sales(created_at desc);
create index if not exists idx_direct_sales_paid_at on public.direct_sales(paid_at) where paid_at is not null;

-- 3. Tabel item (mirip wo_items, discount clamp di DB)
create table if not exists public.direct_sale_items (
  id uuid primary key default gen_random_uuid(),
  direct_sale_id uuid not null references public.direct_sales(id) on delete cascade,
  kind public.wo_item_kind not null,
  part_id uuid references public.parts(id) on delete restrict,
  description text,
  qty numeric(10,2) not null check (qty > 0),
  unit_price numeric(14,2) not null check (unit_price >= 0),
  discount numeric(14,2) not null default 0 check (discount >= 0),
  constraint direct_sale_items_discount_bounded check (discount <= qty * unit_price),
  constraint direct_sale_items_kind_matches_part check ((kind='part' and part_id is not null) or kind='jasa')
);
create index if not exists idx_direct_sale_items_sale on public.direct_sale_items(direct_sale_id);
create index if not exists idx_direct_sale_items_part on public.direct_sale_items(part_id) where part_id is not null;

-- 4. RLS
alter table public.direct_sales enable row level security;
alter table public.direct_sale_items enable row level security;

drop policy if exists "direct_sales_select_authenticated" on public.direct_sales;
create policy "direct_sales_select_authenticated" on public.direct_sales for select to authenticated using (true);
drop policy if exists "direct_sales_insert_authenticated" on public.direct_sales;
create policy "direct_sales_insert_authenticated" on public.direct_sales for insert to authenticated with check (true);
drop policy if exists "direct_sales_update_authenticated" on public.direct_sales;
create policy "direct_sales_update_authenticated" on public.direct_sales for update to authenticated using (true) with check (true);
drop policy if exists "direct_sales_delete_admin" on public.direct_sales;
create policy "direct_sales_delete_admin" on public.direct_sales for delete to authenticated using (public.is_admin());

drop policy if exists "direct_sale_items_select_authenticated" on public.direct_sale_items;
create policy "direct_sale_items_select_authenticated" on public.direct_sale_items for select to authenticated using (true);
drop policy if exists "direct_sale_items_insert_authenticated" on public.direct_sale_items;
create policy "direct_sale_items_insert_authenticated" on public.direct_sale_items for insert to authenticated with check (true);
drop policy if exists "direct_sale_items_update_admin" on public.direct_sale_items;
create policy "direct_sale_items_update_admin" on public.direct_sale_items for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "direct_sale_items_delete_admin" on public.direct_sale_items;
create policy "direct_sale_items_delete_admin" on public.direct_sale_items for delete to authenticated using (public.is_admin());

grant usage on schema public to authenticated, service_role;
grant select, insert, update, delete on table public.direct_sales to authenticated;
grant select, insert, update, delete on table public.direct_sale_items to authenticated;
grant all privileges on table public.direct_sales to service_role;
grant all privileges on table public.direct_sale_items to service_role;
grant usage, select on sequence public.wo_number_seq to authenticated, service_role;
revoke execute on function public.gen_sale_number() from public, anon;
grant execute on function public.gen_sale_number() to authenticated, service_role;

-- 5. RPC atomik checkout: validasi stok + insert header/items + part_movements out
create or replace function public.checkout_direct_sale(
  p_customer_id uuid,
  p_items jsonb,
  p_pay_method text,
  p_paid_amount numeric
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_sale_id uuid;
  v_total numeric(14,2) := 0;
  v_item jsonb;
  v_kind text;
  v_part_id uuid;
  v_qty numeric(10,2);
  v_unit_price numeric(14,2);
  v_discount numeric(14,2);
  v_stock numeric(12,2);
  v_need record;
  v_pay_method public.pay_method;
begin
  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'Minimal 1 item diperlukan';
  end if;

  if p_pay_method is not null and p_pay_method not in ('cash','transfer','qris') then
    raise exception 'Metode pembayaran tidak valid';
  end if;
  v_pay_method := case when p_pay_method in ('cash','transfer','qris') then p_pay_method::public.pay_method else null end;

  -- Hitung total & validasi per-item ringan (discount bound sudah di CHECK, tapi cek pesan ramah)
  for v_item in select * from jsonb_array_elements(p_items) loop
    v_kind := v_item->>'kind';
    v_qty := (v_item->>'qty')::numeric;
    v_unit_price := (v_item->>'unit_price')::numeric;
    v_discount := coalesce((v_item->>'discount')::numeric, 0);
    if v_kind not in ('part','jasa') then raise exception 'Jenis item tidak valid'; end if;
    if v_qty is null or v_qty <= 0 then raise exception 'Jumlah item harus lebih dari 0'; end if;
    if v_unit_price is null or v_unit_price < 0 then raise exception 'Harga item tidak valid'; end if;
    if v_discount < 0 or v_discount > v_qty * v_unit_price then raise exception 'Diskon melebihi subtotal'; end if;
    v_total := v_total + (v_qty * v_unit_price - v_discount);
  end loop;

  if p_paid_amount is null or p_paid_amount < v_total then
    raise exception 'Nominal kurang dari total %', v_total;
  end if;

  -- Validasi stok: agregasi kebutuhan per part, kunci parts ORDER BY id
  for v_need in
    select (e->>'part_id')::uuid as part_id, sum((e->>'qty')::numeric) as need, max(coalesce(e->>'description','Part')) as name
    from jsonb_array_elements(p_items) e
    where e->>'kind'='part'
    group by (e->>'part_id')::uuid
    order by part_id
  loop
    if v_need.part_id is null then raise exception 'Part ID tidak valid pada item part'; end if;
    select stock_qty into v_stock from public.parts where id=v_need.part_id for update;
    if not found then raise exception 'Part tidak ditemukan'; end if;
    if v_stock < v_need.need then
      raise exception 'Stok tidak cukup untuk part % (butuh %, tersedia %)', v_need.name, v_need.need, v_stock;
    end if;
  end loop;

  insert into public.direct_sales (customer_id, cashier_id, paid_amount, pay_method, paid_at)
  values (p_customer_id, auth.uid(), p_paid_amount, v_pay_method, now())
  returning id into v_sale_id;

  insert into public.direct_sale_items (direct_sale_id, kind, part_id, description, qty, unit_price, discount)
  select v_sale_id, (e->>'kind')::public.wo_item_kind,
         case when e->>'part_id' ~ '^[0-9a-f-]{36}$' then (e->>'part_id')::uuid else null end,
         nullif(e->>'description',''), (e->>'qty')::numeric, (e->>'unit_price')::numeric, coalesce((e->>'discount')::numeric,0)
  from jsonb_array_elements(p_items) e;

  insert into public.part_movements (part_id, direction, qty, ref_type, ref_id, created_by)
  select (e->>'part_id')::uuid, 'out', (e->>'qty')::numeric, 'penjualan_langsung', v_sale_id, auth.uid()
  from jsonb_array_elements(p_items) e where e->>'kind'='part';

  return v_sale_id;
end;
$$;
revoke execute on function public.checkout_direct_sale(uuid, jsonb, text, numeric) from public, anon;
grant execute on function public.checkout_direct_sale(uuid, jsonb, text, numeric) to authenticated, service_role;

-- 6. Audit triggers
drop trigger if exists audit_direct_sales on public.direct_sales;
create trigger audit_direct_sales after insert or update or delete on public.direct_sales for each row execute function public.audit_trigger();
drop trigger if exists audit_direct_sale_items on public.direct_sale_items;
create trigger audit_direct_sale_items after insert or update or delete on public.direct_sale_items for each row execute function public.audit_trigger();
