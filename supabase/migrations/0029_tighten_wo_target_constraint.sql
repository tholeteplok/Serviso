-- Serviso 0029: Perketat constraint work_orders — customer_id wajib di jalur service_label
--
-- Migrasi 0027 hanya mewajibkan (vehicle_id IS NOT NULL OR service_label IS NOT NULL), sehingga
-- WO jalur manual/jasa-umum bisa dibuat TANPA customer_id sama sekali — nota, riwayat, dan
-- notifikasi jadi tidak punya pelanggan yang valid untuk kasus itu (lihat diskusi jenis usaha).

-- 1. Backfill: WO manual lama yang terlanjur tanpa customer_id tidak bisa di-invent datanya,
--    jadi tidak ada backfill otomatis di sini — constraint baru hanya berlaku untuk INSERT baru.
--    (Data lama yang sudah ada tetap dibiarkan; kalau ingin diberi tanda, tambahkan flag terpisah,
--    bukan dipaksa constraint retroaktif yang akan gagal migrate kalau ada data lama semacam ini.)

alter table public.work_orders
  drop constraint if exists work_orders_target_check;

alter table public.work_orders
  add constraint work_orders_target_check
  check (
    vehicle_id is not null
    or (service_label is not null and customer_id is not null)
  );
