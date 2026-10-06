import re

with open('Request/request_form.htm', encoding='utf-8') as f:
    text = f.read()

start = text.find('function addNewRowData(')
end = text.find('function removeRow(', start)
fn = text[start:end]

classes = re.findall(r'row-[a-z0-9_-]+', fn)
# unique while preserving order
seen = set()
ordered = []
for c in classes:
    if c not in seen:
        seen.add(c)
        ordered.append(c)

for idx, c in enumerate(ordered):
    print(f'{idx}: {c}')
