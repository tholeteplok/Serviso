-- Serviso 0007: Penambahan kolom distributor, harga beli, metode bayar (tunai/hutang), dan pelunasan pada kartu stok.

alter table public.part_movements 
  add column if not exists distributor text,
  add column if not exists purchase_price numeric(14,2),
  add column if not exists payment_type text not null default 'tunai' 
    constraint part_movements_payment_type_check check (payment_type in ('tunai', 'hutang')),
  add column if not exists debt_status text not null default 'lunas'
    constraint part_movements_debt_status_check check (debt_status in ('lunas', 'belum_lunas')),
  add column if not exists due_date date,
  add column if not exists paid_at timestamptz;

create index if not exists idx_part_movements_unpaid_debt 
  on public.part_movements(debt_status, created_at) 
  where debt_status = 'belum_lunas';

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
