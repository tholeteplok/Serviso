-- Serviso 0007: Penambahan kolom distributor, harga beli, metode bayar (tunai/hutang), dan pelunasan pada kartu stok.

-- 1. Penambahan Kolom Baru pada part_movements
alter table public.part_movements 
  add column if not exists distributor text,
  add column if not exists purchase_price numeric(14,2),
  add column if not exists payment_type text not null default 'tunai' 
    constraint part_movements_payment_type_check check (payment_type in ('tunai', 'hutang')),
  add column if not exists debt_status text not null default 'lunas'
    constraint part_movements_debt_status_check check (debt_status in ('lunas', 'belum_lunas')),
  add column if not exists due_date date,
  add column if not exists paid_at timestamptz;

-- 2. Backfill Otomatis Data Lama yang tersimpan via Fallback Text
-- Tandai transaksi dengan note [HUTANG] sebagai hutang & belum lunas
update public.part_movements
set payment_type = 'hutang',
    debt_status = 'belum_lunas'
where note like '%[HUTANG]%' and (debt_status is null or debt_status = 'lunas');

-- Ekstrak nama distributor dari note yang memiliki format [Distributor: ...]
update public.part_movements
set distributor = trim(substring(note from '\[Distributor:\s*([^\]]+)\]'))
where note like '%[Distributor:%' and (distributor is null or distributor = '');

-- Isi purchase_price dari parts.cost_price untuk data lama yang harga belinya kosong
update public.part_movements pm
set purchase_price = p.cost_price
from public.parts p
where pm.part_id = p.id
  and pm.direction = 'in'
  and (pm.purchase_price is null or pm.purchase_price = 0);

-- 3. Index untuk Query Hutang Belum Lunas
create index if not exists idx_part_movements_unpaid_debt 
  on public.part_movements(debt_status, created_at) 
  where debt_status = 'belum_lunas';

-- 4. Stored Procedure Pelunasan Hutang
create or replace function public.mark_debt_paid(p_movement_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $func$
begin
  update public.part_movements
  set debt_status = 'lunas',
      paid_at = now()
  where id = p_movement_id and debt_status = 'belum_lunas';
end;
$func$;

revoke execute on function public.mark_debt_paid(uuid) from public, anon;
grant execute on function public.mark_debt_paid(uuid) to authenticated, service_role;
