# Design System — Master Data Governance
**PT Kayu Mebel Indonesia (KMI) — Wood & Furniture Manufacturing**  
*Dokumen Spesifikasi Desain & Panduan Implementasi Frontend Halaman Enterprise MDG*  
*Sumber Referensi Aktual: `landing/landing_page.htm`*

---

## 1. Design Overview

### 1.1 Tujuan Desain
Dokumen ini mendefinisikan sistem desain antarmuka (*design system*) resmi untuk aplikasi enterprise **Master Data Governance (MDG)** pada lingkungan SAP Business Server Pages (BSP) PT Kayu Mebel Indonesia. Tujuannya adalah menetapkan standar visual dan interaksi tunggal (*single source of truth*) yang menjamin setiap modul baru, formulir permohonan (*request*), staging data, maupun alur persetujuan (*approval*) memiliki konsistensi visual 100% terhadap halaman acuan utama (`landing_page.htm`).

### 1.2 Karakter Visual Utama
* **Deep Forest Green Identity**: Menggunakan warna hijau hutan mendalam (`#184434`) sebagai pondasi representasi industri manufaktur kayu premium yang tenang, kokoh, dan berwibawa.
* **Modern High-Contrast Clean Surfaces**: Mengombinasikan canvas off-white bersih (`#f7f9f8`) dengan panel kartu putih murni (`#ffffff`) serta aksen emerald tajam (`#10b981`, `#059669`).
* **Glassmorphism & Depth**: Menghadirkan efek kaca buram halus (*backdrop blur*) pada navbar, backdrop modal, serta layer kontainer icon.
* **Full-Width Fluidity**: Memaksimalkan ruang kerja monitor enterprise modern (100% viewport) tanpa batasan container kaku (*no boxy boxed-layout*), namun tetap terstruktur rapi dengan grid konsisten.
* **Micro-Interactions**: Transisi halus berbasis *spring cubic-bezier*, elevasi hover kartu yang tegas, dan animasi pulse status yang informatif.

### 1.3 Kesan yang Ingin Diberikan
* **Enterprise-Grade Reliability**: Stabil, aman, dan siap pakai untuk operasional master data berskala pabrik.
* **Modern & Delightful**: Mengikis stereotip antarmuka SAP kuno menjadi aplikasi web modern berstandar internasional.
* **Executive & Operational Balance**: Menyajikan ringkasan kuantitatif eksekutif di bar atas (*analytics bar*) sekaligus akses cepat ke aksi operasional di baris bawah (*entity cards*).

### 1.4 Prinsip Desain yang Digunakan
* Menghindari *visual clutter* dengan menyembunyikan detail kompleks ke dalam modal/drawer kontekstual.
* Mempertahankan hierarki informasi yang kuat: Judul Utama -> Metrik Kuantitatif -> Pilihan Entitas Utama.
* Kepatuhan total terhadap batasan runtime SAP NetWeaver SE80 (ES5, max 255 karakter per baris, UTF-8/ASCII safe).

### 1.5 Target Penggunaan Interface
* R&D Engineers dan Wood Specialists perumus spesifikasi material & komponen furniture.
* Master Data Stewards yang memvalidasi duplikasi kode, akun bank rekanan bisnis, dan kepatuhan data pajak.
* Approver tingkat manajemen (Dept Head, GM, Direksi) yang membutuhkan overview cepat sebelum menyetujui request.

### 1.6 Relationship antara Halaman Landing dengan Halaman Internal
Halaman `landing_page.htm` bertindak sebagai gerbang orkestrasi pusat (*central gateway*). Hubungan navigasinya dirancang sebagai berikut:
1. **Material Master Request**: Mengarahkan pengguna via popup aksi ke formulir pembuatan material baru (`request_material.htm`) atau pengubahan spesifikasi (`request_change.htm`).
2. **Business Partner & Customer Directory**: Membuka modal inspeksi data langsung dari tabel SAP (`LFA1`, `KNA1`, `BNKA`, `KNVI`) sebelum pengguna berpindah ke form request vendor/customer.
3. **Master Data Hub**: Tautan langsung pada logo navbar menuju katalog induk data governance (`master_data_hub.htm`).
4. **Status Transisi Modul**: Menyediakan dialog status transparan (*under development*) untuk modul yang masih dalam pengujian Core Team tanpa memutus kenyamanan navigasi pengguna.

---

## 2. Design Principles

| Prinsip | Definisi | Penerapan Konkret pada `landing_page.htm` |
| :--- | :--- | :--- |
| **Clean** | Tampilan bebas distorsi visual dan informasi yang tidak perlu. | Ruang putih (*white space*) luas di antara kartu, garis pemisah halus berbobot 1px (`#edf2f0`), dan pembatasan palet warna primer ke turunan hijau hutan. |
| **Professional** | Nada visual formal yang sesuai untuk sistem perbankan & ERP manufaktur. | Tipografi tanpa serif yang kokoh (*Plus Jakarta Sans*), format angka ribuan terstandarisasi (`en-US` separator koma), serta badge kode SAP (`MTART`, `LIFNR`, `KUNNR`) dengan font monospace khusus. |
| **Modern** | Mengadopsi tren frontend kontemporer tanpa mengorbankan performa. | Sudut kartu membulat modern (*border-radius* 20px - 28px), *soft drop shadow* multi-layer, sticky frosted-glass navbar (`backdrop-filter: blur(12px)`), dan animasi SVG donut chart interaktif. |
| **Minimal** | Elemen visual memiliki fungsi jelas tanpa dekorasi berlebihan. | Ikonografi monokromatik dalam wadah kontras transparan (`rgba(255, 255, 255, 0.16)`), teks bantuan ringkas (*tooltips/subtitles*), dan tombol aksi terarah (*single primary CTA*). |
| **Responsive** | Tata letak menyesuaikan secara mulus dari layar ultra-wide hingga mobile. | Perubahan grid otomatis dari 4 kolom dan 3 kolom pada desktop menjadi 2 kolom di tablet dan 1 kolom vertikal bertingkat di perangkat mobile. |
| **Consistent** | Seluruh komponen memiliki bahasa visual dan pola interaksi yang seragam. | Seluruh modal berbagi struktur header identik (icon 48px, title 20px, tombol close bulat 36px), dan seluruh pagination tabel memiliki layout footer seragam. |
| **User-Focused** | Mengutamakan efisiensi pencarian dan kenyamanan mata pengguna. | Pencarian real-time dengan filter instan, debounce 300ms pada pencarian teks berat, dan dialog informatif saat fitur belum siap tanpa menampilkan error sistem mentah. |

---

## 3. Layout & Structure

### 3.1 Overall Page Structure
Halaman menggunakan model aliran dokumen vertikal penuh 100% viewport width:
```
+-----------------------------------------------------------------------------------+
|  1. TOP NAVBAR (Sticky, 100% Full-Width, Glassmorphic, Height ~74px)              |
|  [Logo & Subtext]         [Search Bar Global (max 520px)]          [User Profile] |
+-----------------------------------------------------------------------------------+
|  2. HERO BANNER (Deep Forest Green #184434, Padding 38px 44px 42px 44px)          |
|     - Title: "Master Data Governance" (34px Bold)                                |
|     - Subtitle: "PT KAYU MEBEL INDONESIA" (13.5px Uppercase)                      |
|     - ANALYTICS GRID (4 Kolom Kuantitatif, Gap 22px)                             |
|       [Tile Material]   [Tile BP]   [Tile Financial]   [Tile Customer]            |
+-----------------------------------------------------------------------------------+
|  3. MAIN WRAPPER (Light Canvas #f7faf9, Padding 44px 44px 60px 44px)               |
|     - ENTITY GRID (3 Kolom Kartu Aksi Utama, Gap 26px)                            |
|       [Card Material]           [Card Business Partner]         [Card Financial]  |
+-----------------------------------------------------------------------------------+
|  4. MODALS & OVERLAYS (Fixed Position, Blur Backdrop, Z-Index 999 - 2000)         |
|     - Material Action Modal (3 Sub-pilihan)                                       |
|     - Material Type Donut Chart & Breakdown Table Modal                           |
|     - Business Partner Vendor Directory Modal                                     |
|     - Customer Master Directory Modal                                             |
|     - Under Development Announcement Modal                                        |
|     - Slide-over Drawer & Floating Toast Notification                             |
+-----------------------------------------------------------------------------------+
```

### 3.2 Nilai Aktual Layout dari Kode
* **Reset Global**:
  ```css
  *, *::before, *::after {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }
  ```
* **Body**:
  ```css
  width: 100%;
  min-height: 100vh;
  background-color: #f7f9f8;
  overflow-x: hidden;
  ```
* **Top Navbar (`.top-navbar`)**:
  * Posisi: `position: sticky; top: 0; left: 0; width: 100%; z-index: 100;`
  * Padding dalam container: `padding: 16px 44px;`
  * Layout flex: `display: flex; align-items: center; justify-content: space-between; gap: 32px;`
* **Hero Banner (`.hero-banner`)**:
  * Background: `#184434`
  * Padding: `38px 44px 42px 44px;`
  * Flex direction: `column; gap: 28px;`
  * Bayangan: `box-shadow: 0 4px 20px rgba(10, 35, 25, 0.12);`
* **Analytics Grid (`.analytics-grid`)**:
  * Layout: `display: grid; grid-template-columns: repeat(4, 1fr); gap: 22px; width: 100%;`
* **Main Wrapper (`.main-wrapper`)**:
  * Background: `#f7faf9`
  * Padding: `44px 44px 60px 44px;`
  * Flex direction: `column; gap: 36px;`
* **Entity Grid (`.entity-grid`)**:
  * Layout: `display: grid; grid-template-columns: repeat(3, 1fr); gap: 26px; width: 100%;`
* **Detail Drawer (`.detail-drawer`)**:
  * Posisi: `position: fixed; right: -480px; top: 0; width: 450px; height: 100vh; z-index: 1000;`
  * Padding: `40px 32px;`

---

## 4. Typography

### 4.1 Font Family & Deklarasi
Sistem antarmuka mengimpor font Google resmi:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
```
* **Primary Family**: `'Plus Jakarta Sans', 'Inter', -apple-system, sans-serif`
* **Monospace Badges**: `ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace`

### 4.2 Skala & Hirarki Tipografi Aktual

| Peruntukan Elemen | Font Size | Font Weight | Line Height | Letter Spacing | Warna Teks | Transformasi |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Hero Title (`h1`)** | `34px` | `800` | Normal (`~1.2`) | `-0.02em` | `#ffffff` | None |
| **Hero Subtitle (`p`)** | `13.5px` | `700` | Normal | `0.08em` | `#52b788` | `uppercase` |
| **Entity Card Title (`h2`)** | `30px` | `700` | `1.2` | `-0.02em` | `#ffffff` | None |
| **Analytics Value** | `26px` | `800` | `1.15` | `-0.02em` | `#0f172a` | None |
| **Drawer Main Title** | `24px` | `700` | Normal | Normal | `#0f172a` | None |
| **Drawer Stat Val / Chart Val**| `22px` | `700 / 800`| `1.1` | Normal | `#047857 / #0f172a`| None |
| **Modal Heading Titles** | `20px - 21px`| `800` | `1.35` | `-0.02em` | `#0f172a` | None |
| **Navbar Brand Title** | `18px` | `800` | `1.2` | `-0.02em` | `#0f172a` | None |
| **Submenu Card Title (`h3`)**| `16.5px` | `800` | `1.35` | Normal | `#0f172a` | None |
| **Table Header Title** | `15px` | `700` | Normal | Normal | `#0f172a` | None |
| **Navbar Search / Input Text**| `14px` | `400 / 500`| Normal | Normal | `#1e293b` | None |
| **User Profile Name** | `14px` | `700` | Normal | Normal | `#1e293b` | None |
| **Customer Name Title** | `14px` | `700` | Normal | Normal | `#0f172a` | None |
| **Notice / Modal Body Text** | `13.5px` | `400 / 500`| `1.6` | Normal | `#475569` | None |
| **Analytics Tile Label** | `13px` | `600` | Normal | Normal | `#64748b` | None |
| **Table Cell Primary** | `13px` | `700` | `1.3` | Normal | `#0f172a` | None |
| **Table TH (Header Kolom)** | `12px` | `700` | Normal | `0.03em` | `#475569` | `uppercase` |
| **Submenu Description** | `12.5px` | `400` | `1.45` | Normal | `#64748b` | None |
| **Modal Subtitle** | `12.5px - 13px`| `600` | Normal | Normal | `#64748b` | None |
| **Analytics "View Detail"** | `11.5px` | `700` | Normal | `0.01em` | `#ffffff` | None |
| **Badge Monospace Code** | `11px - 11.5px`| `700 / 800`| Normal | `0.04em` | Beragam | None |
| **Status Pill Text** | `11px` | `700 / 800`| Normal | `0.05em` | Beragam | `uppercase` |
| **Navbar Brand Subtext** | `11px` | `600` | Normal | `0.02em` | `#64748b` | None |

---

## 5. Color System

Semua nilai warna berikut diambil secara presisi dari implementasi aktual:

```
 PALET WARNA RESMI - PT KAYU MEBEL INDONESIA
 ---------------------------------------------------------------------------------
 [ #184434 ] Deep Forest Green       --> Background Utama Hero Banner & Entity Cards
 [ #52b788 ] Muted Mint Green        --> Subtitle Hero Banner & Teks Aksen Lembut
 [ #10b981 ] Emerald 500 (Primary)   --> Brand Accent, Gradients, Active Border
 [ #059669 ] Emerald 600 (Darker)    --> Hover State, Button Gradients, Link CTA
 [ #047857 ] Emerald 700 (Deep)      --> Text Accent, Badge Text, Footer Line
 [ #038356 ] Emerald 800 (Button)    --> Tombol "View Detail", Tile Icon Background
 [ #026945 ] Emerald 900 (Hover)     --> Hover State Tombol "View Detail"
 ---------------------------------------------------------------------------------
 [ #f7f9f8 ] Canvas Background       --> Body Background (Off-White Soft)
 [ #f7faf9 ] Surface Tinted          --> Main Section Wrapper Background
 [ #ffffff ] Pure White              --> Navbar, Cards, Tiles, Modal Containers
 [ #f8faf9 ] Soft Gray-Green Tint    --> Modal Header, Chart Card Background
 [ #f8fafc ] Slate Tint 50           --> Pagination Footer, Disabled Card Surface
 [ #f1f5f9 ] Slate Light 100         --> Search Field Input, Close Button Normal
 [ #e2e8f0 ] Slate Border 200        --> Border Default Container, Input, Table
 [ #cbd5e1 ] Slate Border 300        --> Border Focus, Dashed Border Disabled
 [ #94a3b8 ] Slate Muted 400         --> Placeholder Input, Disabled Text Icon
 [ #64748b ] Slate Secondary 500     --> Label, Subtext, TH Kolom Tabel
 [ #475569 ] Slate Body 600          --> Deskripsi Panjang, Isi Drawer, Notice Text
 [ #1e293b ] Dark Slate 800          --> Nama Pengguna, Teks Input Aktif
 [ #0f172a ] Deep Dark Slate 900     --> Heading Utama, Angka Kuantitatif, Toast
 ---------------------------------------------------------------------------------
 [ #0284c7 ] Sky Blue 600            --> Icon Request Change, Badge Aktif Pagination
 [ #e0f2fe ] Sky Blue 100            --> Background Pill "Change Form" & Badge SAP
 [ #bae6fd ] Sky Blue 200            --> Border Pill Sky Blue
 [ #d97706 ] Amber 600               --> Icon Under Development, Warning Pulse Dot
 [ #fffbeb ] Amber 50                --> Icon Box Background Under Development
 [ #fef3c7 ] Amber 100               --> Background Pill "Tahap Pengembangan"
 [ #fde68a ] Amber 200               --> Border Pill Amber
 [ #be123c ] Rose Red 700            --> Teks Pill "Request Delete"
 [ #fee2e2 ] Rose Red 100            --> Background Pill "Request Delete"
 [ #fecaca ] Rose Red 200            --> Border Pill Rose Red
```

### Palet Warna Donut Chart (15 Kategori MTART SAP)
Ketika menyajikan distribusi tipe material, gunakan urutan indeks warna baku berikut:
1. `#0284c7` (Sky Blue)
2. `#0d9488` (Teal)
3. `#16a34a` (Green)
4. `#d97706` (Amber)
5. `#dc2626` (Red)
6. `#7c3aed` (Violet)
7. `#c026d3` (Fuchsia)
8. `#2563eb` (Royal Blue)
9. `#059669` (Emerald)
10. `#ca8a04` (Yellow Dark)
11. `#e11d48` (Rose)
12. `#9333ea` (Purple)
13. `#4f46e5` (Indigo)
14. `#0891b2` (Cyan)
15. `#65a30d` (Lime)

---

## 6. Background & Visual Effects

### 6.1 Efek Backdrop Blur
* **Navbar Sticky**:
  ```css
  background: rgba(255, 255, 255, 0.94);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  ```
  *Tujuan*: Mempertahankan keterbacaan logo dan pencarian saat halaman digulir ke bawah tanpa menutup penuh visual di belakangnya.
* **Modal Backdrop Regular (`.mat-modal-backdrop`, `.bp-modal-backdrop`)**:
  ```css
  background: rgba(15, 23, 42, 0.55);
  backdrop-filter: blur(6px);
  -webkit-backdrop-filter: blur(6px);
  ```
* **Modal Backdrop Aksi (`.mat-action-modal-backdrop`)**:
  ```css
  background: rgba(15, 23, 42, 0.58);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  ```
* **Modal Under Development Backdrop (`.dev-notice-modal-backdrop`)**:
  ```css
  background: rgba(15, 23, 42, 0.65);
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  ```
* **Page Body Blur Filter saat Modal Aktif**:
  ```css
  body.modal-open-blur > form {
    filter: blur(8px);
    -webkit-filter: blur(8px);
    pointer-events: none;
    transition: filter 0.3s cubic-bezier(0.16, 1, 0.3, 1);
  }
  ```

### 6.2 Sistem Gradient
* **Logo Icon Badge (`.logo-icon-wrap`)**:
  `linear-gradient(135deg, #10b981 0%, #059669 50%, #047857 100%)`
* **User Avatar Badge (`.user-avatar`)**:
  `linear-gradient(135deg, #34d399, #059669)`
* **Modal Header Icon Wrap**:
  `linear-gradient(135deg, #10b981, #047857)`
* **Submenu Create Icon**:
  `linear-gradient(135deg, #10b981 0%, #059669 100%)`
* **Submenu Change Icon**:
  `linear-gradient(135deg, #0284c7 0%, #0369a1 100%)`
* **Submenu Delete Icon**:
  `linear-gradient(135deg, #e11d48 0%, #be123c 100%)`
* **Modal Accent Top Bar (`.dev-notice-accent-bar`)**:
  `linear-gradient(90deg, #f59e0b, #d97706, #10b981)` (Tinggi 4px)
* **Primary Modal Button (`.dev-notice-btn-close`)**:
  `linear-gradient(135deg, #10b981 0%, #059669 100%)` -> Hover: `linear-gradient(135deg, #059669 0%, #047857 100%)`

### 6.3 Glassmorphism pada Kartu Hijau Hutan
Di dalam kartu `.entity-card` yang berlatar belakang `#184434`, elemen grafis tidak menggunakan warna solid melainkan layer kaca:
* **Icon Box**:
  ```css
  background: rgba(255, 255, 255, 0.16);
  border: 1px solid rgba(255, 255, 255, 0.25);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
  ```
  Saat hover berubah menjadi `rgba(255, 255, 255, 0.22)`.
* **Border Kartu**:
  `border: 1px solid rgba(255, 255, 255, 0.08);` berubah saat hover menjadi `border-color: rgba(255, 255, 255, 0.3);`.
* **Garis Footer Kartu**:
  `border-top: 1px solid rgba(255, 255, 255, 0.2);`

---

## 7. Cards & Components

### 7.1 Analytics Tile (`.analytics-tile`)
* **Tujuan**: Menampilkan metrik kuantitatif ringkas dan tombol rincian data per modul.
* **Struktur HTML**:
  ```html
  <div class="analytics-tile analytics-tile-clickable" onclick="...">
    <div class="analytics-icon-box">
      <!-- SVG 24x24 -->
    </div>
    <div class="analytics-data">
      <span class="analytics-label">Material Request</span>
      <button type="button" class="analytics-btn-view">
        <span>View Detail</span>
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <path d="M9 18l6-6-6-6" />
        </svg>
      </button>
    </div>
  </div>
  ```
* **Spesifikasi CSS**:
  * Background: `#ffffff`
  * Border: `1px solid rgba(255, 255, 255, 0.8)`
  * Border Radius: `20px`
  * Padding: `20px 24px`
  * Bayangan: `box-shadow: 0 4px 18px rgba(0, 0, 0, 0.08);`
  * Icon Box: Ukuran `50px x 50px`, radius `14px`, background `#038356`, bayangan `0 3px 10px rgba(3, 131, 86, 0.25)`.
  * Tombol Aksi: background `#038356`, font `11.5px` bold, padding `5px 14px`, radius `9999px`.
* **Hover State**:
  * Kartu terangkat: `transform: translateY(-3px); box-shadow: 0 10px 28px rgba(0, 0, 0, 0.15); border-color: #ffffff;`
  * Tombol di dalam kartu: background `#026945`, bayangan `0 4px 12px rgba(2, 105, 69, 0.35)`, tanda panah bergeser `translateX(3px)`.

### 7.2 Entity Card (`.entity-card`)
* **Tujuan**: Pintu masuk interaktif utama menuju proses bisnis Master Data.
* **Struktur HTML**:
  ```html
  <a href="javascript:void(0)" class="entity-card card-material" onclick="...">
    <div class="card-icon-container">
      <!-- SVG Icon 32x32 Stroke White -->
    </div>
    <div class="card-body">
      <h2 class="card-title">Material</h2>
    </div>
  </a>
  ```
* **Spesifikasi CSS**:
  * Ukuran: `min-height: 250px; width: 100%;`
  * Background: `#184434`
  * Border Radius: `26px`
  * Padding: `32px`
  * Layout: `display: flex; flex-direction: column; justify-content: space-between;`
  * Border: `1px solid rgba(255, 255, 255, 0.08)`
  * Bayangan: `box-shadow: 0 12px 28px -6px rgba(13, 41, 30, 0.25);`
  * Transition: `all 0.35s cubic-bezier(0.16, 1, 0.3, 1);`
  * Icon Container: `60px x 60px`, radius `18px`, border `1px solid rgba(255, 255, 255, 0.25)`.
* **Hover State**:
  * `transform: translateY(-8px) scale(1.01);`
  * `box-shadow: 0 24px 48px -10px rgba(20, 83, 45, 0.45);`
  * `border-color: rgba(255, 255, 255, 0.3);`
  * Icon Container: `transform: scale(1.08); background: rgba(255, 255, 255, 0.22);`

### 7.3 Submenu Action Card (`.mat-action-card-item`)
* **Tujuan**: Memberikan opsi navigasi sub-menu yang sangat jelas (Create, Change, Delete).
* **Spesifikasi CSS**:
  * Ukuran: `min-height: 180px;`
  * Border Radius: `20px`
  * Border: `1.5px solid #e2e8f0`
  * Background: `#f8faf9`
  * Padding: `24px 20px`
  * Layout: `display: flex; flex-direction: column; justify-content: space-between;`
  * Icon Box: `52px x 52px`, radius `16px`, box-shadow `0 6px 16px rgba(0, 0, 0, 0.12)`.
* **Hover State (Active Items)**:
  * `background: #ffffff; transform: translateY(-6px);`
  * Varian Create: `border-color: #10b981; box-shadow: 0 16px 32px rgba(16, 185, 129, 0.16);`
  * Varian Change: `border-color: #0284c7; box-shadow: 0 16px 32px rgba(2, 132, 199, 0.16);`
  * Panah CTA: `transform: translateX(4px);`
* **Disabled State (`.mat-action-disabled`)**:
  * Background: `#f8fafc`
  * Border Style: `border-style: dashed; border-color: #cbd5e1;`
  * Opacity: `0.82`
  * Kursor: `cursor: not-allowed;`

### 7.4 Modal Dialog Containers (`.mat-modal-card`, `.bp-modal-card`, `.mat-action-modal-card`)
* **Border Radius**: `28px`
* **Background**: `#ffffff`
* **Border**: `1px solid #e2e8f0`
* **Bayangan**: `0 25px 60px -12px rgba(0, 0, 0, 0.28)`
* **Header Modal**: Padding `20px 32px` (atau `22px 32px`), background `#f8faf9`, border-bottom `1px solid #edf2f0`.
* **Animasi Masuk**: Skala transisi dari `scale(0.94)` ke `scale(1)` dengan timing `0.35s cubic-bezier(0.16, 1, 0.3, 1)`.

---

## 8. Navigation

### 8.1 Header Navigation Bar
* **Posisi**: Sticky di puncak dokumen (`top: 0; left: 0; z-index: 100`).
* **Container Width**: 100% full-width tanpa batasan max-width.
* **Padding**: `16px 44px` (Desktop).
* **Komponen**:
  1. **Brand Identitas**:
     * Icon wrap: `44px x 44px`, radius `12px`, gradient `#10b981` -> `#047857`, teks "KMI" 14px 800 bold.
     * Judul perusahaan: `18px`, weight 800, `#0f172a`.
     * Subteks kategori: `11px`, weight 600, `#64748b`.
  2. **Search Input Bar Global**:
     * Posisi di tengah navbar, `max-width: 520px; width: 100%`.
     * Border radius pill `9999px`, background `#f4f7f6`.
     * Icon search SVG `18x18` posisi absolute `left: 16px`.
     * Padding input: `12px 18px 12px 44px`.
  3. **User Profile Widget**:
     * Bentuk pill dengan border `#e2e8f0` dan background `#ffffff`.
     * Avatar bundar `36px x 36px` dengan inisial nama pertama pengguna (diambil otomatis dari variabel ABAP `lv_user_display`).
     * Teks nama `14px` bold `#1e293b`.

---

## 9. Buttons & Interactive Elements

### 9.1 Klasifikasi Tombol Resmi

```css
/* 1. Tombol View Detail (Pada Analytics Tile) */
.analytics-btn-view {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 5px 14px;
  font-size: 11.5px;
  font-weight: 700;
  color: #ffffff !important;
  background: #038356;
  border: none;
  border-radius: 9999px;
  cursor: pointer;
  transition: all 0.25s ease;
  box-shadow: 0 2px 6px rgba(3, 131, 86, 0.25);
  text-decoration: none;
}
.analytics-btn-view:hover {
  background: #026945;
  box-shadow: 0 4px 12px rgba(2, 105, 69, 0.35);
  transform: translateY(-1px);
}

/* 2. Tombol Primary Action Modal (Tombol "Mengerti") */
.dev-notice-btn-close {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  color: #ffffff;
  border: none;
  font-size: 13.5px;
  font-weight: 700;
  padding: 12px 36px;
  border-radius: 14px;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 4px 14px rgba(16, 185, 129, 0.3);
}
.dev-notice-btn-close:hover {
  background: linear-gradient(135deg, #059669 0%, #047857 100%);
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(16, 185, 129, 0.4);
}

/* 3. Tombol Tutup Bulat / Close Button (Header Modal & Drawer) */
.close-btn {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: 1px solid #e2e8f0;
  background: #ffffff;
  color: #64748b;
  font-size: 22px;
  line-height: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
}
.close-btn:hover {
  background: #f1f5f9;
  color: #0f172a;
  border-color: #cbd5e1;
}

/* 4. Tombol Pagination Tabel */
.bp-pagination-wrap button {
  padding: 6px 12px;
  font-size: 12px;
  border-radius: 6px;
  border: 1px solid #cbd5e1;
  background: #ffffff;
  color: #334155;
  cursor: pointer;
  transition: all 0.2s ease;
}
.bp-pagination-wrap button:hover:not(:disabled) {
  background: #f1f5f9;
  border-color: #94a3b8;
}
.bp-pagination-wrap button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
/* Tombol Halaman Aktif */
.bp-pagination-wrap button.active-page {
  background: #0284c7; /* atau #059669 untuk Customer */
  color: #ffffff;
  border-color: #0284c7;
  font-weight: 700;
}
```

---

## 10. Icons & Graphic Elements

### 10.1 Standar Ikonografi
* **Format**: Pure SVG inline (tidak menggunakan external icon fonts seperti FontAwesome untuk menjamin keamanan & performa SE80).
* **Ukuran Standar**:
  * Mini / CTA Arrow: `12px x 12px` atau `16px x 16px` (stroke-width: 2.2 atau 2.5)
  * Navbar Search / Tooltip: `18px x 18px`
  * Analytics & Modal Header: `24px x 24px` atau `26px x 26px` (stroke-width: 2.0)
  * Entity Card Display: `32px x 32px` (stroke-width: 2.0)
  * Notice Warning Icon: `34px x 34px`
* **Style**: Feather/Lucide geometry style, outline/stroke-based, `stroke-linecap="round" stroke-linejoin="round"`, `fill="none"`.

### 10.2 Cuplikan SVG Resmi

```html
<!-- Material / Box Icon -->
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
  <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path>
  <polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline>
  <line x1="12" y1="22.08" x2="12" y2="12"></line>
</svg>

<!-- Business Partner / Vendor Icon -->
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
  <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
  <circle cx="8.5" cy="7" r="4"></circle>
  <polyline points="17 11 19 13 23 9"></polyline>
</svg>

<!-- Customer / User Icon -->
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
  <circle cx="12" cy="7" r="4"></circle>
</svg>

<!-- Financial / Database Cylinder Icon -->
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
  <ellipse cx="12" cy="6" rx="8" ry="3"></ellipse>
  <path d="M4 6v6c0 1.66 3.58 3 8 3s8-1.34 8-3V6"></path>
  <path d="M4 12v6c0 1.66 3.58 3 8 3s8-1.34 8-3v-6"></path>
</svg>
```

---

## 11. Animation & Transition

### 11.1 Master Transition Parameters
* **Primary Easing Curve**: `cubic-bezier(0.16, 1, 0.3, 1)`
  Kurva fisika pegas cepat dengan perlambatan halus di akhir. Digunakan untuk modal opening, hover kartu entitas, dan slide-over drawer.
* **Standard Easing**: `ease` atau `ease-in-out` dengan durasi `0.2s - 0.25s` untuk perubahan warna teks, background hover, dan tombol.

### 11.2 Daftar Animasi Terdaftar

| Nama Animasi / Transisi | Trigger | Durasi | Easing | Transformasi / Efek |
| :--- | :--- | :--- | :--- | :--- |
| **Card Elevate** | Hover `.entity-card` | `0.35s` | `cubic-bezier(0.16, 1, 0.3, 1)` | `translateY(-8px) scale(1.01)` + bayangan lebih dalam |
| **Analytics Elevate** | Hover `.analytics-tile`| `0.25s` | `ease` | `translateY(-3px)` + bayangan meluas |
| **Modal Scale-Up** | `.active` class | `0.35s` | `cubic-bezier(0.16, 1, 0.3, 1)` | `scale(0.94) -> scale(1)` + opacity `0 -> 1` |
| **Drawer Slide-In** | `.active` class | `0.35s` | `cubic-bezier(0.16, 1, 0.3, 1)` | `right: -480px -> right: 0` |
| **Toast Pop-Up** | `.active` class | `0.3s` | `cubic-bezier(0.16, 1, 0.3, 1)` | `translateY(20px) -> translateY(0)` + opacity `0 -> 1` |
| **Pulse Dot (`devPulse`)**| Continuous (Loop) | `1.8s` | Infinite Loop | `@keyframes devPulse { 0%,100% {opacity:1; transform:scale(1);} 50% {opacity:0.35; transform:scale(0.8);} }` |
| **Donut Slice Expand** | Hover SVG Path | `0.3s` | `ease` | `stroke-width: 34; opacity: 0.85;` |
| **Arrow Nudge** | Hover Tombol/Kartu | `0.25s` | `ease` | `translateX(3px)` atau `translateX(4px)` |

---

## 12. Responsive Design

Halaman menggunakan pendekatan Desktop-First dengan 3 titik putus (*breakpoints*) utama:

### 12.1 Breakpoint Desktop (> 1200px)
* Layout Analytics Bar: **4 Kolom** (`repeat(4, 1fr)`).
* Layout Entity Grid: **3 Kolom** (`repeat(3, 1fr)`).
* Padding Navbar & Hero: `44px` horizontal.
* Modal Layout: Grid 2 kolom (Chart kiri 290px sticky, Table kanan flex-1).

### 12.2 Breakpoint Tablet (Max-Width: 1200px)
```css
@media (max-width: 1200px) {
  .analytics-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  .entity-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
```
* Analytics Bar memecah menjadi 2 baris x 2 kolom.
* Entity Grid memecah menjadi 2 kolom (kartu ke-3 berada di baris kedua).

### 12.3 Breakpoint Tablet Portabel (Max-Width: 820px)
```css
@media (max-width: 820px) {
  .mat-action-modal-body {
    grid-template-columns: 1fr;
    padding: 20px;
    gap: 16px;
  }
  .mat-action-modal-card {
    max-height: 90vh;
    overflow-y: auto;
  }
}
```
* Submenu aksi modal bertumpuk vertikal (1 kolom penuh).

### 12.4 Breakpoint Mobile (Max-Width: 768px)
```css
@media (max-width: 768px) {
  .navbar-container {
    padding: 14px 20px;
    flex-wrap: wrap;
  }
  .search-box-wrap {
    order: 3;
    max-width: 100%;
    width: 100%;
    margin-top: 8px;
  }
  .hero-banner {
    padding: 24px 20px 28px 20px;
    gap: 20px;
  }
  .main-wrapper {
    padding: 24px 20px 40px 20px;
    gap: 28px;
  }
  .hero-section h1 {
    font-size: 26px;
  }
  .hero-section p {
    font-size: 14px;
  }
  .analytics-grid {
    grid-template-columns: 1fr;
  }
  .entity-grid {
    grid-template-columns: 1fr;
  }
  .detail-drawer {
    width: 100vw;
    right: -100vw;
  }
  .mat-modal-body,
  .bp-modal-body {
    grid-template-columns: 1fr;
    padding: 20px;
    gap: 24px;
  }
  .chart-box-card,
  .bp-summary-card {
    position: relative;
    top: auto;
  }
}
```
* Navbar menjadi dua baris: Baris 1 berisi Logo & Profil, Baris 2 berisi Search Box 100% penuh.
* Seluruh grid berubah menjadi **1 kolom tunggal bertingkat**.
* Ukuran font judul hero turun menjadi `26px`.
* Drawer dan Modal mengambil lebar 100% viewport (`100vw`).

---

## 13. Spacing System

Pola spasi (*spacing scale*) yang dipakai konsisten di seluruh kode:

| Spacing Token | Nilai Piksel | Penggunaan pada Halaman |
| :--- | :--- | :--- |
| **`space-2xs`** | `2px - 4px` | Margin subtitle, border progress track, gap teks kecil |
| **`space-xs`** | `6px - 8px` | Gap tombol icon, padding badge kecil, jarak antar baris |
| **`space-sm`** | `10px - 12px`| Padding dropdown, gap navbar profil, radius kontainer kecil |
| **`space-md`** | `14px - 16px`| Padding tombol, padding TH/TD tabel, gap kartu submenu |
| **`space-lg`** | `20px - 24px`| Padding kartu analytics, padding modal body, gap grid kolom |
| **`space-xl`** | `26px - 32px`| Padding kartu entitas, padding header modal, gap section |
| **`space-2xl`**| `38px - 44px`| Padding luar navbar, hero banner, dan main section wrapper |
| **`space-3xl`**| `60px` | Bottom padding penutup halaman utama |

---

## 14. Border Radius

Nilai border radius resmi yang terdata dari CSS:

* **`9999px` (Pill Shape)**:
  * Global Search Input Box
  * User Profile Widget
  * Tombol "View Detail" pada Analytics Tile
  * Badges & Status Pills
  * Progress Bar Track & Fill
  * Drawer Action CTA Button
* **`28px` (Large Modal Container)**:
  * `.mat-modal-card`, `.bp-modal-card`, `.mat-action-modal-card`, `.dev-notice-modal-card`
* **`26px` (Entity Hero Card)**:
  * `.entity-card`
* **`22px` (Medium Container & Big Notice Icon)**:
  * `.chart-box-card`, `.dev-notice-icon-box`
* **`20px` (Tile & Submenu Card)**:
  * `.analytics-tile`, `.mat-action-card-item`
* **`18px` (Glassmorphic Icon Container)**:
  * `.card-icon-container`
* **`16px` (Table Wrapper & Stat Box)**:
  * `.mtart-table-wrap`, `.mat-action-big-icon`, `.drawer-stat-box`
* **`14px` (Small Icon Box & Toast)**:
  * `.analytics-icon-box`, `.mat-modal-icon-wrap`, `.mat-toast-notification`, `.dev-notice-btn-close`
* **`12px` (Brand Logo & Table Bottom Footer)**:
  * `.logo-icon-wrap`, `.cust-card-box`, `.bp-pagination-wrap`
* **`8px` (Form Controls & Input Mini)**:
  * `#bpBankFilter`, search dropdowns, customer code badge
* **`6px` (Micro Badges & Pagination Buttons)**:
  * `.mtart-badge`, tombol nomor pagination

---

## 15. Shadows & Depth (Elevation Scale)

Sistem elevasi (*depth levels*) diimplementasikan sebagai berikut:

```css
/* Level 0: Flat / Inset (Input Fields & Tables) */
border: 1px solid #e2e8f0;

/* Level 1: Subtle Navbar & Micro-Widget */
box-shadow: 0 2px 8px rgba(0, 0, 0, 0.03); /* User profile */
box-shadow: 0 2px 10px rgba(0, 0, 0, 0.02); /* Top navbar */

/* Level 2: Surface Card & Analytics Tile */
box-shadow: 0 4px 18px rgba(0, 0, 0, 0.08); /* Analytics tile normal */
box-shadow: 0 4px 20px rgba(10, 35, 25, 0.12); /* Hero banner */

/* Level 3: Card Hover & Small Buttons */
box-shadow: 0 10px 28px rgba(0, 0, 0, 0.15); /* Analytics tile hover */
box-shadow: 0 12px 28px -6px rgba(13, 41, 30, 0.25); /* Entity card normal */
box-shadow: 0 4px 14px rgba(16, 185, 129, 0.3); /* Green CTA buttons */

/* Level 4: Entity Card Active Hover */
box-shadow: 0 24px 48px -10px rgba(20, 83, 45, 0.45); /* Entity card hover */
box-shadow: 0 16px 32px rgba(16, 185, 129, 0.16); /* Action card hover */

/* Level 5: Modal Dialogs, Drawers & Toasts */
box-shadow: 0 25px 60px -12px rgba(0, 0, 0, 0.28); /* Standard modals */
box-shadow: 0 25px 65px -12px rgba(15, 23, 42, 0.35); /* Notice modal */
box-shadow: -15px 0 40px rgba(0, 0, 0, 0.18); /* Slide drawer */
box-shadow: 0 16px 36px rgba(0, 0, 0, 0.28); /* Floating toast */
```

---

## 16. States (Visual Interaction States)

### 16.1 Default State
* Komponen berada pada posisi netral tanpa translasi koordinat.
* Border kontainer menggunakan `#e2e8f0` atau transparan berbobot tipis `rgba(255, 255, 255, 0.08)`.

### 16.2 Hover State
* Tombol CTA: Pergeseran warna ke satu tingkat lebih gelap, translasi `-1px` atau `-2px`, dan bayangan melebar.
* Kartu Interaktif: Translasi vertikal ke atas (`-3px` s.d `-8px`) disertai sedikit skala `1.01`.
* Icon dalam kartu mengalami pembesaran skala `1.08`.
* Baris tabel: Background berubah menjadi `#f8fafc`.

### 16.3 Focus State (Input Pencarian)
* Background berubah dari off-white (`#f4f7f6`) menjadi putih murni (`#ffffff`).
* Border color beralih ke warna aksen primer (`#10b981`).
* Muncul outer glow: `box-shadow: 0 0 0 4px rgba(16, 185, 129, 0.12);`
* Outline default browser dimatikan (`outline: none;`).

### 16.4 Active / Selected State (Pagination)
* Tombol halaman aktif terisi warna solid `#0284c7` atau `#059669` dengan teks putih tebal.
* Baris kartu accordion customer yang terbuka memperoleh border hijau `#059669` dan background header `#f0fdf4`.

### 16.5 Disabled State
* Digunakan pada modul yang belum dirilis (seperti *Request Delete Material*):
  * Kursor berubah menjadi `not-allowed`.
  * Garis tepi berubah menjadi garis putus-putus (*dashed*) `#cbd5e1`.
  * Background menjadi abu-abu pudar `#f8fafc`.
  * Opacity diset ke `0.82`.
  * Mengabaikan event klik formulir dan mengalihkan ke trigger toast pemberitahuan.

---

## 17. Accessibility (A11y)

### 17.1 Aspek yang Telah Diterapkan
* **Kontras Warna Memenuhi Standar WCAG AA**:
  * Teks putih `#ffffff` di atas Forest Green `#184434` memiliki rasio kontras `11.8:1` (jauh di atas batas minimal 4.5:1).
  * Teks judul `#0f172a` di atas latar putih `#ffffff` memiliki rasio kontras `16.1:1`.
* **Keyboard Navigation**:
  * Tombol modal dan kartu aksi memiliki atribut `role="button"` dan `tabindex="0"`.
  * Listener event global menangkap tombol `Escape` untuk menutup modal aktif secara otomatis:
    ```javascript
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') {
        closeMaterialActionModal();
        closeDevNoticeModal();
      }
    });
    ```
* **Semantic HTML**:
  * Penggunaan tag `<header>`, `<main>`, `<section>`, `<h1>`, `<h2>`, `<h3>`, `<table>`, `<thead>`, `<tbody>`, `<button>`.
* **User Feedback Protection**:
  * Pengguna tidak dibiarkan terdampar pada tautan mati (*dead links*); setiap elemen non-aktif memunculkan dialog atau toast penjelasan yang manusiawi.

### 17.2 Rekomendasi Peningkatan (*Improvement Recommendations*)
1. Menambahkan atribut `aria-label` eksplisit pada tombol icon murni (seperti tombol silang `.close-btn` dan `.dev-notice-close-x`).
2. Menambahkan `aria-expanded="true/false"` pada elemen modal dan accordion drawer.
3. Menyediakan elemen `aria-live="polite"` pada hasil pencarian dinamis tabel Vendor & Customer agar screen reader dapat mengumumkan jumlah data yang ditemukan.

---

## 18. Reusable Design Rules & Guidelines

Bagian ini adalah **aturan praktis wajib** bagi developer yang hendak membangun atau merenovasi halaman lain di dalam sistem Master Data Governance PT Kayu Mebel Indonesia.

### 18.1 Do's (Aturan yang Harus Diikuti)
1. **Gunakan Palet Forest Green untuk Area Utama**:
   * Header hero atau banner judul utama wajib memakai `#184434` dengan teks putih dan subtitle `#52b788` (uppercase).
2. **Gunakan Google Fonts Plus Jakarta Sans**:
   * Jangan mengandalkan font sistem bawaan (*Arial/Times*). Selalu sertakan link stylesheet Google Fonts untuk Plus Jakarta Sans & Inter.
3. **Standarisasi Radius Sudut Kontainer**:
   * Gunakan `28px` untuk modal, `26px` untuk kartu besar, `20px` untuk kartu sedang, dan `9999px` untuk tombol aksi pill atau badge status.
4. **Wajib Menggunakan SVG Outline Tanpa Dependency Luar**:
   * Seluruh ikon harus berupa SVG inline dengan `stroke="currentColor"` atau `stroke="white"` dan `fill="none"`. Jangan mengimpor FontAwesome atau icon webfonts pihak ketiga.
5. **Gunakan Backdrop Blur untuk Setiap Overlay Modal**:
   * Setiap modal baru wajib memiliki backdrop `rgba(15, 23, 42, 0.55 - 0.65)` dengan `backdrop-filter: blur(8px - 14px)`.
   * Terapkan kelas `modal-open-blur` pada `body` agar konten latar belakang ter-blur halus.
6. **Sediakan Debounce untuk Input Pencarian Berat**:
   * Untuk filter tabel di sisi klien dengan data lebih dari 100 baris, terapkan debounce minimal `300ms` seperti pada `debouncedCustSearch()`.

### 18.2 Don'ts (Hal yang Dilarang)
1. **Dilarang Menggunakan Warna Sembarangan**:
   * Jangan menggunakan warna biru murni `#0000ff`, hijau stabilo `#00ff00`, atau merah terang tanpa tonalitas. Ikuti hex code resmi di Bagian 5.
2. **Dilarang Menampilkan Kotak Dialog Bawaan Browser**:
   * Hindari penggunaan `alert('Feature coming soon')`. Selalu gunakan modal Under Development (`.dev-notice-modal-backdrop`) atau toast notification (`.mat-toast-notification`).
3. **Dilarang Menggunakan CSS Framework Berat**:
   * Hindari menyematkan CDN Bootstrap atau Tailwind berukuran besar ke dalam file BSP individual. Gunakan Vanilla CSS terstruktur sesuai kelas yang terdokumentasi di sini demi kecepatan load di jaringan SAP lokal.
4. **Dilarang Melanggar Aturan SAP SE80**:
   * **Maksimal 255 karakter per baris** pada file layout `.htm`. Baris HTML/CSS/JS yang terlalu panjang akan terpotong dan menyebabkan syntax error saat di-save/di-aktivasi di SAP GUI SE80.
   * **Gunakan Vanilla JavaScript ES5**: Gunakan `var`, `function`, loop tradisional, dan string concatenation (`+`). Jangan gunakan `const`, `let`, arrow functions `() => {}`, atau template literal (`` ` ``) karena engine parser SAP BSP lawas akan gagal mengompilasinya.
   * **Hindari Karakter Emoji Mentah**: Gunakan kode SVG alih-alih emoji Unicode agar tidak rusak saat enkripsi encoding database SAP NetWeaver.

---

### 18.3 Template Kode Halaman Standar (Boilerplate BSP)
Developer dapat menyalin template kerangka berikut untuk membangun halaman modul turunan baru yang 100% konsisten:

```html
<%@page language="ABAP" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PT Kayu Mebel Indonesia - [Nama Modul]</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html, body {
      width: 100%; min-height: 100vh; background-color: #f7f9f8;
      font-family: 'Plus Jakarta Sans', 'Inter', -apple-system, sans-serif;
      color: #0f172a; -webkit-font-smoothing: antialiased; overflow-x: hidden;
    }
    .top-navbar {
      position: sticky; top: 0; left: 0; width: 100%;
      background: rgba(255, 255, 255, 0.94); backdrop-filter: blur(12px);
      -webkit-backdrop-filter: blur(12px); border-bottom: 1px solid #edf2f0;
      z-index: 100; box-shadow: 0 2px 10px rgba(0, 0, 0, 0.02);
    }
    .navbar-container {
      width: 100%; padding: 16px 44px; display: flex;
      align-items: center; justify-content: space-between; gap: 32px;
    }
    .brand-logo { display: flex; align-items: center; gap: 12px; text-decoration: none; }
    .logo-icon-wrap {
      width: 44px; height: 44px; border-radius: 12px;
      background: linear-gradient(135deg, #10b981 0%, #059669 50%, #047857 100%);
      display: flex; align-items: center; justify-content: center;
      color: #ffffff; font-weight: 800; font-size: 14px;
      box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
    }
    .hero-banner {
      width: 100%; background: #184434; padding: 38px 44px 42px 44px;
      display: flex; flex-direction: column; gap: 20px;
      box-shadow: 0 4px 20px rgba(10, 35, 25, 0.12);
    }
    .hero-section { text-align: center; }
    .hero-section h1 { font-size: 34px; font-weight: 800; color: #ffffff; }
    .hero-section p { font-size: 13.5px; color: #52b788; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; }
    .main-wrapper {
      width: 100%; padding: 44px 44px 60px 44px;
      display: flex; flex-direction: column; gap: 32px; background-color: #f7faf9;
    }
  </style>
</head>
<body>
  <form id="bspForm" name="bspForm" method="post" action="[nama_halaman].htm">
    <header class="top-navbar">
      <div class="navbar-container">
        <a href="landing_page.htm" class="brand-logo">
          <div class="logo-icon-wrap">KMI</div>
          <div>
            <div style="font-size:18px; font-weight:800; color:#0f172a;">PT Kayu Mebel Indonesia</div>
            <div style="font-size:11px; font-weight:600; color:#64748b;">Wood & Furniture Manufacturing</div>
          </div>
        </a>
      </div>
    </header>
    <div class="hero-banner">
      <section class="hero-section">
        <h1>[Judul Modul Baru]</h1>
        <p>Enterprise Master Data Governance</p>
      </section>
    </div>
    <main class="main-wrapper">
      <!-- Konten Modul Spesifik di sini -->
    </main>
  </form>
</body>
</html>
```
