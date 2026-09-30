# SAP BSP (KMI Specific) - Lessons Learned & Common Errors

Dokumen ini berisi kumpulan "jebakan" teknis, aturan *business logic* spesifik KMI, dan *error* yang sering terjadi selama pengembangan. AI WAJIB membaca ini sebelum menulis logic untuk menghindari bug yang berulang.

## 1. Database & Table Quirks
- **ZECM_LOG:** Field untuk mencatat log adalah `user_id`, `action_date`, `action_time`, dan `reason`. **JANGAN** menggunakan field standar seperti `created_by` atau `created_at`.
- **Tabel Routing:** Jangan mencari tabel `ZECM_IROUTING` karena tabel itu TIDAK ADA. Data routing disimpan di tabel `ZECM_REQ` dengan filter `change_scope = 'ROUT'`.
- **Flag IREQ vs ECR:** Gunakan field boolean `IS_IREQ`. Nilai `'X'` berarti IREQ, sedangkan kosong/spasi `''` berarti ECR.
- **NUMC Fields:** Selalu gunakan function module conversion `ALPHA_INPUT` saat berurusan dengan field bertipe `NUMC`.

## 2. ABAP Logic Pitfalls (CRITICAL)
- **The `sy-subrc` Trap:** Operasi *internal table* seperti `DELETE` atau `APPEND` akan me-reset nilai `sy-subrc`. Jika kamu melakukan `SELECT` dan perlu mengecek `sy-subrc`-nya setelah memproses tabel, **SELALU** simpan hasil `sy-subrc` dari database ke variabel lokal terlebih dahulu. 
  *(Contoh: `lv_subrc = sy-subrc.` lalu lakukan operasi internal table, lalu baru cek `IF lv_subrc = 0.`)*
- **BAPI_REQUISITION_DELETE:** Saat menghapus Purchase Requisition (PR), BAPI ini akan **gagal/error** jika Purchase Orders (POs) yang terkait belum di-*unlink* (dilepas) terlebih dahulu.

## 3. UI, Frontend, & SE80 Quirks
- **SE80 HTML Truncation:** Ingat batas 255 karakter! Jika baris HTML (terutama class CSS yang panjang) melebihi batas ini, SE80 akan memotong string tersebut secara tiba-tiba dan merusak *layout*. **Solusi:** Simpan string panjang ke dalam variabel ABAP di `OnInit` dan panggil menggunakan `<%= lv_class %>` di layout.
- **State Management (Tabs):** Karena BSP sering me-reload halaman (*server-side render*), **SELALU** simpan dan lempar *state* tab aktif melalui parameter URL, agar user tidak kembali ke tab pertama setiap kali melakukan aksi.
- **Audit Log/History:** Menampilkan audit log jangan memaksakan UI yang terlalu kompleks di halaman yang sama. Gunakan *redirect* ke halaman khusus atau popup modal sederhana.

## 4. Business Flow & Roles (ECM / IREQ)
- **Hak Akses Approval:** Approval IREQ dilakukan oleh **Kepala R&D (APPROVER)**, BUKAN oleh Admin.
- **Read-Only Fields:** Pada status tertentu (seperti `APPR` atau `INWK`), field **Material** harus dikunci menjadi *read-only*.
- **Hard Delete:** Penghapusan permanen (Hard Delete) untuk IREQ HANYA diperbolehkan jika status dokumen masih `'REQ'`.
- **Dashboard Layout:** Untuk dashboard (terutama V10+), biasakan untuk membagi tabel antrean menjadi dua bagian utama: **Antrian** (Pending Actions) dan **Riwayat** (History/Completed).

## 5. File Management (Attachments)
- **Upload Path:** Semua file yang di-upload oleh user (seperti file ECR/IREQ) harus diarahkan dan disimpan ke path direktori: `/mnt/sap_media/ecm_files/`.