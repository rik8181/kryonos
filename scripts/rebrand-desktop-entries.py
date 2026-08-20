#!/usr/bin/env python3
"""
KryonOS build-segédszkript — a .desktop alkalmazás-parancsikonok
MEGJELENÍTÉSI szövegeiben ("Name=", "Comment=", "GenericName=", és
ezek lokalizált "Name[xx]=" változatai) lecseréli a "Bazzite" szót
"KryonOS"-ra.

FONTOS, SZÁNDÉKOS KORLÁTOZÁS: az Exec=, TryExec=, Icon=, Categories=
és minden egyéb sort SZÁNDÉKOSAN érintetlenül hagyja — ezek a tényleges
működést vezérlik (milyen parancsot futtat a menüpont), és ezeknek
törésmentesen kell maradniuk. Csak azt írjuk át, amit a felhasználó
ténylegesen LÁT a menüben.

Ez a szkript build-időben fut le a Containerfile-ból, majd a
Containerfile törli is a lemezről — nem marad a végleges image-ben.
"""

import glob
import re

DISPLAY_FIELD_PATTERN = re.compile(
    r"^(Name|Comment|GenericName)(\[[a-zA-Z_@.]+\])?=(.*)$"
)

SEARCH_DIRS = [
    "/usr/share/applications",
    "/usr/share/desktop-directories",
    "/etc/xdg/autostart",
]

changed_files = 0
changed_lines = 0

for base_dir in SEARCH_DIRS:
    for path in glob.glob(f"{base_dir}/**/*.desktop", recursive=True):
        try:
            with open(path, "r", encoding="utf-8", errors="strict") as f:
                lines = f.readlines()
        except (UnicodeDecodeError, FileNotFoundError):
            continue

        file_changed = False
        new_lines = []
        for line in lines:
            stripped = line.rstrip("\n")
            match = DISPLAY_FIELD_PATTERN.match(stripped)
            if match and "bazzite" in stripped.lower():
                # Csak a mező ÉRTÉKÉT írjuk át, a kulcsot/nyelvi taget nem
                key_part = stripped[: stripped.index("=") + 1]
                value_part = stripped[stripped.index("=") + 1 :]
                new_value = re.sub(
                    r"[Bb]azzite", "KryonOS", value_part
                )
                new_lines.append(key_part + new_value + "\n")
                if new_value != value_part:
                    changed_lines += 1
                    file_changed = True
            else:
                new_lines.append(line)

        if file_changed:
            with open(path, "w", encoding="utf-8") as f:
                f.writelines(new_lines)
            print(f"Átbrandelve: {path}")
            changed_files += 1

print(f"\nÖsszesen: {changed_files} fájl, {changed_lines} sor módosítva.")
