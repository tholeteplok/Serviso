# Design Spec — Serviso
**Soft UI + Neo-Brutalism Accent System**

> Sistem POS & Manajemen Bengkel Otomotif — Flutter (Riverpod, GoRouter)

---

## 1. Filosofi Desain

Serviso menggunakan gaya **Soft UI dengan aksen Neo-Brutalism**: dasar yang hangat, bulat, dan "calm" ala aplikasi health/wellness — dipadukan dengan ketegasan visual neo-brutalist (border tebal, warna kontras berani, hierarki blok yang jelas) agar terasa **profesional, cepat dibaca, dan punya karakter** — cocok untuk konteks kerja cepat di lantai bengkel (kasir, mekanik, admin), bukan sekadar cantik.

**Prinsip inti:**
1. **Rounded, bukan kaku** — sudut membulat di semua card/tombol untuk kesan approachable.
2. **Border tegas, bukan shadow samar** — setiap card/komponen interaktif punya border solid 1.5–2px, bukan drop-shadow halus ala Neumorphism klasik. Ini krusial untuk keterbacaan cepat di lapangan (outdoor light, layar low-end).
3. **Warna sebagai sinyal status, bukan dekorasi** — palet cerah dipakai fungsional (status Work Order, stok, pembayaran), bukan random.
4. **Kontras berani di titik keputusan** — CTA utama, badge status, dan angka penting (total tagihan, stok kritis) memakai warna solid tanpa gradasi supaya "menabrak" mata secara sengaja.
5. **Whitespace tetap dijaga** — meski border tebal, layout tidak sesak; ada ruang napas di antara card.

---

## 2. Color Palette

### 2.1 Base
| Token | Hex | Penggunaan |
|---|---|---|
| `bg.base` | `#F7F8FA` | Background layar utama |
| `bg.surface` | `#FFFFFF` | Card, sheet, modal |
| `border.strong` | `#1E2327` | Border tebal khas neo-brutalist (card, tombol outline) |
| `text.primary` | `#1E2327` | Teks utama |
| `text.secondary` | `#6B7280` | Teks sekunder, caption |

### 2.2 Aksen Fungsional (Status)
| Token | Hex | Konteks |
|---|---|---|
| `status.waiting` (Menunggu) | `#FFB020` (oranye) | Badge & kolom kanban Work Order |
| `status.progress` (Dikerjakan) | `#3B82F6` (biru) | Badge & kolom kanban |
| `status.done` (Selesai) | `#22C55E` (hijau mint) | Badge, konfirmasi pembayaran sukses |
| `status.cancelled` (Dibatalkan) | `#EF4444` (merah/coral) | Badge, alert stok kritis |
| `accent.primary` | `#22C55E` | Tombol CTA utama, active nav |
| `accent.secondary` | `#FFB020` | Highlight, badge notifikasi, level/challenge |

> Warna status dipetakan 1:1 ke alur Kanban Work Order (`Menunggu ➔ Dikerjakan ➔ Selesai ➔ Dibatalkan`) supaya kasir/mekanik bisa scan status hanya dari warna, tanpa baca teks.

### 2.3 Dark surface (opsional, untuk header/nav)
| Token | Hex |
|---|---|
| `surface.dark` | `#1E2327` |
| `text.on-dark` | `#F7F8FA` |

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

## 5. Border & Elevation (ciri neo-brutalist)

- **Semua card interaktif** (Work Order card, item stok, invoice row) pakai border solid:
  ```
  border: 1.5px solid #1E2327 (atau warna status untuk card kontekstual)
  ```
- **Tanpa** `box-shadow` blur besar ala Material elevation. Jika perlu depth, gunakan **offset shadow keras** (bukan blur):
  ```
  box-shadow: 3px 3px 0px rgba(30,35,39,0.9)  // gaya "hard shadow"
  ```
  dipakai selektif untuk elemen yang benar-benar butuh ditekan (tombol primer, kartu Work Order yang di-drag di Kanban).
- Card informatif pasif (statistik dashboard) boleh pakai border tipis tanpa hard-shadow agar tidak terlalu ramai.
- Divider antar section: `1px solid #E5E7EB` (lebih tipis dari border card).

---

## 6. Komponen Kunci

### 6.1 Kanban Work Order Board
- Kolom = status (`Menunggu / Dikerjakan / Selesai / Dibatalkan`), header kolom pakai warna status sebagai top-border tebal 4px.
- Card WO: border 1.5px hitam, radius 16px, badge status solid di pojok kanan atas, plat nomor pakai IBM Plex Mono bold.

### 6.2 Tombol
| Varian | Style |
|---|---|
| Primary | Fill `accent.primary`, teks putih, radius 12px, hard-shadow 2px saat idle, shadow hilang saat pressed (efek "tertekan") |
| Secondary / Outline | Border 1.5px `border.strong`, fill transparan/putih |
| Danger | Fill `status.cancelled` |
| Icon button (nav bawah) | Circle, active state: fill `accent.primary` + icon putih |

### 6.3 Badge Status
Pill shape, radius full, fill solid warna status, teks putih/gelap sesuai kontras, font Inter 600, uppercase kecil (11–12sp).

### 6.4 Card Stok / Suku Cadang
- Border kiri tebal 4px warna indikator (hijau = stok aman, oranye = menipis, merah = habis).
- Angka stok pakai IBM Plex Mono besar & bold sebagai focal point (mirip pola "3620/6000 steps" pada referensi desain health app).

### 6.5 Struk / Invoice (preview PDF & layar pembayaran)
- Tetap bersih ala thermal receipt: monospace penuh, garis putus-putus sebagai divider, total akhir di-highlight dengan background `accent.secondary` tipis + border tebal di sekelilingnya.

### 6.6 Form / Wizard Multi-langkah (Work Order create)
- Step indicator berbentuk chip bernomor dengan border tebal, step aktif solid fill hijau, step selesai outline dengan centang.
- Input field: border 1.5px abu-abu, saat focus border berubah jadi `accent.primary` tebal 2px (bukan shadow glow).

### 6.7 Audit Log / JSON Diff Viewer
- Baris "before" pakai aksen kiri merah muda, "after" aksen kiri hijau muda — tetap dengan border tebal card pembungkus untuk konsistensi.

---

## 7. Ikonografi & Ilustrasi

- Ikon: line icon dengan stroke tebal (≥ 2px), bukan icon tipis Material default — selaras dengan border tebal komponen.
- Hindari gradient pada ikon; gunakan warna solid dari palet status/aksen.

---

## 8. Motion (ringan)

- Transisi status Kanban: slide + fade 200ms.
- Tombol primary: scale 0.97 + hard-shadow hilang saat pressed (memberi sensasi "fisik/tertekan", khas neo-brutalist).
- Tidak memakai animasi bounce berlebihan — tetap profesional untuk konteks kerja bengkel.

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
  static const bgBase = Color(0xFFF7F8FA);
  static const bgSurface = Color(0xFFFFFFFF);
  static const borderStrong = Color(0xFF1E2327);
  static const textPrimary = Color(0xFF1E2327);
  static const textSecondary = Color(0xFF6B7280);

  // Status
  static const statusWaiting = Color(0xFFFFB020);
  static const statusProgress = Color(0xFF3B82F6);
  static const statusDone = Color(0xFF22C55E);
  static const statusCancelled = Color(0xFFEF4444);

  // Accent
  static const accentPrimary = Color(0xFF22C55E);
  static const accentSecondary = Color(0xFFFFB020);
}
```

Radius & spacing sebaiknya juga dipusatkan (`AppRadius`, `AppSpacing`) agar konsisten di seluruh modul (`features/auth`, `customers`, `inventori`, `work_orders`, `laporan`, `admin`).

---

*Dokumen ini adalah spesifikasi desain awal berdasarkan diskusi gaya visual (Soft UI + aksen Neo-Brutalism). Sesuaikan hex/token final dengan brand color Serviso bila sudah ditentukan.*
