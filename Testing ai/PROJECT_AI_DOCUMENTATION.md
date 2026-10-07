# Dokumentasi Proyek SAP MDG AI Assistant

Dokumen ini berisi penjelasan teknis, arsitektur, dan panduan penggunaan **SAP MDG AI Assistant** untuk PT Kayu Mebel Indonesia (KMI).

---

## 1. Ikhtisar Proyek (Project Overview)

**SAP MDG AI Assistant** adalah aplikasi AI Chatbot interaktif berbasis **SAP WAS BSP (Business Server Pages)** 
dan **Claude 3.5 Sonnet Engine**. Aplikasi ini dirancang khusus untuk membantu pengguna (user & approver) di PT Kayu Mebel Indonesia 
dalam mencari, memvalidasi, dan mengelola data Master Data Governance (MDG) pada sistem SAP S/4HANA (Material Master, BOM, Business Partner, 
Customer, Vendor, dan alur Workflow Approval).

---

## 2. Arsitektur Sistem (System Architecture)

Sistem terdiri dari 3 lapisan utama (*3-tier architecture*):

```
+-----------------------------------------------------------------------+
|                         FRONTEND (SAP BSP)                            |
|  File: test_ai.htm                                                    |
|  - UI/UX Apple HIG + Google Sans Typography                           |
|  - Real-time Output Token & Processing Time Tracker                   |
|  - Dynamic Contextual Loading Status Timer                            |
|  - Full Multi-turn Session History Modal                              |
+-----------------------------------+-----------------------------------+
                                    |
                                    v
+-----------------------------------+-----------------------------------+
|                        BACKEND (SAP ABAP)                             |
|  Files: OnInputProcessing.abap & OnInitialization.abap                |
|  Tabel Database: ZMDG_AI_CHAT_LOG (SE11)                             |
|  - Menyimpan Riwayat Percakapan (Session & Messages)                  |
|  - Event Handler: SAVE_CHAT_LOG, GET_SESSION_LIST, GET_SESSION_MESSAGES|
|  - Endpoint OData SAP: ZMDG_MATERIAL_SRV_MDG_SRV                      |
+-----------------------------------+-----------------------------------+
                                    |
                                    v
+-----------------------------------+-----------------------------------+
|                  MIDDLEWARE & AI ENGINE (Node.js)                     |
|  Directory: sap-ai-middleware/server.js                               |
|  - Express.js Proxy Server (http://localhost:3000/api/claude)        |
|  - Injeksi Konteks Data SAP OData & System Prompt MDG                 |
|  - Integrasi Anthropic Claude 3.5 Sonnet API                          |
+-----------------------------------------------------------------------+
```

---

## 3. Fitur Utama (Key Features)

1. **Pencarian & Tanya Jawab Kontekstual SAP MDG**
   - Mampu menjawab pertanyaan terkait status material (`MATNR`), deskripsi (`MAKTX`), jenis material (`MTART`), status approval workflow, maupun data Business Partner / Vendor.
   - Didukung oleh injeksi data *live* dari OData SAP S/4HANA.

2. **KONTINUITAS Percakapan Multi-turn (Session History)**
   - AI mengingat konteks percakapan sebelumnya dalam satu sesi (contoh: jika user bertanya tentang material `40002307` 
     lalu bertanya *"Kenapa statusnya masih Approval?"*, AI memahami materi yang dimaksud).

3. **Log & Riwayat Percakapan Tersimpan di SAP Database (`ZMDG_AI_CHAT_LOG`)**
   - Seluruh sesi percakapan disimpan secara permanen di database SAP SE11.
   - User dapat membuka kembali sesi riwayat kapan saja melalui modal *Riwayat Chat*.

4. **Monitoring Token & Processing Duration Aktual**
   - Menampilkan penggunaan output token riil dari API dan durasi pemrosesan dalam detik:
     `Output: 274 tokens • 2.4s`
   - Bebas dari angka dummy atau hardcoded.

5. **Status Pemrosesan Kontekstual & Progresif**
   - Indikator status loading berubah secara alami berdasarkan intent dan elapsed time:
     - *0–9s*: `Sedang mencari data di SAP...` / `Sedang memvalidasi data...`
     - *10–19s*: `Sedang memeriksa data MDG...`
     - *20–29s*: `Agent sedang mencari data, harap menunggu...`
     - *30–59s*: `Sedang memproses data SAP...`
     - *60s+*: `Proses membutuhkan sedikit waktu lebih lama...`

6. **Desain Antarmuka Apple HIG & Google Sans**
   - Layout bersih, minimalis, dan responsif dari layar Smartphone (390px) hingga Monitor Desktop (1920px).
   - Bebas dari horizontal scrollbar dan aman dari memory leak.

---

## 4. Struktur File & Modul

| Nama File / Folder | Lokasi | Fungsi Utama |
| :--- | :--- | :--- |
| `test_ai.htm` | `Testing ai/` | Halaman utama BSP Chatbot UI, HTML, CSS (Tailwind + Google Sans), & JS logic. |
| `oninputprocessing.abap` | `Testing ai/` | Logic ABAP untuk memproses event HTTP POST (save log & get history). |
| `oninitialization.abap` | `Testing ai/` | Logic ABAP saat halaman BSP pertama kali dimuat. |
| `server.js` | `Testing ai/sap-ai-middleware/` | Server Node.js Express yang menjembatani SAP BSP ke API Claude. |
| `.env` | `Testing ai/sap-ai-middleware/` | File konfigurasi environment (API Key & Port Server). |
| `ZMDG_AI_CHAT_LOG` | SAP SE11 Table | Tabel custom SAP untuk persistensi riwayat chat. |

---

## 5. Cara Menjalankan Aplikasi (How to Run)

1. **Jalankan Middleware Node.js**:
   ```bash
   cd "Testing ai/sap-ai-middleware"
   node server.js
   ```
   *Middleware akan berjalan di `http://localhost:3000/api/claude`.*

2. **Akses Halaman BSP di SAP**:
   Buka transaksi **SE80** atau browser dengan URL BSP SAP:
   `http://kmiprd.kmi.com:8001/sap/bc/bsp/sap/zmdg_ai_chat/test_ai.htm`

---

## 6. Standar Pengembangan (Compliance Standards)

- **Line Length Rule**: Seluruh kode (ABAP, HTML, JS) mematuhi batas maksimal 200 karakter per baris.
- **Regex Safety**: Bebas dari regex escape backslash (`/\\/g`) yang dilarang pada WAS BSP.
- **Zero Memory Leak**: Timer `setInterval` selalu dibersihkan secara aman saat request selesai atau error.
