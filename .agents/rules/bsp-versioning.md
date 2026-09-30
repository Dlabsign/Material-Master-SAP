# Versioning System & Directory Management

Manajemen kode dilakukan secara manual menggunakan sistem hierarki folder. AI Agent harus selalu bekerja pada *sub-version* yang tepat.

## 1. Struktur Hierarki
- **Major Version:** Representasi fase besar project (Contoh: `V08`, `V10`, `V11`).
- **Sub-version:** Folder iterasi fitur di dalam Major Version (Contoh: `v11_a`, `v11_b`, `v11_c`).

## 2. Aturan Navigasi & Modifikasi
- **Verifikasi Direktori:** SELALU periksa dan konfirmasi *sub-version* yang sedang aktif sebelum membaca atau mengubah file. Jangan gunakan folder versi lama (misal masih baca `V08` padahal project sudah di `V11`).
- **Jangan Naikkan Versi Sendiri:** DILARANG keras membuat folder Major Version (misal ke `V12`) atau sub-version baru (misal `v11_l`) tanpa instruksi eksplisit dari User. Selesaikan iterasi di dalam *sub-version* yang sedang ditugaskan.
- **Isolasi Fitur:** Jaga agar pengembangan fitur tetap diskrit. Jangan menggabungkan kode atau fitur dari *sub-version* yang berbeda (misal menggabungkan fitur `v11_j` ke `v11_k` secara diam-diam).
- **Scope Modifikasi:** Batasi perubahan UI/fitur HANYA pada role/dashboard yang sedang dikerjakan (misal: hanya role *Approver*). Jangan secara proaktif mengubah role lain sebelum role yang diuji sukses dan disetujui.