# Serviso V1 — Implementation Plan

Aplikasi manajemen bengkel mobil. Flutter (Android-first) + Supabase.
Multi-user (Admin/Pemilik, Kasir) dengan username+password, audit CRUD lengkap per user,
UI modern-minimalis, satu bengkel, online-only, struk PDF + share.

## Konteks Proyek

- Nama aplikasi: **Serviso**. Bahasa UI: **Bahasa Indonesia** (hardcode, tanpa l10n).
- Target: Android (debug/test via widget-unit tests; APK release di Task 9).
- Backend: Supabase (Postgres + Auth + RLS + Realtime + Edge Functions).
- Kredensial Supabase belum tersedia saat pengembangan → semua akses backend dibungkus
  repository layer; test memakai fake/mock. Verifikasi live ditunda sampai user menyediakan
  `SUPABASE_URL`/`SUPABASE_ANON_KEY` (checklist smoke ada di runbook).

<!-- GLOBAL -->
## Global Constraints (BINDING — berlaku untuk semua task)

1. Flutter stable 3.x / Dart 3.x terpasang di mesin (Windows). Shell: PowerShell 5.1 —
   jangan pakai `&&`; pakai `;` atau `if ($?) {}`. Jalankan dari workdir proyek.
2. Dependencies v1 (jangan tambah tanpa kebutuhan): `supabase_flutter`, `flutter_riverpod`,
   `go_router`, `google_fonts`, `pdf`, `printing`, `share_plus`, `fl_chart`, `intl`,
   `connectivity_plus`. Dev: `flutter_lints`, `mocktail`, `flutter_test`.
   **Tanpa build_runner/codegen di v1.**
3. Design tokens (JANGAN divariasi):
   - `primary #512D6D` (plum) · `action #F8485E` (koral) · `teal #00C1D4`
   - `canvas #EEEEEE` · `surface #FFFFFF` · `ink #241531` · `inkMuted #6E6579` · `line #E4E1E7`
   - Status WO: menunggu=netral abu (#6E6579 bg tint), dikerjakan=teal, selesai=plum,
     dibatalkan=koral. Tidak ada warna di luar sistem ini.
4. Tipografi (google_fonts): display **Chakra Petch** (angka dashboard besar, judul layar —
   hemat), body/UI **Plus Jakarta Sans**, data **IBM Plex Mono** (plat, KM, rupiah, no. WO).
5. Komponen tanda tangan: **PlateChip** — chip gaya pelat nomor Indonesia: border tebal ink
   radius 8, bg surface, teks IBM Plex Mono bold uppercase, dipakai SETIAP kali kendaraan
   tampil. Tersedia di `core/widgets/`.
6. Bahasa copy UI: kalimat aktif, sentence case, istilah operasional bengkel
   ("Selesaikan", "Stok Masuk", "Antrian"). Error message menjelaskan apa yang salah dan cara
   memperbaiki, tidak meminta maaf, tidak kosong ("Terjadi kesalahan" saja = salah).
7. Semua akses Supabase melalui class Repository per fitur (tidak ada `.from()` tersebar di
   screen/controller). Testable: repository behind interface + fake untuk test.
8. Env config via `--dart-define`: `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Jika kosong:
   tampilkan ConfigErrorScreen yang menjelaskan cara set, jangan crash.
9. Definition of DONE tiap task: `flutter analyze` 0 issue, semua test hijau, kode
   ter-commit (pesan singkat imperatif). Tanpa komentar kecuali memang perlu.
10. RLS adalah sumber kebenaran keamanan; UI guard hanya kenyamanan.
11. Uang disimpan sebagai numeric(14,2) di DB; di Dart pakai `double` untuk tampilan +
    formatter `intl id_ID` (`Rp1.234.567`). Jangan introkan money package baru.
12. Timestamps: `timestamptz`, default `now()`. ID: `uuid default gen_random_uuid()`,
    PK, kecuali `audit_logs` (`bigint generated always as identity`).
<!-- /GLOBAL -->

<!-- TASK:0 -->
## TASK 0 — Scaffold & Tema

**Goal:** Kerangka aplikasi navigable dengan tema final + komponen inti + tooling.

Requirements:
1. `flutter create serviso --org app.serviso --platforms android` di root repo
   (folder `serviso/`). ApplicationId menjadi `app.serviso.serviso`.
2. Tambah dependencies sesuai Global Constraints #2 (`flutter pub add ...`).
3. `analysis_options.yaml`: flutter_lints + rules ekstra
   (`prefer_const_constructors`, `avoid_print`, `require_trailing_commas` via lints yang ada;
   jangan tambah plugin eksternal).
4. `lib/core/theme/app_colors.dart` — konstanta token sesuai Global Constraints #3
   + shade turunan seperlunya (mis. `primaryDim`, tint status 12% opacity).
5. `lib/core/theme/app_typography.dart` + `app_theme.dart` — ThemeData Material 3 light:
   scaffold canvas #EEEEEE, card surface putih radius 16 border hairline line,
   filled button primary, input decoration seragam (radius 12, fill surface),
   textTheme dari Plus Jakarta Sans, displayLarge/Headline pakai Chakra Petch.
6. `lib/core/widgets/`: `plate_chip.dart`, `status_chip.dart` (enum WoStatus → warna),
   `empty_state.dart` (ikon + judul + ajakan aksi), `error_view.dart` (pesan + tombol Coba Lagi),
   `section_card.dart`.
7. `lib/core/utils/formatters.dart`: `rupiah(num)` → "Rp1.234.567" (intl id_ID),
   `dateTimeId(DateTime)`, `timeId(DateTime)`, `plate(String)` normalisasi uppercase-trim.
8. `lib/core/router/app_router.dart` — GoRouter: `/login`, StatefulShellRoute 4 tab
   (`/beranda`, `/antrian`, `/inventori`, `/laporan`) berisi placeholder screen bertema;
   redirect stub (selalu izinkan; guard nyata di Task 2).
9. `lib/main.dart` bootstrap: baca dart-define (Global #8), `Supabase.initialize` guarded,
   MaterialApp.router + tema.
10. `.gitignore`: standar flutter + `.env*` + `.superpowers/`.

Acceptance: `flutter analyze` bersih; `flutter test` hijau (buat minimal: test PlateChip
render plat uppercase, test rupiah(), test status_chip mapping warna).
Commit: "chore: scaffold app shell, theme tokens, core widgets".
<!-- /TASK:0 -->

<!-- TASK:1 -->
## TASK 1 — Skema & Keamanan Supabase (SQL)

**Goal:** Seluruh backend database dalam migrasi SQL + runbook. Belum dieksekusi live
(tidak ada kredensial) → kualitas lewat review statis + skrip smoke.

Files: `supabase/migrations/0001_schema.sql`, `0002_functions.sql`, `0003_audit.sql`,
`0004_rls.sql`, `supabase/tests/smoke.sql`, `supabase/RUNBOOK.md`.

Requirements:
1. **0001_schema.sql**
   - Enum: `user_role ('admin','kasir')`, `wo_status ('menunggu','dikerjakan','selesai','dibatalkan')`,
     `movement_direction ('in','out','adjust')`, `movement_ref ('pembelian','wo','koreksi','pembatalan')`,
     `pay_method ('cash','transfer','qris')`, `wo_item_kind ('part','jasa')`,
     `audit_action ('insert','update','delete','login','logout')`.
   - Tabel & kolom sesuai rencana: profiles, customers, vehicles, parts, part_movements,
     work_orders, wo_items, audit_logs, app_settings (single row: shop_name, address, phone).
     Detail kunci:
     - `profiles.username citext UNIQUE NOT NULL`, email, full_name, role user_role NOT NULL
       DEFAULT 'kasir', is_active bool DEFAULT true.
     - `vehicles.plate_no text UNIQUE NOT NULL` (disimpan uppercase; CHECK length>0),
       customer_id FK ON DELETE RESTRICT.
     - `parts.stock_qty int NOT NULL DEFAULT 0 CHECK (stock_qty >= 0)`,
       min_stock int DEFAULT 0, cost_price/sell_price numeric(14,2) CHECK >= 0.
     - `work_orders.wo_number text UNIQUE NOT NULL DEFAULT gen_wo_number()`;
       assigned_to FK profiles; paid_amount numeric(14,2) DEFAULT 0; odometer_in int.
     - `wo_items.qty numeric(10,2) > 0`, unit_price numeric(14,2), discount numeric(14,2)
       DEFAULT 0; part_id FK nullable; CHECK (kind='part' AND part_id IS NOT NULL OR kind='jasa').
     - `part_movements`: direction movement_direction, qty numeric(10,2),
       untuk 'adjust' qty boleh negatif (delta); untuk in/out qty positif (CHECK).
       ref_type movement_ref, ref_id uuid nullable, note text.
     - Indexes: vehicles(customer_id), work_orders(status), work_orders(vehicle_id),
       work_orders(created_at DESC), part_movements(part_id, created_at DESC),
       audit_logs(actor_id), audit_logs(created_at DESC), audit_logs(table_name).
   - Trigger `on_auth_user_created` → insert profiles (username/email/full_name dari
     raw_user_meta_data, fallback username dari email local-part).
   - Trigger updated_at otomatis (customers, parts, work_orders).
2. **0002_functions.sql**
   - `gen_wo_number()` volatile security invoker: `'WO-'||to_char(now(),'YYMMDD')||'-'||
     lpad(nextval('wo_number_seq')::text,3,'0')`; sequence `wo_number_seq` start 1.
   - `lookup_login_email(p_username citext) RETURNS text` SECURITY DEFINER:
     return email profiles WHERE username=p_username AND is_active; null jika tidak ada.
     Revoke from anon; grant execute to authenticated.
   - `record_auth_event(p_action audit_action)` SECURITY DEFINER: insert audit_logs
     (actor auth.uid(), action, table_name 'auth', record_id auth.uid()::text).
     Hanya menerima 'login'/'logout' (raise jika lain). Grant authenticated.
   - `complete_work_order(p_work_order_id uuid)` SECURITY INVOKER, transaksional:
     lock row FOR UPDATE; validasi status='dikerjakan' (else raise exception berbahasa
     Indonesia); untuk setiap wo_items kind='part': INSERT part_movements direction 'out'
     qty=item qty ref 'wo' ref_id=WO id; UPDATE status='selesai', completed_at=now().
     Validasi stok cukup sebelum posting (sum per part vs stock_qty; raise jika kurang).
   - `cancel_work_order(p_work_order_id uuid)` SECURITY INVOKER: jika status='selesai'
     → insert entri pembalikan per movement 'out' ref 'wo' tsb (direction 'in',
     ref_type 'pembatalan'); set status='dibatalkan'. Jika sudah dibatalkan → exception.
3. **0003_audit.sql**
   - Fungsi generik `audit_trigger()`: AFTER INSERT OR UPDATE OR DELETE pada
     customers, vehicles, parts, part_movements, work_orders, wo_items, profiles.
     Insert: actor auth.uid(), action per opsi, table_name TG_TABLE_NAME, record_id PK
     (text), old_data to_jsonb(OLD) (update/delete), new_data to_jsonb(NEW)
     (insert/update). SECURITY DEFINER (agar bisa tulis audit_logs meski RLS menutup).
     Abaikan perubahan yang hanya menyentuh updated_at (skip insert jika
     old-new identik setelah strip updated_at).
4. **0004_rls.sql** — enable RLS semua tabel. Helper `is_admin()` security definer
   stable (SELECT role dari profiles WHERE id=auth.uid()). Policy:
   - profiles: SELECT authenticated; UPDATE self (kolom terbatas: full_name, phone)
     atau admin penuh; INSERT/DELETE admin only.
   - customers/vehicles/work_orders/wo_items/part_movements/parts: SELECT,INSERT,UPDATE
     untuk authenticated; DELETE admin only.
   - app_settings: SELECT authenticated; UPDATE admin.
   - audit_logs: SELECT admin only; TIDAK ADA policy INSERT/UPDATE/DELETE untuk siapa pun
     (hanya lewat security definer trigger/fungsi).
5. **smoke.sql**: skrip verifikasi manual (dijalankan di SQL editor nanti): buat data uji,
   jalankan alur WO lengkap, assert jumlah baris audit_logs naik, assert stock_qty konsisten,
   assert kasir (role bukan admin) ditolak DELETE parts & SELECT audit_logs
   (pakai `SET LOCAL ROLE authenticated` + set request.jwt.claims).
6. **RUNBOOK.md**: langkah buat project Supabase, jalankan migrasi urut di SQL editor,
   invite user admin pertama (Auth → invite, metadata JSON username/full_name/role),
   catatan SMTP custom untuk reset password produksi, format env dart-define untuk
   `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.

Acceptance: SQL konsisten antar-file (urutan dependensi benar, semua fungsi terdefinisi);
reviewer statis menyetujui logika trigger/RPC/RLS.
Commit: "feat(db): schema, audit triggers, RPC, RLS, runbook".
<!-- /TASK:1 -->

<!-- TASK:2 -->
## TASK 2 — Autentikasi Username + Guard Role

**Goal:** Login username/password, sesi, role-aware routing, audit login/logout.

Requirements:
1. `features/auth/models/profile.dart` — Profile (id, username, email?, fullName, role,
   isActive, phone?) + mapper dari Map.
2. `features/auth/data/auth_repository.dart` — interface `AuthRepository`:
   `Future<Profile> login({username, password})` — RPC lookup_login_email → signInWithPassword
   → fetch profiles → record_auth_event('login') (best-effort try/catch).
   `Future<void> logout()` — record_auth_event('logout') best-effort → signOut.
   `Stream<Profile?> watchSession()`, `Future<Profile?> currentProfile()`.
   Impl `SupabaseAuthRepository`; akun is_active=false → signOut paksa + AuthException
   berbahasa Indonesia ("Akun dinonaktifkan. Hubungi pemilik bengkel.").
   Mapping error supabase → pesan Indonesia: kredensial salah → "Username atau password
   salah", network → "Tidak ada koneksi internet".
3. `features/auth/controllers/session_controller.dart` — Riverpod: sessionProvider
   (AsyncNotifier<Profile?>), isAdminProvider.
4. `features/auth/screens/login_screen.dart` — logo wordmark "SERVISO" (Chakra Petch,
   plum), field Username & Password (obscure + toggle lihat), tombol Masuk full-width
   primary, inline error, state loading. Latar canvas, kartu surface.
5. Router: redirect berdasar sessionProvider — belum login → /login; login → tabs;
   route `/admin/*` butuh isAdminProvider (kasir → redirect /beranda + snackbar info).
   Splash/loading screen selama restore sesi (layar polos + wordmark).
6. Profil screen (dari tab Beranda ikon akun): nama, username, role chip; tombol Keluar
   (confirm dialog). Edit nama/telepon sendiri (opsional minimal: simpan via repository
   profiles.update self-limited fields).
7. Tests (fake AuthRepository): unit redirect router (3 kasus: anon→login, kasir→admin
   diblokir, admin lolos); widget test login screen gagal login menampilkan pesan;
   test logout memanggil repository.

Acceptance: analyze + tests hijau. Commit: "feat(auth): username login, session, role guard, auth audit".
<!-- /TASK:2 -->

<!-- TASK:3 -->
## TASK 3 — Pelanggan & Kendaraan

**Goal:** CRUD pelanggan + kendaraan nested, pencarian cepat.

Requirements:
1. Models + mapper: Customer, Vehicle (plate normalisasi uppercase via formatters.plate).
2. Repositories (`CustomerRepository`, `VehicleRepository`) — interface + impl supabase:
   list paginated (range 50), search ilike (customer: name/phone; vehicle: plate_no/nama
   pelanggan via join select), create/update/delete (delete admin-only di sisi UI; RLS
   tetap sumber kebenaran), detail + kendaraan + hitungan WO.
3. Controllers Riverpod per layar (list w/ search query param, detail, form).
4. Screens:
   - Daftar Pelanggan (masuk dari Beranda quick action + app bar search): kartu ringkas
     (nama, telepon, jumlah kendaraan), FAB tambah.
   - Detail Pelanggan: info kontak, daftar kendaraan (PlateChip + merek/model/tahun),
     tambah/edit kendaraan (bottom-sheet form: plat wajib unik — error server duplikat
     diterjemahkan jadi pesan plat sudah terdaftar), riwayat singkat.
   - Form pelanggan: nama wajib, telepon opsional pattern longgar, alamat, catatan.
5. Empty states: "Belum ada pelanggan" + tombol Tambah Pelanggan.
6. Delete pelanggan/kendaraan: confirm dialog eksplisit (sebutkan nama/plat), admin only.
7. Tests: validator form (plat wajib, nama wajib), mapper unit tests, widget smoke list
   + empty state dengan fake repository.

Acceptance: analyze + tests hijau. Commit: "feat(customers): customers & vehicles CRUD + search".
<!-- /TASK:3 -->

<!-- TASK:4 -->
## TASK 4 — Inventori Suku Cadang

**Goal:** Master parts + kartu stok + stok masuk/koreksi; stok TIDAK PERNAH ditulis langsung.

Requirements:
1. Model Part, PartMovement + mapper.
2. `PartRepository`: list (search code/name ilike, filter low-stock), CRUD
   (create/update admin-only utk harga; delete admin-only soft? → v1 hard delete admin-only),
   `stockIn(partId, qty, note)`, `adjustStock(partId, signedDelta, reason)` — keduanya
   insert part_movements (ref pembelian / koreksi); `movements(partId)` list desc.
3. Trigger DB (Task 1) mengubah stock_qty — repository tidak punya path update stock_qty.
4. Screens:
   - Inventori tab: daftar parts (nama, code mono, sell_price rupiah, stok badge:
     merah action-bg jika stock<=min_stock, netral selainnya), search + filter chip
     "Stok Menipis", FAB tambah (admin & kasir boleh tambah part baru? → ya, keduanya).
   - Detail Part: info harga (modal beli/jual), stok besar (Chakra Petch), tombol Stok
     Masuk (semua role) & Koreksi Stok (admin only, alasan wajib), riwayat kartu stok
     (arah ±, qty, ref, oleh siapa via join profiles, waktu).
   - Form part: nama wajib, code auto-suggest, unit (pcs/botol/dll dropdown bebas),
     min_stock, harga.
5. Dialog stok masuk: qty > 0, catatan opsional. Koreksi: delta signed, alasan wajib
   (ditolak jika kosong), preview stok hasil.
6. Guard stok minus: server CHECK + complete_work_order validasi; UI juga cegah
   (disable submit jika koreksi membuat < 0, dengan pesan).
7. Tests: unit logic badge low-stock & preview koreksi; mapper; widget smoke list/detail
   dgn fake; test repository fake contract (stok masuk memanggil movements insert).

Acceptance: analyze + tests hijau. Commit: "feat(inventory): parts, stock movements, low-stock alerts".
<!-- /TASK:4 -->

<!-- TASK:5 -->
## TASK 5 — Work Order Board Realtime

**Goal:** Pusat operasional: board antrian realtime + wizard WO + alur status.

Requirements:
1. Models: WorkOrder (+status enum shared dgn core), WoItem.
2. `WorkOrderRepository`: 
   - `watchBoard()` — stream work_orders join vehicles/customers/assigned profile name
     order created_at desc; subscribe Supabase Realtime (channel on work_orders) +
     refetch strategi sederhana (re-fetch list pada payload change; tanpa diff engine).
   - `getById(id)` detail + items (+part names), `create(...)` draft status menunggu
     (wo_number otomatis DB), `start(id)` (menunggu→dikerjakan, started_at),
     `complete(id)` → RPC complete_work_order, `cancel(id)` → RPC cancel_work_order,
     `addItem/removeItem` hanya saat status menunggu/dikerjakan.
3. Screens:
   - Antrian tab: 3 kolom horizontal scroll (Menunggu, Dikerjakan, Selesai) — kolom =
     header count + kartu WO: PlateChip, nama pelanggan, keluhan 1 baris ellipsis,
     initial avatar teknisi (atau "—"), jam dibuat. Kartu tap → detail. Filter hari ini
     default + toggle "Semua".
   - Wizard WO Baru (FAB global): step 1 kendaraan (search plat/pelanggan; link buat
     pelanggan+kendaraan baru inline reuse form Task 3), step 2 detail (keluhan wajib,
     odometer_in optional, teknisi dropdown profiles optional), step 3 item: baris jasa
     (deskripsi+harga) & picker part (search, qty, validasi stok tersisa dengan warning
     "stok dikurangi saat diselesaikan"), ringkasan total live. Submit → board.
   - Detail WO: header status chip + wo_number mono, PlateChip + kendaraan + odometer,
     keluhan/diagnosis/catatan teknisi (editable inline saat dikerjakan), tabel items
     (ikon part/jasa), total. Aksi kontekstual: [Mulai Kerja], [Batalkan] (admin only,
     konfirmasi; jika sudah selesai tampilkan peringatan pembalikan stok),
     [Selesaikan] (konfirmasi ringkasan item+total).
4. Transisi ilegal dicegah UI + server RPC raise. Kasir boleh semua kecuali Batalkan.
5. Connectivity: snackbar persisten "Offline" via connectivity_plus (informasional).
6. Tests: unit state machine (transisi valid/invalid), wizard validator (keluhan wajib,
   qty part > 0, part wajib stok preview), widget smoke board 3 kolom dgn fixture,
   detail aksi sesuai status/role (tabel kasus kecil).

Acceptance: analyze + tests hijau. Commit: "feat(workorders): realtime board, wizard, status flow".
<!-- /TASK:5 -->

<!-- TASK:6 -->
## TASK 6 — Penyelesaian, Pembayaran, Struk PDF

**Goal:** Bayar di WO selesai + struk PDF share-able.

Requirements:
1. Migration `0005_app_settings_seed.sql`: seed 1 row app_settings (placeholder nama
   "Bengkel Serviso").
2. Model PaymentInfo (paid_amount, pay_method, paid_at) + totals calculator pure Dart:
   `WoTotals.calculate(items)` → subtotal, diskon, total (uji ketat).
3. `SettingsRepository`: get/update (update admin-only UI).
4. Payment flow di Detail WO status selesai: sheet Pembayaran — total (read-only),
   paid_amount (default total, validasi >= 0), method chips cash/transfer/qris, simpan →
   update work_orders (paid_at=now()). Chip status "Lunas"/"Belum Lunas" di kartu & detail.
5. Struk PDF (`features/workorders/pdf/receipt_builder.dart`, paket pdf): ukuran half-A5,
   header app_settings (shop_name bold Chakra-Petch-like via font bawaan pdf — google_fonts
   tidak dipakai di pdf pkg; gunakan font default bold + spacing), PlatChip digambar
   (rect rounded border tebal + teks mono-ish default), tabel items (jasa & part), total,
   bayar (metode + nominal + kembaliannya bila cash & paid>total), footer:
   "Dicetak oleh {fullName} • {dateTimeId}". Simpan file temp, `printing.sharePdf` +
   preview `printing.layoutPdf`. Share text pendek via share_plus opsional.
6. Tombol [Struk] di detail WO selesai (dan snackbar sukses selesai menawarkan struk).
7. Pengaturan screen (admin): edit shop_name/address/phone.
8. Tests: WoTotals cases (diskon per item, kosong), receipt builder menghasilkan bytes
   non-empty + doc page count 1 (unit), payment validator.

Acceptance: analyze + tests hijau. Commit: "feat(workorders): payment, settings, PDF receipt".
<!-- /TASK:6 -->

<!-- TASK:7 -->
## TASK 7 — Dashboard & Laporan

**Goal:** Beranda ringkas + laporan periode.

Requirements:
1. Migration `0006_reporting_views.sql`:
   - View `v_daily_summary(date, revenue, wo_done_count, parts_out_qty)` dari work_orders
     selesai (paid_at basis revenue) join agregasi items.
   - View `v_top_parts(month_start, part_id, name, qty_out, revenue)` agregasi
     part_movements out ref wo.
2. `ReportRepository`: todaySummary(), rangeSummary(start,end) (daily rows),
   topParts(month), queueCounts() (count per status untuk header beranda).
3. Beranda tab: salam + tanggal, 3 stat cards (Pendapatan Hari Ini — angka besar
   Chakra Petch; WO Aktif; Stok Menipis count → tap ke inventori filtered), grafik garis
   7 hari (fl_chart, garis primary + titik teal, grid tipis line color), quick actions
   (WO Baru, Pelanggan, Inventori).
4. Laporan tab: segmented periode (7 Hari / 30 Hari / Bulan Ini), summary cards
   (pendapatan, WO selesai, parts terjual), chart batang harian, daftar Top Parts
   (qty + revenue), empty state bila tanpa data.
5. Semua angka rupiah via formatter; loading skeleton sederhana (shimmer-free:
   container abu berkedip via AnimatedOpacity sederhana ATAU spinner konsisten — pilih
   spinner + placeholder blok statik, tanpa dependency baru).
6. Tests: mapper view rows → model (fixture json), period label logic, widget smoke
   beranda & laporan dgn fake repository.

Acceptance: analyze + tests hijau. Commit: "feat(reports): dashboard stats, charts, period reports".
<!-- /TASK:7 -->

<!-- TASK:8 -->
## TASK 8 — Admin: Kelola User & Audit Log

**Goal:** Manajemen user via Edge Function + penampil audit log lengkap.

Requirements:
1. Edge Function `supabase/functions/manage-user/index.ts` (Deno): POST JSON
   `{action: 'create'|'deactivate'|'activate'|'reset_password', ...}`.
   - Verifikasi JWT pemanggil (Authorization Bearer) → getUser → cek profiles.role=admin,
     else 403.
   - create: adminUser.inviteUserByEmail(email, {data:{username,full_name,role}}) —
     password di-set user lewat email undangan. Validasi username unik (cek profiles dulu).
   - deactivate/activate: admin.updateUserById(is_active ban=false/…: implement via
     profiles.is_active flag + ban/unban user agar sesi mati).
   - reset_password: trigger reset email.
   - Service key dari env function; CORS minimal (allow app origin '*': ok internal).
2. `AdminRepository` (interface+impl): panggil function via supabase.functions.invoke;
   users list (profiles), toggleActive, createUser(payload), sendReset(email).
3. Screens (route /admin/*, guard role dari Task 2):
   - Kelola User: daftar (nama, username mono, role chip, aktif/nonaktif), FAB Tambah
     User (form email, username, nama, role dropdown) — result sukses → "Undangan
     terkirim ke {email}", error diterjemahkan (username dipakai, email terdaftar).
     Toggle aktif (confirm), kirim reset password.
   - Audit Log: filter bar (dropdown tabel, dropdown aksi, dropdown user, date range),
     list kartu: waktu, actor name, action chip warna (insert teal, update plum,
     delete koral, login/logout netral-teal), table_name + record_id mono; tap expand →
     diff old/new jsonb pretty (key berubah disorot, mono font). Infinite scroll 25/hal.
   - AuditLogRepository: select audit_logs join profiles actor, filter params, order
     created_at desc, range pagination.
4. Menu admin masuk di Profil screen (section "Administrasi": Kelola User, Audit Log)
   — hanya render untuk admin.
5. Tests: payload builder unit tests; widget guard (Profil tanpa section utk kasir —
   tabel kecil); audit diff highlight logic unit; screens smoke dgn fake.

Acceptance: analyze + tests hijau. Function direview statis (keamanan: tanpa service-key
leak, 403 path benar). Commit: "feat(admin): user management edge fn + audit log viewer".
<!-- /TASK:8 -->

<!-- TASK:9 -->
## TASK 9 — Polish, Ikon, Release Build

**Goal:** Kualitas akhir + artefak rilis.

Requirements:
1. Audit UI lintas layar: semua list punya empty state; semua async error pakai
   ErrorView + Coba Lagi; loading konsisten; touch target >= 48dp; kontras teks
   (inkMuted hanya utk sekunder, tidak utk teks panjang).
2. App icon: script Dart kecil (dev-only, tools/) memakai package `image` (dev dep)
   menggambar monogram: bg rounded #512D6D, huruf "S" + siluet kunci pas sederhana putih
   — hasil `assets/icon.png` 1024px; `flutter_launcher_icons` generate mipmap adaptive
   (bg #512D6D). Jika hasil monogram buruk secara programatik, fallback: bg solid +
   glyph wrench dari path geometris sederhana — nilai estetika minimal rapi.
3. Splash: launch background putih-canvas dgn brand center (styles.xml + drawable layer-list).
4. `README.md` root: setup dev (prereq, pub get, env dart-define, run), setup Supabase
   (arah ke supabase/RUNBOOK.md), struktur folder, build release APK command + catatan
   signing (debug keystore utk internal dulu).
5. Versioning: pubspec version 1.0.0+1.
6. Sweep analisis final: `flutter analyze` 0, `flutter test` semua hijau, hapus TODO
   basi, pastikan tanpa print/debug leftover.
7. Build: `flutter build apk --release` (tanpa signing custom) — laporkan path APK.

Acceptance: analyze+tests hijau, APK release berhasil dibangun, README lengkap.
Commit: "chore: polish pass, app icon, release build docs".
<!-- /TASK:9 -->

---

## Catatan Eksekusi (untuk controller, bukan implementer)

- Eksekusi memakai subagent-driven-development: fresh implementer per task + task review
  (spec + quality) + final whole-branch review. Ledger: `.superpowers/sdd/progress.md`.
- Verifikasi live backend (Tasks 1-8) tertunda hingga kredensial tersedia — checklist:
  RUNBOOK.md diikuti, smoke.sql dijalankan, login kedua role diuji, satu WO end-to-end.
- Risiko terbuka yang sudah diketahui: audit login client-reported (batasan platform),
  SMTP perlu diatur untuk reset password produksi.
