import zipfile, xml.etree.ElementTree as ET

with zipfile.ZipFile('Excel/main template/HALB.xlsx', 'r') as z:
    shared = []
    if 'xl/sharedStrings.xml' in z.namelist():
        tree = ET.fromstring(z.read('xl/sharedStrings.xml'))
        for si in tree:
            text = ''.join(si.itertext())
            shared.append(text)
    tree = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
    rows = []
    for row in tree.findall('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}sheetData/{http://schemas.openxmlformats.org/spreadsheetml/2006/main}row'):
        r_vals = []
        for c in row.findall('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c'):
            t = c.get('t')
            v = c.find('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}v')
            val = v.text if v is not None else ''
            if t == 's' and val != '':
                val = shared[int(val)]
            r_vals.append(val)
        rows.append(r_vals)
    headers = rows[0]

line = 'UPL-MTXWW4\t1\t\tF\t\tHALB\tQTM001\tKG\tPlat MS QTS\tM3\tNORM\t2000\t2233\t33X37X190\tID\t1\tMWST\tNORM\t0001\t0001\tX\t200301\tSF01\t\t1\tS\t\tPD\tE\t1\t0\tM\tC1\tKP\t\t\tX\tX\t100\t\tZWH6\tGT1\tEX\t0\t20\t\t\t\t\t\t0001\t1\t\t0\t0\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tZMG1\t\t20.000,00\t20.000\t0\t\t0\t0\t0\t0\t\t0\tKG\t0\t0\t\t\t1\t\t\t0\t0\t0\t\t0\t0\t0\t\t\t1207\t0,0\t0,0\t\t\t\t4\tX\t\t\t\tX\tX\tX\tX\t\t1,14'
cols = line.split('\t')

# Notice col 0 is UPL-MTXWW4 (REQ_NO), col 1 is 1 (ITEM_NO)
# So excel headers might start at col 2!
print(f"Data columns: {len(cols)}")
for idx in range(len(cols)):
    c_val = cols[idx]
    # If shifted by 2:
    h_idx = idx - 2
    h_name = headers[h_idx] if 0 <= h_idx < len(headers) else '<N/A>'
    if c_val != '' or h_idx in [35, 36, 37, 38, 39, 40]:
        print(f'col[{idx:3d}] (excel {h_idx:3d}): {h_name:30s} = [{c_val}]')
