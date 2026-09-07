# Design Spec — Serviso
**Craftsman Field Ledger (Soft Hand-Drawn & Tactile POS System)**

> Sistem POS & Manajemen Bengkel Otomotif — Flutter (Riverpod, GoRouter)  
> Dokumen Referensi Desain Resmi — Versi 3.0 (Revisi Ergonomi & Sentuhan Taktil)

---

## 1. Filosofi & Arah Desain

Serviso bertransisi dari gaya *Neo-Brutalism* kaku (yang rentan memicu kelelahan visual akibat garis hitam pekat `#111111` dan bayangan balok keras *0-blur*) menuju **Craftsman Field Ledger (Buku Catatan Teknisi Lapangan / Soft Hand-Drawn)**.

Pendekatan ini mengambil analogi fisik otentik dari lantai bengkel otomotif: **buku jurnal servis manual, surat perintah kerja (SPK) berkarbon, clipboard mekanik, tiket servis berlubang cincin, dan stempel verifikasi inspeksi**. Hasilnya adalah antarmuka yang ramah manusia, hangat, dan memiliki pembeda visual radikal dibanding SaaS kasir konvensional (yang umumnya serba datar, dingin, dan monoton ala Material/iOS standar) — tanpa pernah mengorbankan otoritas teknis dan presisi finansial bengkel.

### 1.1 Prinsip Inti Desain
1. **Tinta Tunggal Hangat (`#332E28`)**: Menggantikan hitam pekat `#111111` atau `#000000`. Warna arang pekat bersuhu hangat (*warm deep charcoal*) menurunkan rasio kontras ekstrem dari ~18:1 ke rasio ergonomis **~9.5:1** di atas kanvas kertas hangat. Menghilangkan efek *glare* dan kelelahan akomodasi otot mata (*asthenopia*) selama shift kerja 8–10 jam.
2. **Garis Bergetar Deterministik (*Consistent Micro-Jitter*)**: Garis tepi card dan tombol meniru tekanan mata pena fisik dengan kurva mikro Bézier yang halus (deviasi `0.8px – 1.4px`). Pola ini tidak digambar acak tiap *frame* (menghindari boros kalkulasi GPU dan ilusi gerak yang memusingkan), melainkan di-cache secara deterministik per ukuran komponen.
3. **Hierarki Ketegasan Hybrid (Tri-Font Strategy)**:
   - **Kalam**: Jiwa manusiawi — dipakai khusus untuk Judul Seksi, Judul Card, Label Form, dan Stempel Status.
   - **IBM Plex Mono**: Kekudusan presisi teknis & finansial — wajib untuk semua nominal Rupiah, angka stok, plat nomor, nomor WO/struk, dan kode part.
   - **Inter**: Kenyamanan membaca berkecepatan tinggi — dipakai untuk teks body, deskripsi pekerjaan, dan catatan paragraf panjang.
4. **Sistem Elevasi 2-Tier (Pencegahan Moiré & Noise pada Daftar 100+ Barang)**:
   - **Tier 1 (Flat Grounded)** untuk daftar berulang (100+ kartu inventaris sparepart, tabel histori transaksi). Tanpa bayangan (*0px shadow*) saat diam, mencegah tumpukan bayangan yang merusak fokus mata dan memicu lag rendering.
   - **Tier 2 (Warm Offset Shadow)** untuk tombol tindakan utama (CTA), tombol floating, kartu keranjang belanja bawah, dan dialog konfirmasi.
5. **Detail Taktil Analog**: Menghidupkan nuansa fisik bengkel lewat garis perforasi sobekan nota (*dashed receipt cut*), lubang gantungan SPK (*binder eyelet*), dan stempel inspeksi miring (*angled rubber stamp*).

---

## 2. Color Palette & Tonal Tokens

Sistem warna Serviso dirancang menyerupai media fisik: kanvas kertas linen, tinta pulpen arang, stabilo pastel, dan stempel bengkel.

### 2.1 Base Surface & Ink
| Token | Hex | Role & Penjelasan |
|---|---|---|
| `bg.base` | `#FAF6F0` | Kanvas latar belakang utama seluruh layar (kertas manila/linen hangat). Mengeliminasi pantulan silau cahaya lampu bengkel. |
| `bg.surface` | `#FFFFFF` | Latar kartu informasi utama, sheet dialog, dan modul data (kertas putih bersih). |
| `bg.surfaceSubtle` | `#FFFDF9` | Latar alternatif untuk kartu sekunder, header kolom, atau field input teks. |
| `ink.primary` | `#332E28` | **Tinta Utama**: Seluruh garis outline/border, teks judul, teks data penting, dan bayangan tonal. |
| `ink.secondary` | `#6C665F` | Teks sekunder, label pembantu, placeholder form, dan caption (WCAG AA 4.5:1 terjaga). |
| `ink.divider` | `#E8E2D8` | Garis pembatas tipis antar-baris list di dalam tabel (garis tenang tanpa jitter). |
| `ink.shadow` | `rgba(51, 46, 40, 0.28)` | Warna bayangan offset untuk tombol dan kartu interaktif Tier 2. |

### 2.2 Functional Status Palette (Soft Highlighter Wash)
Warna status menggunakan nuansa warna stabilo/cat air pastel yang lembut namun berkarakter, selalu dibingkai oleh outline tinta tunggal `#332E28`:

| Token | Fill Hex | Border Hex | Konteks & Alur Status Bengkel |
|---|---|---|---|
| `status.waiting` | `#FEF3C7` (Amber Pastel) | `#332E28` | SPK baru masuk, menunggu giliran pengerjaan, stok menipis mendekati minimum. |
| `status.progress`| `#E0F2FE` (Biru Kalkir) | `#332E28` | Kendaraan sedang dikerjakan mekanik di pit servis, transaksi aktif. |
| `status.done`    | `#DCFCE7` (Mint Herbal) | `#332E28` | Pekerjaan selesai, pembayaran lunas, stok aman terkendali. |
| `status.cancelled`| `#FFE4E6` (Merah Pastel) | `#332E28` | Pekerjaan dibatalkan, alert stok kritis/habis, transaksi ditolak. |

### 2.3 Interactive Action Accents (CTA)
| Token | Fill Hex | Teks / Icon Hex | Border Hex | Penggunaan |
|---|---|---|---|---|
| `accent.primary` | `#332E28` (Charcoal Solid) | `#FAF6F0` (Krem Bersih) | `#332E28` | Tombol CTA Utama ("Bayar Sekarang", "Buat Transaksi", "Simpan"). Memberi kontras paling berwibawa di layar. |
| `accent.success` | `#2D6A4F` (Deep Forest) | `#FFFFFF` | `#332E28` | Alternatif CTA pembayaran lunas / konfirmasi serah terima kunci. |
| `accent.secondary`| `#FFFFFF` (Surface Paper) | `#332E28` | `#332E28` | Tombol sekunder ("Batal", "Filter", "Cetak Ulang", "Tambah Baris"). |
| `accent.warning`  | `#F59E0B` (Amber Taktil) | `#332E28` | `#332E28` | Tombol aksi peringatan ("Panggil Mekanik", "Stok Masuk"). |

---

## 3. Tipografi: Tri-Font Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│  [KALAM BOLD]                                                          │
│  "Estimasi Servis Rutin — Toyota Avanza"                               │
│                                                                        │
│  [INTER REGULAR]                               [IBM PLEX MONO BOLD]    │
│  Ganti oli mesin 10W-40 & kuras minyak rem      Rp 450.000             │
│  Plat Nomor: B 1234 SVO                        WO-2026-0881            │
└────────────────────────────────────────────────────────────────────────┘
```

Disiplin tipografi adalah benteng pertahanan Serviso agar tetap terlihat profesional dan tidak merosot menjadi aplikasi buku harian santai:

### 3.1 Peran dan Alokasi Font

| Role | Family Font | Weight | Size (sp) | Catatan & Aturan Keras |
|---|---|---|---|---|
| **App Title & Screen Title** | **Kalam** | 700 (Bold) | 22–26sp | Memberikan identitas jurnal kerja lapangan pada header layar. |
| **Card Header & Section Title** | **Kalam** | 700 (Bold) | 17–20sp | Nama pelanggan, nama grup servis, nama modul kasir. |
| **Status Tag / Badge Stempel** | **Kalam** | 700 (Bold) | 12–14sp | Stempel status: *"Lunas"*, *"Dikerjakan"*, *"Stok Habis"*. |
| **Label Form & Field Header** | **Kalam** | 400 (Regular) | 13–14sp | *"Catatan Mekanik:"*, *"Keluhan Pelanggan:"*. |
| **Semua Nominal Finansial** | **IBM Plex Mono** | 600–700 | 14–22sp | **HARAM pakai Kalam.** Nominal Rupiah harus sejajar dan presisi tinggi di tabel dan struk thermal. |
| **Plat Nomor, Kode Part, SKU**| **IBM Plex Mono** | 600 (Semibold)| 13–15sp | `B 1234 SVO`, `PART-OIL-01`, `WO-2026-0042`. |
| **Angka Stok & Satuan** | **IBM Plex Mono** | 700 (Bold) | 14–18sp | Jumlah ketersediaan sparepart: `12 pcs`, `0.5 L`. |
| **Body Text / Deskripsi Servis**| **Inter** | 400 (Regular) | 13–14sp | Penjelasan rincian perbaikan mobil/motor, paragraf panjang (menjaga kecepatan baca kasir). |
| **Caption & Meta Timestamp** | **Inter** | 500 (Medium) | 11–12sp | Tanggal transaksi, nama admin pembuat WO. |

---

## 4. Sistem Border & Elevasi 2-Tier

Mencegah paradoks visual *"When everything pops, nothing pops"* saat menampilkan puluhan hingga ratusan data.

```
TIER 1 (FLAT REPEATING DATA)                TIER 2 (PRESSABLE ACTION ITEMS)
Contoh: 100 Kartu Inventaris Sparepart      Contoh: Tombol CTA "Bayar", Floating "+ Part"

┌───────────────────────────────────────┐   ┌───────────────────────────────────────┐
│ 1.2px Garis Tinta Tunggal (#332E28)   │   │ 1.5px Garis Tinta (#332E28)           │
│ Micro-Jitter halus (tenang)           │   │ Organik Jitter Taktil                 │
│ Background: Putih Kertas (#FFFFFF)    │   │ Warna: Solid Charcoal / Aksen         │
│ BAYANGAN: 0px (FLAT GROUNDED)         │   └───────────────────────────────────────┘
└───────────────────────────────────────┘     ███████████████████████████████████████
                                              Warm Charcoal Shadow: Offset(3, 3)
```

### 4.1 Tier 1: Komponen Informasi & List Berulang (Flat Grounded)
- **Komponen**: Kartu inventaris part di list, baris riwayat transaksi kasir, rincian biaya jasa di nota, panel informasi pelanggan.
- **Border**: Garis tinta tunggal `1.2px` warna `#332E28`. Jitter kurva dibuat sangat minim (hanya deviasi 0.5px di sudut membulat) agar deretan 100 kartu tetap terlihat tertib dan mudah dipindai.
- **Bayangan**: **0px (Tanpa Shadow)**. Kartu duduk rata di atas kanvas kertas `#FAF6F0`.
- **Micro-Interaction**: Saat disentuh jari kasir (*tap*), latar kartu sekejap berubah (*tint*) menjadi warna pastel hangat (misal `#FFF3EF`) selama 70ms sebagai umpan balik visual instan.
- **Keuntungan Lapangan**: Bebas dari kelelahan mata akibat garis ganda, dan rendering scroll 100 part berjalan mulus pada kecepatan 60/120 FPS di tablet entry-level.

### 4.2 Tier 2: Komponen Interaktif & Tombol Tindakan (Elevated Pressable)
- **Komponen**: Tombol CTA utama (`NeoButton`), Tombol Floating Tambah Transaksi, Floating Cart Summary Bar, Kartu Kanban yang dapat di-drag, Modal Dialog Alert.
- **Border**: Garis tinta `1.5px` warna `#332E28` dengan jitter organik penuh.
- **Bayangan**: **Model 1 (Warm Offset Shadow)**:
  ```dart
  BoxShadow(
    color: Color(0x47332E28), // Warm charcoal ~28% opacity
    offset: Offset(3.0, 3.0),
    blurRadius: 0,
    spreadRadius: 0,
  )
  ```
- **Kinetika Interaksi Saat Ditekan (*Kinetic Press*)**:
  - *Resting State (Idle)*: Komponen berada di posisi normal, offset bayangan `(3.0, 3.0)`.
  - *Pressed State (Disentuh)*: Komponen turun secara fisik dengan `transform: Matrix4.translationValues(2.0, 2.0, 0)`, offset bayangan menyusut menjadi `(1.0, 1.0)`. Memberi sensasi taktil seperti menekan tuts register mekanik fisik.
  - *Duration*: Animasi pegas cepat 70ms (`Curves.easeOut`).

---

## 5. Aksen Fisik Bengkel (*Workshop Analog Accents*)

Detail otentik yang diadopsi dari alat fisik bengkel untuk menyempurnakan identitas visual:

### 5.1 Garis Perforasi Tiket (*Perforated Receipt Divider*)
- **Penerapan**: Pemisah antara daftar rincian sparepart/jasa dengan total akhir tagihan pada kartu kasir, atau pemisah voucher promo.
- **Bentuk**: Garis putus-putus (*dashed line*) dengan lekukan setengah lingkaran (*half-circle notches*) di sisi kiri dan kanan kartu, menyerupai sobekan kertas struk thermal atau tiket servis parkir.
- **Implementasi**: Komponen `DashedDivider` tersentralisasi dengan path warna `#332E28`.

### 5.2 Lubang Gantungan SPK (*Binder Eyelet / Ring Clip*)
- **Penerapan**: Pada bagian atas modal dialog, detail Work Order, atau drawer rincian servis.
- **Bentuk**: Ornamen lingkaran kecil berdiameter 16px dengan outline `#332E28` dan titik tengah tembaga/kuningan hangat, menyerupai lubang kertas SPK yang dijepitkan pada papan clipboard mekanik atau digantung di spion mobil.

### 5.3 Stempel Karet Miring (*Angled Rubber Stamp*)
- **Penerapan**: Status krusial seperti **"LUNAS"**, **"DP DITERIMA"**, **"QC OK"**, atau **"BATAL"**.
- **Bentuk**: Badge dengan border ganda kasar tipis, font **Kalam Bold**, dan rotasi acak terkontrol antara `-4°` hingga `-6°`. Memberikan aksen bahwa kartu tersebut telah diverifikasi secara manual oleh kepala bengkel atau kasir.

---

## 6. Iconography: Organic Monoline

- **Gaya**: Ikon berbasis garis (*outline*) dengan ujung membulat (*strokeCap: StrokeCap.round, strokeJoin: StrokeJoin.round*).
- **Ketebalan Garis**: `1.6px – 1.8px`, selalu mengikuti warna tinta `#332E28`.
- **Karakter Bentuk**: Menghindari geometri presisi kaku yang tajam; sudut-sudut ikon memiliki kelembutan radius organik agar selaras dengan border card dan tombol.
- **Sentralisasi**: Dikelola murni melalui `AppIcons` di `serviso/lib/core/theme/app_icons.dart`.

---

## 7. Arsitektur Kode & Aturan Implementasi Flutter

Semua aturan visual ini **WAJIB** berada di dalam fondasi core dan tidak boleh ada nilai hardcoded di layer fitur:

### 7.1 Struktur File Terpusat
```
serviso/lib/core/
├── theme/
│   ├── app_colors.dart         # Hex #332E28, kanvas #FAF6F0, pastel tokens
│   ├── app_typography.dart     # Kalam (Aksen), IBM Plex Mono (Data), Inter (Body)
│   ├── app_shadow.dart         # Offset warm shadow (Tier 2), zero-shadow (Tier 1)
│   ├── app_radius.dart         # Sudut organik membulat (12px - 18px, pill 999px)
│   ├── app_theme.dart          # ThemeData terintegrasi
│   └── app_icons.dart          # Icon data tersentralisasi
└── widgets/
    ├── neo_card.dart           # Mendukung variant .info (Tier 1) & .pressable (Tier 2)
    ├── neo_button.dart         # Tombol elevasi kinetik dengan bayangan arang hangat
    ├── stock_indicator_card.dart # Kartu stok Tier 1 flat dengan status pastel & angka mono
    ├── service_card.dart       # Kartu jasa servis Tier 1 flat
    ├── dashed_divider.dart     # Perforasi sobekan tiket kasir
    ├── neo_app_bar.dart        # Header layar dengan Kalam Bold & aksen hangat
    └── neo_dialog.dart         # Modal sheet bergaya memo SPK fisik
```

### 7.2 Aturan Kinerja Rendering (60–120 FPS Benchmark)
1. **Determinisme Path Border**: Algoritma kurva bergetar tidak boleh menggunakan generator angka acak (`Random()`) di dalam method `build()` atau `paint()`. Path harus dihitung berdasarkan ukuran geometri kartu (`Size(width, height)`) dan disimpan dalam cache memori objek.
2. **Eliminasi Overdraw**: Tidak menggunakan tumpukan 3 lapis `BoxShadow` blur pada kartu berulang. Tier 1 murni `BoxShadow: null`, Tier 2 hanya 1 lapis `BoxShadow` offset arang padat tanpa blur.
3. **No Hardcoded Values**: Seluruh ukuran font, warna, margin, dan radius di layer `features/` harus merujuk ke konstanta `AppTypography`, `AppColors`, `AppSpacing`, dan `AppRadius`.

---

## 8. Ringkasan Matriks Penggunaan Desain

| Elemen UI | Border (Garis Tinta) | Bayangan (Shadow) | Font Utama | Background Fill |
|---|---|---|---|---|
| **Layar Utama Canvas** | - | - | - | `#FAF6F0` (Kertas Linen) |
| **Kartu Inventaris Part (x100)** | 1.2px `#332E28` | **Tanpa Bayangan (Flat)** | Nama: Inter, Stok & Harga: **Mono** | `#FFFFFF` |
| **Kartu Jasa Servis (Katalog)** | 1.2px `#332E28` | **Tanpa Bayangan (Flat)** | Nama: Inter, Tarif: **Mono** | `#FFFFFF` |
| **Tombol CTA ("Bayar / Simpan")** | 1.5px `#332E28` | **Model 1 Warm Offset (3px)** | **Kalam Bold** / Inter Bold | `#332E28` (Teks Krem) |
| **Tombol Sekunder ("Batal / Filter")**| 1.5px `#332E28`| **Model 1 Warm Offset (2.5px)**| Inter Medium | `#FFFFFF` |
| **Kartu Kanban Work Order (Antrean)** | 1.5px `#332E28` | **Model 1 Warm Offset (3px)** | Plat: **Mono**, Judul: **Kalam** | Header Pastel, Body Putih |
| **Stempel Status ("LUNAS")** | 1.5px `#332E28` (Miring) | Tanpa Bayangan | **Kalam Bold** | Tint Status Pastel |
| **Divider Rincian Tagihan** | Putus-putus (Perforasi) | - | - | Transparan |

---
*Dokumen ini menjadi standar tunggal acuan implementasi kode antarmuka Serviso ke depan.*
