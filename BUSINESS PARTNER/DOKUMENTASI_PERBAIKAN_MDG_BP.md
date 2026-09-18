# Dokumentasi Perbaikan & Rekapitulasi Pengembangan BSP MDG Business Partner

---

## 📋 Ringkasan Eksekutif

Dokumen ini berisi rekapitulasi lengkap perbaikan bug, penyempurnaan UI/UX, penambahan animasi & modal popup, serta analisis mendalam mengenai penanganan **BP Role SAP** pada aplikasi **Business Server Page (BSP) Master Data Governance (MDG) Business Partner** (`bp_create_customer.htm` dan `bp_create_vendor.htm`).

---

## 1. 🚨 Perbaikan Error BSP 403 Forbidden

### **Permasalahan**
Saat pengguna menekan tombol **Submit**, muncul error dari sistem SAP:
> **BSP exception:** *Access to URL /sap(bD1lbiZjPTMwMA==)/bc/bsp/sap/zmdg_request/test_bp_create_request.htm is forbidden*

### **Penyebab Utama**
Target URL pada atribut form (`<form action="...">`) dan fungsi JavaScript `resetForm()` mengarah ke file `test_bp_create_request.htm` yang tidak terdaftar/tidak diizinkan di Transaction `SICF` / `SE80` SAP.

### **Solusi & Penanganan**
Tujuan submission disesuaikan dengan nama halaman BSP resmi yang terdaftar di SAP:
- **Customer Form:** Mengarah ke `test_bp_create_customer.htm`
- **Vendor Form:** Mengarah ke `test_bp_create_vendor.htm`

```html
<!-- SEBELUM: -->
<form id="mdgBpForm" name="bpForm" method="post" action="test_bp_create_request.htm">

<!-- SESUDAH (Customer): -->
<form id="mdgBpForm" name="bpForm" method="post" action="test_bp_create_customer.htm">
```

---

## 2. 🎨 Animasi Loading Overlay & Pop-Up Modal Sukses

### **A. Loading Overlay (`#loadingModal`)**
- **Trigger:** Aktif secara otomatis begitu pengguna menekan tombol **Submit**.
- **Tampilan:** Full-screen backdrop transparan beranimasi (*glassmorphic effect*) dengan *glowing spinner ring* dan ikon `cloud_upload`.
- **Fungsi:** Memberikan konfirmasi visual instan bahwa data sedang dikirim dan diproses oleh server SAP Staging.

### **B. Pop-Up Modal Sukses (`#successResultModal`)**
- **Trigger:** Aktif otomatis setelah halaman selesai memuat ulang (*reload*) pasca pengiriman data.
- **Tampilan:** Pop-up dialog modern di tengah layar dengan badge ikon centang hijau besar (*check_circle*).
- **Rincian Informasi:**
  - Status: **Data Berhasil Di-upload!**
  - **Request ID** (Contoh: `BP18104254`)
  - **Nama Organisasi / Perusahaan**
  - Konfirmasi tersimpannya permohonan ke tabel staging `ZMDG_BP_REQ` dengan status `SUBMITTED`.

---

## 3. 🧹 Penyederhanaan UI & Eliminasi Istilah Teknis SAP

### **A. Pengaturan Business Partner Category**
- Field **Business Partner Category** disembunyikan sepenuhnya dari tampilan antarmuka form.
- Di dalam logika aplikasi & payload submit, nilai default ditetapkan secara otomatis ke **`2` (Organization)**:
  ```html
  <input type="hidden" name="bp_category" value="2">
  ```

### **B. Pembersihan Istilah Teknis (SAP Technical Jargon Purge)**
Seluruh label dan instruksi yang terlalu teknis dibersihkan dan diganti dengan istilah bisnis Indonesia yang profesional dan komunikatif:

| Istilah Teknis Asli SAP | Istilah Baru yang Dipakai |
| :--- | :--- |
| `Nama Badan Usaha (Legal Entity)` | **Nama Badan Usaha** |
| `Title (Anrede)` | **Gelar / Title** |
| `Name 2 (NAME_ORG2)` | **Nama Tambahan** |
| `Search Term 1 (BU_SORT1)` | **Kata Kunci Pencarian** |
| `Alamat Standar Perusahaan (Standard Address)` | **Alamat Perusahaan** |
| `Street (Nama Jalan Kantor/Pabrik)` | **Alamat** |
| `House Number` | **Nomor Bangunan** |
| `Postal Code (POST_CODE1)` | **Kode Pos** |
| `City (CITY1)` | **Kota** |
| `Country (COUNTRY)` | **Negara** |
| `Region / Province` | **Provinsi / Wilayah** |
| `Language Key (LANGU)` | **Bahasa Komunikasi** |
| `Telephone (Telepon Kantor / PIC)` | **Nomor Telepon** |
| `Bank Country (Ctry)` | **Negara Bank** |
| `Legal Entity` | **Entitas Hukum** |

> *Sub-deskripsi seperti "Validasi mandatori guna mencegah error sistem SAP BAPI / BUT000" telah dihapus total.*

### **C. Penyesuaian Judul Section**
- **Section 01:** Diubah menjadi **`BP ROLE`** (sub-deskripsi dihapus).
- **Section 02:** Diubah menjadi **`Data Business Partner`**.

---

## 4. 📄 Pagination Histori & Popup Read-Only "View Detail"

### **A. Pagination Responsive (Maksimal 10 Baris)**
- Tabel **Histori Pengajuan & Persetujuan** memuat maksimal 10 baris per halaman.
- Dilengkapi tombol navigasi: **Previous**, **Nomor Halaman** (1, 2, dst.), dan **Next**.

### **B. Modal Read-Only "View Detail"**
- Tombol aksi di ubah dari *Edit* menjadi **`View Detail`**.
- Membuka modal popup read-only (`#viewDetailModal`) yang menampilkan seluruh atribut permohonan secara rinci berdasarkan data aktual record yang dipilih.

---

## 5. 🔍 Analisis BP Role SAP (`FLCU00`, `FLCU01`, `FLVN00`, `FLVN01`)

### **A. Gejala Terjadi Truncation `FLCU00`**
Saat form dikirim dengan opsi gabungan `"FLCU00,FLCU01"` (13 karakter), database tercatat sebagai **`FLCU00`**.

### **B. Penyebab Utama**
Di Data Dictionary (DDIC) SAP, field `BP_ROLE` pada tabel `ZMDG_BP_REQ` bertipe data **`BU_PARTNERROLE`** (`CHAR` dengan panjang **maksimal 6 Karakter**). String 13 karakter dipotong (*truncated*) oleh ABAP menjadi 6 karakter pertama (`FLCU00`).

### **C. Konsep Standar SAP untuk Role Lengkap**
Dalam standar SAP (Transaction `BP` / BAPI):
- **`FLCU01` (SD Customer):** Merupakan **Role Utama Customer Lengkap** (Penjualan + Keuangan). Saat BP dibuat dengan role `FLCU01` dan diisi data *Company Code* (`BUKRS`) & *Reconciliation Account* (`AKONT`), SAP secara otomatis membuatkan role **`FLCU00` (FI)** dan **`FLCU01` (SD)** di tabel master SAP `BUT100`.
- **`FLCU00` (FI Customer):** Merupakan Role khusus Keuangan Saja (Finance/Accounting Only).

### **D. Konfigurasi Opsi Dropdown Terbaru**

#### **Formulir Customer (`bp_create_customer.htm`):**
```html
<select name="bp_role" id="bpRoleTypeSelect">
  <option value="FLCU01">FLCU01 - SD Customer (Lengkap: Penjualan & Keuangan)</option>
  <option value="FLCU00">FLCU00 - FI Customer (Keuangan Saja)</option>
</select>
```

#### **Formulir Vendor (`bp_create_vendor.htm`):**
```html
<select name="bp_role" id="bpRoleTypeSelect">
  <option value="FLVN01">FLVN01 - MM Supplier (Lengkap: Pembelian & Keuangan)</option>
  <option value="FLVN00">FLVN00 - FI Supplier (Keuangan Saja)</option>
</select>
```

---

## 🛠️ Ringkasan File yang Diperbarui

1. [bp_create_customer.htm](file:///d:/DANIEL/ANTIGRAVITY/MASTER%20DATA%20GOVERNANCE/BUSINESS%20PARTNER/bp_create_customer/bp_create_customer.htm) — Halaman BSP Pengajuan Customer
2. [bp_create_vendor.htm](file:///d:/DANIEL/ANTIGRAVITY/MASTER%20DATA%20GOVERNANCE/BUSINESS%20PARTNER/bp_create_vendor/bp_create_vendor.htm) — Halaman BSP Pengajuan Vendor

---
*Dokumen ini dibuat otomatis sebagai panduan teknis dan referensi pemeliharaan sistem MDG SAP.*
