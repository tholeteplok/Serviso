-- Serviso 0020: RPC Hardening untuk Multi-Tenant (Security Definer fixes & Auth Trigger)

-- 1. pay_debt (security definer)
create or replace function public.pay_debt(
  p_movement_id uuid,
  p_amount numeric,
  p_pay_method text default null,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $func$
declare
  v_total_debt numeric;
  v_total_paid numeric;
  v_remaining numeric;
  v_payment_type text;
  v_debt_status text;
  v_direction public.movement_direction;
  v_qty numeric;
  v_purchase_price numeric;
  v_shop_id uuid;
begin
  if p_amount is null or p_amount <= 0 then
    raise exception 'Nominal pembayaran harus lebih dari 0';
  end if;

  select (qty * coalesce(purchase_price, 0)), payment_type, debt_status, direction, qty, purchase_price, shop_id
    into v_total_debt, v_payment_type, v_debt_status, v_direction, v_qty, v_purchase_price, v_shop_id
  from public.part_movements
  where id = p_movement_id
  for update;

  if not found then
    raise exception 'Movement tidak ditemukan';
  end if;

  if not public.is_platform_admin() and v_shop_id is distinct from public.current_shop_id() then
    raise exception 'Akses ditolak (shop_id mismatch)';
  end if;

  if v_direction <> 'in' then
    raise exception 'Hanya hutang pembelian (stok masuk) yang dapat dicicil';
  end if;

  if v_payment_type <> 'hutang' then
    raise exception 'Movement ini bukan hutang (payment_type=hutang diperlukan)';
  end if;

  if v_debt_status = 'lunas' then
    raise exception 'Hutang sudah lunas';
  end if;

  perform 1 from public.debt_payments where movement_id = p_movement_id for update;

  select coalesce(sum(amount), 0)
    into v_total_paid
  from public.debt_payments
  where movement_id = p_movement_id;

  v_remaining := v_total_debt - v_total_paid;

  if v_remaining <= 0 then
    raise exception 'Hutang sudah lunas';
  end if;

  if p_amount > v_remaining then
    raise exception 'Nominal melebihi sisa hutang (Rp %)', v_remaining;
  end if;

  insert into public.debt_payments(movement_id, amount, pay_method, note, paid_by, shop_id)
  values (p_movement_id, p_amount, p_pay_method, p_note, auth.uid(), v_shop_id);

  v_total_paid := v_total_paid + p_amount;
  if v_total_paid >= v_total_debt then
    update public.part_movements
       set debt_status = 'lunas', paid_at = now()
     where id = p_movement_id;
  end if;

  return jsonb_build_object(
    'total_debt', v_total_debt,
    'total_paid', v_total_paid,
    'remaining', v_total_debt - v_total_paid,
    'is_settled', v_total_paid >= v_total_debt
  );
end;
$func$;

-- 2. mark_debt_paid (security definer)
create or replace function public.mark_debt_paid(p_movement_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $func$
declare
  v_total_debt numeric;
  v_total_paid numeric;
  v_remaining numeric;
  v_shop_id uuid;
begin
  select (qty * coalesce(purchase_price, 0)), shop_id
    into v_total_debt, v_shop_id
  from public.part_movements
  where id = p_movement_id
  for update;

  if not found then
    raise exception 'Movement tidak ditemukan';
  end if;

  if not public.is_platform_admin() and v_shop_id is distinct from public.current_shop_id() then
    raise exception 'Akses ditolak (shop_id mismatch)';
  end if;

  select coalesce(sum(amount), 0) into v_total_paid
  from public.debt_payments where movement_id = p_movement_id;

  v_remaining := v_total_debt - v_total_paid;

  if v_remaining > 0 then
    insert into public.debt_payments(movement_id, amount, pay_method, note, paid_by, shop_id)
    values (p_movement_id, v_remaining, 'tunai', 'Pelunasan via mark_debt_paid', auth.uid(), v_shop_id);
  end if;

  update public.part_movements
  set debt_status = 'lunas', paid_at = now()
  where id = p_movement_id and debt_status = 'belum_lunas';
end;
$func$;

-- 3. handle_new_user (auth trigger)
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
  v_shop_id uuid;
begin
  v_username := coalesce(
    nullif(new.raw_user_meta_data ->> 'username', ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'user'
  );

  v_shop_id := case when new.raw_user_meta_data ->> 'shop_id' ~ '^[0-9a-f-]{36}$' then (new.raw_user_meta_data ->> 'shop_id')::uuid else null end;

  while exists (select 1 from public.profiles p where p.username = v_username and ((v_shop_id is null and p.shop_id is null) or (p.shop_id = v_shop_id))) loop
    v_username := v_username || '_' || substr(md5(random()::text), 1, 4);
  end loop;

  v_email := coalesce(nullif(new.raw_user_meta_data ->> 'email', ''), new.email);
  v_full_name := coalesce(nullif(new.raw_user_meta_data ->> 'full_name', ''), v_username);
  v_role := coalesce(new.raw_user_meta_data ->> 'role', 'kasir');
  insert into public.profiles (id, username, email, full_name, role, is_active, shop_id)
  values (
    new.id,
    v_username,
    v_email,
    v_full_name,
    case when v_role in ('admin', 'kasir') then v_role::public.user_role else 'kasir' end,
    true,
    v_shop_id
  );
  return new;
end;
$$;

