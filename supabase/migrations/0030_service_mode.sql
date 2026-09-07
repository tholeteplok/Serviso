-- Serviso 0030: service_mode — mode jasa ditentukan sekali di Pengaturan, bukan per-WO
--
-- Sebelumnya, toko business_type='keduanya' menampilkan toggle "Data Terdaftar / Manual" di
-- SETIAP pembuatan WO — kasir dipaksa memilih ulang tipe otomotif/umum tiap transaksi. Ini terasa
-- tidak natural: keputusan itu semestinya sifat toko (ditentukan sekali), bukan sifat transaksi.
--
-- service_mode menggantikan toggle itu: dipilih sekali di Pengaturan Toko, WO Wizard langsung
-- mengikuti tanpa bertanya lagi. Relevan untuk business_type 'jasa' MAUPUN 'keduanya' — keduanya
-- independen dari business_type, bukan hanya untuk 'keduanya' saja.

alter table public.shops
  add column if not exists service_mode text
  check (service_mode is null or service_mode in ('otomotif', 'umum'))
  default 'otomotif';

-- Backward-compat: toko existing (semuanya otomotif sejak awal) otomatis dapat 'otomotif',
-- tidak ada perubahan perilaku untuk toko yang sudah berjalan.
update public.shops set service_mode = 'otomotif' where service_mode is null;
alter table public.shops alter column service_mode set not null;
