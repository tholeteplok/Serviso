-- ============================================================================
-- Serviso smoke.sql — verifikasi manual backend.
-- Jalankan di Supabase SQL Editor (sebagai owner/postgres) SETELAH migrasi
-- 0001-0004 sukses dijalankan, satu transaksi penuh sekaligus.
-- Sukses = deretan notice "OK: ..." tanpa error, diakhiri "SMOKE SELESAI".
-- Gagal = exception "ASSERT GAGAL: ..." dan seluruh bagian terkait rollback.
-- Data uji dibiarkan tinggal untuk inspeksi; bagian 0 membersihkannya saat
-- skrip dijalankan lagi. User uji memakai password dummy (tidak bisa login).
-- ============================================================================

-- ---------- Bagian 0: bersihkan sisa data uji dari run sebelumnya ----------
begin;
delete from public.wo_items
where work_order_id in (
  '66666666-6666-6666-6666-666666666666',
  '77777777-7777-7777-7777-777777777777'
);
delete from public.part_movements where part_id = '55555555-5555-5555-5555-555555555555';
delete from public.work_orders where id in (
  '66666666-6666-6666-6666-666666666666',
  '77777777-7777-7777-7777-777777777777'
);
delete from public.vehicles where id = '44444444-4444-4444-4444-444444444444';
delete from public.customers where id = '33333333-3333-3333-3333-333333333333';
delete from public.parts where id = '55555555-5555-5555-5555-555555555555';
delete from auth.users where id in (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222'
);
commit;

-- ---------- Bagian 1: seed user auth (trigger buat profiles), settings, master data ----------
begin;
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
values
  ('00000000-0000-0000-0000-000000000000',
   '11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated',
   'admin@serviso.test', '$2a$10$smokedummyhashsmokedummyhashsmokedummyhashsmoke00',
   now(), now(), now(),
   '{"provider":"email","providers":["email"]}',
   '{"username":"admin","full_name":"Admin Bengkel","role":"admin"}',
   '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000',
   '22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated',
   'kasir@serviso.test', '$2a$10$smokedummyhashsmokedummyhashsmokedummyhashsmoke11',
   now(), now(), now(),
   '{"provider":"email","providers":["email"]}',
   '{"username":"kasir01","full_name":"Kasir Satu"}',
   '', '', '', '');

do $$
begin
  if (select role from public.profiles where id = '11111111-1111-1111-1111-111111111111') <> 'admin' then
    raise exception 'ASSERT GAGAL: role admin tidak terisi dari metadata';
  end if;
  if (select username from public.profiles where id = '22222222-2222-2222-2222-222222222222') <> 'kasir01' then
    raise exception 'ASSERT GAGAL: username kasir tidak sesuai metadata';
  end if;
  raise notice 'OK: trigger on_auth_user_created membuat profiles sesuai metadata';
end $$;

insert into public.app_settings (id, shop_name) values (1, 'Bengkel Uji Serviso');

insert into public.customers (id, name, phone)
values ('33333333-3333-3333-3333-333333333333', 'Budi Santoso', '081234567890');

insert into public.vehicles (id, customer_id, plate_no, brand, model, year)
values ('44444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333',
        'B 1234 XYZ', 'Toyota', 'Avanza', 2019);

insert into public.parts (id, code, name, stock_qty, min_stock, cost_price, sell_price)
values ('55555555-5555-5555-5555-555555555555', 'OLI-10W40', 'Oli Mesin 10W-40',
        10, 3, 80000, 120000);
commit;

-- ---------- Bagian 2 (admin): WO baru + nomor otomatis ----------
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

insert into public.work_orders (id, vehicle_id, complaint, odometer_in, assigned_to)
values ('66666666-6666-6666-6666-666666666666', '44444444-4444-4444-4444-444444444444',
        'Oli hitam, mesin berbunyi', 45000, '11111111-1111-1111-1111-111111111111');

insert into public.wo_items (work_order_id, kind, part_id, description, qty, unit_price)
values ('66666666-6666-6666-6666-666666666666', 'part', '55555555-5555-5555-5555-555555555555',
        'Oli Mesin 10W-40', 4, 120000),
       ('66666666-6666-6666-6666-666666666666', 'jasa', null,
        'Ganti oli + tune up ringan', 1, 150000);

do $$
declare v_num text;
begin
  select wo_number into v_num from public.work_orders where id = '66666666-6666-6666-6666-666666666666';
  if v_num is null or v_num !~ '^WO-[0-9]{6}-[0-9]{3,}$' then
    raise exception 'ASSERT GAGAL: format wo_number salah: %', coalesce(v_num, '<null>');
  end if;
  raise notice 'OK: wo_number otomatis tergenerate: %', v_num;
end $$;
commit;

-- ---------- Bagian 3 (admin): start -> complete -> assert stok & audit ----------
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

update public.work_orders set status = 'dikerjakan', started_at = now()
where id = '66666666-6666-6666-6666-666666666666';

-- Lompatan status langsung ke selesai harus ditolak trigger penjaga transisi.
do $$
begin
  update public.work_orders set status = 'menunggu'
  where id = '66666666-6666-6666-6666-666666666666';
  raise exception 'ASSERT GAGAL: regresi status harusnya ditolak';
exception
  when others then
    if sqlerrm not like 'Perubahan status%' then
      raise exception 'ASSERT GAGAL: pesan transisi salah: %', sqlerrm;
    end if;
    raise notice 'OK: lompatan/regresi status ditolak trigger: %', sqlerrm;
end $$;

do $$
declare n_before bigint; n_after bigint; v_qty numeric;
begin
  select count(*) into n_before from public.audit_logs;

  perform public.complete_work_order('66666666-6666-6666-6666-666666666666');

  if (select status from public.work_orders where id = '66666666-6666-6666-6666-666666666666') <> 'selesai' then
    raise exception 'ASSERT GAGAL: status tidak menjadi selesai';
  end if;
  if (select completed_at from public.work_orders where id = '66666666-6666-6666-6666-666666666666') is null then
    raise exception 'ASSERT GAGAL: completed_at kosong';
  end if;

  select stock_qty into v_qty from public.parts where id = '55555555-5555-5555-5555-555555555555';
  if v_qty <> 6 then
    raise exception 'ASSERT GAGAL: stock_qty harus 6, dapat %', v_qty;
  end if;

  select qty into v_qty from public.part_movements
  where ref_type = 'wo' and ref_id = '66666666-6666-6666-6666-666666666666' and direction = 'out';
  if v_qty is null or v_qty <> 4 then
    raise exception 'ASSERT GAGAL: movement out tidak sesuai (dapat %)', coalesce(v_qty, '<null>');
  end if;

  select count(*) into n_after from public.audit_logs;
  if n_after <= n_before then
    raise exception 'ASSERT GAGAL: audit_logs tidak bertambah (% -> %)', n_before, n_after;
  end if;
  raise notice 'OK: complete_work_order — stok 10->6, movement out qty 4, audit naik %->%', n_before, n_after;
end $$;

-- Complete ulang harus ditolak dengan pesan Indonesia yang tepat.
do $$
begin
  perform public.complete_work_order('66666666-6666-6666-6666-666666666666');
  raise exception 'ASSERT GAGAL: complete ulang harusnya ditolak';
exception
  when others then
    if sqlerrm not like 'Work order sudah selesai%' then
      raise exception 'ASSERT GAGAL: pesan complete ulang salah: %', sqlerrm;
    end if;
    raise notice 'OK: complete ulang ditolak: %', sqlerrm;
end $$;
commit;

-- ---------- Bagian 4 (admin): complete dengan stok kurang harus gagal atomik ----------
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

insert into public.work_orders (id, vehicle_id, complaint)
values ('77777777-7777-7777-7777-777777777777', '44444444-4444-4444-4444-444444444444',
        'Uji kebutuhan stok melebihi persediaan');
insert into public.wo_items (work_order_id, kind, part_id, description, qty, unit_price)
values ('77777777-7777-7777-7777-777777777777', 'part', '55555555-5555-5555-5555-555555555555',
        'Oli (uji stok kurang)', 999, 120000);
update public.work_orders set status = 'dikerjakan', started_at = now()
where id = '77777777-7777-7777-7777-777777777777';

do $$
declare v_stock int;
begin
  perform public.complete_work_order('77777777-7777-7777-7777-777777777777');
  raise exception 'ASSERT GAGAL: stok kurang harusnya ditolak';
exception
  when others then
    if sqlerrm not like 'Stok tidak cukup%' then
      raise exception 'ASSERT GAGAL: pesan stok kurang salah: %', sqlerrm;
    end if;
    select stock_qty into v_stock from public.parts where id = '55555555-5555-5555-5555-555555555555';
    if v_stock <> 6 then
      raise exception 'ASSERT GAGAL: stok berubah saat validasi gagal (dapat %)', v_stock;
    end if;
    raise notice 'OK: complete stok kurang ditolak atomik: %', sqlerrm;
end $$;

delete from public.wo_items where work_order_id = '77777777-7777-7777-7777-777777777777';
delete from public.work_orders where id = '77777777-7777-7777-7777-777777777777';
commit;

-- ---------- Bagian 5 (admin): cancel WO selesai -> pembalikan stok ----------
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

do $$
declare v_stock int; n_rev int;
begin
  perform public.cancel_work_order('66666666-6666-6666-6666-666666666666');

  if (select status from public.work_orders where id = '66666666-6666-6666-6666-666666666666') <> 'dibatalkan' then
    raise exception 'ASSERT GAGAL: status tidak menjadi dibatalkan';
  end if;

  select stock_qty into v_stock from public.parts where id = '55555555-5555-5555-5555-555555555555';
  if v_stock <> 10 then
    raise exception 'ASSERT GAGAL: stok harus kembali 10, dapat %', v_stock;
  end if;

  select count(*) into n_rev from public.part_movements
  where direction = 'in' and ref_type = 'pembatalan'
    and ref_id = '66666666-6666-6666-6666-666666666666' and qty = 4;
  if n_rev <> 1 then
    raise exception 'ASSERT GAGAL: movement pembalikan tidak ada (dapat %)', n_rev;
  end if;
  raise notice 'OK: cancel_work_order membalikkan stok 6->10 dengan movement pembatalan';
end $$;

-- Batalkan ulang harus ditolak.
do $$
begin
  perform public.cancel_work_order('66666666-6666-6666-6666-666666666666');
  raise exception 'ASSERT GAGAL: cancel ulang harusnya ditolak';
exception
  when others then
    if sqlerrm not like 'Work order sudah dibatalkan%' then
      raise exception 'ASSERT GAGAL: pesan cancel ulang salah: %', sqlerrm;
    end if;
    raise notice 'OK: cancel ulang ditolak: %', sqlerrm;
end $$;
commit;

-- ---------- Bagian 6 (kasir): RLS denials + kontrol positif ----------
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

do $$
declare n int;
begin
  select count(*) into n from public.parts;
  if n = 0 then raise exception 'ASSERT GAGAL: kasir tidak bisa baca parts'; end if;
  select count(*) into n from public.work_orders;
  if n = 0 then raise exception 'ASSERT GAGAL: kasir tidak bisa baca work_orders'; end if;
  raise notice 'OK: kasir membaca parts & work_orders (kontrol positif)';
end $$;

-- Kasir tidak bisa hapus parts: policy delete admin-only menyaring baris (tetap ada).
do $$
begin
  delete from public.parts where id = '55555555-5555-5555-5555-555555555555';
  if not exists (select 1 from public.parts where id = '55555555-5555-5555-5555-555555555555') then
    raise exception 'ASSERT GAGAL: part terhapus oleh kasir!';
  end if;
  raise notice 'OK: kasir DELETE parts ditolak RLS (baris tetap ada)';
end $$;

-- Kasir tidak melihat audit_logs sama sekali.
do $$
declare n int;
begin
  select count(*) into n from public.audit_logs;
  if n <> 0 then raise exception 'ASSERT GAGAL: kasir melihat % baris audit_logs', n; end if;
  raise notice 'OK: kasir tidak dapat membaca audit_logs';
end $$;

-- Insert langsung audit_logs ditolak (tanpa policy insert).
do $$
begin
  insert into public.audit_logs (actor_id, action, table_name, record_id)
  values (auth.uid(), 'login', 'auth', auth.uid()::text);
  raise exception 'ASSERT GAGAL: kasir berhasil insert audit_logs';
exception
  when insufficient_privilege then
    raise notice 'OK: insert audit_logs oleh kasir ditolak RLS';
end $$;

-- Item WO selesai tidak boleh berubah oleh siapa pun lewat client.
do $$
declare q numeric;
begin
  update public.wo_items set qty = 99 where work_order_id = '66666666-6666-6666-6666-666666666666';
  select qty into q from public.wo_items
  where work_order_id = '66666666-6666-6666-6666-666666666666' and kind = 'part';
  if q <> 4 then raise exception 'ASSERT GAGAL: qty item berubah jadi %', q; end if;
  raise notice 'OK: update wo_items pada WO selesai diblokir RLS';
end $$;

-- Kasir tidak bisa update app_settings.
do $$
declare nm text;
begin
  update public.app_settings set shop_name = 'Diganti Kasir';
  select shop_name into nm from public.app_settings where id = 1;
  if nm <> 'Bengkel Uji Serviso' then
    raise exception 'ASSERT GAGAL: app_settings berubah oleh kasir: %', nm;
  end if;
  raise notice 'OK: kasir update app_settings diblokir RLS';
end $$;

-- Kasir mencoba membatalkan WO: RPC menolak (validasi admin di dalam fungsi).
do $$
begin
  perform public.cancel_work_order('66666666-6666-6666-6666-666666666666');
  raise exception 'ASSERT GAGAL: kasir berhasil membatalkan WO';
exception
  when others then
    if sqlerrm not like 'Hanya admin%' then
      raise exception 'ASSERT GAGAL: pesan cancel kasir salah: %', sqlerrm;
    end if;
    raise notice 'OK: cancel_work_order oleh kasir ditolak: %', sqlerrm;
end $$;
commit;

-- ---------- Bagian 7 (admin): path admin tetap jalan ----------
begin;
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

update public.app_settings set shop_name = 'Bengkel Uji Serviso (diubah admin)' where id = 1;

do $$
begin
  if (select shop_name from public.app_settings where id = 1) <> 'Bengkel Uji Serviso (diubah admin)' then
    raise exception 'ASSERT GAGAL: admin gagal update app_settings';
  end if;
  raise notice 'OK: admin update app_settings';
end $$;
commit;

do $$
begin
  raise notice 'SMOKE SELESAI: semua assert hijau.';
end $$;
