import re

with open(r'Request/request_form.htm', 'r', encoding='utf-8') as f:
    content = f.read()

# find all THs in partTable
thead_m = re.search(r'<table[^>]*id=["\']partTable["\'][^>]*>.*?<thead>(.*?)</thead>', content, re.DOTALL)
ths = re.findall(r'<th[^>]*>(.*?)</th>', thead_m.group(1), re.DOTALL) if thead_m else []
ths_cleaned = [re.sub(r'<[^>]+>', '', t).strip() for t in ths]

# find all TDs in addNewRowData
addrow_m = re.search(r'function\s+addNewRowData\s*\([^)]*\)\s*\{(.*?)\n\s*tr\.innerHTML', content, re.DOTALL)
parts = addrow_m.group(1).split("html += '<td")[1:] if addrow_m else []

print(f'TH count: {len(ths_cleaned)}, TD count: {len(parts)}')
for i in range(max(len(ths_cleaned), len(parts))):
    th = ths_cleaned[i] if i < len(ths_cleaned) else 'MISSING_TH'
    td = parts[i] if i < len(parts) else 'MISSING_TD'
    
    # extract input class or identify td
    inp_m = re.search(r'class="([^"]*row-[^"]*)"', td)
    if inp_m:
        cls = inp_m.group(1)
    elif 'row-ai-status-badge' in td:
        cls = 'row-maktx (material desc)'
    elif 'deleteRow' in td:
        cls = 'btn-delete'
    else:
        cls = 'no-row-class'
    
    print(f'{i+1:03d} | TH: {th:<25} | TD: {cls}')
