# Serviso — System POS & Manajemen Bengkel Otomotif Modern

**Serviso** adalah aplikasi Point of Sale (POS) dan manajemen operasional bengkel otomotif modern berbasis Flutter, dipadukan dengan arsitektur *backend* terdesentralisasi Supabase (PostgreSQL + RLS + Edge Functions).

---

## 🚀 Fitur Utama

- **Otentikasi & Keamanan Peran**: Login PIN 6-digit untuk Kasir dan Admin/Pemilik dengan sesi terenkripsi persisten dan penegakan otorisasi *Role-Based Access Control* (RBAC).
- **Manajemen Pelanggan & Kendaraan**: Pencatatan data master pelanggan dan riwayat servis kendaraan dengan normalisasi otomatis format Plat Nomor Indonesia (`B 1234 XYZ`).
- **Suku Cadang & Kartu Stok**: Ledger mutasi stok (*movement in, out, adjustment*), peringatan otomatis stok menipis, serta validasi stok *atomis* berbasis PostgreSQL Triggers.
- **Work Order Kanban Board & Wizard**: Manajemen status pengerjaan visual (`Menunggu` ➔ `Dikerjakan` ➔ `Selesai` ➔ `Dibatalkan`) serta form pembuatan/pemeriksaan multi-langkah (*complaint, parts, services*).
- **Pembayaran & Cetak Struk PDF**: Perhitungan otomatis subtotal, diskon, dan pajak; pembayaran multi-metode (Tunai, Transfer, QRIS); pencetakan struk transaksi format thermal 58mm/80mm via PDF & Thermal Bluetooth.
- **Analytics & Laporan Periodik**: Dashboard ringkasan pendapatan harian/bulanan, statistik Work Order aktif, grafik tren pendapatan (`fl_chart`), serta analisis daftar suku cadang terlaris.
- **Administrasi Pengguna & Audit Log Viewer**: Fitur manajemen akun internal via Edge Function (Deno) dan peninjau riwayat *Audit Log* perubahan data secara visual dengan format JSON Diff.

---

## 🛠️ Teknologi & Arsitektur

- **Frontend**: Flutter 3.x, Dart
- **State Management**: Riverpod (Notifier & AsyncValue)
- **Routing**: GoRouter
- **Typography & Theme**: Google Fonts (Inter, IBM Plex Mono, Chakra Petch), AppColors terpusat.
- **Backend & Database**: Supabase PostgreSQL dengan Row Level Security (RLS) & Triggers.
- **Edge Compute**: Supabase Edge Functions (TypeScript / Deno runtime).

---

## 📁 Struktur Direktori

```text
Serviso/
├── docs/                      # Dokumentasi rencana & arsitektur proyek
│   └── plans/
│       └── serviso-v1-plan.md # Spesifikasi detail Task 0 - 9
├── supabase/                  # Konfigurasi & Script Backend Supabase
│   ├── migrations/            # Script DDL SQL (0001 - 0006)
│   ├── functions/             # Supabase Edge Functions (manage-user)
│   ├── seed.sql               # Data contoh pengujian & demo
│   ├── smoke.sql              # Verification query suite
│   └── RUNBOOK.md             # Panduan deployment database & Edge Functions
└── serviso/                   # Aplikasi Utama Flutter
    ├── assets/                # Asset gambar & ikon launcher (1024x1024)
    ├── lib/
    │   ├── core/              # Theme, Router, Utils, & Widget Terpusat
    │   └── features/          # Modul Fitur (Auth, Customers, Inventori, WorkOrders, Laporan, Admin)
    ├── test/                  # Test suite lengkap (Unit & Widget tests)
    └── tools/                 # Script pembantu pengembangan (generate_icon.dart)
```

---

## ⚡ Panduan Pengembangan (Dev Setup)

### 1. Prasyarat
- Flutter SDK v3.27+
- Dart SDK v3.6+
- Akun Supabase (atau Supabase CLI lokal)

### 2. Menginstal Dependensi
Buka terminal pada direktori `serviso/`:
```bash
cd serviso
flutter pub get
```

### 3. Konfigurasi Lingkungan (Dart Define)
Jalankan aplikasi Flutter dengan menyertakan URL dan Anon Key Supabase Anda:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-supabase-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

---

## 🗄️ Setup Backend Supabase

Untuk panduan selengkapnya mengenai eksekusi migrasi database, skema RLS, dan deployment Edge Function `manage-user`, silakan merujuk ke dokumentasi:
👉 **[supabase/RUNBOOK.md](file:///c:/Users/fabian%20nuriel/Serviso/supabase/RUNBOOK.md)**

---

## 🧪 Pengujian & Analisis Kode Statis

Pastikan kualitas kode tetap terjaga dengan menjalankan perintah berikut di direktori `serviso/`:

### Analisis Statis (0 Issues)
```bash
flutter analyze
```

### Jalankan Seluruh Test Suite (137 Tests)
```bash
flutter test
```

---

## 📦 Membangun Paket Rilis APK (Release Build)

Untuk membangun file rilis APK siap pakai (internal testing):

```bash
cd serviso
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-supabase-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

File APK hasil build akan berada pada lokasi:
`serviso/build/app/outputs/flutter-apk/app-release.apk`
