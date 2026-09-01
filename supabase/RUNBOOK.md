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
| 5 | `supabase/migrations/0005_app_settings_seed.sql` | seed `app_settings` |
| 6 | `supabase/migrations/0006_reporting_views.sql` | view `v_daily_summary`, `v_top_parts` |
| 7 | `supabase/migrations/0007_stock_in_and_payables.sql` | kolom `distributor/purchase_price/payment_type/debt_status` + `mark_debt_paid` |
| 8 | `supabase/migrations/0008_revenue_by_pay_method.sql` | view `v_daily_summary_by_pay_method` |
| 9 | `supabase/migrations/0009_debt_partial_payments.sql` | tabel `debt_payments` + `pay_debt` |
| 10 | `supabase/migrations/0010_price_guard_and_low_stock_view.sql` | `v_low_stock_parts` + trigger `check_price_update_is_admin` |
| 11 | `supabase/migrations/0011_business_logic_hardening.sql` | `CHECK discount<=qty*unit_price`, hardening `enforce_wo_transition` (admin guard), `complete_work_order FOR UPDATE wo_items`, `cancel_work_order is_active` |
| 12 | `supabase/migrations/0012_debt_hardening.sql` | `CHECK payment tunai=>lunas`, `pay_debt` race-safe + validasi, `debt_payments` append-only, `mark_debt_paid` ledger-aware |
| 13 | `supabase/migrations/0013_reporting_and_audit_hardening.sql` | fix `v_daily_summary`/`v_top_parts` historis, audit `app_settings`+`debt_payments` |
| 14 | `supabase/migrations/0014_direct_sales.sql` | enum `penjualan_langsung`, `direct_sales`+`direct_sale_items` (discount bound), `gen_sale_number()` PL-, RPC `checkout_direct_sale()` atomik + RLS + audit |
| 15 | `supabase/migrations/0015_reporting_combined.sql` | `v_daily_summary_combined` + `v_top_parts_combined` gabungan WO + Penjualan Langsung |

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

Login memakai **username**, bukan email. Email akun auth dibuat **sintetis
deterministik**: `{username}@users.serviso.app` — username di-trim dan dijadikan
lowercase, lalu alamatnya dihitung client-side sebelum `signInWithPassword`.
Tidak ada RPC pra-login (fungsi lookup email lama sudah dihapus).

1. **Authentication → Users → Invite user**.
2. Kolom email isi **alamat sintetis**, contoh untuk username `admin`:
   `admin@users.serviso.app` (bukan email asli pemilik).
3. Isi **User Metadata (JSON)** dengan identitas asli — termasuk **email
   pemulihan yang benar-benar bisa menerima email**:

```json
{
  "username": "admin",
  "full_name": "Nama Pemilik",
  "role": "admin",
  "email": "pemilik@bengkel.com"
}
```

Trigger `on_auth_user_created` memetakan metadata itu ke `profiles`: username,
full_name, role, dan email asli ke kolom `profiles.email` (artinya kini:
email pemulihan, bukan email login). `role` hanya mengenal `admin` / `kasir`;
nilai lain jatuh ke `kasir`. Undangan user berikutnya (kasir) sama, tanpa
`role` atau dengan `"role":"kasir"`.

**Kenapa email login harus sintetis:** Supabase mengirim email reset password ke
`auth.users.email`. Alamat sintetis tidak dapat menerima email siapa pun, sehingga
reset password mandiri lewat email tak berlaku; reset kelak hanya dilakukan admin
lewat Edge Function (Task 8) yang membaca email pemulihan asli dari
`profiles.email` — satu pintu, ter-audit, dan tanpa membocorkan email asli
sebelum autentikasi.

## 5. SMTP custom untuk produksi

Email bawaan Supabase dibatasi ketat (~2 email/jam). Untuk produksi — supaya reset
password selalu terkirim — pasang SMTP custom: **Project Settings → Authentication
→ SMTP Settings** → isi provider/kredensial SMTP sendiri. Tanpa ini, fitur "Lupa
Password" akan sering gagal kirim di pemakaian nyata.

## 6. Verifikasi dengan smoke test

**SQL Editor** → paste seluruh `supabase/tests/smoke.sql` → **Run**.

Ekspektasi: deretan notice `OK: ...` tanpa error, diakhiri `SMOKE SELESAI: semua
assert hijau.` Cakupan: trigger profil (username/role/email pemulihan dari
metadata), email auth sintetis konvensi, nomor WO otomatis, alur
mulai→selesai→batal beserta gerakan stok & audit, guard transisi (update tanpa
ubah status sah, regresi ke menunggu sah, lompatan ditolak, `dibatalkan`
terminal), penolakan stok kurang,
penolakan double-complete/double-cancel, serta RLS untuk kasir (tidak bisa hapus
part, tidak melihat audit log, tidak bisa ubah settings/item WO selesai).

Data uji (email auth sintetis `admin@users.serviso.app` /
`kasir01@users.serviso.app`; password dummy tidak dipakai untuk login; email
pemulihan asli di metadata) tinggal untuk inspeksi; jalankan ulang skrip
membersihkannya otomatis di awal. Hapus manual via Table Editor jika ingin
bersih total.

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
- Update langsung status `work_orders` dijaga trigger transisi dengan whitelist:
  `menunggu→{dikerjakan,dibatalkan}`, `dikerjakan→{selesai,dibatalkan,menunggu}`
  (kembali ke antrian sah), `selesai→dibatalkan`, `dibatalkan` terminal;
  update tanpa perubahan status selalu sah. Transisi lain ditolak pesan Indonesia
  (`Perubahan status dari X ke Y tidak diizinkan.`). Penyelesaian wajib lewat
  `complete_work_order` agar stok diposting.

### Catatan login username (desain baru)

Email login dihitung client-side tanpa panggilan server: alamat sintetis
deterministik `{trim+lowercase(username)}@users.serviso.app`. Tidak ada RPC
pra-login — permukaan enumerasi username/email lewat API anon jadi nihil.
`profiles.email` bukan email login lagi, melainkan email pemulihan asli yang
hanya tersentuh alur reset password sisi admin (Edge Function Task 8).

### Status hardening v1.1 (0011-0013)

- `enforce_wo_transition` kini menolak `selesai/dikerjakan → dibatalkan` jika bukan `is_admin()` (`is_active` true) — menutup bypass RLS di v1.
- `complete_work_order` mengunci `wo_items FOR UPDATE` sebelum validasi stok — menutup TOCTOU injeksi item konkuren.
- `cancel_work_order` pakai `is_admin()` (cek `is_active`) — konsisten dengan RLS.
- `wo_items CHECK (discount <= qty*unit_price)` menolak diskon melebihi subtotal (total negatif tertutup).
- `pay_debt` race-safe (`FOR UPDATE` movement + `debt_payments`) + validasi `direction='in' && payment_type='hutang'` + tolak `amount<=0` / melebihi sisa; `debt_payments` append-only (tanpa DELETE/UPDATE); `mark_debt_paid` ledger-aware.
- `v_daily_summary`/`v_top_parts` sudah historis & benar (tanpa fallback `updated_at`, revenue historis).

Bypass langsung `selesai→dibatalkan` yang dijelaskan di batasan v1 **sudah tertutup** di 0011.

## 9. Troubleshooting

| Gejala | Penyebab & solusi |
| --- | --- |
| `duplicate key ... vehicles_plate_no_key` | Plat sudah terdaftar; plat disimpan uppercase — normalisasi dulu di form. |
| `duplicate key ... profiles_username_key` | Username undangan sudah dipakai; ganti username. |
| `Stok tidak cukup untuk part ...` | Tambah stok via Stok Masuk (movement `in`) sebelum menyelesaikan WO. |
| `Perubahan status X ke Y tidak diizinkan.` | Gunakan aksi UI/RPC yang sah (Mulai Kerja / Selesaikan / Batalkan), jangan update kolom status manual. |
| `Hanya admin yang dapat membatalkan work order.` | Pembatalan hanya untuk role admin. |
| Login gagal "Akun dinonaktifkan" | `profiles.is_active = false`; aktifkan kembali via admin (Task 8). |
