import re

with open('c:\\Users\\ilyas\\Desktop\\project PFE\\circleback\\lib\\l10n\\app_localizations.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

getters = []
for i, line in enumerate(lines):
    match = re.search(r'String get (\w+) =>', line)
    if match:
        name = match.group(1)
        getters.append((name, i + 1))

seen = {}
duplicates = []
for name, line_num in getters:
    if name in seen:
        duplicates.append((name, seen[name], line_num))
    seen[name] = line_num

if duplicates:
    print("Found duplicates:")
    for name, line1, line2 in duplicates:
        print(f"  {name}: lines {line1} and {line2}")
else:
    print("No duplicate getters found.")
