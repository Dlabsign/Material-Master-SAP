import openpyxl
from openpyxl.styles import PatternFill, Font, Alignment, Border, Side
from openpyxl.comments import Comment
from openpyxl.utils import get_column_letter

def build_template():
    src_file = 'Excel/TEMPLATE_QUOTATION.xlsx'
    out_file = 'Excel/TEMPLATE_UPLOAD_QUOTATION.xlsx'

    # Load source to get all headers and sample rows
    src_wb = openpyxl.load_workbook(src_file, data_only=True)
    src_ws = src_wb.active

    # Create new workbook
    wb = openpyxl.Workbook()
    
    # Sheet 1: Data Sheet for Upload (must be first sheet and named Sheet1)
    ws1 = wb.active
    ws1.title = "Sheet1"
    ws1.views.sheetView[0].showGridLines = True

    # =========================================================================
    # STYLING PALETTES (High-End & Harmonious Theme)
    # =========================================================================
    # 1. RED (Jangan Diisi / Wajib Kosong)
    fill_red_hdr = PatternFill(start_color="FFE4E6", end_color="FFE4E6", fill_type="solid") # Rose 100
    font_red_hdr = Font(name="Segoe UI", size=10, bold=True, color="9F1239")                 # Rose 800
    fill_red_data = PatternFill(start_color="FFF1F2", end_color="FFF1F2", fill_type="solid")
    font_red_data = Font(name="Segoe UI", size=10, color="9F1239", italic=True)

    # 2. GREEN (Wajib Diubah / Diisi Tiap Barang Baru)
    fill_green_hdr = PatternFill(start_color="DCFCE7", end_color="DCFCE7", fill_type="solid") # Emerald 100
    font_green_hdr = Font(name="Segoe UI", size=10, bold=True, color="166534")                 # Emerald 800
    fill_green_data = PatternFill(start_color="F0FDF4", end_color="F0FDF4", fill_type="solid")
    font_green_data = Font(name="Segoe UI", size=10, bold=True, color="166534")

    # 3. YELLOW (Sering Disesuaikan / Kategori / Pabrik / Akuntansi)
    fill_yellow_hdr = PatternFill(start_color="FEF3C7", end_color="FEF3C7", fill_type="solid") # Amber 100
    font_yellow_hdr = Font(name="Segoe UI", size=10, bold=True, color="92400E")                 # Amber 800
    fill_yellow_data = PatternFill(start_color="FFFBEB", end_color="FFFBEB", fill_type="solid")
    font_yellow_data = Font(name="Segoe UI", size=10, color="92400E")

    # 4. GRAY / SLATE (Default Standar Quotation - Jangan Diubah)
    fill_gray_hdr = PatternFill(start_color="F1F5F9", end_color="F1F5F9", fill_type="solid") # Slate 100
    font_gray_hdr = Font(name="Segoe UI", size=10, bold=True, color="475569")                 # Slate 600
    fill_gray_data = PatternFill(start_color="FFFFFF", end_color="FFFFFF", fill_type="solid")
    font_gray_data = Font(name="Segoe UI", size=10, color="334155")

    # Borders
    thin_border = Side(style='thin', color='CBD5E1')
    hdr_border = Border(left=thin_border, right=thin_border, top=thin_border, bottom=Side(style='medium', color='64748B'))
    data_border = Border(left=thin_border, right=thin_border, top=thin_border, bottom=thin_border)

    # Column Categorization (1-based index)
    # RED: WAJIB KOSONG
    col_red = {1, 3} # 1: Material, 3: Old Material Number

    # GREEN: WAJIB DIUBAH TIAP BARANG
    col_green = {
        6,   # Base Unit of Measure (F)
        7,   # Material Description (G)
        37,  # Standard price (AK)
        38,  # Moving Average Price (AL)
        39,  # Price Unit (AM)
    }

    # YELLOW: SESUAIKAN DENGAN KEBUTUHAN / KATEGORI
    col_yellow = {
        5,   # Material Group (E)
        14,  # Plant (N)
        15,  # Storage Location (O)
        35,  # Profit Center (AI)
        36,  # Valuation Class (AJ)
        40,  # Price Control (AN)
        41,  # Price Unit Hard Currency (AO)
        96,  # Origin Group (CR)
        100, # Valuation Area (CV)
    }

    # Comments mapping for Row 1
    comments_map = {
        1: ("⛔ JANGAN DIISI / KOSONGKAN!\n"
            "Nomor material akan digenerate otomatis oleh SAP saat proses approval.\n"
            "Jika diisi nomor manual yang sudah terdaftar di MARA SAP, akan memicu error duplikasi."),
        3: ("KOSONGKAN!\n"
            "Nomor material lama (opsional, biarkan kosong untuk material quotation baru)."),
        5: ("🟡 KELOMPOK MATERIAL (MATERIAL GROUP)!\n"
            "Sesuaikan kelompok material sesuai kategori barang. Contoh: QTM001."),
        6: ("✅ WAJIB DIUBAH / DIISI!\n"
            "Satuan dasar material (Base UoM). Contoh: M3, PC, KG, SET, ROLL."),
        7: ("✅ WAJIB DIUBAH / DIISI!\n"
            "Deskripsi / Nama lengkap material quotation (Maks. 40 karakter).\n"
            "Contoh: SOLID MAPLE QTS."),
        14: ("🟡 PABRIK TUJUAN (PLANT)!\n"
             "• 2000 = PT Kayu Mebel Indonesia (Mata uang Company Code: USD)\n"
             "• 1000 = Pabrik lokal IDR (Mata uang Company Code: IDR)."),
        15: ("🟡 LOKASI GUDANG (STORAGE LOCATION)!\n"
             "Contoh: 2221 (Pabrik 2000), 1001, dll."),
        35: ("🟡 PROFIT CENTER!\n"
             "Wajib diisi di Mandant 300. Contoh: 100201."),
        36: ("🟡 VALUATION CLASS!\n"
             "Akun kelas valuasi material di SAP. Contoh: RW01 (Raw Material Wood)."),
        37: ("✅ WAJIB DIUBAH SESUAI HARGA STANDAR!\n"
             "Harga Standar material di SAP:\n"
             "• Plant 2000 (USD): Masukkan nominal USD (contoh: 1363.09)\n"
             "• Plant 1000 (IDR): Masukkan nominal IDR (contoh: 24000000)\n"
             "*Gunakan tanda titik (.) untuk angka desimal, jangan gunakan pemisah ribuan."),
        38: ("✅ HARGA MOVING AVERAGE!\n"
             "Untuk Price Control 'S', isi nilai yang SAMA dengan Standard Price "
             "agar tidak memicu selisih kurs valas / error konversi di SAP."),
        39: ("✅ PRICE UNIT!\n"
             "Satuan jumlah unit untuk harga (Default: 1).\n"
             "Nilai 1 berarti harga di samping berlaku untuk per 1 Base UoM."),
        40: ("🟡 PRICE CONTROL!\n"
             "'S' = Standard Price (Rekomendasi untuk quotation / material standar).\n"
             "'V' = Moving Average Price."),
        41: ("🟡 PRICE UNIT HARD CURRENCY!\n"
             "Default: 1. (Jangan diisi nominal rupiah seperti 24.000.000)."),
        96: ("🟡 ORIGIN GROUP (MBEW-HERBL)!\n"
             "Grup asal biaya CO (Opsional). Pastikan terdaftar di tabel SAP TKKH1 jika diisi."),
        100: ("🟡 VALUATION AREA!\n"
              "Samakan nilainya dengan kode Plant (misal: 2000 atau 1000)."),
    }

    # Populate Headers
    max_col = src_ws.max_column
    for c in range(1, max_col + 1):
        h_val = src_ws.cell(1, c).value
        # Fix missing header labels for Col 78 and 79 if empty
        if c == 78 and not h_val:
            h_val = "Period Indicator"
        elif c == 79 and not h_val:
            h_val = "Fiscal Year Variant"
        
        cell = ws1.cell(1, c, h_val)
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = hdr_border

        # Apply Colors
        if c in col_red:
            cell.fill = fill_red_hdr
            cell.font = font_red_hdr
        elif c in col_green:
            cell.fill = fill_green_hdr
            cell.font = font_green_hdr
        elif c in col_yellow:
            cell.fill = fill_yellow_hdr
            cell.font = font_yellow_hdr
        else:
            cell.fill = fill_gray_hdr
            cell.font = font_gray_hdr

        # Apply Comment
        if c in comments_map:
            comm_text = comments_map[c]
            cell.comment = Comment(comm_text, "MDG System", width=270, height=115)

    # Populate All 16 Quotation Items from source (Cleaned & Standardized)
    max_row = src_ws.max_row
    for r_idx in range(2, max_row + 1):
        for c in range(1, max_col + 1):
            val = src_ws.cell(r_idx, c).value
            
            # Special Overrides for Clean Sample Data
            if c == 1:
                val = None # Col A: Material MUST BE BLANK!
            elif c == 41:
                val = 1    # Col AO: Price Unit Hard Currency must be 1, NOT 24000000!

            cell = ws1.cell(r_idx, c, val)
            cell.border = data_border

            # Number formatting
            if isinstance(val, (int, float)):
                if c in [37, 38]: # Prices
                    cell.number_format = '#,##0.00'
                    cell.alignment = Alignment(horizontal="right", vertical="center")
                else:
                    cell.alignment = Alignment(horizontal="center", vertical="center")
            else:
                if c in [6, 7]: # UoM, Description
                    cell.alignment = Alignment(horizontal="left", vertical="center")
                else:
                    cell.alignment = Alignment(horizontal="center", vertical="center")

            # Apply Data Row Colors
            if c in col_red:
                cell.fill = fill_red_data
                cell.font = font_red_data
            elif c in col_green:
                cell.fill = fill_green_data
                cell.font = font_green_data
            elif c in col_yellow:
                cell.fill = fill_yellow_data
                cell.font = font_yellow_data
            else:
                cell.fill = fill_gray_data
                cell.font = font_gray_data

    # Set row height
    ws1.row_dimensions[1].height = 42
    for r in range(2, max_row + 1):
        ws1.row_dimensions[r].height = 24

    # Freeze Header Row
    ws1.freeze_panes = "A2"

    # Auto-adjust column widths
    for col in ws1.columns:
        col_letter = get_column_letter(col[0].column)
        h_str = str(col[0].value or '')
        val_lens = [len(str(c.value or '')) for c in col[1:6]]
        max_len = max([len(h_str)] + val_lens)
        ws1.column_dimensions[col_letter].width = max(max_len + 4, 12)

    # Specific comfortable widths for key columns
    ws1.column_dimensions['A'].width = 18 # Material
    ws1.column_dimensions['B'].width = 16 # Industry Sector
    ws1.column_dimensions['D'].width = 16 # Material Type
    ws1.column_dimensions['E'].width = 16 # Material Group
    ws1.column_dimensions['F'].width = 14 # Base UoM
    ws1.column_dimensions['G'].width = 32 # Material Description
    ws1.column_dimensions['N'].width = 12 # Plant
    ws1.column_dimensions['O'].width = 16 # S.Loc
    ws1.column_dimensions['AI'].width = 16 # Profit Center
    ws1.column_dimensions['AJ'].width = 16 # Valuation Class
    ws1.column_dimensions['AK'].width = 18 # Standard Price
    ws1.column_dimensions['AL'].width = 22 # Moving Avg Price
    ws1.column_dimensions['AM'].width = 14 # Price Unit
    ws1.column_dimensions['AN'].width = 14 # Price Control
    ws1.column_dimensions['AO'].width = 24 # Price Unit Hard Currency

    # =========================================================================
    # SHEET 2: PANDUAN PENGISIAN (PETUNJUK LENGKAP)
    # =========================================================================
    ws2 = wb.create_sheet(title="PANDUAN_PENGISIAN")
    ws2.views.sheetView[0].showGridLines = True

    # Title Banner
    ws2.merge_cells("A1:G1")
    title_cell = ws2.cell(1, 1, "PANDUAN & PETUNJUK PENGISIAN TEMPLATE QUOTATION MATERIAL MASTER")
    title_cell.font = Font(name="Segoe UI", size=14, bold=True, color="1E3A8A") # Blue 900
    title_cell.fill = PatternFill(start_color="DBEAFE", end_color="DBEAFE", fill_type="solid") # Blue 100
    title_cell.alignment = Alignment(horizontal="left", vertical="center", indent=1)
    ws2.row_dimensions[1].height = 40

    ws2.merge_cells("A2:G2")
    sub_cell = ws2.cell(2, 1, "Sistem Master Data Governance (MDG) — PT Kayu Mebel Indonesia")
    sub_cell.font = Font(name="Segoe UI", size=10, italic=True, color="3B82F6")
    sub_cell.fill = PatternFill(start_color="EFF6FF", end_color="EFF6FF", fill_type="solid")
    sub_cell.alignment = Alignment(horizontal="left", vertical="center", indent=1)
    ws2.row_dimensions[2].height = 24

    # Section 1: Color Legend
    ws2.cell(4, 1, "1. ARTI KODE WARNA PADA HEADER KOLOM (Sheet1)").font = Font(name="Segoe UI", size=11, bold=True, color="0F172A")
    
    legends = [
        ("MERAH (Rose)", "JANGAN DIISI / WAJIB KOSONG!", 
         "Kolom A (Material) & Kolom C (Old Material). Biarkan kolom ini kosong! Sistem SAP akan men-generate nomor material unik otomatis melalui Number Range saat approval. Mengisi nomor manual yang sudah ada di SAP MARA akan menyebabkan error duplikasi."),
        ("HIJAU (Emerald)", "WAJIB DIUBAH / DIISI SETIAP BARIS BARANG BARU!", 
         "Kolom F (Base UoM), Kolom G (Material Description), Kolom AK (Standard Price), Kolom AL (Moving Average Price), Kolom AM (Price Unit). Ini adalah identitas utama material quotation Anda."),
        ("KUNING (Amber)", "SESUAIKAN DENGAN KEBUTUHAN / PABRIK / KATEGORI!", 
         "Kolom E (Material Group), Kolom N (Plant), Kolom O (Storage Location), Kolom AI (Profit Center), Kolom AJ (Valuation Class), Kolom AN (Price Control), Kolom AO (Price Unit Hard Currency), Kolom CV (Valuation Area). Sesuaikan jika quotation ditujukan untuk Plant 1000 atau Plant 2000."),
        ("ABU-ABU (Slate)", "DEFAULT STANDAR QUOTATION (JANGAN DIUBAH)!", 
         "Semua kolom konfigurasi lainnya (Material Type ZR01, Division M1, MRP Type PD, Purchasing Group K01, dll.). Kolom-kolom ini sudah disetting sesuai konfigurasi standar quotation SAP. Cukup biarkan apa adanya.")
    ]

    leg_fills = [fill_red_hdr, fill_green_hdr, fill_yellow_hdr, fill_gray_hdr]
    leg_fonts = [font_red_hdr, font_green_hdr, font_yellow_hdr, font_gray_hdr]

    ws2.cell(5, 1, "Warna").font = Font(name="Segoe UI", size=10, bold=True)
    ws2.cell(5, 1).border = hdr_border
    ws2.cell(5, 2, "Status / Aturan").font = Font(name="Segoe UI", size=10, bold=True)
    ws2.cell(5, 2).border = hdr_border
    ws2.merge_cells("C5:G5")
    ws2.cell(5, 3, "Penjelasan & Tindakan User").font = Font(name="Segoe UI", size=10, bold=True)
    ws2.cell(5, 3).border = hdr_border
    for c in range(4, 8): ws2.cell(5, c).border = hdr_border

    ws2.row_dimensions[5].height = 25

    for idx, (w_lbl, s_lbl, p_lbl) in enumerate(legends, start=6):
        c1 = ws2.cell(idx, 1, w_lbl)
        c1.fill = leg_fills[idx-6]
        c1.font = leg_fonts[idx-6]
        c1.border = data_border
        c1.alignment = Alignment(horizontal="center", vertical="center")

        c2 = ws2.cell(idx, 2, s_lbl)
        c2.font = Font(name="Segoe UI", size=10, bold=True, color="1E293B")
        c2.border = data_border
        c2.alignment = Alignment(horizontal="left", vertical="center")

        ws2.merge_cells(start_row=idx, start_column=3, end_row=idx, end_column=7)
        c3 = ws2.cell(idx, 3, p_lbl)
        c3.font = Font(name="Segoe UI", size=9, color="334155")
        c3.alignment = Alignment(horizontal="left", vertical="center", wrap_text=True)
        for col_i in range(3, 8): ws2.cell(idx, col_i).border = data_border

        ws2.row_dimensions[idx].height = 36

    # Section 2: Key Columns Table
    row_curr = 12
    ws2.cell(row_curr, 1, "2. RINCIAN KOLOM PENTING YANG PERLU DIKETAHUI").font = Font(name="Segoe UI", size=11, bold=True, color="0F172A")
    row_curr += 1

    tbl_headers = ["Kolom Excel", "Field SAP", "Nama Kolom Header", "Warna", "Contoh Nilai", "Aturan & Cara Pengisian"]
    ws2.row_dimensions[row_curr].height = 25
    for c_i, th in enumerate(tbl_headers, start=1):
        if c_i == 6:
            ws2.merge_cells(start_row=row_curr, start_column=6, end_row=row_curr, end_column=7)
            ws2.cell(row_curr, 7).border = hdr_border
        cell = ws2.cell(row_curr, c_i, th)
        cell.font = Font(name="Segoe UI", size=10, bold=True, color="1E293B")
        cell.fill = PatternFill(start_color="E2E8F0", end_color="E2E8F0", fill_type="solid")
        cell.border = hdr_border
        cell.alignment = Alignment(horizontal="center", vertical="center")

    cols_detail = [
        ("Kolom A (Col 1)", "MARA-MATNR", "Material", "MERAH", "(KOSONG)", "WAJIB KOSONG! Nomor material akan digenerate otomatis oleh SAP."),
        ("Kolom D (Col 4)", "MARA-MTART", "Material Type", "ABU-ABU", "ZR01", "Default quotation: ZR01 (Raw Material Wood)."),
        ("Kolom E (Col 5)", "MARA-MATKL", "Material Group", "KUNING", "QTM001", "Kelompok material. Contoh: QTM001 (Quotation Material)."),
        ("Kolom F (Col 6)", "MARA-MEINS", "Base Unit of Measure", "HIJAU", "M3", "WAJIB DIISI! Satuan dasar barang. Contoh: M3, PC, KG, SET."),
        ("Kolom G (Col 7)", "MAKT-MAKTX", "Material Description", "HIJAU", "SOLID MAPLE QTS", "WAJIB DIUBAH! Nama material baru (Maks. 40 karakter)."),
        ("Kolom N (Col 14)", "MARC-WERKS", "Plant", "KUNING", "2000", "Pabrik tujuan. 2000 (Mata uang USD) atau 1000 (Mata uang IDR)."),
        ("Kolom O (Col 15)", "MARD-LGORT", "Storage Location", "KUNING", "2221", "Lokasi gudang penyimpanan material. Contoh: 2221."),
        ("Kolom AI (Col 35)", "MARC-PRCTR", "Profit Center", "KUNING", "100201", "Wajib terisi untuk SAP Mandant 300."),
        ("Kolom AJ (Col 36)", "MBEW-BKLAS", "Valuation Class", "KUNING", "RW01", "Kelas valuasi akuntansi SAP. Contoh: RW01."),
        ("Kolom AK (Col 37)", "MBEW-STPRS", "Standard price", "HIJAU", "1363.09", "WAJIB DIISI! Harga standar dalam mata uang Company Code (USD di Plant 2000, IDR di Plant 1000). Gunakan titik untuk desimal."),
        ("Kolom AL (Col 38)", "MBEW-VERPR", "Moving Average Price", "HIJAU", "1363.09", "Untuk Price Control S, isi nilai yang SAMA dengan Standard Price agar tidak memicu selisih kurs valas."),
        ("Kolom AM (Col 39)", "MBEW-PEINH", "Price Unit", "HIJAU", "1", "Default: 1. Satuan unit harga (berlaku per 1 Base UoM)."),
        ("Kolom AN (Col 40)", "MBEW-VPRSV", "Price Control", "KUNING", "S", "'S' = Standard Price, 'V' = Moving Average Price."),
        ("Kolom AO (Col 41)", "MBEW-PEINH_2", "Price Unit Hard Curr", "KUNING", "1", "Default: 1. Jangan masukkan nilai harga rupiah di sini!"),
        ("Kolom CV (Col 100)", "MBEW-BWKEY", "Valuation Area", "KUNING", "2000", "Samakan nilainya dengan Plant (2000 atau 1000).")
    ]

    for d_idx, item in enumerate(cols_detail, start=row_curr+1):
        ws2.row_dimensions[d_idx].height = 24
        for c_i in range(1, 6):
            cell = ws2.cell(d_idx, c_i, item[c_i-1])
            cell.font = Font(name="Segoe UI", size=9, color="1E293B")
            cell.border = data_border
            if c_i in [1, 2, 4, 5]:
                cell.alignment = Alignment(horizontal="center", vertical="center")
            else:
                cell.alignment = Alignment(horizontal="left", vertical="center")
            
            # Color badge
            if c_i == 4:
                if item[3] == "MERAH":
                    cell.fill = fill_red_hdr; cell.font = font_red_hdr
                elif item[3] == "HIJAU":
                    cell.fill = fill_green_hdr; cell.font = font_green_hdr
                elif item[3] == "KUNING":
                    cell.fill = fill_yellow_hdr; cell.font = font_yellow_hdr
                else:
                    cell.fill = fill_gray_hdr; cell.font = font_gray_hdr

        ws2.merge_cells(start_row=d_idx, start_column=6, end_row=d_idx, end_column=7)
        c_rule = ws2.cell(d_idx, 6, item[5])
        c_rule.font = Font(name="Segoe UI", size=9, color="334155")
        c_rule.alignment = Alignment(horizontal="left", vertical="center")
        ws2.cell(d_idx, 6).border = data_border
        ws2.cell(d_idx, 7).border = data_border

    # Section 3: Pricing Rules Note
    row_note = row_curr + len(cols_detail) + 2
    ws2.cell(row_note, 1, "3. PANDUAN PENGISIAN HARGA (PRICING & CURRENCY)").font = Font(name="Segoe UI", size=11, bold=True, color="0F172A")
    row_note += 1

    pricing_notes = [
        "• Plant 2000 (PT Kayu Mebel Indonesia): Mata uang utama Company Code adalah USD, dan Hard Currency adalah IDR.",
        "  - Masukkan harga dalam USD pada kolom Standard Price (Kolom AK) dan Moving Average Price (Kolom AL), contoh: 1363.09.",
        "  - Format desimal menggunakan titik (.), JANGAN gunakan tanda koma (,) atau pemisah ribuan titik.",
        "  - Pastikan Price Unit (Kolom AM) dan Price Unit Hard Currency (Kolom AO) tetap bernilai 1.",
        "• Plant 1000 (Pabrik Lokal): Mata uang utama Company Code adalah IDR.",
        "  - Masukkan harga dalam Rupiah tanpa titik pemisah ribuan (contoh: 24000000).",
        "• Price Control 'S': Untuk material dengan Price Control S, pastikan Moving Average Price diisi angka yang SAMA dengan Standard Price agar tidak memicu error 'Translation result ... IDR is too big' saat proses approval SAP."
    ]

    for p_str in pricing_notes:
        ws2.merge_cells(start_row=row_note, start_column=1, end_row=row_note, end_column=7)
        cell = ws2.cell(row_note, 1, p_str)
        cell.font = Font(name="Segoe UI", size=9, color="0F766E" if "•" in p_str and "Plant" in p_str else "334155")
        cell.alignment = Alignment(horizontal="left", vertical="center")
        ws2.row_dimensions[row_note].height = 20
        row_note += 1

    # Adjust Sheet 2 column widths
    ws2.column_dimensions['A'].width = 20
    ws2.column_dimensions['B'].width = 20
    ws2.column_dimensions['C'].width = 26
    ws2.column_dimensions['D'].width = 14
    ws2.column_dimensions['E'].width = 18
    ws2.column_dimensions['F'].width = 45
    ws2.column_dimensions['G'].width = 35

    # Save
    wb.save(out_file)
    print(f"Successfully created: {out_file}")

if __name__ == '__main__':
    build_template()
