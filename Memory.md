# Memory.md - Working Log & Technical Context

---

## 1. Metadata Pekerjaan
- **Tanggal Pekerjaan**: 27 Agustus 2026
- **Project / Module**: SAP Material Master Governance - Wood Part Staging Platform (R&D) (`BOM/index4`)
- **Developer / Agent**: Pair Programming Session (Antigravity & User)

---

## 2. Tujuan Pekerjaan Hari Ini
1. **Redesign UI/UX `BOM/index4/index4.htm`**: Mengubah tampilan layout, warna (emerald system), typography (Google Font Inter), spacing, card glassmorphism (`.glass-panel`, `.glass-subpanel`), button pill, status tracker cards, tab switcher, dan modal dialogs agar 100% konsisten dengan [request_form.htm](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/Request/request_form.htm).
2. **Fix ABAP Compilation Error**: Memperbaiki error sintaks ABAP BSP pada line 176 `index4.htm` / `OnInputprocessing.abap` (`APPROVED_BY` vs `APPROVED_AT` data type incompatibility).
3. **Implementasi Search Material & SAP MARA Reference**: Menambahkan Container 01 pencarian data SAP MARA (2-column layout grid: Query Parameters & Material Master Results dengan paginasi, filter wildcard, dan tombol `Use as Ref`) ke [index4.htm](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/index4/index4.htm) serta backend handler `WHEN 'SEARCH_MARA'` di [OnInputprocessing.abap](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/index4/OnInputprocessing.abap).

---

## 3. File yang Dimodifikasi
1. **[index4.htm](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/index4/index4.htm)**
   - *Bagian/Function*: Head styles, Top Header, Centered Title, Section 01 (Search MARA Container & Table Result), Section 02 (Part Specifications & Table Input), Section 03 (Riwayat Upload & Status Tracker), Modals (Loading, Reason, Success), dan JS functions (`searchMaraSAP`, `renderMaraResults`, `useMaraIndex`, `resetFilter`, `matchWildcard`).
2. **[OnInputprocessing.abap](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/index4/OnInputprocessing.abap)**
   - *Bagian/Function*: Event handler `WHEN 'GET_HISTORY'` (fix positional mapping) dan penambahan event handler `WHEN 'SEARCH_MARA'`.

---

## 4. Perubahan & Detail Implementasi

### A. UI/UX Redesign & Glassmorphic Design System ([index4.htm](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/index4/index4.htm))
- Mengintegrasikan Google Font `Inter` dan Tailwind CSS extended palette (`emerald-50` s/d `emerald-900`).
- Menerapkan efek backdrop blur pada background (`radial-gradient`), navbar sticky, card `.glass-panel` (blur 16px, border white/80), `.glass-subpanel` (blur 8px, border slate-200), dan input focus rings.
- Mengupdate Top Navbar dengan logo mark gradient `MM` dan avatar pill (`<%= sy-uname %>`).
- Memformat ulang 4 mini summary cards (Pending, Hold, Approved, Rejected) dan pill tab switcher.
- Memperbarui Modals (Loading Overlay, Submit Reason Modal, dan Submit Success Modal) menjadi style `rounded-3xl` glassmorphic.

### B. Search Material & SAP MARA Reference ([index4.htm](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/index4/index4.htm) & [OnInputprocessing.abap](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/index4/OnInputprocessing.abap))
- **Section 01 Layout**: Grid 2 Kolom (Left: Query Parameters `filterMatnr`, `filterMaktx`, `filterMtart`, `filterMatkl`; Right: Material Master Result Table dengan badge status, table results, dan paginasi).
- **Penomoran Section**:
  - `01` : `SEARCH MATERIAL & SAP REFERENCE`
  - `02` : `PART SPECIFICATIONS & DYNAMIC GROUPING`
  - `03` : `RIWAYAT PROCESS UPLOAD & STATUS TRACKER`
- **Backend ABAP Handler (`WHEN 'SEARCH_MARA'`)**:
  - Melakukan `LEFT OUTER JOIN` antara `mara AS a` dan `makt AS b ON a~matnr = b~matnr AND b~spras = @sy-langu`.
  - Memproses filter `FILTER_MATNR`, `FILTER_MAKTX`, `FILTER_MTART`, `FILTER_MATKL` dengan wildcard pattern `%`.
  - Menjalankan `CONVERSION_EXIT_ALPHA_INPUT` untuk `MATNR` numerik.
  - Mengembalikan string JSON terkompresi `ty_mara_res` (`matnr`, `maktx`, `mtart`, `matkl`, `meins`, `bismt`, `mbrsh`, `spart`).

---

## 5. Logic & Function yang Ditambahkan / Diperbaiki

| Function / Handler | Location | Deskripsi & Peran Logic |
| :--- | :--- | :--- |
| `WHEN 'GET_HISTORY'` | `OnInputprocessing.abap` | Menyelaraskan urutan `ty_history` dengan `SELECT` dan menggunakan `INTO CORRESPONDING FIELDS OF TABLE @lt_history`. |
| `WHEN 'SEARCH_MARA'` | `OnInputprocessing.abap` | Handler AJAX untuk query SAP MARA database dan mengembalikan JSON. |
| `searchMaraSAP()` | `index4.htm` | Mengirim data filter ke backend dan memproses hasil query dengan `matchWildcard()`. |
| `renderMaraResults()` | `index4.htm` | Menampilkan hasil pencarian MARA berpaginasi (10 item/halaman) lengkap dengan tombol `Use as Ref`. |
| `useMaraIndex(idx)` | `index4.htm` | Memetakan item MARA terpilih ke dalam kolom input BOM staging (mengisi baris 1 jika kosong, atau menambah baris baru dengan `addNewRowData`). |
| `resetFilter()` | `index4.htm` | Membersihkan field filter pencarian dan mengembalikan state tabel MARA ke *Ready to Search*. |

---

## 6. Keputusan Teknis (Technical Decisions)

1. **Preserve Existing Form Contract**:
   - Semua nama field HTML form (`REQ_ID`, `CURRENT_UPLOAD_ID`, `CURRENT_FILENAME`, `ROW_COUNT`, `matnr_X`, `maktx_X`, `disgr_X`, `werks_X`, dll.) dan endpoint URL (`index2.htm?OnInputProcessing=SAVE_STAGE`) dipertahankan 100% tanpa mengubah nama variabel yang dikonsumsi oleh ABAP backend `OnInputprocessing.abap`.
2. **Defensive Open SQL Mapping**:
   - Menggunakan `INTO CORRESPONDING FIELDS OF TABLE` di ABAP Open SQL daripada positional mapping murni agar penambahan kolom di kemudian hari tidak merusak urutan penampungan data.
3. **Seamless Reference Staging**:
   - Pada fungsi `useMaraIndex(idx)`, jika baris 1 pada tabel BOM masih dalam keadaan kosong (`maktx` & `matnr` belum diisi), data reference langsung diisikan ke baris 1. Jika baris 1 sudah memiliki data, sistem akan secara otomatis membuat baris baru (`addNewRowData`).
   - Hasil reference tetap **100% editable** oleh user.

---

## 7. Field Data Mapping (`Use as Ref`)

| MARA Reference Field | Target Input Selector (`index4.htm`) | Keterangan Data |
| :--- | :--- | :--- |
| `matnr` / `MATNR` | `.row-matnr` | Kode Material SAP (leading zeros dibersihkan) |
| `maktx` / `MAKTX` | `.row-maktx` | Part Name / Material Description |
| `mtart` / `MTART` | `.row-mtart` | Tipe Material (e.g. `HALB`, `ROH`) |
| `matkl` / `MATKL` | `.row-matkl` | Grup Material (e.g. `HSF011`) |
| `meins` / `MEINS` | `.row-meins` | Satuan / Base UoM (e.g. `PC`, `M3`, `M2`) |
| `groes` / `GROES` | `.row-groes-fin-str` | Finish Size / Dimensi |

---

## 8. Error yang Ditemukan & Solusi

### Error 1: ABAP Data Type Incompatibility pada `GET_HISTORY`
- **Pesan Error**: `176 BSP Page INDEX4.HTM - The data type of the component APPROVED_BY of LT_HISTORY is not compatible with the data type of APPROVED_AT.`
- **Penyebab**: Deklarasi `ty_history` menempatkan `sub_reason` (`STRING`) pada komponen ke-7, sedangkan klausa `SELECT` menempatkan `approved_by` (`CHAR12`) pada posisi ke-7 dan `approved_at` (`TIMESTAMP` / `DEC 15`) pada posisi ke-8. Karena `INTO TABLE @lt_history` melakukan positional mapping murni, ABAP mencoba memasukkan `approved_at` (`TIMESTAMP`) ke komponen `approved_by` (`CHAR12`).
- **Solusi**: Re-order field pada `ty_history` agar sama persis dengan urutan klausa `SELECT` dan tambahkan `INTO CORRESPONDING FIELDS OF TABLE @lt_history`.

### Error 2: JS Uncaught SyntaxError (Invalid or Unexpected Token) pada `switchHistoryTab`
- **Pesan Error**: `Uncaught SyntaxError: Invalid or unexpected token (at index4.htm:936:41)`
- **Penyebab**: Baris string literal class Tailwind CSS yang sangat panjang terpisah ke baris baru tanpa string concatenation (`+`), menyebabkan parser JavaScript menganggapnya sebagai string tak tertutup (*unclosed string literal*).
- **Solusi**: Memecah deklarasi string class (`baseActive` & `baseInactive`) ke dalam beberapa baris pendek yang menggunakan penggabungan string (`+`) sehingga tetap aman dari batas 255 karakter SE80 dan valid secara sintaks JS.

### Error 3: JS Uncaught SyntaxError (Invalid or Unexpected Token) pada `showToast`
- **Pesan Error**: `Uncaught SyntaxError: Invalid or unexpected token (at index4.htm:2054:106)`
- **Penyebab**: String literal pada properti `toast.className` terpisah secara tak sengaja ke baris baru tanpa tanda `+`.
- **Solusi**: Memecah string `toast.className` menjadi variabel terpisah `baseStyle` & `typeStyle` yang menggunakan penggabungan string (`+`) pada baris-baris pendek.

---

## 9. Status Project & Task Per Hari Ini
- [x] Redesign UI/UX `index4.htm` konsisten dengan `request_form.htm` &rarr; **SELESAI**
- [x] Fix compilation error `APPROVED_BY` vs `APPROVED_AT` &rarr; **SELESAI**
- [x] Implementasi Search SAP MARA & Use Reference ke `index4.htm` & `OnInputprocessing.abap` &rarr; **SELESAI**
- [x] Fix JS SyntaxError line break di `switchHistoryTab` & `showToast` &rarr; **SELESAI**
- [x] Implementasi Format Tampilan Auto-Split 2 Baris `+` untuk Data > 200 Karakter &rarr; **SELESAI**
- [x] Hapus Seluruh Fitur Auto Input / Auto-Fill / MRP Presets (`MRP_PRESETS`, `applyMrpGroupPresets`, default fallbacks `addNewRowData`, `parseStandardExcelRD`, `loadUploadDetail`) &rarr; **SELESAI**
- [x] Tambahkan 6 Kolom Baru pada Material Master Result Table (`Plant`, `MRP Group`, `MRP Controller`, `SLoc 1`, `SLoc 2`, `Material Type`, `Material Group`) &rarr; **SELESAI**
- [x] Menghubungkan Backend ABAP `SEARCH_MARA` dengan Data Tabel `MARC` (`WERKS`, `DISGR`, `DISPO`, `LGPRO`, `LGFSB`) &rarr; **SELESAI**
- [x] Support Kombinasi Multi-Plant per Material dari MARC &rarr; **SELESAI**
- [x] Auto-generation `Finish Size` (`TxWxL`) & `Code Material` dari Dimensi Finish (Kolom M, N, O) di [index4.htm](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/index4/index4.htm) &rarr; **SELESAI**
- [x] Verifikasi Penegakan Konsep "User Input (`Use.xlsx`) ≠ Data Steward / SAP Format (`MAIN TEMPLATE.xlsx`)" &rarr; **SELESAI**

---

## 10. SAP MARC Join & Material Master Result Data Mapping
1. **Peningkatan Query ABAP `WHEN 'SEARCH_MARA'` (`OnInputprocessing.abap`)**:
   - Menambahkan `LEFT OUTER JOIN marc AS c ON a~matnr = c~matnr` pada klausa Open SQL.
   - Mengambil data aktual dari tabel `MARC`:
     - `c~werks` &rarr; `werks` (**Plant**)
     - `c~disgr` &rarr; `disgr` (**MRP Group**)
     - `c~dispo` &rarr; `dispo` (**MRP Controller**)
     - `c~lgpro` &rarr; `lgort1` (**SLoc 1** / Production SLoc)
     - `c~lgfsb` &rarr; `lgort2` (**SLoc 2** / External Procurement SLoc)
   - **Multiple Plant Handling**: Jika 1 material memiliki beberapa Plant di tabel `MARC`, klausa `JOIN` akan mengembalikan setiap kombinasi **Material + Plant** secara terpisah tanpa menimpa data sebelumnya.

2. **Material Master Result Table Columns (12 Kolom)**:
   - Tabel **Material Master Result** pada [index4.htm](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/index4/index4.htm) kini menampilkan 12 kolom lengkap:
     1. `No`
     2. `Kode Material` (`MATNR`)
     3. `Description` (`MAKTX`)
     4. `Plant` (`MARC-WERKS`)
     5. `MRP Group` (`MARC-DISGR`)
     6. `MRP Ctrl` (`MARC-DISPO`)
     7. `SLoc 1` (`MARC-LGPRO`)
     8. `SLoc 2` (`MARC-LGFSB`)
     9. `Material Type` (`MARA-MTART`)
     10. `Material Group` (`MARA-MATKL`)
     11. `UoM` (`MARA-MEINS`)
     12. `Action` (`Use as Ref`)
   - `renderMaraResults()` dan `useMaraIndex()` dipetakan untuk merender dan mentransfer seluruh 12 kolom (termasuk `dispo` / MRP Controller) ke tabel staging.

---

## 11. Excel Mapping & Transformation (`Use.xlsx` &rarr; `Template Bom.xlsx`)
1. **Analisis File Excel**:
   - **Source Input**: `Use.xlsx` (Col 0: No, Col 1: Code Number, Col 2: SAP Matnr, Col 3: Finish Size, Col 4: Part Name, Col 20: Description, Col 21: MRP Group, Col 22: MRP Ctrl, Col 23: SLoc 1, Col 24: SLoc 2, Col 25: Plant, Col 26: M3, Col 27: M2, Col 35: Material Type, Col 36: Material Group).
   - **Target Output Structure**: `Template Bom.xlsx`.
2. **Transformasi Field Khusus (`Finish Size` &rarr; `Dimension`)**:
   - Kolom `FINISH SIZE` pada `Use.xlsx` (Col 3, e.g. `'19X320X2434'`) diubah nama/di-mapping ke field **`Dimension`** pada tabel staging [index4.htm](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/index4/index4.htm) dan template output.
3. **Mekanisme Dynamic SAP MARC Lookup Fallback**:
   - Jika field `MRP Group`, `MRP Controller`, `SLoc 1`, atau `SLoc 2` ada pada Excel (seperti pada `Use.xlsx`), sistem menggunakan data dari Excel.
   - Jika field tersebut kosong (seperti pada `Template 2.xlsx`), fungsi `checkAndLookupMissingSapData()` secara otomatis melakukan AJAX query ke SAP MARC (`SEARCH_MARA`) untuk mengambil `MARC-DISGR`, `MARC-DISPO`, `MARC-LGPRO`, `MARC-LGFSB`, `MARC-WERKS`.
   - **Bebas Value Hardcoded**: Tidak ada pengisian preset otomatis. Jika tidak ditemukan di SAP, field tetap bernilai kosong (`-` / `""`) dan informasi debug dicatat di console log.

---

## 12. Data Steward Staging Format (`part_stagging2.htm` &rarr; `MAIN TEMPLATE.xlsx`)
1. **Prinsip Alur Data**:
   `Use.xlsx` (Upload User di `index4.htm`) &rarr; Parsing & Validasi &rarr; Staging & Transformasi Data &rarr; `part_stagging2.htm` (Data Steward Review mengikuti `MAIN TEMPLATE.xlsx`) &rarr; Approval / Lock Data &rarr; Integrasi SAP (`MAIN TEMPLATE.xlsx` format 139 Kolom).
2. **Alignment Header & Field Staging**:
   - `FINISH SIZE (MM)` &rarr; **`DIMENSIONS (MM)`**
   - `Description` &rarr; `Material Description`
   - `SLOC 1` &rarr; `Production Storage Location`
   - `SLOC 2` &rarr; `Storage Location for EP`
   - `Satuan` &rarr; `Base Unit of Measure`
3. **Export Engine `MAIN TEMPLATE.xlsx`**:
   - Fungsi `exportSapMainTemplate()` di [part_stagging2.htm](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/part_stagging2/part_stagging2.htm) memungkinkan Data Steward mengunduh file hasil staging langsung dalam struktur 139 kolom `MAIN TEMPLATE.xlsx` yang siap di-upload ke SAP.

---
## 13. Auto-Generation Logic Finish Size & Code Material (`index4.htm`) & Dynamic Header Mapper
1. **Penggabungan Dimensi Finish**:
   - Kolom `Finish Size` dan `Code Material` di-generate secara otomatis dengan menggabungkan ketiga dimensi Finish: `Thickness (T)`, `Width (W)`, dan `Length (L)` menggunakan format separator `x` (kecil).
   - **Contoh**: `T = 19`, `W = 320`, `L = 2434` &rarr; `Finish Size` & `Code Material` = `19x320x2434`.
2. **Dynamic UI Listener (`oninput`)**:
   - Pada [index4.htm](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/index4/index4.htm), fungsi `updateFinishSizeAndMatnr(input)` memantau pengisian input `row-ft`, `row-fw`, dan `row-fl`. Saat pengguna mengetik dimensi finish, field `Finish Size` (`row-groes-fin-str`) dan `Code Material` (`row-matnr`) terupdate secara real-time.
3. **Dynamic Template Header Mapper & High Flexibility**:
   - Menambahkan deteksi otomatis kolom Excel (`colMap`) pada `parseStandardExcelRD()` di `index4.htm`.
   - Jika pengguna mengunggah template Excel `Use.xlsx` baru di mana kolom `CODE MATERIAL SAP` dan `FINISH SIZE` (teks string) telah dihapus/digeser, sistem secara dinamis mendeteksi offset posisi kolom (`Part Name` di index 2, Finish T/W/L di index 10/11/12) sehingga tidak terjadi `ReferenceError: partNameVal is not defined`.
   - Mengisi seluruh variabel baris dengan safe getter `getCellStr()` sehingga sistem fleksibel terhadap format Excel baru maupun lama.

---

## 14. Excel Table Preview & Dual View Mode (`part_stagging2.htm`)
1. **100% Identical Excel SAP Structure with `MAIN TEMPLATE.xlsx` (139 Kolom)**:
   - Tampilan preview default pada [part_stagging2.htm](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/part_stagging2/part_stagging2.htm) kini mengadopsi 100% struktur **139 Kolom SAP Excel Template** persis seperti header dan format isian pada [BOM/EXCEL/MAIN TEMPLATE.xlsx](file:///d:/DANIEL/ANTIGRAVITY/PROJEK/BOM/EXCEL/MAIN%20TEMPLATE.xlsx).
   - Seluruh header (Material, Industry Sector, Old Material Number, Material Type, Material Group, Base Unit of Measure, Material Description, Division, Dimensions, Plant, Storage Location, Profit Center, Valuation Class, MRP Type, MRP Group, MRP Controller, Lot Sizing, Procurement Type, Storage Location for EP, QM Control Key, Inspection Types, dll) dan format 139 kolom + Pos ditampilkan dengan container scroll 2D (`overflow-x-auto max-h-[500px]`) dan sticky headers (`sticky top-0 bg-slate-100/95 z-10 backdrop-blur-xs`).
2. **View Mode Switcher (Mode Toggle)**:
   - **📊 Excel SAP Template (MAIN TEMPLATE.xlsx)**: Mode default yang menampilkan preview 139 kolom SAP persis seperti file Excel template utama.
   - **🧩 BOM Staging Detail (34 Kolom)**: Mode alternatif yang menampilkan breakdown detail ZBOM staging (termasuk 6 sub-kolom Rough Size T1..L2, Qty Item/Ord, M3, Finishing, dll).
3. **Behavior Preview & Auto-Scroll**:
   - **Empty Placeholder**: Saat data staging kosong, menampilkan SVG empty state card dengan pesan informatif.
   - **Line Counter Badge**: Menampilkan jumlah baris aktif (`#stagingCounterChip`).
   - **Auto-Scroll Behavior**: Setelah user menekan Submit / Review / Bind (`loadUploadDetail`, `generateAndBindMaterialCode`), sistem secara otomatis menjalankan smooth scroll ke `#stagingTableSection` agar preview data Excel langsung terlihat oleh pengguna.
3. **Data Integrity & Column Preservation**:
   - Menampilkan seluruh 34+ kolom staging termasuk Rough Size (6 sub-kolom T1..L2), Dimensions (3 sub-kolom T, W, L), MRP Group, MRP Controller, SLoc 1, SLoc 2, Plant, UoM, Material Type, Material Group, dll.
   - Handling nilai kosong/null dengan fallback `-` agar layout tabel tidak rusak saat kolom Excel berjumlah sangat banyak.

---

## 15. Next Steps / Rencana Selanjutnya
- Lakukan testing fungsionalitas end-to-end pada environment SAP BSP (upload Excel `Use.xlsx`, validation parsing, MARA search & reference lookup, simpan draft, submit request, Data Steward review di `part_stagging2.htm`, generate material code, export `MAIN TEMPLATE.xlsx`, dan lock & approve ke SAP).

---

## 16. Catatan Penting & Lessons Learned (Technical Rules)
1. **Open SQL Positional Mapping**: Saat menggunakan `SELECT ... INTO TABLE @lt_itab` tanpa `CORRESPONDING FIELDS`, urutan komponen pada `TYPES` / `DATA` internal table **HARUS 100% SAMA** dengan urutan ekspresi di `SELECT`. Selalu utamakan `INTO CORRESPONDING FIELDS OF TABLE`.
2. **SE80 HTML Baris Maximum 255 Karakter**: Perhatikan panjang baris HTML/CSS Tailwind pada file `.htm` agar tidak terpotong saat di-save di editor SAP SE80.
3. **Strict Function & Field Isolation**: Menyesuaikan tampilan/UI/UX tidak boleh mengubah name/class selector yang terikat dengan pemrosesan `request->get_form_field()` di ABAP backend.
4. **Excel as Single Source of Truth**: Sistem tidak boleh mengarang atau mengisi nilai preset otomatis secara implisit. Semua data berasal dari Excel upload atau input eksplisit pengguna.
5. **SAP MARC Multi-Plant Lookup**: Pengambilan data Plant & MRP harus mengambil data langsung dari `MARC` melalui `LEFT OUTER JOIN`, mengizinkan material tanpa plant tetap tampil (plant kosong `-`) dan material dengan multi-plant tampil dalam baris kombinasi yang lengkap.
6. **Finish Size & Code Material Auto-Generation**: Dimensi `ft`, `fw`, `fl` secara otomatis digabungkan dengan format `TxWxL` (e.g. `19x320x2434`) untuk mengisi kolom `Finish Size` dan `Code Material` jika belum ada nomor SAP khusus.
7. **Dynamic Excel Header Detection**: Selalu gunakan header scan/position mapping dinamis saat membaca file Excel agar aplikasi fleksibel terhadap penghapusan atau pergeseran kolom oleh pengguna.
8. **Excel Preview UX Standard**: Tabel preview data Excel pada staging/review harus menyertakan vertical & horizontal scroll, sticky header, count chip, empty state placeholder, dan smooth scroll ke section preview setelah submit.

---

## 17. Database Architecture: Separation of Header & Detail (`ZBOM_STG_HDR` & `ZBOM_STG_PART`)
1. **Normalization & Data Cleanliness**:
   - Seluruh histori upload, status approval (`DRAFT`, `SUBMITTED`, `CODE_BOUND`, `READY_SAP`, `REJECTED`), uploader/approver ID (`ERNAM`, `APPROVED_BY`), timestamp (`ERDAT`, `ERTIM`, `APPROVED_AT`), dan alasan penolakan (`REJECT_REASON`, `SUB_REASON`) dipisahkan ke tabel **`ZBOM_STG_HDR`**.
   - Tabel **`ZBOM_STG_PART`** difokuskan murni untuk menyimpan data line items BOM Part (`POSNR`, `CODE_NUM`, `MATNR`, `MAKTX`, `GROES`, `GROES_FIN`, `MENGE`, `WERKS`, `DISGR`, `DISPO`, `LGORT1`, `LGORT2`, `WRKST`, `NOTE`, `FINISHING`, dll.).
2. **Transaction Identifier (`UPLOAD_CODE`)**:
   - 1 File Excel Upload = 1 `UPLOAD_CODE` unik di `ZBOM_STG_HDR` (PK) yang terhubung dengan N baris item BOM di `ZBOM_STG_PART` (PK: `MANDT` + `UPLOAD_CODE` + `POSNR`, FK: `UPLOAD_CODE`).
   - Eliminasi duplikasi data histori di setiap baris item BOM.