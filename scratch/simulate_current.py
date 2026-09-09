import openpyxl

wb = openpyxl.load_workbook('Excel/main template/HALB.xlsx', data_only=True)
ws = wb.active
rows = list(ws.iter_rows(values_only=True))
header_row = rows[0]
data_row = rows[1]

header_col_map = {}
for idx, h in enumerate(header_row):
    if h is not None:
        s = str(h).strip().upper()
        if s:
            header_col_map[s] = idx

def get_cell_str(row, idx, default_val='', pad_len=None):
    if not row or idx >= len(row) or row[idx] is None:
        return default_val
    v = str(row[idx]).strip()
    return v if v else default_val

# EXACT code from request_form.htm lines 1922-1936
def get_smart_val(row, primary_idx, keywords, default_val='', pad_len=None):
    if keywords and len(keywords) > 0:
        for k in range(len(keywords)):
            kw = keywords[k].upper()
            for h_name in header_col_map:
                if h_name == kw or kw in h_name:
                    col_idx = header_col_map[h_name]
                    val = get_cell_str(row, col_idx, '', pad_len)
                    if val != '':
                        return val, f'matched kw "{kw}" in "{h_name}" (col {col_idx+1})'
    return get_cell_str(row, primary_idx, default_val, pad_len), f'fallback primary_idx {primary_idx+1}'

lgort, r_lgort = get_smart_val(data_row, 14, ['S.LOC', 'LGORT'], '')
lgpro, r_lgpro = get_smart_val(data_row, 83, ['PRODUCTION STORAGE LOCATION', 'LGPRO'], '')
lgpro_ep, r_ep = get_smart_val(data_row, 84, ['STORAGE LOCATION FOR EP', 'LGPRO_EP'], '')
meins, r_meins = get_smart_val(data_row, 5, ['BASE UOM', 'MEINS'], '')

print(f'lgort: "{lgort}" ({r_lgort})')
print(f'meins: "{meins}" ({r_meins})')
print(f'lgpro: "{lgpro}" ({r_lgpro})')
print(f'lgpro_ep: "{lgpro_ep}" ({r_ep})')
