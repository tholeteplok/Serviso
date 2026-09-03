-- Serviso 0025: Format Nomor Penjualan Langsung (Direct Sales) DS-yymmdd-001

-- 1. Sequence khusus untuk penomoran Direct Sales
create sequence if not exists public.direct_sale_seq start 1;

-- 2. Function generator penomoran dengan format DS-yymmdd-001
create or replace function public.gen_sale_number()
returns text
language plpgsql
volatile
security definer
set search_path = public
as $$
begin
  return 'DS-' || to_char(now(), 'YYMMDD') || '-' || lpad(nextval('public.direct_sale_seq')::text, 3, '0');
end;
$$;

revoke execute on function public.gen_sale_number() from public, anon;
grant execute on function public.gen_sale_number() to authenticated, service_role;

-- 3. Set default column sale_number pada tabel direct_sales
alter table if exists public.direct_sales
  alter column sale_number set default public.gen_sale_number();

-- 4. Perbarui RPC checkout_direct_sale agar mengembalikan jsonb (id & sale_number) dan mendukung multi-tenant
drop function if exists public.checkout_direct_sale(uuid, jsonb, text, numeric);

create or replace function public.checkout_direct_sale(
  p_customer_id uuid,
  p_items jsonb,
  p_pay_method text,
  p_paid_amount numeric
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sale_id uuid;
  v_sale_number text;
  v_shop_id uuid;
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

  v_shop_id := public.current_shop_id();

  -- Hitung total & validasi per-item
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

  insert into public.direct_sales (customer_id, cashier_id, paid_amount, pay_method, paid_at, shop_id)
  values (p_customer_id, auth.uid(), p_paid_amount, v_pay_method, now(), v_shop_id)
  returning id, sale_number into v_sale_id, v_sale_number;

  insert into public.direct_sale_items (direct_sale_id, kind, part_id, description, qty, unit_price, discount, shop_id)
  select v_sale_id, (e->>'kind')::public.wo_item_kind,
         case when e->>'part_id' ~ '^[0-9a-f-]{36}$' then (e->>'part_id')::uuid else null end,
         nullif(e->>'description',''), (e->>'qty')::numeric, (e->>'unit_price')::numeric, coalesce((e->>'discount')::numeric,0), v_shop_id
  from jsonb_array_elements(p_items) e;

  insert into public.part_movements (part_id, direction, qty, ref_type, ref_id, created_by, shop_id)
  select (e->>'part_id')::uuid, 'out', (e->>'qty')::numeric, 'penjualan_langsung', v_sale_id, auth.uid(), v_shop_id
  from jsonb_array_elements(p_items) e where e->>'kind'='part';

  return jsonb_build_object(
    'id', v_sale_id,
    'sale_number', v_sale_number
  );
end;
$$;

revoke execute on function public.checkout_direct_sale(uuid, jsonb, text, numeric) from public, anon;
grant execute on function public.checkout_direct_sale(uuid, jsonb, text, numeric) to authenticated, service_role;
