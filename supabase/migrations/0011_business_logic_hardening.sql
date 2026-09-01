-- Serviso 0011: hardening logika bisnis Fase 1 — stok, status WO, discount.
-- Urutan: lock wo_items TOCTOU, admin guard, discount bound.

-- 1. Guard discount tidak boleh melebihi subtotal baris (qty * unit_price)
--    Menutup celah total negatif di work_order.dart:52 lineTotal.
alter table public.wo_items
  drop constraint if exists wo_items_discount_bounded;

alter table public.wo_items
  add constraint wo_items_discount_bounded
  check (discount <= qty * unit_price);

-- 2. Hardening transisi status: pembatalan dari dikerjakan/selesai wajib admin
--    Menutup bypass RLS work_orders_update_authenticated USING true.
create or replace function public.enforce_wo_transition()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.status is distinct from old.status then
    if old.status = 'menunggu' and new.status in ('dikerjakan', 'dibatalkan') then
      -- menunggu -> dibatalkan diizinkan untuk kasir (UI: kasir boleh batal antrian)
      -- menunggu -> dikerjakan bebas
      null;
    elsif old.status = 'dikerjakan' and new.status = 'menunggu' then
      -- kembali antri (mis. teknisi salah start) — bebas
      null;
    elsif old.status = 'dikerjakan' and new.status in ('selesai', 'dibatalkan') then
      -- dikerjakan -> selesai hanya via complete_work_order (cek completed_at di bawah)
      -- dikerjakan -> dibatalkan wajib admin
      if new.status = 'dibatalkan' and not public.is_admin() then
        raise exception 'Hanya pemilik/admin yang dapat membatalkan work order dari status %.', old.status;
      end if;
    elsif old.status = 'selesai' and new.status = 'dibatalkan' then
      if not public.is_admin() then
        raise exception 'Hanya pemilik/admin yang dapat membatalkan work order yang sudah selesai.';
      end if;
    else
      raise exception 'Perubahan status dari % ke % tidak diizinkan.', old.status, new.status;
    end if;
  end if;

  if new.status = 'selesai' and new.completed_at is null then
    raise exception 'Work order selesai wajib memiliki completed_at. Gunakan complete_work_order.';
  end if;
  if new.status = 'dibatalkan' and new.cancelled_at is null then
    raise exception 'Work order dibatalkan wajib memiliki cancelled_at. Gunakan cancel_work_order.';
  end if;
  return new;
end;
$$;

-- trigger sudah ada, function replace cukup (revoke tetap)
revoke execute on function public.enforce_wo_transition() from public, anon, authenticated;
drop trigger if exists trg_work_orders_transition on public.work_orders;
create trigger trg_work_orders_transition
before update on public.work_orders
for each row execute function public.enforce_wo_transition();

-- 3. Fix complete_work_order: lock wo_items untuk tutup TOCTOU 4.3
create or replace function public.complete_work_order(p_work_order_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_status public.wo_status;
  v_stock numeric(12,2);
  rec record;
begin
  select status into v_status
  from public.work_orders
  where id = p_work_order_id
  for update;

  if not found then
    raise exception 'Work order tidak ditemukan.';
  end if;

  if v_status = 'selesai' then
    raise exception 'Work order sudah selesai.';
  elsif v_status = 'dibatalkan' then
    raise exception 'Work order sudah dibatalkan.';
  elsif v_status = 'menunggu' then
    raise exception 'Work order belum dikerjakan. Mulai kerja dulu sebelum menyelesaikan.';
  end if;

  -- Kunci semua baris wo_items untuk WO ini sebelum validasi — mencegah INSERT
  -- konkuren (RLS masih izinkan addItem saat dikerjakan) yang belum tervalidasi.
  perform 1 from public.wo_items
  where work_order_id = p_work_order_id
  for update;

  -- Validasi stok: agregasi kebutuhan per part setelah wo_items terkunci,
  -- lalu kunci baris part urut part_id (hindari deadlock).
  for rec in
    select wi.part_id, sum(wi.qty) as need_qty, max(p.name) as part_name
    from public.wo_items wi
    join public.parts p on p.id = wi.part_id
    where wi.work_order_id = p_work_order_id and wi.kind = 'part'
    group by wi.part_id
    order by wi.part_id
  loop
    select stock_qty into v_stock
    from public.parts
    where id = rec.part_id
    for update;

    if v_stock < rec.need_qty then
      raise exception 'Stok tidak cukup untuk part % (butuh %, tersedia %).', rec.part_name, rec.need_qty, v_stock;
    end if;
  end loop;

  insert into public.part_movements (part_id, direction, qty, ref_type, ref_id, created_by)
  select wi.part_id, 'out', wi.qty, 'wo', p_work_order_id, auth.uid()
  from public.wo_items wi
  where wi.work_order_id = p_work_order_id and wi.kind = 'part';

  update public.work_orders
  set status = 'selesai', completed_at = now()
  where id = p_work_order_id;
end;
$$;

revoke execute on function public.complete_work_order(uuid) from public;
revoke execute on function public.complete_work_order(uuid) from anon;
grant execute on function public.complete_work_order(uuid) to authenticated, service_role;

-- 4. Fix cancel_work_order: pakai is_admin() (cek is_active) bukan role check mentah
create or replace function public.cancel_work_order(p_work_order_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_status public.wo_status;
begin
  if not public.is_admin() then
    raise exception 'Hanya admin yang dapat membatalkan work order.';
  end if;

  select status into v_status
  from public.work_orders
  where id = p_work_order_id
  for update;

  if not found then
    raise exception 'Work order tidak ditemukan.';
  end if;

  if v_status = 'dibatalkan' then
    raise exception 'Work order sudah dibatalkan.';
  end if;

  if v_status = 'selesai' then
    insert into public.part_movements (part_id, direction, qty, ref_type, ref_id, note, created_by)
    select pm.part_id, 'in', pm.qty, 'pembatalan', pm.ref_id,
           'Pembalikan stok karena pembatalan work order.', auth.uid()
    from public.part_movements pm
    where pm.direction = 'out' and pm.ref_type = 'wo' and pm.ref_id = p_work_order_id;
  end if;

  update public.work_orders
  set status = 'dibatalkan', cancelled_at = now()
  where id = p_work_order_id;
end;
$$;

revoke execute on function public.cancel_work_order(uuid) from public;
revoke execute on function public.cancel_work_order(uuid) from anon;
grant execute on function public.cancel_work_order(uuid) to authenticated, service_role;
