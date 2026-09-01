-- Serviso 0009: Pembayaran hutang parsial (cicilan) per distributor.
-- Menambahkan tabel debt_payments sebagai ledger cicilan dan
-- stored procedure pay_debt untuk validasi + auto-lunas.

-- 1. Tabel riwayat pembayaran hutang (mendukung parsial)
create table if not exists public.debt_payments (
  id uuid primary key default gen_random_uuid(),
  movement_id uuid not null references public.part_movements(id) on delete cascade,
  amount numeric(14,2) not null check (amount > 0),
  pay_method text,
  note text,
  paid_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

-- 2. Index untuk lookup cepat per movement
create index if not exists idx_debt_payments_movement
  on public.debt_payments(movement_id);

-- 3. RLS: hanya authenticated user
alter table public.debt_payments enable row level security;

create policy "Authenticated users can manage debt payments"
  on public.debt_payments for all
  using (auth.role() = 'authenticated')
  with check (auth.role() = 'authenticated');

-- 4. Stored procedure: bayar hutang parsial/penuh
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
begin
  -- Ambil total hutang dari movement
  select (qty * coalesce(purchase_price, 0))
    into v_total_debt
    from part_movements
   where id = p_movement_id;

  if v_total_debt is null then
    raise exception 'Movement tidak ditemukan';
  end if;

  -- Hitung total yang sudah dibayar
  select coalesce(sum(amount), 0)
    into v_total_paid
    from debt_payments
   where movement_id = p_movement_id;

  v_remaining := v_total_debt - v_total_paid;

  if p_amount > v_remaining then
    raise exception 'Nominal melebihi sisa hutang (Rp %)', v_remaining;
  end if;

  -- Insert pembayaran
  insert into debt_payments(movement_id, amount, pay_method, note, paid_by)
  values (p_movement_id, p_amount, p_pay_method, p_note, auth.uid());

  -- Update status jika total pembayaran sudah >= total hutang
  v_total_paid := v_total_paid + p_amount;
  if v_total_paid >= v_total_debt then
    update part_movements
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
