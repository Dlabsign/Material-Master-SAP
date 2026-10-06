# PRODUCT REQUIREMENT DOCUMENT (PRD)

| Metadata Dokumen | Keterangan |
| :--- | :--- |
| **Nama Proyek** | AI-Powered Furniture BOM & SAP Master Data Extractor |
| **Kode Proyek** | PRD-AI-SAP-BOM-001 |
| **Versi** | 1.0.0 |
| **Status** | Approved / Ready for Development |
| **Tanggal Terbit** | 5 Oktober 2026 |
| **Target Rilis** | Q1 2027 |
| **Pemilik Produk** | Engineering & SAP Solutions Lead |
| **Domain Industri** | Manufaktur Furnitur Kayu & Logam (Woodworking & Furniture Export) |

---

## 1. Executive Summary & Problem Statement

### 1.1 Latar Belakang
Pada industri manufaktur furnitur kayu, departemen Desain/Drafter menghasilkan gambar kerja teknis (AutoCAD `.dwg`/`.dxf` atau PDF/3D render) yang mencantumkan ukuran bersih (*finish size*). Di sisi lain, departemen **Master Data & PPIC** di SAP ERP membutuhkan:
1. Kode material unik (*Material Number*) terstandarisasi untuk ribuan part.
2. Dimensi kasar (*rough size*) dengan toleransi serut (*planing*) dan gergaji (*saw kerf*) guna menghitung kubikasi bahan baku ($M^3$).
3. Identifikasi komponen pembantu/tersembunyi (*auxiliary materials*) seperti sekrup, *wooden dowel*, lem PVAc, tali anyaman jok, hingga material finishing.
4. Pengikatan komponen BOM (*Bill of Materials*) ke stasiun kerja produksi (*Routing Operations / Work Centers*).

### 1.2 Masalah yang Dihadapi (Pain Points)
* **Lead Time Konversi Lambat:** Memerlukan waktu 3–6 jam per model produk bagi tim Master Data untuk menerjemahkan tabel cutting list drafter ke format input SAP (`MM01`, `CS01`, `CA01`).
* **Duplikasi Master Data:** Sering terjadi pembuatan kode material baru untuk part standar (seperti *corner block*, baut, dowel) karena tidak ada mekanisme pencarian kemiripan (*similarity search*).
* **Missing Items pada BOM:** Drafter sering kali tidak mencatat material penolong (lem, sekrup, pelapis finishing) di gambar kerja, menyebabkan selisih inventaris saat order produksi dirilis.
* **Keterpisahan BOM dan Routing:** Di SAP, BOM (`CS01`) dan Routing (`CA01`) sering tidak terhubung di level operasi, sehingga pengeluaran barang (*Goods Issue* 261) tidak bisa dilakukan bertahap sesuai stasiun kerja.

### 1.3 Solusi yang Diusulkan
Membangun platform *middleware* cerdas berbasis web yang mampu membaca file CAD mentah (`.dwg`/`.dxf`) serta gambar kerja produk, menggunakan multimodal AI untuk mendekonstruksi anatomi furnitur, menghitung dimensi kasar dan kubikasi secara otomatis, merekomendasikan kode SAP eksisting vs baru, serta mengikat komponen langsung ke operasi pabrik (*Component Allocation*) sebelum disinkronkan ke SAP ERP via BAPI.

---

## 2. Tujuan & Sasaran Produk (Goals & Success Metrics)

| Sasaran Bisnis / Metrik | Kondisi Baseline (Manual) | Target dengan Sistem AI |
| :--- | :--- | :--- |
| **Waktu Pembuatan BOM SAP** | 180 – 360 menit / model | $\le 10$ menit / model |
| **Akurasi Ekstraksi Part** | 85% (human error pada part kecil) | $\ge 98\%$ part teridentifikasi |
| **Pencegahan Duplikasi Kode** | Sering terjadi duplikasi master data | Menurunkan $\ge 90\%$ duplikasi part standar |
| **Kesiapan Data Routing (CA01)** | Alokasi material manual di SAP GUI | 100% otomatis teralokasi ke 5 tahapan kerja |

---

## 3. Persona Pengguna & Pemangku Kepentingan

1. **Drafter / CAD Engineer:** Mengunggah file `.dwg`/`.dxf` atau render 3D produk hasil perancangan beserta dimensi keseluruhan ($W \times D \times H$).
2. **Master Data Specialist:** Memverifikasi hasil ekstraksi AI, meninjau rekomendasi kode SAP (`NEW` vs `EXISTING`), dan menyetujui draf BOM.
3. **PPIC / Production Planner:** Memeriksa alokasi material pada 5 stasiun kerja pabrik (*Routing Operations*) dan memastikan *Production Version* (`C223`) terbentuk sempurna.
4. **Cost Accounting / Akuntansi Biaya:** Memanfaatkan kalkulasi kubikasi kayu ($M^3$) dan *rough size* untuk dasar perhitungan Harga Pokok Penjualan (HPP / *Standard Costing*).

---

## 4. Alur Kerja Sistem (End-to-End System Workflow)

```
[ DRAFTER / USER ]
       │
       ▼ (1. Upload .dwg / .dxf / Gambar + Input Dimensi Produk)
[ STAGING WEB PORTAL (SAP Fiori Style) ]
       │
       ▼
[ CAD ENGINE & MULTIMODAL AI EXTRACTOR ]
       ├─ Membaca binary CAD / layer / vektor
       ├─ Dekonstruksi anatomi visual (kaki, rel, sandaran, dudukan)
       ├─ Kalkulasi Finish Size ➔ Rough Size (+toleransi) & Kubikasi (M³)
       └─ Auto-Suggest material tersembunyi (dowel, sekrup, lem, anyaman)
       │
       ▼
[ MASTER DATA SIMILARITY & MAPPING ENGINE ]
       ├─ Query Material Master SAP (MARA/MAKT)
       ├─ Klasifikasi status part: [NEW] vs [EXISTING] vs [AUTO-SUGGEST]
       └─ Pemetaan ke 5 Alur Stasiun Kerja Pabrik (Part ➔ Comp ➔ Mach ➔ Assy ➔ Paint)
       │
       ▼
[ HUMAN-IN-THE-LOOP REVIEW & ALLOCATION SCREEN ]
       ├─ Review tabel interaktif & CAD Blueprint Viewer
       ├─ Validasi alokasi komponen ke nomor operasi (Zuordnung CA01)
       └─ Klik tombol: "Sync to SAP ERP"
       │
       ▼
[ SAP BAPI CONNECTOR / MIDDLEWARE ]
       ├─ BAPI_MATERIAL_SAVEDATA ➔ Registrasi part baru (MM01)
       ├─ CSAP_MAT_BOM_MAINTAIN ➔ Buat struktur hirarki BOM (CS01)
       └─ BAPI_ROUTING_CREATE   ➔ Buat Routing & ikat PLMZ (CA01) + C223
```

---

## 5. Ruang Lingkup & Kebutuhan Fungsional (Functional Requirements)

### Modul 1: CAD & Visual Ingestion (FR-01)
* **FR-01.1:** Sistem wajib mendukung *upload* file gambar raster (`.png`, `.jpg`, `.jpeg`), dokumen vektor/PDF, serta file mentah AutoCAD (`.dwg` versi 2007–2024 dan `.dxf` ASCII).
* **FR-01.2:** Engine CAD parser harus mampu membaca header biner AutoCAD (`AC1021`, `AC1027`, `AC1031`, `AC1032`) serta mengekstrak teks dimensi, nama layer, dan entitas geometri.
* **FR-01.3:** Menyediakan komponen **CAD 2D Blueprint Canvas Viewer** interaktif bergaya *Model Space* yang mendukung *pan*, *zoom in/out*, *fit-to-screen*, grid metrik, dan sumbu UCS.
* **FR-01.4:** Form input parameter mencakup:
  * `Product Code / BOM Code` (contoh: `NT-325-2`)
  * `Product Name` (contoh: `GABBY`)
  * `Product Type` (contoh: `HAMBLIN BARSTOOL`)
  * `Overall Dimension` dalam milimeter ($W \times D \times H$)
  * `Revision Date`
  * `Primary Wood Species` (Mahoni, Jati, Sungkai, Oak, Rubberwood).

### Modul 2: AI Decomposition & Sizing Engine (FR-02)
* **FR-02.1:** AI mengidentifikasi anatomi struktural furnitur berdasarkan tipe produk:
  * Kaki depan (*Front Legs*) & Kaki belakang (*Back Legs/Posts*).
  * Rel pengikat dudukan (*Front/Back/Side Rails*).
  * Palang tumpuan kaki (*Stretchers*), mendeteksi material kayu vs pipa kuningan (*brass*).
  * Konstruksi sandaran (*Backrest Crown, Vertical Slats, Middle Tuscan Slat*).
  * Tipe dudukan (*Solid Wood*, *Upholstery*, atau *Woven Seat*).
* **FR-02.2:** Rumus kalkulasi dimensi kasar (*Rough Size*) dari dimensi bersih (*Finish Size*):
  * Tebal ($T_{\text{rough}}$) = $T_{\text{finish}} + 3\text{ mm}$ s/d $5\text{ mm}$
  * Lebar ($W_{\text{rough}}$) = $W_{\text{finish}} + 5\text{ mm}$ s/d $8\text{ mm}$
  * Panjang ($L_{\text{rough}}$) = $L_{\text{finish}} + 10\text{ mm}$ s/d $15\text{ mm}$
* **FR-02.3:** Rumus kalkulasi kubikasi kayu mentah komponen ($M^3$):
  $$\text{Gross Volume } (M^3) = \frac{T_{\text{rough}} \times W_{\text{rough}} \times L_{\text{rough}} \times \text{Quantity}}{1\,000\,000\,000}$$

### Modul 3: Auto-Suggest Engine untuk Komponen Tersembunyi (FR-03)
* **FR-03.1:** Jika terdeteksi konstruksi rangka kursi/meja, sistem otomatis menambahkan:
  * **Corner Block:** 4 unit kayu keras (*Rubberwood*) dengan ukuran standar.
  * **Sekrup Pengunci:** Sekrup kayu countersunk $4 \times 35\text{ mm}$ (8 pcs).
  * **Wooden Dowel:** Dowel pasak kayu White Beech ($10 \times 30\text{ mm}$ dan $10 \times 20\text{ mm}$).
  * **Perekat Kimia:** Lem kayu PVAc D3 Crosslink ($0.15\text{ kg}$ per unit).
* **FR-03.2:** Jika terdeteksi tekstur anyaman pada area dudukan, sistem otomatis menambahkan material *Seat Weaving Cord* (*Kraft Cord / Paper Rope*) dengan estimasi bobot ($1.2\text{ kg}$ per unit).

### Modul 4: Pemetaan ke 5 Alur Stasiun Kerja Pabrik (FR-04)
Setiap komponen yang diekstrak harus dipetakan ke dalam 5 bagian operasi kerja manufaktur furnitur:
1. **Part (Operasi 0010 / Work Center: `WC-PART`):**
   * Pemotongan balok/papan gergajian kasar (*Rough Mill / Sawn Timber*).
   * Tipe Material: `ROH`.
2. **Component (Operasi 0020 / Work Center: `WC-COMP`):**
   * Penyerutan 4 sisi (*S4S - Planer/Jointer*) untuk mencapai dimensi bersih, penyiapan *corner block*.
   * Tipe Material: `ROH / HALB`.
3. **Machining Component (Operasi 0030 / Work Center: `WC-MACH`):**
   * Pembuatan pen/purus (*tenon/mortise*), bor lubang dowel, profil lengkung CNC, laminasi *Tuscan*.
   * Tipe Material: `ROH / HALB`.
4. **Assembling (Operasi 0040 / Work Center: `WC-ASSY`):**
   * Perakitan rangka modul sub-assy dengan lem PVAc, pengepresan klem, sekrup *corner block*, dan anyaman tali dudukan.
   * Tipe Material: `HALB` (Sub-Assembly Body).
5. **Painting & Packing (Operasi 0050 / Work Center: `WC-PNT`):**
   * Pengamplasan halus, pewarnaan (*wood stain*), *top coat*, perakitan aksesoris kuningan (*Brass Cap & Stretcher*), dan pengemasan boks.
   * Tipe Material: `FERT` (Produk Jadi).

### Modul 5: Component Allocation (Zuordnung) & Production Version (FR-05)
* **FR-05.1:** Komponen material tidak boleh mengambang tanpa stasiun kerja. Sistem harus mengalokasikan nomor item BOM ke nomor operasi di Routing (`PLMZ Allocation Matrix`):
  * Balok mahoni $\rightarrow$ Operasi 0010 (Part)
  * Corner block $\rightarrow$ Operasi 0020 (Component)
  * Profil kaki & kisi sandaran $\rightarrow$ Operasi 0030 (Machining)
  * Lem, dowel, sekrup, tali anyaman $\rightarrow$ Operasi 0040 (Assembling)
  * Fitting kuningan & bahan cat $\rightarrow$ Operasi 0050 (Painting)
* **FR-05.2:** Menghasilkan entitas **Production Version (T-Code `C223`)** yang mengunci:
  $$\text{Production Version} = \text{Material FERT} + \text{Alternative BOM} + \text{Routing Group}$$

### Modul 6: Integrasi SAP ERP via BAPI (FR-06)
* **FR-06.1 - Pembuatan Material Master Baru (T-Code `MM01`):**
  * Memanggil Function Module `BAPI_MATERIAL_SAVEDATA` untuk material bertanda status `NEW`.
  * Mengisi view: Basic Data 1 & 2, Purchasing, MRP 1–4, Work Scheduling, dan Accounting 1.
* **FR-06.2 - Pembuatan Struktur BOM (T-Code `CS01`):**
  * Memanggil Function Module `CSAP_MAT_BOM_MAINTAIN` untuk Header `FERT` dan Sub-Assembly `HALB`.
  * BOM Usage: `1` (Production), Item Category: `L` (Stock Item).
* **FR-06.3 - Pembuatan Routing & Alokasi Komponen (T-Code `CA01`):**
  * Memanggil Function Module `BAPI_ROUTING_CREATE` untuk mendaftarkan 5 stasiun kerja dan matriks alokasi tabel `PLMZ`.

---

## 6. Kebutuhan Antarmuka Pengguna (UI/UX Requirements)

1. **Gaya Desain:** Enterprise modern bernuansa **SAP Fiori**, dominasi warna abu-abu netral (*slate*), biru korporat, dan badge status fungsional.
2. **Layout Dua Kolom Responsif:**
   * **Kolom Kiri (Input & Parameter):**
     * Area drag-and-drop CAD/Drawing viewer dengan canvas blueprint interaktif.
     * Formulir parameter teknis produk (Kode, Nama, Tipe, Dimensi $W \times D \times H$, Tanggal Revisi, Kayu Utama).
     * Tombol aksi utama: `🔍 Analisis Gambar & Generate BOM (AI)`.
   * **Kolom Kanan (Review Master Data & Alur Pabrik):**
     * 4 Kartu Metrik Ringkas: Total Komponen, Total Kubikasi ($M^3$), Material Baru (`NEW`), dan Material Standar (`EXISTING`).
     * Tab 1: **Tabel Review BOM Master Data (CS01)** dengan indikator status, dimensi bersih vs kasar, dan filter pencarian cepat.
     * Tab 2: **CAD Entities & Layers** untuk audit integritas gambar teknis.
     * Tab 3: **Alokasi Operasi CA01 (Zuordnung & C223)** memperlihatkan tabel matriks part ke stasiun kerja.
     * Tab 4: **SAP JSON Payload** menampilkan struktur JSON baku siap kirim ke BAPI.
3. **Action Bar Bawah:** Tombol `Export Excel/CSV` dan tombol eksekusi `🚀 Sync to SAP ERP`.

---

## 7. Skema Data & Spesifikasi Teknis

### 7.1 Aturan Penamaan Kode Material SAP (Naming Convention Rule)

| Kategori Material | Format Penamaan Kode | Contoh Deskripsi Material SAP |
| :--- | :--- | :--- |
| **Produk Jadi (FERT)** | `FG-[KODE_PRODUK]` | `FG-NT-325-2` (HAMBLIN BARSTOOL GABBY) |
| **Sub-Assembly (HALB)** | `SA-[KODE_PRODUK]-[MODUL]` | `SA-NT325-BDY` (SUB ASSY BODY) |
| **Komponen Kayu (ROH)** | `WD-[SPESIES]-[PART]-[DIMENSI]` | `WD-MAH-FLEG-L-4445` (Mahoni 44x45x743.5) |
| **Komponen Logam (ROH)** | `MET-[LOGAM]-[PART]-[PANJANG]` | `MET-BRS-STR-F-0498` (Brass Stretcher 498.5) |
| **Hardware Standar (ROH)** | `HD-[TIPE]-[SPESIFIKASI]` | `HD-DWL-BEECH-1030` (Dowel 10x30 mm) |
| **Bahan Penolong (ROH)** | `CH-[TIPE]-[VARIAN]` | `CH-GLU-PVAC-XLINK` (Lem Kayu PVAc) |

### 7.2 Spesifikasi JSON Payload Baku untuk Middleware SAP

```json
{
  "system_header": {
    "interface_id": "INT-AI-SAP-BOM-SYNC",
    "sap_target_system": "S4HANA_PRD",
    "sap_client": "100",
    "plant": "1010",
    "timestamp": "2026-10-05T03:32:59Z"
  },
  "product_header": {
    "product_code": "NT-325-2",
    "product_name": "GABBY",
    "product_type": "HAMBLIN BARSTOOL",
    "overall_dimensions_mm": {
      "width": 542.0,
      "depth": 612.0,
      "height": 1215.0
    },
    "revision_date": "2026-10-04",
    "base_uom": "PC",
    "total_gross_volume_m3": 0.02485,
    "production_version": {
      "version_id": "0001",
      "valid_from": "2026-10-01",
      "valid_to": "9999-12-31",
      "bom_alternative": "01",
      "routing_group": "ROUT-NT325"
    }
  },
  "routing_operations": [
    {
      "operation_no": "0010",
      "work_center": "WC-PART",
      "description": "Pembelahan & Pemotongan Kasar Balok (Rough Mill)",
      "storage_location": "SL-ROH"
    },
    {
      "operation_no": "0020",
      "work_center": "WC-COMP",
      "description": "Penyerutan 4 Sisi S4S & Penyiapan Corner Block",
      "storage_location": "SL-COMP"
    },
    {
      "operation_no": "0030",
      "work_center": "WC-MACH",
      "description": "Permesinan Kayu Presisi, Dowel, Tenon & Mortise",
      "storage_location": "SL-MACH"
    },
    {
      "operation_no": "0040",
      "work_center": "WC-ASSY",
      "description": "Perakitan Rangka, Lem, Doweling, & Anyam Jok",
      "storage_location": "SL-ASSY"
    },
    {
      "operation_no": "0050",
      "work_center": "WC-PNT",
      "description": "Finishing, Pemasangan Brass Fittings, & Packaging",
      "storage_location": "SL-FG"
    }
  ],
  "bom_items": [
    {
      "item_no": "0010",
      "level": 2,
      "parent_material": "SA-NT325-BDY",
      "part_name": "FRONT LEG L",
      "sap_material_type": "ROH",
      "suggested_material_code": "WD-MAH-FLEG-L-4445",
      "sap_status": "NEW",
      "quantity": 1.0,
      "base_uom": "PC",
      "finish_dimension_mm": { "t": 44.0, "w": 45.0, "l": 743.5 },
      "rough_dimension_mm": { "t": 48.0, "w": 52.0, "l": 755.0 },
      "gross_volume_m3": 0.001884,
      "allocated_operation": "0030",
      "work_center": "WC-MACH"
    },
    {
      "item_no": "0020",
      "level": 2,
      "parent_material": "SA-NT325-BDY",
      "part_name": "FRONT CORNER L",
      "sap_material_type": "ROH",
      "suggested_material_code": "WD-RUB-00106",
      "sap_status": "EXISTING",
      "quantity": 1.0,
      "base_uom": "PC",
      "finish_dimension_mm": { "t": 32.0, "w": 43.5, "l": 106.0 },
      "rough_dimension_mm": { "t": 36.0, "w": 50.0, "l": 118.0 },
      "gross_volume_m3": 0.000212,
      "allocated_operation": "0020",
      "work_center": "WC-COMP"
    },
    {
      "item_no": "0030",
      "level": 2,
      "parent_material": "SA-NT325-BDY",
      "part_name": "WOOD SCREW 4X35",
      "sap_material_type": "ROH",
      "suggested_material_code": "HD-SCR-0004",
      "sap_status": "AUTO-SUGGEST",
      "quantity": 8.0,
      "base_uom": "PC",
      "finish_dimension_mm": null,
      "rough_dimension_mm": null,
      "gross_volume_m3": 0.0,
      "allocated_operation": "0040",
      "work_center": "WC-ASSY"
    }
  ]
}
```

---

## 8. Kebutuhan Non-Fungsional (Non-Functional Requirements)

1. **Performa Pemrosesan (Response Time):**
   * Parsing biner CAD `.dwg`/`.dxf` di browser $\le 2.0\text{ detik}$.
   * Ekstraksi visual AI dan pembentukan draf BOM $\le 5.0\text{ detik}$.
2. **Keandalan & Validasi Data (Reliability):**
   * Seluruh part berdimensi kayu wajib memiliki nilai volume kasar ($M^3$) bukan nol.
   * Toleransi ukuran bersih tidak boleh melampaui dimensi terluar produk jadi.
3. **Keamanan & Otorisasi (Security):**
   * Koneksi RFC ke SAP dilindungi dengan enkripsi TLS/SNC (*Secure Network Communications*).
   * Kredensial akun sistem SAP disimpan di secret manager terenkripsi AES-256.
4. **Audit Trail & Logging:**
   * Setiap penolakan atau perubahan kode rekomendasi AI oleh engineer dicatat ke dalam database untuk kebutuhan perbaikan model (*fine-tuning loop*).

---

## 9. Rencana Implementasi & Roadmap Pengembangan

```
+-----------------------------------------------------------------------------------+
| ROADMAP PENGEMBANGAN SISTEM                                                       |
+-----------------------------------------------------------------------------------+
| TAHAP 1: Standarisasi Kamus Master Data & Dataset CAD (Bulan 1 - 2)               |
| - Pembakuan Naming Rules material SAP (FERT, HALB, ROH).                          |
| - Pengumpulan 100 sampel DWG/Cutting List kursi, meja, dan lemari.                |
+-----------------------------------------------------------------------------------+
| TAHAP 2: Pengembangan CAD Engine & AI Multimodal Vision (Bulan 3 - 4)             |
| - Implementasi Web CAD Canvas Viewer (DXF/DWG Parser).                            |
| - Penalaan System Prompt AI dekonstruksi visual & kalkulasi toleransi kubikasi.  |
+-----------------------------------------------------------------------------------+
| TAHAP 3: Middleware & Integrasi BAPI SAP ERP (Bulan 5)                            |
| - Pembangunan service API konektor SAP (BAPI_MATERIAL_SAVEDATA & CSAP).          |
| - Implementasi matriks alokasi operasi PLMZ (CA01) & Production Version (C223).   |
+-----------------------------------------------------------------------------------+
| TAHAP 4: User Acceptance Testing (UAT) & Peluncuran Pabrik (Bulan 6)              |
| - Uji coba paralel tim Drafter dan Master Data pada 50 model baru.                |
| - Go-Live & integrasi penuh ke Production Plant SAP 1010.                         |
+-----------------------------------------------------------------------------------+
```

---

## 10. Manajemen Risiko & Mitigasi

| Risiko | Dampak | Peluang | Strategi Mitigasi |
| :--- | :--- | :--- | :--- |
| **Versi DWG Proprietary Baru** | Gagal mengekstrak geometri dari file binary | Sedang | Menyediakan *auto-fallback* ke format DXF dan OCR visual gambar teknis. |
| **Part Unik Salah Dipetakan** | Terjadi salah alokasi stasiun kerja produksi | Rendah | Menggunakan mekanisme *Human-in-the-Loop*; draf BOM wajib disetujui Engineer sebelum sinkronisasi SAP. |
| **Koneksi Jaringan SAP Terputus** | Data BOM gagal terposting ke server SAP | Rendah | Mengimplementasikan antrean transaksi (*queueing mechanism*) dengan status *Pending Retry*. |