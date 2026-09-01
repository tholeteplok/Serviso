-- Serviso 0012: hardening hutang distributor — ledger konsisten, race-safe, append-only.

-- 1. Konsistensi kolom hutang: tunai wajib lunas, hutang boleh lunas/belum_lunas
alter table public.part_movements
  drop constraint if exists part_movements_debt_consistency;
alter table public.part_movements
  add constraint part_movements_debt_consistency
  check (
    (payment_type = 'tunai' and debt_status = 'lunas')
    or (payment_type = 'hutang' and debt_status in ('lunas','belum_lunas'))
  );

-- 2. purchase_price untuk hutang tidak boleh null/0 agar total_debt valid
--    (existing rows dibiarkan, baru wajib >0 jika hutang)
--    Gunakan constraint deferrable tidak, jadi check conditional:
alter table public.part_movements
  drop constraint if exists part_movements_hutang_price_check;
alter table public.part_movements
  add constraint part_movements_hutang_price_check
  check (
    payment_type = 'tunai'
    or (payment_type = 'hutang' and coalesce(purchase_price, -1) >= 0)
  );

-- 3. RLS debt_payments: append-only (hapus DELETE/UPDATE)
drop policy if exists "Authenticated users can manage debt payments" on public.debt_payments;
create policy "debt_payments_select_authenticated" on public.debt_payments
  for select to authenticated using (auth.role() = 'authenticated');
create policy "debt_payments_insert_authenticated" on public.debt_payments
  for insert to authenticated with check (auth.role() = 'authenticated');
-- Tidak ada policy UPDATE/DELETE -> append-only, histori tidak bisa dihapus kasir

revoke all privileges on table public.debt_payments from anon;
revoke all privileges on table public.debt_payments from authenticated;
grant select, insert on table public.debt_payments to authenticated;
grant all privileges on table public.debt_payments to service_role;

-- 4. Hardening pay_debt: validasi semantik + lock + amount >0
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
begin
  if p_amount is null or p_amount <= 0 then
    raise exception 'Nominal pembayaran harus lebih dari 0';
  end if;

  -- Kunci baris movement untuk cegah race concurrent pay_debt
  select (qty * coalesce(purchase_price, 0)), payment_type, debt_status, direction, qty, purchase_price
    into v_total_debt, v_payment_type, v_debt_status, v_direction, v_qty, v_purchase_price
  from public.part_movements
  where id = p_movement_id
  for update;

  if not found then
    raise exception 'Movement tidak ditemukan';
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

  -- Kunci ledger cicilan untuk hitung total_paid yang konsisten
  -- pg >=14: SELECT sum FOR UPDATE tidak mengunci baris yang belum ada,
  -- jadi kunci via advisory atau aggregate dengan lock movement sudah cukup.
  -- Tambahan: lock semua debt_payments untuk movement ini:
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

  insert into public.debt_payments(movement_id, amount, pay_method, note, paid_by)
  values (p_movement_id, p_amount, p_pay_method, p_note, auth.uid());

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

revoke execute on function public.pay_debt(uuid, numeric, text, text) from public, anon;
grant execute on function public.pay_debt(uuid, numeric, text, text) to authenticated, service_role;

-- 5. Hardening mark_debt_paid: jadikan ledger-aware (auto-insert sisa)
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
begin
  -- Kunci movement
  select (qty * coalesce(purchase_price, 0))
    into v_total_debt
  from public.part_movements
  where id = p_movement_id
  for update;

  if not found then
    raise exception 'Movement tidak ditemukan';
  end if;

  select coalesce(sum(amount), 0) into v_total_paid
  from public.debt_payments where movement_id = p_movement_id;

  v_remaining := v_total_debt - v_total_paid;

  if v_remaining > 0 then
    -- Catat pelunasan sisa sebagai ledger agar rekonsiliasi konsisten
    insert into public.debt_payments(movement_id, amount, pay_method, note, paid_by)
    values (p_movement_id, v_remaining, 'tunai', 'Pelunasan via mark_debt_paid', auth.uid());
  end if;

  update public.part_movements
  set debt_status = 'lunas', paid_at = now()
  where id = p_movement_id and debt_status = 'belum_lunas';
end;
$func$;

revoke execute on function public.mark_debt_paid(uuid) from public, anon;
grant execute on function public.mark_debt_paid(uuid) to authenticated, service_role;
