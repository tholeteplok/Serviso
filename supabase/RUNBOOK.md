# Serviso — Supabase Runbook

Panduan menyiapkan backend database Serviso dari nol sampai aplikasi bisa login.
Semua langkah memakai dashboard Supabase (SQL Editor) — tidak butuh CLI.

## 1. Buat project Supabase

1. Masuk ke [supabase.com](https://supabase.com) → **New project**.
2. Nama: `serviso`. Region terdekat (rekomendasi: Singapore). Buat database password
   yang kuat dan simpan di password manager.
3. Tunggu provisioning selesai (~2 menit).

## 2. Jalankan migrasi (WAJIB berurutan)

Buka **SQL Editor** → New query → paste isi file → **Run**. Ulangi satu per satu:

| Urutan | File | Isi |
| --- | --- | --- |
| 1 | `supabase/migrations/0001_schema.sql` | enum, tabel, index, trigger auth + updated_at |
| 2 | `supabase/migrations/0002_functions.sql` | RPC bisnis, sinkronisasi stok, penjaga transisi WO |
| 3 | `supabase/migrations/0003_audit.sql` | trigger audit untuk 7 tabel |
| 4 | `supabase/migrations/0004_rls.sql` | helper `is_admin()`, RLS, policy, grants |

Verifikasi cepat setelah selesai:

- **Table Editor**: muncul 9 tabel (`profiles`, `customers`, `vehicles`, `parts`,
  `part_movements`, `work_orders`, `wo_items`, `audit_logs`, `app_settings`).
- **Database → Triggers**: ada trigger pada `auth.users`, `part_movements`,
  `work_orders`, dan 7 trigger audit.
- **Database → Roles**: tidak perlu diubah; semua grant sudah di dalam migrasi.

Urutan tidak boleh dibalik: `0004` butuh semua tabel, `0001` membuat fungsi
`gen_wo_number()` yang dipakai sebagai default kolom `work_orders.wo_number`.

## 3. Seed pengaturan bengkel

```sql
insert into public.app_settings (shop_name) values ('Bengkel Serviso');
```

(Tasks 6 menyertakan migrasi seed resmi `0005_app_settings_seed.sql`; langkah ini
opsional jika ingin nama bengkel benar lebih awal.)

## 4. Invite user admin pertama

1. **Authentication → Users → Invite user**.
2. Isi email pemilik bengkel, lalu isi **User Metadata (JSON)**:

```json
{
  "username": "admin",
  "full_name": "Nama Pemilik",
  "role": "admin"
}
```

3. Pemilik membuka email undangan → set password → login di aplikasi memakai
   **username** (`admin`), bukan email.

Trigger `on_auth_user_created` otomatis membuat baris `profiles` dari metadata itu.
`role` hanya mengenal `admin` / `kasir`; nilai lain jatuh ke `kasir`.
Undangan user berikutnya (kasir) sama, tanpa `role` atau dengan `"role":"kasir"`.

## 5. SMTP custom untuk produksi

Email bawaan Supabase dibatasi ketat (~2 email/jam). Untuk produksi — supaya reset
password selalu terkirim — pasang SMTP custom: **Project Settings → Authentication
→ SMTP Settings** → isi provider/kredensial SMTP sendiri. Tanpa ini, fitur "Lupa
Password" akan sering gagal kirim di pemakaian nyata.

## 6. Verifikasi dengan smoke test

**SQL Editor** → paste seluruh `supabase/tests/smoke.sql` → **Run**.

Ekspektasi: deretan notice `OK: ...` tanpa error, diakhiri `SMOKE SELESAI: semua
assert hijau.` Cakupan: trigger profil, nomor WO otomatis, alur
mulai→selesai→batal beserta gerakan stok & audit, penolakan stok kurang,
penolakan double-complete/double-cancel, serta RLS untuk kasir (tidak bisa hapus
part, tidak melihat audit log, tidak bisa ubah settings/item WO selesai).

Data uji (user `admin@serviso.test` / `kasir@serviso.test`, password dummy tidak
dipakai untuk login) tinggal untuk inspeksi; jalankan ulang skrip membersihkannya
otomatis di awal. Hapus manual via Table Editor jika ingin bersih total.

## 7. Jalankan aplikasi

Dari folder `serviso/` (PowerShell):

```
flutter run --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon-public-key>
```

- URL & anon key: **Project Settings → API** (pakai key `anon` `public`, BUKAN
  service_role — service_role tidak boleh masuk aplikasi).
- Jika salah satu kosong, aplikasi menampilkan ConfigErrorScreen berisi petunjuk,
  tidak crash.

## 8. Ringkasan model keamanan

- RLS aktif di semua tabel; role `anon` tanpa hak apa pun.
- `authenticated` boleh SELECT/INSERT/UPDATE data operasional
  (customers, vehicles, parts, work_orders, wo_items) dan INSERT part_movements;
  DELETE data operasional hanya admin (policy `is_admin()`).
- Kolom terkunci lewat GRANT:
  - `profiles`: user hanya bisa update `full_name` dan `phone` miliknya sendiri;
    manajemen user penuh lewat Edge Function service_role (Task 8).
  - `parts.stock_qty`: tidak bisa di-update langsung oleh siapa pun via client —
    stok hanya berubah lewat insert `part_movements` (trigger
    `trg_part_movements_stock`).
- `part_movements` append-only bagi client (tanpa UPDATE); koreksi stok = movement
  baru ref `koreksi`.
- `audit_logs`: SELECT admin saja; tidak ada policy tulis untuk siapa pun — tulis
  hanya lewat trigger/fungsi SECURITY DEFINER.
- `cancel_work_order` memvalidasi admin di dalam fungsi (selain RLS).
- Update langsung status `work_orders` dijaga trigger transisi
  (`menunggu→dikerjakan`, `dikerjakan→selesai/dibatalkan`,
  `selesai→dibatalkan` hanya via `cancel_work_order` agar stok dibalikkan);
  penyelesaian wajib lewat `complete_work_order` agar stok diposting.

### Catatan penting untuk Task 2 (login username)

`lookup_login_email` sengaja **tidak** bisa dipanggil oleh anon (brief: revoke from
anon) untuk menutup enumerasi email. Alur login username memang butuh resolusi
email sebelum `signInWithPassword`. Dua opsi saat implementasi Task 2:

1. Terima trade-off internal: `grant execute on function public.lookup_login_email(citext)
   to anon;` (migrasi kecil tambahan), atau
2. Buat RPC gabungan server-side `login_with_username(username, password)` yang
   memverifikasi kredensial di dalam database.

Diskusikan pilihan sebelum Task 2 dimulai.

## 9. Troubleshooting

| Gejala | Penyebab & solusi |
| --- | --- |
| `duplicate key ... vehicles_plate_no_key` | Plat sudah terdaftar; plat disimpan uppercase — normalisasi dulu di form. |
| `duplicate key ... profiles_username_key` | Username undangan sudah dipakai; ganti username. |
| `Stok tidak cukup untuk part ...` | Tambah stok via Stok Masuk (movement `in`) sebelum menyelesaikan WO. |
| `Perubahan status X ke Y tidak diizinkan.` | Gunakan aksi UI/RPC yang sah (Mulai Kerja / Selesaikan / Batalkan), jangan update kolom status manual. |
| `Hanya admin yang dapat membatalkan work order.` | Pembatalan hanya untuk role admin. |
| Login gagal "Akun dinonaktifkan" | `profiles.is_active = false`; aktifkan kembali via admin (Task 8). |
