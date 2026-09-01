# Design Spec — Serviso
**Soft Pastel UI + Thick Bottom-Border Buttons**

> Sistem POS & Manajemen Bengkel Otomotif — Flutter (Riverpod, GoRouter)

---

## 1. Filosofi Desain

Serviso menggunakan gaya **Soft UI berpalet pastel**, dengan sentuhan taktil pada tombol lewat **border bawah yang tebal (thick bottom-border)** — teknik yang memberi kesan "3D ringan/tertekan" tanpa perlu shadow blur atau outline tebal di semua sisi seperti neo-brutalism. Hasilnya: tampilan hangat, ramah, dan playful ala brand studio (bukan dingin/korporat), tapi tetap jelas mana yang bisa ditekan — penting untuk kasir yang bekerja cepat di lantai bengkel.

**Prinsip inti:**
1. **Rounded penuh, sangat bulat** — radius besar di card, chip, dan tombol (mendekati pill-shape) untuk kesan lembut & friendly.
2. **Tombol = border bawah tebal, sisi lain tipis/tanpa border** — bukan border merata di 4 sisi. Border bawah (2–4x lebih tebal dari border samping/atas) menciptakan efek "kaki tombol" — saat ditekan, border bawah menipis/hilang untuk simulasi tombol turun.
3. **Warna pastel/solid sebagai identitas fill, hitam khusus untuk garis & teks** — background & card pakai fill pastel lembut (krem, kuning pucat, pink, mint, biru muda) atau solid (mint untuk CTA utama); **`#111111` (ink.900) hanya dipakai untuk teks, border/outline, dan bayangan — tidak pernah untuk fill kartu, tombol, chip, atau elemen chart**, agar kesan soft UI tidak berkurang jadi "berat"/kontras seperti neo-brutalism penuh.
4. **Border hitam konsisten sebagai garis bentuk (line-art), bukan sinyal warna** — semua elemen bentuk (card, tombol, badge, progress bar, hingga bar/segmen chart) diberi outline `#111111` tipis-konsisten; identitas warna/status murni diwakili oleh **fill**, bukan warna border. Ini terinspirasi referensi Pinterest (dashboard fitness pastel dengan outline hitam konsisten di kartu, bar chart, dan donut chart) — palet pastel jadi terasa lebih berani & "digambar" karena dibingkai garis tegas, tanpa kehilangan kelembutan Soft UI.
5. **Ilustrasi/ikon organik & blob-shape** — sudut sangat membulat, bentuk menyerupai karakter/blob, selaras dengan nuansa brand-studio yang hangat.
6. **Whitespace lega** — layout tidak sesak, banyak ruang napas antar elemen, sesuai kesan "calm" dari palet pastel.

---

## 2. Color Palette

Palet dasar bersifat **pastel/soft** untuk fill (background, card, tombol, chip, chart); **`#111111` (ink.900) hanya berperan sebagai warna teks, border/outline, dan bayangan** — tidak pernah dipakai sebagai fill. Identitas status Work Order/stok diwakili oleh warna fill, bukan warna border — border selalu satu warna (hitam) di seluruh komponen agar konsisten seperti garis line-art pada referensi Pinterest.

### 2.1 Base
| Token | Hex | Penggunaan |
|---|---|---|
| `bg.base` | `#FDF7F2` | Background layar utama (krem hangat) |
| `bg.surface` | `#FFFFFF` | Card, sheet, modal |
| `ink.900` | `#111111` | **Khusus**: teks utama, seluruh border/outline komponen, bayangan (shadow tint) — tidak untuk fill |
| `text.secondary` | `#8A8A8A` | Teks sekunder, caption |
| `divider.subtle` | `#ECE6DF` | Divider tipis antar-baris list (bukan outline bentuk/komponen) |

### 2.2 Palet Pastel (fill utama, dari style reference)
| Token | Hex | Penggunaan |
|---|---|---|
| `pastel.cream` | `#FFF3EF` | Surface sekunder, section alternatif |
| `pastel.yellow` | `#FFE59A` | Highlight, ikon CTA kecil, badge notifikasi, fill status menunggu/menipis |
| `pastel.pink` | `#FFB5C1` | Aksen dekoratif, ilustrasi, fill status dibatalkan/habis |
| `pastel.mint` | `#B7E1D0` | Fill status positif/selesai (versi lembut) |
| `pastel.blue` | `#A9D3FF` | Fill status info/dikerjakan (versi lembut) |

### 2.3 Aksen Fungsional (Status Work Order) — fill pastel, border selalu hitam
| Token | Fill (pastel/solid) | Border | Konteks |
|---|---|---|---|
| `status.waiting` (Menunggu) | `#FFE59A` | `#111111` | Badge & kolom kanban |
| `status.progress` (Dikerjakan) | `#A9D3FF` | `#111111` | Badge & kolom kanban |
| `status.done` (Selesai) | `#B7E1D0` | `#111111` | Badge, konfirmasi pembayaran sukses |
| `status.cancelled` (Dibatalkan) | `#FFB5C1` | `#111111` | Badge, alert stok kritis |
| `accent.primary` | `#3FBE85` (solid mint — warna aksi utama, dipakai berulang di semua tombol CTA) | `#111111` | Tombol CTA utama, active nav |
| `accent.secondary` | `#FFE59A` | `#111111` | Tombol sekunder, highlight |

> Karena border selalu hitam di semua status, **fill (warna latar)** menjadi satu-satunya pembeda visual utama — pastikan tiap status juga tetap punya label teks (lihat §9) agar tidak bergantung 100% pada warna untuk pengguna buta warna.

> Warna status tetap 1:1 dengan alur Kanban (`Menunggu ➔ Dikerjakan ➔ Selesai ➔ Dibatalkan`), hanya dilembutkan ke pastel agar selaras dengan background hangat — kontras dijaga lewat outline hitam konsisten + label teks pada badge, bukan lewat variasi warna border.

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

## 5. Border & Elevation — Thick Bottom-Border Button (Border Selalu Hitam)

Teknik utama pengganti hard-shadow: **border bawah tebal** pada elemen yang bisa ditekan (tombol, chip aksi, toggle). Warna border **selalu `#111111`** di semua komponen — variasi warna hanya terjadi pada **fill**, bukan pada border, agar sistem outline terasa seperti garis line-art yang konsisten (lihat §1 prinsip #4).

**Anatomi tombol:**
```
border-top:    1.5px solid #111111
border-left:   1.5px solid #111111
border-right:  1.5px solid #111111
border-bottom: 4px   solid #111111   // 2.5–3x lebih tebal, warna sama (hitam), bukan shade fill
border-radius: full (pill) atau 14–16px untuk tombol persegi
fill:          warna pastel/solid sesuai varian (lihat §6.2) — inilah yang membedakan status/aksi
```
- **State default:** border bawah tebal hitam penuh → tombol terlihat "berdiri".
- **State pressed:** border bawah menyusut ke 1.5px + tombol translate-y +2px → efek tombol "turun/tertekan", tanpa perlu shadow blur.
- **State hover:** fill sedikit lebih terang, border bawah tetap tebal & tetap hitam.
- **State disabled:** fill & border diturunkan opacity ke ~40%, tanpa efek tekan.

**Card** (item stok, invoice row, elemen list pasif lainnya) memakai border tipis merata `1.5px solid #111111` + radius besar — outline hitam konsisten, bukan warna per-status (lihat §6.4 untuk cara status stok diwakili lewat fill, bukan border).

**Pengecualian ketebalan — Card Work Order di papan Kanban:** tetap memakai border 2px (sedikit lebih tebal dari card list lain, tapi tetap hitam `#111111`), lihat §6.1. Alasannya kontekstual: papan Kanban adalah tampilan *scanning cepat* saat antrian padat, dan card-nya bisa di-drag antar kolom — border lebih tebal membantu mata memisahkan batas antar-card serta memperjelas target drop-zone. Card list lain (stok, invoice) dibaca sekuensial satu-satu sehingga 1.5px sudah cukup.

Divider antar section (list separator, bukan outline bentuk): `1px solid #ECE6DF` (`divider.subtle`) — satu-satunya tempat warna non-hitam boleh dipakai untuk garis, karena fungsinya memisahkan konten, bukan membingkai bentuk.

---

## 6. Komponen Kunci

### 6.1 Kanban Work Order Board
- Kolom = status (`Menunggu / Dikerjakan / Selesai / Dibatalkan`), header kolom pakai **fill pastel status** sebagai top-bar 4px (bukan border berwarna) — border kolom sendiri tetap hitam tipis.
- Card WO: border 2px `#111111`, radius 16px, badge status **fill pastel + border hitam** di pojok kanan atas, plat nomor pakai IBM Plex Mono bold.

### 6.2 Tombol — Thick Bottom-Border System
Mengikuti matriks varian ala referensi (with background / with stroke × primary / warning / danger / info / secondary), diselaraskan ke palet pastel Serviso. **Border selalu `#111111`** — yang berubah antar varian hanya fill:

| Varian | Fill | Border | Ikon | Konteks |
|---|---|---|---|---|
| **Primary** (with background) | `#3FBE85` (solid mint) | `#111111` | opsional kiri/kanan | Simpan, Bayar, Konfirmasi |
| **Warning** | `#FFE59A` | `#111111` | ⚠/★ | Peringatan stok, konfirmasi berisiko rendah |
| **Danger** | `#FFB5C1` (fill) / merah solid untuk aksi destruktif final | `#111111` | 🗑 | Batalkan Work Order, hapus item |
| **Info** | `#A9D3FF` | `#111111` | ℹ | Notifikasi, tips |
| **Secondary** | `#F3F3F3` / krem `#FFF3EF` | `#111111` | — | Tombol batal, aksi netral |
| Varian **with stroke** (outline) | Transparan / `bg.surface` | `#111111`, border bawah tetap ditebalkan (3–4px) meski sisi lain tipis | sesuai varian (ikon boleh berwarna) | Aksi sekunder di dalam card |
| Icon button (nav bawah) | Circle fill `accent.primary` saat aktif | border bawah 3px `#111111` | icon putih | Navigasi utama |

Semua tombol memakai **radius full (pill)** kecuali tombol lebar penuh (full-width CTA) yang boleh radius 16px.

### 6.3 Badge Status
Pill shape, radius full, **fill solid/pastel warna status + border 1.5px `#111111`**, teks gelap (`ink.900`) untuk keterbacaan di atas fill pastel, font Inter 600, uppercase kecil (11–12sp).

### 6.4 Card Stok / Suku Cadang
- **Indikator ketersediaan diwakili lewat fill, bukan warna border** (revisi dari versi sebelumnya) — mengikuti prinsip §1.4: border kartu tetap `1.5px solid #111111` di semua sisi (seragam, seperti card list lain), sementara status ditunjukkan lewat **strip/chip fill berwarna di bagian bawah kartu**, dengan chip itu sendiri diberi outline hitam tipis:
  - Chip fill `pastel.mint` (`#B7E1D0`) + border `#111111`, label "Aman" → stok aman
  - Chip fill `pastel.yellow` (`#FFE59A`) + border `#111111`, label "Menipis" → stok menipis
  - Chip fill `pastel.pink` (`#FFB5C1`) + border `#111111`, label "Habis" → stok habis/kritis
- Alternatif ringan: seluruh background card ditinting lembut dengan fill pastel status (opacity rendah, ~15–20%) sementara border kartu tetap hitam solid — dipakai bila tidak ingin menambah elemen chip terpisah.
- Angka stok pakai IBM Plex Mono besar & bold sebagai focal point (mirip pola "3620/6000 steps" pada referensi desain health app).
- Efek keseluruhan: card terasa seperti "kartu bergambar line-art dengan fill warna", selaras dengan referensi Pinterest — bukan lagi border berwarna, tapi fill berwarna dibingkai garis hitam konsisten.

### 6.5 Tab (Segmented / Filter Tab)
Dipakai untuk switching konteks dalam satu layar: filter status Work Order, tab "Hari ini / Minggu ini / Bulan ini" di Laporan, tab kategori suku cadang.

- **Bentuk:** pill container besar (`bg.surface` atau `pastel.cream`, radius full, border `#111111` 1.5px) berisi beberapa tab item sejajar horizontal.
- **Tab aktif:** **fill pastel/solid** (bukan `ink.900`) — gunakan `accent.primary` (mint) untuk tab netral, atau fill pastel warna status terkait bila tab merepresentasikan status — dengan **border bawah tebal 3px `#111111`**, mengikuti bahasa "border bawah tebal hitam = elemen aktif".
- **Tab non-aktif:** transparan, teks `text.secondary`, tanpa border bawah tebal (rata/flat) agar kontras dengan tab aktif jelas.
- **Transisi antar tab:** indikator (fill + border bawah) slide horizontal 180ms ease-out mengikuti posisi tab aktif — bukan underline tipis ala Material tab, tapi "pill bergeser".
- **Scrollable tab** (untuk kategori suku cadang yang banyak): tab di ujung yang terpotong diberi fade gradient halus sebagai isyarat bisa discroll.

### 6.6 Navbar
Dua konteks: **Bottom Navigation** (nav utama app, mobile) dan **Top App Bar** (header layar/section).

**Bottom Navigation**
- Container: `bg.surface`, radius atas besar (20–24px) jika menempel di bawah layar (floating-style), atau full width dengan top-border tipis `#111111` 1px jika menempel penuh.
- Item aktif: ikon di dalam **circle/pill fill** warna `accent.primary` (mint, atau warna status/section terkait) dengan **border bawah tebal 3px `#111111`** — mengulang motif tombol; item aktif terasa "terangkat" dari bar.
- Item non-aktif: ikon outline tipis, warna `text.secondary`, tanpa fill/border.
- Label teks di bawah ikon opsional (12sp Inter), muncul hanya pada item aktif untuk hemat ruang (mengikuti pola referensi: nav bawah minim label, mengandalkan warna+posisi).
- Badge notifikasi kecil (dot atau angka) di pojok kanan atas ikon, fill `pastel.pink`/merah solid + border tipis `#111111`.

**Top App Bar**
- Layar utama (Dashboard, Work Order List): app bar transparan/menyatu dengan `bg.base`, judul pakai Chakra Petch (teks `ink.900`), ikon aksi kanan (notifikasi, tambah) berupa icon-button bulat kecil dengan border bawah tebal 2–3px `#111111`.
- Layar detail/form (Detail Work Order, Edit Stok): app bar dengan tombol back (chevron dalam circle outline tipis `#111111`, **tanpa** border bawah tebal — back bukan aksi utama) + judul di tengah/kiri + aksi kanan opsional (misalnya "Bagikan Struk") sebagai icon-button dengan border bawah tebal bila itu aksi primer di layar tsb.
- Tab bar bisa menempel langsung di bawah top app bar (lihat §6.5) untuk layar dengan sub-filter, mis. Kanban Work Order (`Semua / Menunggu / Dikerjakan / Selesai`).

### 6.7 Chart & Data Visualization (`fl_chart` — Dashboard, Laporan)
Menjawab kebutuhan "border konsisten hingga bar chart, dll" — seluruh elemen chart mengikuti prinsip yang sama dengan komponen UI lain: **fill warna pastel/solid, outline selalu `#111111`**.

- **Bar chart** (tren pendapatan harian/bulanan): setiap bar diberi stroke `1.5–2px solid #111111` mengelilingi bentuknya, radius sudut atas membulat (6–8px), fill pastel per kategori atau highlight satu bar (misalnya bar hari ini) dengan fill solid `accent.primary` sementara bar lain fill pastel netral — meniru pola highlight-satu-bar pada referensi (chart "Summary day to day").
- **Donut/pie chart** (komposisi suku cadang terlaris, kategori Work Order): tiap segmen diberi stroke `1.5px solid #111111` yang juga berfungsi sebagai pemisah antar-segmen (gap kecil antar segmen + background `bg.surface` mengintip di celah), fill pastel per kategori, dengan legend di sampingnya memakai dot bulat kecil ber-outline hitam senada warna segmen.
- **Line chart** (tren pendapatan mingguan bila dipakai): garis `2–2.5px solid #111111` sebagai stroke utama, area di bawah garis diberi fill pastel gradasi tipis (bukan solid), titik data (dot) fill putih/pastel dengan outline `1.5px #111111`.
- **Progress bar** (progres stok, progres pembayaran cicilan bila ada): track fill `bg.surface`/`pastel.cream`, isi progress fill pastel/solid sesuai konteks, seluruh track diberi outline `1.5px solid #111111`, radius full.
- Semua chart **tidak memakai warna hitam sebagai fill** apa pun — hitam murni untuk garis/stroke, sumbu, dan label angka (IBM Plex Mono).

### 6.8 Struk / Invoice (preview PDF & layar pembayaran)
- Tetap bersih ala thermal receipt: monospace penuh, garis putus-putus sebagai divider, total akhir di-highlight dengan background fill `accent.secondary` (pastel kuning) + border `#111111` di sekelilingnya.

### 6.9 Form / Wizard Multi-langkah (Work Order create)
- Step indicator berbentuk chip bernomor dengan border `#111111`, step aktif fill solid mint (`accent.primary`), step selesai fill pastel dengan ikon centang, border tetap hitam di semua state.
- Input field: border 1.5px `#111111` (bukan abu-abu), saat focus border tetap hitam tapi menebal ke 2px + fill sedikit tinting pastel tipis (bukan shadow glow).

### 6.10 Audit Log / JSON Diff Viewer
- Baris "before" pakai fill tinting pink pastel tipis, "after" pakai fill tinting mint pastel tipis — border card pembungkus tetap `#111111` seragam untuk konsistensi.

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
  static const ink900 = Color(0xFF111111); // teks, border/outline, shadow — TIDAK untuk fill
  static const textSecondary = Color(0xFF8A8A8A);
  static const dividerSubtle = Color(0xFFECE6DF); // hanya untuk list divider, bukan outline bentuk

  // Pastel base (fill)
  static const pastelCream = Color(0xFFFFF3EF);
  static const pastelYellow = Color(0xFFFFE59A);
  static const pastelPink = Color(0xFFFFB5C1);
  static const pastelMint = Color(0xFFB7E1D0);
  static const pastelBlue = Color(0xFFA9D3FF);

  // Status — fill (pastel); border SELALU ink900, tidak ada token border per-status lagi
  static const statusWaiting = Color(0xFFFFE59A);
  static const statusProgress = Color(0xFFA9D3FF);
  static const statusDone = Color(0xFFB7E1D0);
  static const statusCancelled = Color(0xFFFFB5C1);

  // Accent
  static const accentPrimary = Color(0xFF3FBE85); // solid mint, fill CTA utama
  static const accentSecondary = Color(0xFFFFE59A);

  // Border universal — dipakai di SEMUA komponen (card, tombol, chip, chart)
  static const borderInk = ink900;
}
```

**Widget helper disarankan:**
- `ThickBottomBorderButton` — widget terpusat (`Container` + `AnimatedContainer` untuk state pressed) yang menerima `fillColor` sebagai parameter, sementara `borderColor` **selalu default ke `AppColors.borderInk`** (tidak perlu di-pass per pemanggilan) agar mustahil developer lain tidak sengaja memasang border berwarna.
- `AppOutlinedShape` — mixin/decoration helper untuk memastikan setiap `BoxDecoration` custom (card, chip, chart container) otomatis memakai `border: Border.all(color: AppColors.borderInk, width: ...)` sebagai default.

Dipakai ulang di semua modul (`features/auth`, `customers`, `inventori`, `work_orders`, `laporan`, `admin`) agar sistem outline hitam konsisten tanpa duplikasi kode atau salah pakai warna border.

Radius & spacing tetap dipusatkan lewat `AppRadius`, `AppSpacing`.

---

*Dokumen ini adalah spesifikasi desain berdasarkan kombinasi referensi: palet pastel ala brand studio (Miyama Graphics), sistem tombol thick bottom-border, dan prinsip border hitam konsisten (ink.900 khusus teks/border/bayangan, tidak untuk fill) ala referensi dashboard fitness pastel dari Pinterest. Sesuaikan hex/token final dengan brand color Serviso bila sudah ditentukan.*
