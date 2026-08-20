#!/usr/bin/env python3
"""
KryonOS build-segédszkript — letiltja a "terra-mesa" (vagy bármilyen,
"mesa" nevű szekciót tartalmazó, "terra"-hoz köthető) RPM repót.

Miért kell ez? Lásd a Containerfile 1b lépésének kommentjét: az
osbuild/bootc-image-builder projekt #1188-as, jelenleg is nyitott
hibája miatt az ISO-generálás elszáll, ha egy engedélyezett repó
helyi fájl-elérési útra mutató GPG-kulcsot használ
(gpgkey=file:///etc/pki/rpm-gpg/...), mert a bootc-image-builder
saját depsolve-környezete nem éri el ezt a fájlt.

Ez a szkript build-időben fut le a Containerfile-ból, majd a
Containerfile törli is a lemezről — nem marad a végleges image-ben.
"""

import re
import glob
import sys

changed_any = False

for path in glob.glob("/etc/yum.repos.d/*.repo"):
    with open(path) as f:
        content = f.read()

    if "terra" not in content.lower():
        continue

    # Szekciókra bontás (minden [section] fejléc új blokkot indít)
    sections = re.split(r"(?m)^(?=\[)", content)
    out = []
    file_changed = False

    for sec in sections:
        header_match = re.match(r"\[([^\]]+)\]", sec)
        if header_match and "mesa" in header_match.group(1).lower():
            if re.search(r"(?m)^enabled\s*=\s*1", sec):
                sec = re.sub(r"(?m)^enabled\s*=\s*1", "enabled=0", sec)
            elif not re.search(r"(?m)^enabled\s*=", sec):
                sec = sec.rstrip("\n") + "\nenabled=0\n"
            file_changed = True
        out.append(sec)

    if file_changed:
        with open(path, "w") as f:
            f.write("".join(out))
        print("Letiltva a mesa-kapcsolodo szekcio itt:", path)
        changed_any = True

if not changed_any:
    print("FIGYELEM: nem talalt terra/mesa szekciot letiltasra.")
    print("--- Az osszes talalt [szekcio] terra-tartalmu fajlokban (debug): ---")
    for path in glob.glob("/etc/yum.repos.d/*.repo"):
        with open(path) as f:
            content = f.read()
        if "terra" in content.lower():
            for h in re.findall(r"^\[([^\]]+)\]", content, re.MULTILINE):
                print(path, "->", h)
    sys.exit(1)
