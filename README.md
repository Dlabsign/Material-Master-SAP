# SAP Master Data Governance (MDG) Staging Platform

![SAP MDG](https://img.shields.io/badge/SAP-MDG--M%20%7C%20MDG--BP-00897B?style=for-the-badge&logo=sap&logoColor=white)
![ABAP BSP](https://img.shields.io/badge/Tech-ABAP%20BSP-0052CC?style=for-the-badge)
![UI Design](https://img.shields.io/badge/UI-Emerald%20Glassmorphism-10B981?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)

Platform berbasis **SAP BSP (Business Server Pages)** untuk mengelola **SAP Master Data Governance (MDG)** yang mencakup pembuatan, pencarian, validasi, dan alur persetujuan bertingkat (multi-level approval workflow) untuk **Material Master (MDG-M)** dan **Business Partner (MDG-BP)**.

---

## 🌟 Fitur Utama

### 📦 1. Material Master (MDG-M)
* **Search & Reference MARA:** Pencarian data acuan `MARA`, `MAKT`, `MARC`, `MBEW` dengan dukungan parameter wildcard dan *alpha conversion*.
* **BOM Staging Platform:** Penyiapan spesifikasi kayu/furniture dan *Bill of Materials* (BOM) multi-level secara dinamis.
* **Workflow Approval:** Alur pengajuan (*Request*), persetujuan (*Approval*), penolakan (*Reject*), serta pembaharuan (*Update*) oleh Data Steward.
* **Desain Modern:** Mengusung antarmuka *Emerald Glassmorphism* yang responsif dan interaktif.

### 👤 2. Business Partner (MDG-BP)
* **Customer & Vendor Creation:** Form pengajuan pembuatan Customer dan Vendor baru lengkap dengan penanganan atribut dan *type definitions*.
* **Bank Steward & Data Steward Portal:** Pengelolaan data rekening bank (*Bank Steward*) serta validasi data induk perusahaan.
* **Kamus Data SE11:** Struktur tabel kustom `ZTB_BP_REQ` untuk penampungan sementara (*staging table*) sebelum diajukan ke tabel standar SAP `BUT000`.

---

## 📂 Struktur Direktori

```text
MASTER DATA GOVERNANCE/
├── MATERIAL MASTER/            # Modul Staging & Approval Material Master (MDG-M)
│   ├── Approval/               # Interface Halaman Approval / History Approved
│   ├── Request/                # Form pengajuan pembuatan & perubahan Material
│   ├── datasteward/            # Portal pengelolaan data oleh Data Steward
│   ├── landing/ & sidebar/     # Komponen navigasi dan landing page BSP
│   ├── Design.md               # Spesifikasi UI/UX & sistem desain
│   └── PRODUCT.md              # Dokumentasi kapabilitas & arsitektur produk
│
├── BUSINESS PARTNER/           # Modul Staging & Handling Business Partner (MDG-BP)
│   ├── bp_create_customer/     # Form BSP & handler ABAP untuk Customer
│   ├── bp_create_vendor/       # Form BSP & handler ABAP untuk Vendor
│   ├── bp_banksteward/         # Modul persetujuan/validasi Bank
│   ├── bp_datasteward/         # Modul Data Steward Business Partner
│   ├── Design.md               # Dokumentasi UI/UX Business Partner
│   └── ZTB_BP_REQ_SE11...xlsx # Kamus data & definisi struktur tabel SE11
│
├── DATABASE/                   # Template Excel untuk pengajuan Request
│   ├── REQUEST CREATE MATERIAL.xlsx
│   └── REQUEST CHANGE MATERIAL.xlsx
│
└── MODUL MDG/                  # Panduan, dokumentasi teknis & pemetaan tabel SAP
    ├── SAP tables mapping.pptx
    ├── SAP-MDG-rule-based-workflow.pdf
    └── Master Data Governance for Materials.pdf
```

---

## ⚙️ Ketentuan Teknis & Arsitektur (SAP SE80)

Proyek ini dibangun mengikuti batasan ketat lingkungan **SAP BSP SE80 Runtime**:

1. **JavaScript Engine:** Wajib menggunakan **Vanilla ES5** (`var`, `function()`, tanpa sintaks ES6 seperti `let`, `const`, atau *arrow function*).
2. **Batas Panjang Baris:** Maksimal 255 karakter per baris pada file `.htm` dan JavaScript agar sesuai batas kompilasi SAP SE80.
3. **Integrasi ABAP BSP:** Penggunaan tag `<% IF ... %>`, `<% DATA ... %>`, serta event handler `OnInitialization.abap` dan `OnInputProcessing.abap`.
4. **State Management DB Defensive:** Selalu melakukan pengecekan `sy-subrc` secara eksplisit setelah eksekusi query database sebelum melakukan manipulasi internal table.

---

## 📑 Pemetaan Tabel SAP (Mapping Reference)

| Modul | Nama Tabel SAP | Keterangan |
| :--- | :--- | :--- |
| **Material Master** | `MARA` | General Material Data |
| | `MAKT` | Material Descriptions |
| | `MARC` | Plant Data for Material |
| | `MBEW` | Material Valuation |
| **Business Partner** | `BUT000` | BP General Data (Header) |
| | `BUT020` | BP Addresses |
| | `LFA1` | Vendor Master (General Detail) |
| | `KNA1` | Customer Master (General Detail) |
| | `ZTB_BP_REQ` | Custom Staging Table for MDG Request |

---

## 📄 Lisensi

Copyright © 2026 - Master Data Governance Staging Platform. All Rights Reserved.
