# BSP Development Workflow & Rules

Sebagai AI Agent, patuhi pola kerja ini saat mengembangkan atau memodifikasi SAP BSP:

## 1. RANCANG DULU (Design First)
- Jangan langsung menulis kode. Pahami *requirements*, cek struktur file yang ada, dan buat rancangan logic-nya. 
- Analisis *impact* perubahan pada ke-4 file BSP (type_defs, oninit, event_handler, layout).

## 2. ABAP Syntax & Environment Quirks
- **Old Syntax Only:** Gunakan sintaks ABAP klasik. Jangan gunakan fitur modern ABAP (seperti inline declarations `@DATA(...)`, `REDUCE`, `FILTER`, dsb) karena environment tidak mendukung.
- **UI/UX Standard:** 
  - Gunakan tabel model *accordion* (hidden-collapse) dengan tombol *quick-action* di dalamnya.
  - Pemisah menggunakan border tebal (contoh class: `border-b-4`).
  - Untuk filter, gunakan *horizontal inline pills/buttons*, BUKAN dropdown.
  - Untuk audit log/history, gunakan *redirect* ke halaman baru atau modal.
- **File Editing (Untuk AI yang pakai Terminal):** DILARANG Keras menggunakan `sed` atau operasi bash string replacement untuk file ABAP. Tanda kutip tunggal (`'`) pada ABAP akan merusak bash escaping. Selalu gunakan *native patch tool* atau rewrite utuh.

## 3. Debugging & Error Recovery
- **Holistic Check:** Jika terjadi error UI atau logic, cek KEEMPAT file (HTML, OnInit, EventHandler, TypeDefs). Jangan hanya menebak dari satu file.
- **No Hallucination Recovery:** Jika sebuah file korup (terpotong) saat proses *patching/editing*, JANGAN mencoba mereka-reka ulang isi file dari ingatan. Langsung buang file yang rusak, ambil file utuh dari *sub-version* sebelumnya (clean base), dan edit ulang.
- **Cleanup:** Jangan pernah meninggalkan file `.bak` atau *temporary files* di dalam direktori kerja server.