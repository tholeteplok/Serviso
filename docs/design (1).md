# Design Spec — Serviso
**Soft Pastel UI + Thick Bottom-Border Buttons**

> Sistem POS & Manajemen Bengkel Otomotif — Flutter (Riverpod, GoRouter)

---

## 1. Filosofi Desain

Serviso menggunakan gaya **Soft UI berpalet pastel**, dengan sentuhan taktil pada tombol lewat **border bawah yang tebal (thick bottom-border)** — teknik yang memberi kesan "3D ringan/tertekan" tanpa perlu shadow blur atau outline tebal di semua sisi seperti neo-brutalism. Hasilnya: tampilan hangat, ramah, dan playful ala brand studio (bukan dingin/korporat), tapi tetap jelas mana yang bisa ditekan — penting untuk kasir yang bekerja cepat di lantai bengkel.

**Prinsip inti:**
1. **Rounded penuh, sangat bulat** — radius besar di card, chip, dan tombol (mendekati pill-shape) untuk kesan lembut & friendly.
2. **Tombol = border bawah tebal, sisi lain tipis/tanpa border** — bukan border merata di 4 sisi. Border bawah (2–4x lebih tebal dari border samping/atas) memakai shade lebih gelap dari fill tombol, menciptakan efek "kaki tombol" — saat ditekan, border bawah menipis/hilang untuk simulasi tombol turun.
3. **Warna pastel sebagai identitas, warna solid sebagai aksi** — background & card pakai pastel lembut (krem, kuning pucat, pink, mint, biru muda); warna lebih solid/jenuh dipakai khusus pada tombol & badge status agar CTA tetap menonjol dari background yang tenang.
4. **Ilustrasi/ikon organik & blob-shape** — sudut sangat membulat, bentuk menyerupai karakter/blob, selaras dengan nuansa brand-studio yang hangat.
5. **Whitespace lega** — layout tidak sesak, banyak ruang napas antar elemen, sesuai kesan "calm" dari palet pastel.

---

## 2. Color Palette

Palet dasar bersifat **pastel/soft** (untuk background, card, ilustrasi); warna status Work Order tetap dijaga fungsinya tapi dilembutkan ke arah pastel senada, dengan versi **shade lebih gelap** disiapkan khusus untuk border bawah tombol (lihat §5).

### 2.1 Base
| Token | Hex | Penggunaan |
|---|---|---|
| `bg.base` | `#FDF7F2` | Background layar utama (krem hangat) |
| `bg.surface` | `#FFFFFF` | Card, sheet, modal |
| `ink.900` | `#111111` | Teks utama, ikon mata/aksen gelap (khas brand-studio) |
| `text.secondary` | `#8A8A8A` | Teks sekunder, caption |
| `border.hairline` | `#ECE6DF` | Divider tipis, outline pasif |

### 2.2 Palet Pastel (base color, dari style reference)
| Token | Hex | Penggunaan |
|---|---|---|
| `pastel.cream` | `#FFF3EF` | Surface sekunder, section alternatif |
| `pastel.yellow` | `#FFE59A` | Highlight, ikon CTA kecil, badge notifikasi |
| `pastel.pink` | `#FFB5C1` | Aksen dekoratif, ilustrasi, badge info ringan |
| `pastel.mint` | `#B7E1D0` | Status positif/selesai (versi lembut) |
| `pastel.blue` | `#A9D3FF` | Status info/dikerjakan (versi lembut) |

### 2.3 Aksen Fungsional (Status Work Order) — versi pastel + shade gelap untuk border
| Token | Fill (pastel) | Border bawah (shade gelap) | Konteks |
|---|---|---|---|
| `status.waiting` (Menunggu) | `#FFE59A` | `#E0B94D` | Badge & kolom kanban |
| `status.progress` (Dikerjakan) | `#A9D3FF` | `#5B9AE8` | Badge & kolom kanban |
| `status.done` (Selesai) | `#B7E1D0` | `#5FB98C` | Badge, konfirmasi pembayaran sukses |
| `status.cancelled` (Dibatalkan) | `#FFB5C1` | `#E8748A` | Badge, alert stok kritis |
| `accent.primary` | `#111111` (fill gelap, khas tombol utama brand) | `#000000` sedikit lebih gelap / atau varian mint solid `#3FBE85` | Tombol CTA utama, active nav |
| `accent.secondary` | `#FFE59A` | `#E0B94D` | Tombol sekunder, highlight |

> Warna status tetap 1:1 dengan alur Kanban (`Menunggu ➔ Dikerjakan ➔ Selesai ➔ Dibatalkan`), hanya dilembutkan ke pastel agar selaras dengan background hangat — kontras tetap dijaga lewat border bawah gelap & label teks pada badge.

---

## 3. Typography

Mengikuti stack font yang sudah dipakai repo (Google Fonts): **Inter**, **IBM Plex Mono**, **Chakra Petch**.

| Role | Font | Weight | Ukuran | Catatan |
|---|---|---|---|---|
| Display / Judul Layar | Chakra Petch | 600–700 | 22–28sp | Karakter tegas neo-brutalist, dipakai di header layar & nama bengkel |
| Heading (card title, nama pelanggan) | Inter | 600 | 16–18sp | |
| Body | Inter | 400–500 | 14sp | Teks umum, form, deskripsi |
| Angka & Data (harga, stok, plat nomor, timestamp) | IBM Plex Mono | 500–600 | 14–20sp | Monospace untuk alignment angka di struk/tabel — krusial untuk POS |
| Caption / Label kecil | Inter | 400 | 12sp | `text.secondary` |

**Aturan:** semua nominal Rupiah, nomor struk, dan plat nomor **wajib** pakai IBM Plex Mono agar rapi sejajar (penting di tampilan tabel & PDF struk thermal 58/80mm).

---

## 4. Spacing & Grid

- Base unit: **4px**
- Spacing standar: 4 / 8 / 12 / 16 / 24 / 32
- Padding card: 16px
- Gap antar card: 12–16px
- Radius sudut:
  - Card besar: `16px`
  - Tombol / badge / chip: `12px`
  - Input field: `10px`
  - Avatar/icon container: `full (circle)` atau `12px` untuk square icon-box

---

## 5. Border & Elevation — Thick Bottom-Border Button

Teknik utama pengganti hard-shadow: **border bawah tebal** pada elemen yang bisa ditekan (tombol, chip aksi, toggle).

**Anatomi tombol:**
```
border-top:    1.5px solid <shade-gelap 15%>
border-left:   1.5px solid <shade-gelap 15%>
border-right:  1.5px solid <shade-gelap 15%>
border-bottom: 4px   solid <shade-gelap 35–40%>   // 2.5–3x lebih tebal
border-radius: full (pill) atau 14–16px untuk tombol persegi
```
- **State default:** border bawah tebal penuh → tombol terlihat "berdiri".
- **State pressed:** border bawah menyusut ke 1.5px + tombol translate-y +2px → efek tombol "turun/tertekan", tanpa perlu shadow blur.
- **State hover:** fill sedikit lebih terang, border bawah tetap tebal.
- **State disabled:** fill & border bawah diturunkan opacity ke ~40%, tanpa efek tekan.

**Card** (Work Order, item stok, invoice row) tetap pakai border tipis merata (`1px solid border.hairline`) + radius besar — **tanpa** border tebal di semua sisi seperti neo-brutalism penuh; ketebalan border khusus disimpan untuk elemen interaktif (tombol) agar hierarki "mana yang bisa ditekan" jelas.

Divider antar section: `1px solid #ECE6DF`.

---

## 6. Komponen Kunci

### 6.1 Kanban Work Order Board
- Kolom = status (`Menunggu / Dikerjakan / Selesai / Dibatalkan`), header kolom pakai warna status sebagai top-border tebal 4px.
- Card WO: border 1.5px hitam, radius 16px, badge status solid di pojok kanan atas, plat nomor pakai IBM Plex Mono bold.

### 6.2 Tombol — Thick Bottom-Border System
Mengikuti matriks varian ala referensi (with background / with stroke × primary / warning / danger / info / secondary), diselaraskan ke palet pastel Serviso:

| Varian | Fill | Border bawah | Ikon | Konteks |
|---|---|---|---|---|
| **Primary** (with background) | `#111111` atau mint solid `#3FBE85` | shade lebih gelap 35% | opsional kiri/kanan | Simpan, Bayar, Konfirmasi |
| **Warning** | `#FFE59A` | `#E0B94D` | ⚠/★ | Peringatan stok, konfirmasi berisiko rendah |
| **Danger** | `#FFB5C1` (fill) / merah solid untuk aksi destruktif final | `#E8748A` | 🗑 | Batalkan Work Order, hapus item |
| **Info** | `#A9D3FF` | `#5B9AE8` | ℹ | Notifikasi, tips |
| **Secondary** | `#F3F3F3` / krem `#FFF3EF` | `#D8D0C7` | — | Tombol batal, aksi netral |
| Varian **with stroke** (outline) | Transparan, border 1.5px warna varian | border bawah tetap ditebalkan (3–4px) meski sisi lain tipis | sesuai varian | Aksi sekunder di dalam card |
| Icon button (nav bawah) | Circle fill `accent.primary` saat aktif | border bawah 3px shade gelap | icon putih | Navigasi utama |

Semua tombol memakai **radius full (pill)** kecuali tombol lebar penuh (full-width CTA) yang boleh radius 16px.

### 6.3 Badge Status
Pill shape, radius full, fill solid warna status, teks putih/gelap sesuai kontras, font Inter 600, uppercase kecil (11–12sp).

### 6.4 Card Stok / Suku Cadang
- **Indikator ketersediaan dipindah ke border bawah tebal** (bukan border kiri) — konsisten dengan bahasa visual "border bawah tebal = status/aksi" yang sudah dipakai tombol:
  - Border bawah 4px `pastel.mint` / border `#5FB98C` → stok aman
  - Border bawah 4px `pastel.yellow` / border `#E0B94D` → stok menipis
  - Border bawah 4px `pastel.pink` / border `#E8748A` → stok habis/kritis
  - Sisi atas & samping tetap `1px solid border.hairline` — hanya bawah yang ditebalkan, sama seperti anatomi tombol di §5.
- Angka stok pakai IBM Plex Mono besar & bold sebagai focal point (mirip pola "3620/6000 steps" pada referensi desain health app).
- Efek ini membuat card stok terasa seperti "chip besar yang bisa disentuh" (tap untuk lihat kartu stok/histori mutasi), selaras dengan tombol.

### 6.5 Tab (Segmented / Filter Tab)
Dipakai untuk switching konteks dalam satu layar: filter status Work Order, tab "Hari ini / Minggu ini / Bulan ini" di Laporan, tab kategori suku cadang.

- **Bentuk:** pill container besar (`bg.surface` atau `pastel.cream`, radius full) berisi beberapa tab item sejajar horizontal.
- **Tab aktif:** fill solid (`ink.900` untuk tab netral, atau warna status terkait bila tab merepresentasikan status) + **border bawah tebal 3px** shade gelap dari fill — mengikuti bahasa "border bawah tebal = elemen aktif/ditekan".
- **Tab non-aktif:** transparan, teks `text.secondary`, tanpa border bawah tebal (rata/flat) agar kontras dengan tab aktif jelas.
- **Transisi antar tab:** indikator (fill + border bawah) slide horizontal 180ms ease-out mengikuti posisi tab aktif — bukan underline tipis ala Material tab, tapi "pill bergeser".
- **Scrollable tab** (untuk kategori suku cadang yang banyak): tab di ujung yang terpotong diberi fade gradient halus sebagai isyarat bisa discroll.

### 6.6 Navbar
Dua konteks: **Bottom Navigation** (nav utama app, mobile) dan **Top App Bar** (header layar/section).

**Bottom Navigation**
- Container: `bg.surface`, radius atas besar (20–24px) jika menempel di bawah layar (floating-style), atau full width dengan top-border tipis `border.hairline` jika menempel penuh.
- Item aktif: ikon di dalam **circle/pill fill** warna `accent.primary` (atau warna status/section terkait) dengan **border bawah tebal 3px** shade gelap — mengulang motif tombol; item aktif terasa "terangkat" dari bar.
- Item non-aktif: ikon outline tipis, warna `text.secondary`, tanpa fill/border.
- Label teks di bawah ikon opsional (12sp Inter), muncul hanya pada item aktif untuk hemat ruang (mengikuti pola referensi: nav bawah minim label, mengandalkan warna+posisi).
- Badge notifikasi kecil (dot atau angka) di pojok kanan atas ikon, fill `pastel.pink`/merah solid, tanpa border bawah tebal (badge, bukan tombol).

**Top App Bar**
- Layar utama (Dashboard, Work Order List): app bar transparan/menyatu dengan `bg.base`, judul pakai Chakra Petch, ikon aksi kanan (notifikasi, tambah) berupa icon-button bulat kecil dengan border bawah tebal 2–3px senada §5.
- Layar detail/form (Detail Work Order, Edit Stok): app bar dengan tombol back (chevron dalam circle outline tipis, **tanpa** border bawah tebal — back bukan aksi utama) + judul di tengah/kiri + aksi kanan opsional (misalnya "Bagikan Struk") sebagai icon-button dengan border bawah tebal bila itu aksi primer di layar tsb.
- Tab bar bisa menempel langsung di bawah top app bar (lihat §6.5) untuk layar dengan sub-filter, mis. Kanban Work Order (`Semua / Menunggu / Dikerjakan / Selesai`).

### 6.7 Struk / Invoice (preview PDF & layar pembayaran)
- Tetap bersih ala thermal receipt: monospace penuh, garis putus-putus sebagai divider, total akhir di-highlight dengan background `accent.secondary` tipis + border tebal di sekelilingnya.

### 6.8 Form / Wizard Multi-langkah (Work Order create)
- Step indicator berbentuk chip bernomor dengan border tebal, step aktif solid fill hijau, step selesai outline dengan centang.
- Input field: border 1.5px abu-abu, saat focus border berubah jadi `accent.primary` tebal 2px (bukan shadow glow).

### 6.9 Audit Log / JSON Diff Viewer
- Baris "before" pakai aksen kiri merah muda, "after" aksen kiri hijau muda — tetap dengan border tebal card pembungkus untuk konsistensi.

---

## 7. Ikonografi & Ilustrasi

- Ikon: line icon dengan stroke tebal (≥ 2px), bukan icon tipis Material default — selaras dengan border tebal komponen.
- Hindari gradient pada ikon; gunakan warna solid dari palet status/aksen.

---

## 8. Motion (ringan)

- Transisi status Kanban: slide + fade 200ms.
- Tombol: saat pressed → border bawah menyusut dari 4px ke 1.5px + translate-y +2px, durasi 100ms ease-out (simulasi "tombol turun"); kembali ke state semula 120ms saat dilepas.
- Tidak memakai animasi bounce berlebihan — tetap profesional untuk konteks kerja bengkel, meski palet playful.

---

## 9. Aksesibilitas & Konteks Penggunaan

- Kontras teks minimum WCAG AA (4.5:1) — penting karena aplikasi dipakai di lingkungan bengkel dengan cahaya bervariasi.
- Target sentuh minimum 44x44px untuk semua tombol/ikon (dipakai kasir dengan tangan cepat/mungkin sarung tangan tipis).
- Warna status tidak boleh jadi satu-satunya pembeda — selalu sertakan label teks pada badge (bukan hanya warna) untuk pengguna buta warna.

---

## 10. Mapping ke Kode (lib/core/theme)

Rekomendasi struktur token searah dengan `AppColors` terpusat yang sudah ada di proyek:

```dart
class AppColors {
  // Base
  static const bgBase = Color(0xFFFDF7F2);
  static const bgSurface = Color(0xFFFFFFFF);
  static const ink900 = Color(0xFF111111);
  static const textSecondary = Color(0xFF8A8A8A);
  static const borderHairline = Color(0xFFECE6DF);

  // Pastel base
  static const pastelCream = Color(0xFFFFF3EF);
  static const pastelYellow = Color(0xFFFFE59A);
  static const pastelPink = Color(0xFFFFB5C1);
  static const pastelMint = Color(0xFFB7E1D0);
  static const pastelBlue = Color(0xFFA9D3FF);

  // Status — fill (pastel) & border bawah (shade gelap)
  static const statusWaiting = Color(0xFFFFE59A);
  static const statusWaitingBorder = Color(0xFFE0B94D);
  static const statusProgress = Color(0xFFA9D3FF);
  static const statusProgressBorder = Color(0xFF5B9AE8);
  static const statusDone = Color(0xFFB7E1D0);
  static const statusDoneBorder = Color(0xFF5FB98C);
  static const statusCancelled = Color(0xFFFFB5C1);
  static const statusCancelledBorder = Color(0xFFE8748A);

  // Accent
  static const accentPrimary = Color(0xFF111111);
  static const accentPrimaryBorder = Color(0xFF000000);
  static const accentSecondary = Color(0xFFFFE59A);
  static const accentSecondaryBorder = Color(0xFFE0B94D);
}
```

**Widget helper disarankan:** buat `ThickBottomBorderButton` sebagai widget terpusat (`Container` + `AnimatedContainer` untuk state pressed) yang menerima `fillColor` & `borderBottomColor` sebagai parameter, dipakai ulang di semua modul (`features/auth`, `customers`, `inventori`, `work_orders`, `laporan`, `admin`) agar efek border-bawah konsisten tanpa duplikasi kode.

Radius & spacing tetap dipusatkan lewat `AppRadius`, `AppSpacing`.

---

*Dokumen ini adalah spesifikasi desain berdasarkan kombinasi referensi: palet pastel ala brand studio (Miyama Graphics) + sistem tombol thick bottom-border. Sesuaikan hex/token final dengan brand color Serviso bila sudah ditentukan.*
