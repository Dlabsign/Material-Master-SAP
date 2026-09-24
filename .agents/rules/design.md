---
trigger: always_on
---

# Design System — Master Data Governance (PT Kayu Mebel Indonesia)

Dokumen ini merangkum sistem desain (visual language) yang digunakan pada halaman BSP Master Data Governance, sehingga dapat dijadikan acuan konsisten untuk pengembangan halaman BSP lain di lingkungan KMI.

---

## 1. Prinsip Desain

- Gaya visual: modern, bersih, dan profesional dengan aksen warna hijau forest yang merepresentasikan identitas perusahaan (wood & furniture manufacturing).
- Struktur layout: full-width (unlimited), tidak dibatasi max-width, agar memanfaatkan seluruh area layar.
- Interaksi mengutamakan micro-interaction halus (hover lift, transform, shadow transition) untuk memberi kesan responsif tanpa berlebihan.
- Informasi kompleks (data SAP) disajikan melalui kombinasi kartu ringkasan, modal aksi, tabel, dan chart, bukan seluruhnya dalam satu halaman panjang.
- **Clean & minimalist**: hindari teks berlebih pada satu tampilan — tampilkan hanya informasi yang benar-benar dibutuhkan user saat itu, agar dashboard tidak terasa penuh atau membingungkan.
- Satu font tunggal (**Inter**) diterapkan konsisten ke seluruh elemen tanpa pengecualian, agar hierarki visual dibentuk lewat ukuran dan bobot huruf — bukan lewat variasi jenis font.

---

## 2. Palet Warna

### 2.1 Warna Utama (Brand)

| Nama | Hex | Penggunaan |
|---|---|---|
| Forest Green (Primary Dark) | `#184434` | Hero banner, entity card background |
| Emerald 600 | `#10b981` | Gradasi ikon, tombol utama, aksen aktif |
| Emerald 700 | `#059669` | Gradasi ikon, hover state tombol |
| Emerald 800 | `#047857` | Gradasi ikon lanjutan, teks status aktif |
| Mint Accent | `#52b788` | Subtext pada hero banner |
| Tile Icon Green | `#038356` | Background icon box pada analytics tile |

### 2.2 Warna Netral

| Nama | Hex | Penggunaan |
|---|---|---|
| Background Utama | `#f7f9f8` / `#f7faf9` | Latar halaman |
| Card Background Alt | `#f8faf9` / `#f8fafc` | Panel dalam modal, tabel |
| Border Halus | `#e2e8f0` / `#edf2f0` | Pembatas antar elemen |
| Teks Utama | `#0f172a` | Judul, heading |
| Teks Sekunder | `#64748b` / `#475569` | Deskripsi, label |
| Teks Placeholder | `#94a3b8` | Placeholder input, teks kosong |

### 2.3 Warna Status & Kategori (Pill / Badge)

| Nama | Background | Teks | Border | Konteks |
|---|---|---|---|---|
| Hijau (Create) | `#d1fae5` | `#047857` | `#a7f3d0` | Aksi "Create" |
| Biru (Change) | `#e0f2fe` | `#0369a1` | `#bae6fd` | Aksi "Change" |
| Ungu (Steward) | `#f3e8ff` | `#6d28d9` | `#d8b4fe` | Aksi "Data Steward" |
| Merah Muda (Delete) | `#fee2e2` | `#be123c` | `#fecaca` | Aksi "Delete" (disabled) |
| Amber (Bank/Warning) | `#fef3c7` | `#b45309` | `#fde68a` | Aksi "Bank Steward", notifikasi under development |

### 2.4 Gradasi Ikon per Modul

| Modul | Gradient |
|---|---|
| Create | `linear-gradient(135deg, #10b981 0%, #059669 100%)` |
| Change | `linear-gradient(135deg, #0284c7 0%, #0369a1 100%)` |
| Data Steward | `linear-gradient(135deg, #7c3aed 0%, #6d28d9 100%)` |
| Approval | `linear-gradient(135deg, #059669 0%, #047857 100%)` |
| Bank Steward | `linear-gradient(135deg, #d97706 0%, #b45309 100%)` |
| Delete | `linear-gradient(135deg, #e11d48 0%, #be123c 100%)` |

---

## 3. Tipografi

Prinsip utama: **clean, minimalist, mudah dipindai**. Setiap potongan teks harus langsung terlihat perannya (judul, subjudul, isi, atau pendukung) tanpa perlu dibaca dulu — hierarki dibentuk lewat ukuran dan bobot, bukan lewat variasi font.

### 3.1 Font Family — Satu Font untuk Semua

- Seluruh halaman **wajib** menggunakan **Inter** — tanpa pengecualian, termasuk heading, body text, label, tombol, badge, dan elemen kode sekalipun.
- Fallback stack: `'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`.
- Import: `https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap`.
- Font sebelumnya (`Plus Jakarta Sans`) **digantikan sepenuhnya** oleh Inter di seluruh komponen, termasuk badge kode SAP (mtart, kunnr, lifnr) — tidak lagi memakai font monospace terpisah, cukup Inter dengan `font-variant-numeric: tabular-nums` agar angka tetap rapi sejajar.

### 3.2 Skala Hierarki Teks

| Peran | Elemen | Ukuran (Desktop) | Ukuran (Mobile) | Weight | Kegunaan |
|---|---|---|---|---|---|
| **Judul (H1)** | Hero title, judul utama halaman | 32–34px | 26–28px | 800 (Extra Bold) | Satu per halaman/bagian — hal pertama yang dilihat mata |
| **Subjudul (H2)** | Judul modal, judul section besar | 20–24px | 18–20px | 700 (Bold) | Mengatur bagian utama, tetap menonjol namun di bawah H1 |
| **Subjudul (H3)** | Judul kartu, judul sub-section | 16–18px | 16px | 700 (Bold) | Mengatur sub-bagian dalam section |
| **Teks isi** | Body text, deskripsi, konten tabel | 16px | 15px | 400 (Regular) | Konten utama — tidak pernah lebih kecil dari 15px (mobile) / 16px (desktop) |
| **Teks pendukung** | Label, caption, metadata, timestamp | 13px | 13px | 500–600 (Medium/Semibold) | Digunakan hemat — hanya untuk info sekunder |

### 3.3 Aturan Khusus Form & Status

| Elemen | Ukuran | Weight | Warna |
|---|---|---|---|
| Label input | 13px | 600 (Semibold) | Redup — `#64748b` |
| Teks input (value) | 16px | 400 (Regular) | Gelap — `#0f172a` |
| Pesan error | 13px | 600 (Semibold) | Merah — `#dc2626`, selalu disertai ikon |
| Placeholder | 16px | 400 (Regular) | `#94a3b8` |

Setiap elemen teks pada form harus konsisten mengikuti tabel ini — tidak ada variasi ukuran/warna di luar aturan tersebut, agar user tidak bingung membedakan mana label dan mana isi.

### 3.4 Line-Height (Tinggi Baris)

| Kategori | Rasio terhadap font-size | Contoh (pada 16px) |
|---|---|---|
| Teks isi (body) | 1.5× – 1.7× | 24px – 27px |
| Judul & subjudul | 1.1× – 1.3× | Lebih rapat dari body — judul besar tidak butuh spasi antar baris selebar body text |
| Caption & label | 1.3× – 1.4× | Cukup lega untuk keterbacaan teks kecil |

### 3.5 Letter-Spacing (Jarak Antar Huruf)

| Ukuran Teks | Letter-Spacing | Alasan |
|---|---|---|
| Judul besar (32px ke atas) | `-0.5px` hingga `-2px` (negatif) | Teks besar terasa renggang secara alami — merapatkan huruf membuatnya terlihat rapi dan terencana |
| Teks isi (14–20px) | `0` hingga `0.2px` (netral/sedikit positif) | Default — jangan diubah kecuali ada alasan khusus |
| Label kecil & teks UPPERCASE | `0.05em` hingga `0.15em` (positif) | Teks kapital semua selalu butuh jarak lebih lebar agar tetap terbaca |

### 3.6 Penerapan pada Elemen Halaman

| Elemen | Ukuran | Weight | Letter-Spacing |
|---|---|---|---|
| Hero title (H1) | 34px | 800 | -1px |
| Hero subtitle (uppercase) | 13.5px | 700 | 0.08em |
| Card title (H3) | 20–22px | 700 | -0.5px |
| Modal title (H2) | 20px | 800 | -0.5px |
| Body / deskripsi | 16px | 400 | 0 |
| Label & metadata | 13px | 600 | 0.05em (jika uppercase) / 0 (jika normal) |
| Badge kode (mtart, kunnr, dll.) | 13px | 700 | 0.04em |

Catatan: prinsip minimalis berarti membatasi jumlah level hierarki yang tampil bersamaan dalam satu layar — idealnya maksimal 3 level (judul, subjudul, isi) agar dashboard tidak terasa penuh atau membingungkan.

---

## 4. Layout & Struktur Halaman

1. **Top Navbar** — sticky, full-width, blur background (`backdrop-filter: blur(12px)`), berisi logo brand, search bar, dan user profile widget.
2. **Hero Banner** — full-width, warna dasar forest green (`#184434`), berisi judul halaman dan grid analitik (4 kolom).
3. **Main Wrapper** — area konten utama dengan grid kartu entitas (Material, Business Partner, Financial, Info Record).
4. **Modal/Drawer** — digunakan untuk aksi lanjutan (popup aksi, detail breakdown, notifikasi under development), bukan navigasi halaman penuh.

### Grid System

- Analytics grid: `repeat(4, 1fr)`, gap 22px → menjadi `repeat(2, 1fr)` pada tablet, `1fr` pada mobile.
- Entity grid: `repeat(4, 1fr)`, gap 26px → mengikuti pola responsif yang sama.
- Modal aksi: grid 2/3/4 kolom tergantung jumlah menu (2-col, 3-col, 4-col variant).

---

## 5. Komponen Utama

### 5.1 Analytics Tile
- Card putih dengan border radius 20px, shadow lembut, ikon berlatar solid (`#038356`).
- Interaktif (`analytics-tile-clickable`): efek `translateY(-3px)` dan shadow lebih tebal saat hover.
- Tombol "View Detail" berbentuk pill hijau solid.

### 5.2 Entity Card
- Latar solid forest green (`#184434`), border radius 26px, min-height 250px.
- Ikon dalam kotak transparan putih (`rgba(255,255,255,0.16)`).
- Hover: `translateY(-8px) scale(1.01)` dengan shadow lebih dalam.

### 5.3 Modal Aksi (Action Modal)
- Card putih, border radius 28px, header dengan ikon gradient dan judul.
- Body berupa grid kartu aksi (create/change/steward/approval/bank), masing-masing dengan ikon besar, pill kategori, judul, deskripsi, dan footer CTA dengan panah.
- Kartu disabled (misal Delete) menggunakan border dashed dan opacity 0.82.

### 5.4 Modal Detail (Chart & Tabel)
- Layout 2 kolom: chart donut di kiri (sticky), tabel breakdown di kanan.
- Donut chart dibangun manual via SVG `path`, dengan badge nilai total di tengah.
- Tabel breakdown: header sticky, baris menampilkan badge kode, deskripsi, dan progress bar proporsi.

### 5.5 Modal Tabel Data (Vendor/Customer)
- Toolbar berisi search input dan filter dropdown (khusus vendor: filter bank).
- Tabel dengan badge kode (biru), nama (bold), dan info bank (badge hijau).
- Pagination custom di footer tabel (Previous/Next + nomor halaman).

### 5.6 Notifikasi "Under Development"
- Modal terpusat dengan accent bar gradient (amber → hijau), ikon warning amber, badge berkedip (`devPulse` animation), judul dan deskripsi singkat, serta tombol CTA "Mengerti".
- Toast notification (pojok kanan bawah) untuk notifikasi cepat non-blocking, latar gelap (`#0f172a`).

### 5.7 Drawer Detail (Sidebar)
- Slide-in dari kanan (lebar 450px, full-width di mobile), berisi statistik ringkas dan status modul.

---

## 6. Ikonografi

- Menggunakan **inline SVG** (bukan icon font), stroke-based, `stroke-width: 2` atau `2.2–2.5` untuk ikon aksi.
- Warna ikon mengikuti konteks: putih di atas latar gelap/gradient, warna kategori di atas latar terang.
- Ukuran umum: 18–26px untuk ikon navigasi/kartu, 32px untuk ikon entity card.

---

## 7. Efek Visual & Interaksi

| Efek | Spesifikasi |
|---|---|
| Border radius | 12–28px tergantung ukuran komponen (semakin besar komponen, semakin besar radius) |
| Shadow default | `0 4px 18px rgba(0,0,0,0.08)` hingga `0 25px 60px rgba(0,0,0,0.25–0.28)` untuk modal |
| Transisi | `cubic-bezier(0.16, 1, 0.3, 1)` untuk animasi modal/hover, durasi 0.25–0.35s |
| Backdrop modal | `rgba(15,23,42,0.45–0.65)` dengan `backdrop-filter: blur(4–14px)` |
| Hover kartu | Kombinasi `translateY` negatif + peningkatan shadow + perubahan border color |

---

## 8. Responsivitas

| Breakpoint | Perubahan Utama |
|---|---|
| `max-width: 1200px` | Analytics grid & entity grid menjadi 2 kolom |
| `max-width: 820px` | Modal body (grid aksi) menjadi 1 kolom, modal card scrollable |
| `max-width: 768px` | Navbar wrap, search bar full-width, hero/main padding diperkecil, semua grid menjadi 1 kolom, drawer full-screen |

---

## 9. Prinsip Penulisan UI (mengacu pada standar bahasa)

- Label tombol, judul section, dan status menggunakan bahasa formal dan ringkas (contoh: "Simpan", "Ajukan Persetujuan").
- Pesan notifikasi/error informatif tanpa nada berlebihan, dan tanpa ikon/emoji dekoratif berlebihan pada teks (ikon SVG fungsional tetap digunakan sebagai elemen UI, bukan sebagai dekorasi teks).
- Istilah teknis SAP (mtart, kunnr, lifnr, dsb.) ditampilkan sebagai badge monospace agar mudah dibedakan dari teks deskriptif.

---

*Catatan: dokumen ini disusun berdasarkan analisis langsung terhadap kode BSP halaman Master Data Governance yang sudah ada, dan dapat diperbarui bila terdapat perubahan komponen atau palet warna di kemudian hari.*