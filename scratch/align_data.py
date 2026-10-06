with open('Request/OnInputProcessing.abap', encoding='utf-8') as f:
    abap = f.read()

import re
abap_gets = re.findall(r"ls_dtl-([a-zA-Z0-9_]+)\s*=\s*request->get_form_field\(\s*\|?([a-zA-Z0-9_]+)", abap)

line = 'UPL-MTXWW4\t1\t\tF\t\tHALB\tQTM001\tKG\tPlat MS QTS\tM3\tNORM\t2000\t2233\t33X37X190\tID\t1\tMWST\tNORM\t0001\t0001\tX\t200301\tSF01\t\t1\tS\t\tPD\tE\t1\t0\tM\tC1\tKP\t\t\tX\tX\t100\t\tZWH6\tGT1\tEX\t0\t20\t\t\t\t\t\t0001\t1\t\t0\t0\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tZMG1\t\t20.000,00\t20.000\t0\t\t0\t0\t0\t0\t\t0\tKG\t0\t0\t\t\t1\t\t\t0\t0\t0\t\t0\t0\t0\t\t\t1207\t0,0\t0,0\t\t\t\t4\tX\t\t\t\tX\tX\tX\tX\t\t1,14'
cols = line.split('\t')

print(f"Data columns: {len(cols)}")
# Also add req_no, item_no at beginning
all_fields = ['req_no', 'item_no'] + [f[0] for f in abap_gets]
print(f"All ABAP fields: {len(all_fields)}")

for i in range(max(len(cols), len(all_fields))):
    c_val = cols[i] if i < len(cols) else '<NO_DATA>'
    f_name = all_fields[i] if i < len(all_fields) else '<NO_FIELD>'
    if c_val != '' or f_name in ['stprs', 'verpr', 'peinh', 'vprsv', 'peinh_2']:
        print(f'{i:3d}: {f_name:15s} = [{c_val}]')
