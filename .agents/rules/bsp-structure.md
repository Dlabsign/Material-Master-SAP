# SAP BSP Application Structure (KMI Standard)

Dalam pengembangan aplikasi SAP BSP, kita memecah komponen menjadi 4 file utama untuk setiap halaman (page). AI Agent WAJIB memahami peran masing-masing file ini dan tidak boleh mencampuradukkan logic-nya.

## 1. `type_defs.abap` (Type Definitions)
- **Fungsi:** Tempat mendefinisikan struktur data, tipe tabel (`TYPES`), dan konstanta.
- **Aturan:** Hanya berisi deklarasi. Tidak ada logic eksekusi di sini.

## 2. `on_init.abap` (Initialization / OnInit)
- **Fungsi:** Dijalankan SEBELUM halaman di-render. Tempat melakukan query data (`SELECT`), inisialisasi variabel, dan menyiapkan state UI.
- **Aturan:** 
  - Selalu `CLEAR` variabel global/internal table sebelum diisi, terutama di dalam `LOOP`.
  - Deklarasikan variabel form default di sini.

## 3. `event_handler.abap` (OnInputProcessing)
- **Fungsi:** Menangani aksi user (tombol click, form submit).
- **Aturan:**
  - Tangkap trigger dari HTML menggunakan hidden field (misal: `OnInputProcessing`).
  - **CRITICAL:** Selalu simpan nilai `sy-subrc` ke variabel lokal setelah operasi database (`SELECT`, `MODIFY`) SEBELUM melakukan operasi pada internal table (`DELETE`, `APPEND`). Operasi internal table akan me-reset/menimpa nilai `sy-subrc`.

## 4. `layout.htm` (HTML / UI)
- **Fungsi:** Tampilan antarmuka pengguna.
- **Aturan Ketat (SE80 Limitations):**
  - **Maksimal 255 Karakter:** Editor SE80 SAP memotong baris HTML yang lebih dari 255 karakter. Pecah string panjang atau HTML class ke dalam variabel ABAP.
  - **JavaScript:** DILARANG menggunakan ES6 (arrow functions, `let`, `const`). Gunakan JS lawas (`var`, `function`). Pop-up hanya boleh menggunakan `confirm()` atau `prompt()`.
  - **CSS:** Gunakan inline styling jika diperlukan.
  - **Encoding:** DILARANG menggunakan karakter Unicode/Emoji. Selalu gunakan ASCII.
  - **ABAP Tags:** Selalu perhatikan spasi pada tag ABAP `<% IF ... %>`.