require('dotenv').config();
const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;
const CLAUDE_KEY = process.env.ANTHROPIC_API_KEY;

app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '10mb' }));

app.get('/', (req, res) => {
  res.send('SAP MDG AI Middleware is running');
});

let cachedMaterials = [];

app.get('/api/odata', async (req, res) => {
  try {
    const odataUrl = 'http://kmiprd.kmi.com:8001/sap/opu/odata/sap/' +
      'ZMDG_MATERIAL_SRV_MDG_SRV/MaterialSet?$format=json';
    const authHeader = req.headers['authorization'];
    const headers = { 'Accept': 'application/json' };
    if (authHeader) headers['Authorization'] = authHeader;

    const response = await axios.get(odataUrl, { headers, timeout: 15000 });
    if (response.data && response.data.d && response.data.d.results) {
      cachedMaterials = response.data.d.results;
      console.log('[Middleware Cache Updated]:', cachedMaterials.length, 'items');
    }
    res.json(response.data);
  } catch (err) {
    console.warn('[Proxy OData Error]:', err.message);
    res.status(500).json({ error: true, message: err.message });
  }
});

function calculateWoodRoughVolume(item) {
  if (!item) return null;
  const ext = item.dimension_extraction || item.dimensions;
  if (!ext) return null;

  const finish_t_mm = Number(ext.finish_t_mm || ext.t || 0);
  const finish_w_mm = Number(ext.finish_w_mm || ext.w || 0);
  const finish_l_mm = Number(ext.finish_l_mm || ext.l || 0);

  if (!finish_t_mm || !finish_w_mm || !finish_l_mm) return null;

  const allowance = ext.rough_allowance_mm || { t: 0, w: 0, l: 0 };
  const qty = Number(item.quantity || item.qty || 1);

  // 1. Hitung Dimensi Kasar (Rough Size)
  const rough_t = finish_t_mm + Number(allowance.t || 0);
  const rough_w = finish_w_mm + Number(allowance.w || 0);
  const rough_l = finish_l_mm + Number(allowance.l || 0);

  // 2. Kalkulasi Volume M3 Eksak (Pembagi 1 Miliar / 1e9)
  const rawVolume = (rough_t * rough_w * rough_l * qty) / 1000000000;

  // 3. Bulatkan ke 6 digit desimal standar modul SAP CO
  const gross_volume_m3 = Number(rawVolume.toFixed(6));

  return {
    rough_dimension_mm: { t: rough_t, w: rough_w, l: rough_l },
    gross_volume_m3: gross_volume_m3
  };
}

app.post('/api/claude', async (req, res) => {
  try {
    const { prompt, materials, systemPrompt, model, history } = req.body;

    const formattedMessages = [];

    // Restrukturisasi riwayat percakapan sesi (multi-turn history - dibatasi 8 percakapan terakhir)
    if (history && Array.isArray(history)) {
      const recentHistory = history.slice(-8);
      recentHistory.forEach(item => {
        if (item.prompt) {
          formattedMessages.push({ role: 'user', content: String(item.prompt).substring(0, 1000) });
        }
        if (item.response) {
          formattedMessages.push({ role: 'assistant', content: String(item.response).substring(0, 2000) });
        }
      });
    }

    // Gunakan materials dari request atau cachedMaterials jika kosong
    let targetMaterials = (materials && Array.isArray(materials) && materials.length > 0)
      ? materials
      : cachedMaterials;

    if (targetMaterials.length > 0 && cachedMaterials.length === 0) {
      cachedMaterials = targetMaterials;
    }

    // Format OData material context dengan Re-ordering & Prioritas Match
    let materialContext = '';
    if (targetMaterials && targetMaterials.length > 0) {
      const promptText = (prompt || '').trim();
      const promptNumbers = promptText.match(/\b\d+\b/g) || [];
      const cleanPromptNums = promptNumbers.map(n => n.replace(/^0+/, ''));
      const promptWords = promptText.toUpperCase()
        .split(/[\s,.;:?!'"]+/)
        .filter(w => w.length >= 2);

      const matchedItems = [];
      const otherItems = [];

      targetMaterials.forEach(m => {
        const rawMatnr = String(m.Matnr || m.MATNR || '').trim();
        const cleanMatnr = rawMatnr.replace(/^0+/, '');
        const maktx = String(m.Maktx || m.MAKTX || '').trim();
        const mtart = String(m.Mtart || m.MTART || '').trim();
        const matkl = String(m.Matkl || m.MATKL || '').trim();
        const werks = String(m.Werks || m.WERKS || '').trim();
        const lgort = String(m.Lgort || m.LGORT || '').trim();
        const dismm = String(m.Dismm || m.DISMM || '').trim();
        const disgr = String(m.Disgr || m.DISGR || '').trim();
        const dispo = String(m.Dispo || m.DISPO || '').trim();

        let score = 0;

        // 1. Exact / Partial Number Match (MATNR / Clean MATNR)
        cleanPromptNums.forEach(cn => {
          if (cn.length >= 3) {
            if (cleanMatnr === cn || rawMatnr === cn) score += 100;
            else if (cleanMatnr.includes(cn) || rawMatnr.includes(cn)) score += 50;
          }
        });

        // 2. MAKTX Description Match
        if (maktx) {
          const maktxUpper = maktx.toUpperCase();
          let wordMatches = 0;
          promptWords.forEach(w => {
            if (w.length >= 2 && maktxUpper.includes(w)) wordMatches++;
          });
          if (wordMatches > 0) score += (wordMatches * 15);
        }

        // 3. MTART / MATKL / WERKS Match
        const rawUpper = promptText.toUpperCase();
        if (mtart && rawUpper.includes(mtart.toUpperCase())) score += 20;
        if (matkl && rawUpper.includes(matkl.toUpperCase())) score += 20;
        if (werks && rawUpper.includes(werks.toUpperCase())) score += 10;

        const formattedLine = `- [MATNR: ${rawMatnr} | Clean: ${cleanMatnr}] ${maktx}` +
          ` | MTART: ${mtart || 'N/A'}` +
          ` | MATKL: ${matkl || 'N/A'}` +
          ` | WERKS: ${werks || 'N/A'}` +
          ` | LGORT: ${lgort || 'N/A'}` +
          ` | DISMM: ${dismm || 'N/A'}` +
          ` | DISGR: ${disgr || 'N/A'}` +
          ` | DISPO: ${dispo || 'N/A'}`;

        if (score > 0) {
          matchedItems.push({ line: `${formattedLine} [MATCH SCORE: ${score}]`, score });
        } else {
          otherItems.push(formattedLine);
        }
      });

      matchedItems.sort((a, b) => b.score - a.score);

      let contextStr = '';
      if (matchedItems.length > 0) {
        // Pembatasan maksimal 60 item paling cocok agar token prompt tidak melebihi batas 200K
        const topMatched = matchedItems.slice(0, 60);
        contextStr += `=== HASIL PENCOCOKAN MATERIAL DITEMUKAN DI SAP ODATA (${topMatched.length} ITEM DITAMPILKAN DARI ${matchedItems.length} TOTAL MATCH) ===\n` +
          topMatched.map(item => item.line).join('\n') + '\n\n';
      }

      // Pembatasan maksimal 30 item lainnya
      const topOther = otherItems.slice(0, 30);
      contextStr += `=== DAFTAR DATA MATERIAL SAP EKSISTING LAINNYA (${topOther.length} ITEM) ===\n` +
        topOther.join('\n');

      materialContext = `\n\n${contextStr}`;
    } else {
      materialContext = `\n\n[DATABASE SAP MATERIAL ODATA]: Belum ada data material yang dimuat dari OData.`;
    }

    const currentUserMessage = `${prompt || ''}${materialContext}`;
    formattedMessages.push({ role: 'user', content: currentUserMessage });

    const defaultSystem = `
Kamu adalah AI Assistant untuk membantu pengguna dalam proses MDG (SAP S/4HANA Master Data Governance).
Tugas utama: pahami konteks MDG, berikan jawaban relevan, langsung, presisi, dan jelas.

PANDUAN LENGKUP PARAMETER MASTER DATA & MRP (SAP MDG)
1. PARAMETER MASTER DATA MATERIAL (MARA, MARC, MARD):
   - Tipe Material (MTART):
     * Standar SAP: FERT (Finished Goods L0), HALB (Semi-Finished / Sub-assembly L1), ROH (Raw Material L2).
     * Custom SAP Z-Types: ZR01 (Bahan Baku Custom), ZROH, ZHAL, ZFRT, dll.
     * ATURAN AKURASI MUTLAK MTART: Selalu baca dan tampilkan nilai field MTART persis sebagaimana
       terdapat pada dataset OData MaterialSet (contoh: jika OData bernilai MTART: "HALB", SEBUTKAN "HALB").
       DILARANG KERAS mengarang, menyimpulkan, atau mengganti nilai MTART menjadi "COMP" atau istilah generik lain.
   - Kelompok Material (MATKL / Material Group):
     * Klasifikasi: WD_SOLID, WD_LAM, METAL_ACC, FASTENER, CHEMICAL, PACKAGING, RWPN04, dll.
   - Pabrik / Plant (WERKS): Kode plant aktif produksi (misal 1010, 1300).
   - Lokasi Gudang (LGORT / Storage Location): SLoc aktif (1001, 1002, 1003, 1301, 1304, 1306, 13A2, dll).
   - Parameter Perencanaan MRP 1 (Tabel MARC): DISMM, DISGR, DISPO.

2. ATURAN PENCOCOKAN DATA & KONSISTENSI (ODATA MATCHING RULES):
   - Apabila terdapat section "=== HASIL PENCOCOKAN MATERIAL DITEMUKAN DI SAP ODATA ===",
     material pada section tersebut PASTI TERDAFTAR DAN EXISTING DI SAP.
   - Kode Material (MATNR) 18-digit (misal 000000000020299156) dan format clean tanpa nol di depan (20299156)
     adalah SAMA dan MERUJUK KE MATERIAL SAP YANG SAMA. DILARANG MENYATAKAN TIDAK DITEMUKAN.
   - EXISTING: Jika MATNR atau MAKTX cocok, dan WERKS di SAP sudah mencakup Plant target.
   - EXTEND_PLANT: Jika part ditemukan di SAP tetapi kolom WERKS/LGORT masih kosong.
   - NEW: Jika tidak ada kecocokan di SAP, beri status NEW & isi usulan parameter.

3. FORMAT SKEMA OUTPUT JSON (Ekstraksi Dimensi & Keputusan Matching SAP):
{
  "product_header": {
    "product_code": "STRING", "product_name": "STRING",
    "plant": "1010", "material_type": "FERT", "storage_location": "1003"
  },
  "materials": [
    {
      "item_no": 1, "level": 2, "part_name": "FRONT RAIL",
      "material_category": "WOOD_SOLID / HARDWARE / CHEMICAL / PACKAGING",
      "wood_species": "Mahoni / Jati / Mindi / NULL",
      "quantity": 2,
      "dimension_extraction": {
        "finish_t_mm": 25.0,
        "finish_w_mm": 38.0,
        "finish_l_mm": 509.5,
        "rough_allowance_mm": { "t": 4.0, "w": 6.0, "l": 12.0 }
      },
      "sap_matching_decision": {
        "sap_status": "NEW / EXISTING / EXTEND_PLANT / AUTO-SUGGEST",
        "sap_matnr": "STRING_OR_NULL",
        "match_reason": "Dimensi 25x38x509.5 mm unik untuk model ini, tidak ada kecocokan identik di OData"
      },
      "parameters": {
        "mtart": "ROH / HALB / FERT", "matkl": "STRING_GROUP_CODE",
        "werks": "1010", "lgort": "1001 / 1002 / 1003",
        "dismm": "PD / VB / ND", "disgr": "0001", "dispo": "M01 / M02"
      },
      "work_station_code": "0010 / 0020 / 0030 / 0040 / 0050"
    }
  ]
}

4. [GOVERNANCE RULE: BOM COMPLETENESS & MTART INTEGRITY - TEST #5]
   - MTART RESTRICTIONS:
     * Root Assembly (Level 0) = ONLY "FERT"
     * Sub-Assemblies (Level 1) = ONLY "HALB"
     * ALL Child Components, Raw Wood, Dowels, Screws, Glues, Weaving Cords, and Metal Parts = STRICTLY "ROH". Never output "FERT", "HALB", "VERB", or custom codes like "ZR01" for Level 2 items.
   - AUTO-SUGGEST TRIGGERS:
     * IF component contains "CORNER BLOCK", MUST auto-suggest: "WOOD SCREW 4X35" (Qty: 2 pcs per block, Base UoM: PC, MTART: ROH, Status: AUTO-SUGGEST).
     * IF wood joint or frame assembly exists, MUST auto-suggest: "WOOD GLUE PVAC CROSSLINK" (Base UoM: KG, MTART: ROH, Status: AUTO-SUGGEST).
     * IF woven seat texture is present, MUST auto-suggest: "SEAT WEAVING CORD" (Base UoM: KG, MTART: ROH, Status: AUTO-SUGGEST).

5. [GOVERNANCE RULE: SAP ROUTING CA01 & PLMZ ALLOCATION - TEST #6]
   - SINGLE OPERATION CONSTRAINT:
     * Field "work_station_code" MUST be exactly one string: "0010", "0020", "0030", "0040", OR "0050". Multi-station assignment (e.g., "0030 + 0040") is strictly forbidden.
   - WORK STATION MAPPING DIRECTIVES:
     * Assign raw sawn timber/lumber to "0010" (Part).
     * Assign corner blocks and surfaced components (S4S) to "0020" (Component).
     * Assign machined solid wood, curved slats, and profiles to "0030" (Machining).
     * Assign dowels, screws, wood glues, and seat weaving cords to "0040" (Assembling).
     * Assign finishing chemicals AND decorative metal fittings (Brass Stretchers, Brass Caps, glides) to "0050" (Painting).

6. [STRICT GOVERNANCE RULE: WOOD MATCHING & DEDUPLICATION]
   - ZERO-TOLERANCE DIMENSION MATCHING:
     * Komponen kayu solid struktural (kaki, rel, stretcher, kisi sandaran) adalah PART KUSTOM yang terikat model.
     * DILARANG KERAS menetapkan sap_status = "EXISTING" pada komponen kayu hanya karena kesamaan kata kunci (misal sama-sama bernama "FRONT RAIL" atau jenis kayu sama).
     * Status "EXISTING" HANYA boleh diberikan jika:
       a. Dimensi Finish Size (T x W x L) SAMA PERSIS (toleransi 0 mm), DAN
       b. Kode model produk induknya identik.
     * Jika dimensi berbeda meskipun hanya 0.5 mm, WAJIB tetapkan:
       - sap_status: "NEW"
       - sap_matnr: null
       - match_reason: "Dimensi kustom model baru, wajib buat nomor material baru (MM01)"
   - SCOPE PENCARIAN ODATA (TOOL FILTER):
     * Jangan pernah mencocokkan part kustom model aktif dengan nomor material dari seri model lain (misal: mencocokkan part NT-325-2 ke seri HC2515 atau COMUNAL LKL).
     * Status EXISTING diprioritaskan HANYA untuk:
       a. Hardware standar (Dowel Beech, Wood Screw).
       b. Bahan penolong umum (Lem PVAc, finishing).
       c. Corner block ukuran standar pabrik.

7. [MATRIKS VALIDASI KEPUTUSAN STATUS MATERIAL]
   - Kayu Solid Struktural & Seri Model Beda ATAU Dimensi Beda -> STATUS: NEW (sap_matnr: null)
   - Kayu Solid Struktural & Seri Model Sama & Dimensi Identik 100% -> STATUS: EXISTING (sap_matnr: Kode SAP query)
   - Dowel & Fastener & Ukuran Sama Persis -> STATUS: EXISTING (sap_matnr: Kode SAP query)
   - Dowel & Fastener & Ukuran Belum Ada -> STATUS: NEW (sap_matnr: null)
   - Lem & Bahan Kimia Standar Pabrik -> STATUS: AUTO-SUGGEST (sap_matnr: Kode OData / null)

ATURAN UTAMA RESPONS:
1. Jawab pertanyaan pengguna secara langsung terlebih dahulu (kalimat/paragraf biasa).
2. DILARANG membuat tabel secara otomatis. Gunakan tabel HANYA jika diminta eksplisit ("buatkan tabel").
3. DILARANG KERAS MENGARANG ATAU MEMBUAT DATA FAKE/DUMMY SAP. SELALU GUNAKAN DATA MATERIALSET DARI ODATA SAP EKSISTING.
4. SELALU sebutkan Tipe Material (MTART), Kelompok Material (MATKL), Plant (WERKS), dan SLoc (LGORT) persis sesuai data OData.
5. Bedakan antara fakta data SAP, konteks percakapan, dan asumsi.
6. Gunakan konteks percakapan sebelumnya (kontinuitas).
`;

    const selectedModel = model || process.env.CLAUDE_MODEL || 'claude-haiku-4-5-20251001';
    const targetMaxTokens = req.body.max_tokens
      ? parseInt(req.body.max_tokens, 10)
      : (parseInt(process.env.CLAUDE_MAX_TOKENS, 10) || 4000);

    console.log(`[Middleware Requesting Model]: ${selectedModel} (max_tokens: ${targetMaxTokens})`);

    const response = await axios.post(
      'https://api.anthropic.com/v1/messages',
      {
        model: selectedModel,
        max_tokens: targetMaxTokens,
        system: systemPrompt || defaultSystem,
        messages: formattedMessages
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': CLAUDE_KEY,
          'anthropic-version': '2023-06-01'
        },
        timeout: 60000
      }
    );

    if (response && response.data && response.data.content) {
      response.data.content.forEach(block => {
        if (block.type === 'text' && block.text.includes('{')) {
          try {
            const jsonMatch = block.text.match(/```json\s*([\s\S]*?)\s*```/) || block.text.match(/(\{[\s\S]*\})/);
            if (jsonMatch) {
              const parsed = JSON.parse(jsonMatch[1]);
              if (parsed && Array.isArray(parsed.materials)) {
                let enrichedCount = 0;
                parsed.materials.forEach(m => {
                  const coCalc = calculateWoodRoughVolume(m);
                  if (coCalc) {
                    m.calculated_co_volume = coCalc;
                    enrichedCount++;
                  }
                });
                if (enrichedCount > 0) {
                  console.log(`[Middleware CO Volume Calculated]: Enriched ${enrichedCount} wood items with exact M3 volume`);
                }
              }
            }
          } catch (e) {
            // Non-fatal parse error
          }
        }
      });
    }

    res.json(response.data);

  } catch (error) {
    console.error('[Middleware Error]:', error.response ? error.response.data : error.message);
    res.status(500).json({
      error: true,
      message: error.response ? error.response.data : error.message
    });
  }
});

const HOST = process.env.HOST || '0.0.0.0';

app.listen(PORT, HOST, () => {
  console.log(`=================================================`);
  console.log(` SAP AI Middleware running at: http://${HOST}:${PORT}`);
  console.log(` Local:    http://localhost:${PORT}`);
  console.log(` Endpoint: http://${HOST}:${PORT}/api/claude`);
  console.log(`=================================================`);
});