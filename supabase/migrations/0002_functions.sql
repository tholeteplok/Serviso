-- Serviso 0002: fungsi RPC bisnis + trigger sinkronisasi stok & transisi status WO.

-- ===== Lookup email untuk login username (Task 2) =====
create or replace function public.lookup_login_email(p_username citext)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select email from public.profiles where username = p_username and is_active limit 1;
$$;

revoke execute on function public.lookup_login_email(citext) from public;
revoke execute on function public.lookup_login_email(citext) from anon;
grant execute on function public.lookup_login_email(citext) to authenticated, service_role;

-- ===== Audit event login/logout (dipanggil client setelah sign-in / sebelum sign-out) =====
create or replace function public.record_auth_event(p_action public.audit_action)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_action not in ('login', 'logout') then
    raise exception 'Hanya aksi login atau logout yang boleh dicatat.';
  end if;
  insert into public.audit_logs (actor_id, action, table_name, record_id)
  values (auth.uid(), p_action, 'auth', auth.uid()::text);
end;
$$;

revoke execute on function public.record_auth_event(public.audit_action) from public;
revoke execute on function public.record_auth_event(public.audit_action) from anon;
grant execute on function public.record_auth_event(public.audit_action) to authenticated, service_role;

-- ===== Sinkronisasi stok dari kartu stok: satu-satunya jalur perubahan parts.stock_qty =====
-- SECURITY DEFINER agar tidak butuh hak UPDATE kolom stock_qty bagi user biasa,
-- sekaligus menjamin stok tidak pernah ditulis langsung di luar movement.
create or replace function public.apply_movement_to_stock()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.parts
  set stock_qty = stock_qty + case new.direction
    when 'in' then new.qty
    when 'out' then -new.qty
    else new.qty
  end
  where id = new.part_id;
  return new;
end;
$$;

revoke execute on function public.apply_movement_to_stock() from public, anon, authenticated;

create trigger trg_part_movements_stock
after insert on public.part_movements
for each row execute function public.apply_movement_to_stock();

-- ===== Penjaga transisi status work_orders (update langsung dari client tetap sah untuk start/pembayaran, ilegal untuk lompatan status) =====
create or replace function public.enforce_wo_transition()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.status is distinct from old.status then
    if old.status = 'menunggu' and new.status in ('dikerjakan', 'dibatalkan') then
      null;
    elsif old.status = 'dikerjakan' and new.status in ('selesai', 'dibatalkan') then
      null;
    elsif old.status = 'selesai' and new.status = 'dibatalkan' then
      null;
    else
      raise exception 'Perubahan status % ke % tidak diizinkan.', old.status, new.status;
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

revoke execute on function public.enforce_wo_transition() from public, anon, authenticated;

create trigger trg_work_orders_transition
before update on public.work_orders
for each row execute function public.enforce_wo_transition();

-- ===== Selesaikan work order: posting keluar stok + status selesai =====
create or replace function public.complete_work_order(p_work_order_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_status public.wo_status;
  v_stock int;
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

  -- Validasi stok: agregasi kebutuhan per part lalu bandingkan sekali terhadap stok
  -- setelah baris part dikunci (urut part_id untuk menghindari deadlock).
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

  -- Posting keluar stok per item; trigger trg_part_movements_stock menyesuaikan stock_qty.
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

-- ===== Batalkan work order (admin): balikkan stok bila sudah selesai =====
create or replace function public.cancel_work_order(p_work_order_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_status public.wo_status;
begin
  if not exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  ) then
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
