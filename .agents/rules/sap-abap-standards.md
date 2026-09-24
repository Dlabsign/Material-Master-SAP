---
trigger: always_on
---

# Batasan-Batasan dalam Pengembangan SAP ABAP

Dokumen ini merangkum batasan teknis umum yang perlu diperhatikan saat mengembangkan program, laporan, BSP, maupun workflow di SAP (khususnya S/4HANA On-Premise).

## 1. Format Penulisan (Naming Convention)

- Objek custom **wajib** menggunakan prefix `Z` atau `Y` (contoh: `ZBSP_MDG_MAT`, `ZMIR_APP`).
- Nama program, class, function module tidak boleh mengandung spasi atau karakter spesial selain underscore (`_`).
- Nama variabel sebaiknya deskriptif, hindari singkatan ambigu (`lv_x` → `lv_material_id`).
- Konsisten menggunakan Hungarian notation jika mengikuti standar perusahaan (`lv_` untuk local variable, `lt_` untuk internal table, `ls_` untuk structure, `wa_` untuk work area, `it_`/`et_` untuk parameter tabel).

## 2. Batasan Panjang Baris & Karakter (Line Length Limit)

- **Batas Maksimal 255 Karakter per Baris:** Editor SAP (termasuk editor halaman BSP pada SE80/WebDAV/ADT) memiliki batas keras panjang baris maksimal 255 karakter. Teks yang melebihi batas ini akan dipotong paksa dan dipindah ke baris baru oleh sistem.
- **Larangan String Panjang Satu Baris:** Dilarang menulis string literal panjang dalam satu baris tanpa pemecahan (misalnya penulisan utility class Tailwind CSS yang panjang pada JavaScript atau atribut HTML).
- **Aturan Pemecahan Baris (Wrapping):**
  - **JavaScript / BSP:** Jika string melebihi batas wajar atau berisi daftar class styling yang panjang, wajib dipecah menggunakan penggabungan string (`+`), template literal (backtick), atau array `.join(' ')`.
  - **ABAP:** Gunakan string template `|...|` atau operator penggabungan string modern `&&` untuk teks panjang.
  - **HTML:** Format atribut tag HTML menjadi multi-baris agar tidak melampaui lebar baris editor.
- **Batas Aman Agent:** Saat menghasilkan kode (baik ABAP, JavaScript, CSS, maupun HTML), usahakan panjang baris berada di kisaran 80–120 karakter dan jangan pernah melebihi 200 karakter.

## 3. Sintaks

- Hindari penggunaan `SELECT *` — selalu tentukan field yang dibutuhkan.
- Dilarang melakukan `SELECT` di dalam `LOOP` (nested SELECT) — gunakan `FOR ALL ENTRIES` atau JOIN.
- Hindari statement obsolete seperti `MOVE`, `REFRESH`, `COMPUTE` — gunakan sintaks ABAP modern (`DATA()`, inline declaration, `VALUE #( )`).
- Tidak boleh ada `EXIT`/`STOP` yang menyebabkan proses berhenti tanpa penanganan error yang jelas.
- Hindari HARD CODE nilai konfigurasi (client, plant, company code) — gunakan tabel konfigurasi/Z-table atau parameter.

## 4. Struktur & Modularisasi

- Logika bisnis kompleks tidak boleh ditulis langsung di event `START-OF-SELECTION` — pisahkan ke FORM/METHOD/Class.
- Setiap FORM/METHOD idealnya tidak lebih dari ±60–80 baris; jika lebih, pecah menjadi sub-routine.
- Dilarang membuat "God Object" (satu class/program menangani terlalu banyak tanggung jawab).

## 5. Performa

- Dilarang melakukan pemrosesan data besar tanpa `WHERE` clause yang efisien (index-friendly).
- Hindari `ORDER BY` di database jika bisa dilakukan di internal table (`SORT`).
- Internal table besar wajib menggunakan tipe `HASHED` atau `SORTED` jika sering diakses dengan key tertentu, bukan `STANDARD`.
- Dilarang memuat seluruh data tanpa filter ke memory (gunakan `PACKAGE SIZE` untuk data besar).

## 6. Database & Data Dictionary

- Tidak boleh mengubah struktur tabel standar SAP (harus buat tabel Z terpisah, gunakan Append/Include jika perlu).
- Setiap tabel Z wajib memiliki minimal 1 primary key dan technical setting yang sesuai (delivery class, data class).
- Perubahan struktur tabel yang sudah dipakai di production harus melalui proses transport & testing berjenjang (DEV → QAS → PRD).

## 7. Autorisasi & Keamanan

- Dilarang bypass authorization check (`AUTHORITY-CHECK`) pada transaksi/report yang mengakses data sensitif (finance, HR, data pribadi).
- Password/credential tidak boleh di-hardcode di source code.
- Akses ke RFC/BAPI eksternal harus melalui user teknikal dengan role terbatas, bukan user dialog.

## 8. Transport & Deployment

- Objek development wajib dimasukkan ke transport request dengan deskripsi jelas, tidak boleh "local object" (`$TMP`) untuk kebutuhan production.
- Dilarang melakukan release transport langsung ke Production tanpa melalui testing di QAS.
- Satu transport request idealnya fokus pada satu perubahan/fitur, hindari mencampur banyak perubahan tidak terkait.

## 9. UI/BSP Spesifik

- Elemen form BSP wajib memiliki ID unik dan konsisten dengan penamaan field backend.
- Validasi input wajib dilakukan di sisi server (server-side), tidak cukup hanya client-side (JavaScript).
- Session data sensitif tidak boleh disimpan di client-side (cookie/local storage) tanpa enkripsi.
- Kelas styling frontend (seperti Tailwind CSS) pada elemen atau manipulasi DOM JavaScript wajib diatur per baris agar tidak melanggar batas 255 karakter editor BSP.
- **Dilarang Menggunakan Regex Escape Backslash (`/\\/g`) di JavaScript BSP:** Editor/compiler SAP WAS BSP akan mengurai dan menghapus karakter escape backslash (`\`) pada blok JavaScript sebelum disajikan ke browser. Penulisan `replace(/\\/g, "/")` akan berubah menjadi `replace(/\/g, "/")` di browser yang menimbulkan `Uncaught SyntaxError: missing ) after argument list`. Selalu gunakan `split(String.fromCharCode(92)).join("/")` untuk mengganti karakter backslash secara aman.
- **Struktur Tag Script dan Elemen HTML/Modal:** Wajib menutup tag `<script>` dengan `</script>` secara lengkap sebelum menyisipkan markup HTML (seperti modal `<div id="...">`). Menaruh elemen HTML langsung di dalam tag `<script>` atau lupa menutup tag `<script>` akan mengakibatkan `Uncaught SyntaxError: Unexpected token '<'`.

## 10. Dokumentasi

- Setiap program/class wajib memiliki header comment (deskripsi, author, tanggal, tujuan).
- Perubahan signifikan pada objek existing wajib dicatat di changelog/comment, bukan langsung menghapus kode lama tanpa jejak.

## 11. Gaya Bahasa & Presentasi

- Gunakan pilihan kalimat yang profesional dan formal dalam komentar, dokumentasi, maupun pesan error/notifikasi ke user (hindari bahasa gaul, singkatan tidak baku, atau nada bercanda).
- Dilarang menggunakan ikon/emoji berlebihan (✅❌🔥🚀🎉 dsb.) pada komentar kode, log, dokumentasi, maupun pesan pada UI/BSP — cukup gunakan teks yang jelas dan lugas.
- Pesan error/konfirmasi ke user harus informatif dan sopan, tanpa berlebihan (misalnya hindari "Berhasil!! 🎉🎉" cukup "Data berhasil disimpan.").
- Penamaan status, label tombol, dan judul section pada BSP sebaiknya singkat, formal, dan konsisten (contoh: "Simpan", "Batal", "Ajukan Persetujuan" — bukan "Yuk Simpan!" atau "Simpan Yaa~").

---

*Catatan: batasan di atas bersifat panduan umum best practice ABAP development. Beberapa poin (seperti panjang karakter) bisa sedikit berbeda tergantung versi SAP dan kebijakan internal perusahaan.*