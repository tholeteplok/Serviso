-- Serviso 0016: perbaiki constraint hutang agar tidak memblokir stok masuk hutang tanpa harga (fallback ke cost_price).
-- Sebelumnya: hutang dengan purchase_price NULL ditolak (COALESCE -1), menyebabkan fallback yang menghilangkan purchase_price/distributor.
-- Sekarang: hutang boleh NULL, tapi jika diisi harus >=0.

alter table public.part_movements drop constraint if exists part_movements_hutang_price_check;
alter table public.part_movements
  add constraint part_movements_hutang_price_check
  check (payment_type = 'tunai' or purchase_price is null or purchase_price >= 0);

-- Pastikan distributor tidak kosong untuk hutang jika diisi, tapi tetap nullable untuk kompatibilitas lama
-- (validasi wajib distributor untuk hutang dilakukan di aplikasi, bukan DB, agar tidak break data lama tunai)
