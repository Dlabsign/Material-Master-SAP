import re

with open('Request/request_form.htm', encoding='utf-8') as f:
    htm = f.read()

with open('Request/OnInputProcessing.abap', encoding='utf-8') as f:
    abap = f.read()

# Form data appends in saveStagingData
start = htm.find('function saveStagingData(')
end = htm.find('if (targetStatus === \'SUBMITTED\')', start)
save_fn = htm[start:end]
form_appends = re.findall(r"formData\.append\(\s*'([^']+)'\s*,", save_fn)

# Abap get_form_field
abap_gets = re.findall(r"ls_dtl-([a-zA-Z0-9_]+)\s*=\s*request->get_form_field\(\s*\|?([a-zA-Z0-9_]+)", abap)

print("Form appends count:", len(form_appends))
print("ABAP gets count:", len(abap_gets))

for idx, (dtl_field, req_field) in enumerate(abap_gets):
    # check matching form append
    expected_append = req_field.replace('{ idx_str }', 'i').replace('{ idx_str }', '1')
    print(f'{idx}: dtl-{dtl_field} <= {req_field}')
