#!/usr/bin/env python3
"""
KryonOS — akcentszín-variáns generátor
========================================
A kwin-theme/_template/ mappában lévő sablonból (decoration.svg,
buttons.svg, metadata.desktop — placeholder színekkel) legyárt egy-egy
telepíthető Aurorae témát MINDEN itt felsorolt akcentszínhez, plusz
egy hozzáillő KDE globális színsémát (.colors) is, hogy a Rendszer-
beállítások → Színek alatt is kiválasztható legyen ugyanaz a tónus —
így nem csak az ablakkeret, hanem a teljes asztal (gombok, kijelölt
elemek, csúszkák, linkek) is követi a választott akcentet, pont úgy,
ahogy Windows 11 vagy macOS accent-color választója működik.

Futtatás:
    python3 generate_accent_variants.py

Új szín hozzáadása: bővítsd az ACCENTS listát egy (id, label, from, to)
sorral, majd futtasd újra a szkriptet.
"""

import os
import shutil

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE = os.path.join(ROOT, "kwin-theme", "_template")
KWIN_OUT = os.path.join(ROOT, "kwin-theme")
COLORS_OUT = os.path.join(ROOT, "color-schemes")

# (variant_id, megjelenített név, gradiens-kezdet, gradiens-vég)
ACCENTS = [
    ("kryonos-glass-purple",   "Purple Nebula",  "#a855f7", "#3b82f6"),  # alapértelmezett, a logóhoz igazítva
    ("kryonos-glass-blue",     "Arctic Blue",    "#38bdf8", "#2563eb"),
    ("kryonos-glass-graphite", "Graphite",       "#9ca3af", "#4b5563"),
    ("kryonos-glass-red",      "Crimson",        "#f87171", "#dc2626"),
    ("kryonos-glass-green",    "Emerald",        "#34d399", "#059669"),
    ("kryonos-glass-pink",     "Sakura",         "#f472b6", "#db2777"),
    ("kryonos-glass-orange",   "Sunset",         "#fb923c", "#ea580c"),
]


def hex_to_rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def build_kwin_theme(variant_id: str, label: str, accent_from: str, accent_to: str) -> None:
    out_dir = os.path.join(KWIN_OUT, variant_id)
    if os.path.exists(out_dir):
        shutil.rmtree(out_dir)
    shutil.copytree(TEMPLATE, out_dir)

    for fname in ("decoration.svg", "buttons.svg", "metadata.desktop"):
        fpath = os.path.join(out_dir, fname)
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()
        content = (
            content.replace("#ACCENT_FROM#", accent_from)
            .replace("#ACCENT_TO#", accent_to)
            .replace("#VARIANT_LABEL#", label)
            .replace("#VARIANT_ID#", variant_id)
        )
        with open(fpath, "w", encoding="utf-8") as f:
            f.write(content)

    print(f"  ✓ KWin/Aurorae téma: kwin-theme/{variant_id}/")


def build_color_scheme(variant_id: str, label: str, accent_from: str, accent_to: str) -> None:
    """
    Egyszerű KDE .colors séma, ami a Highlight/Link színeket az adott
    akcentre állítja. Ez a fájl a build alatt a
    /usr/share/color-schemes/ alá kerül (lásd Containerfile), onnan a
    Rendszerbeállítások → Megjelenés → Színek panelen választható.
    """
    os.makedirs(COLORS_OUT, exist_ok=True)
    accent_rgb = hex_to_rgb(accent_from)
    accent_rgb_str = ",".join(str(c) for c in accent_rgb)

    content = f"""[General]
ColorScheme=KryonOS {label}
Name=KryonOS {label}
shadeSortColumn=true

[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Selection]
BackgroundNormal={accent_rgb_str}
BackgroundAlternate={accent_rgb_str}
DecorationFocus={accent_rgb_str}
DecorationHover={accent_rgb_str}
ForegroundNormal=255,255,255
ForegroundActive=255,255,255
ForegroundLink=255,255,255

[Colors:Button]
DecorationFocus={accent_rgb_str}
DecorationHover={accent_rgb_str}

[Colors:View]
DecorationFocus={accent_rgb_str}
DecorationHover={accent_rgb_str}
ForegroundLink={accent_rgb_str}

[Colors:Window]
DecorationFocus={accent_rgb_str}
DecorationHover={accent_rgb_str}

[WM]
activeBackground=27,29,33
activeForeground=255,255,255
inactiveBackground=27,29,33
inactiveForeground=160,160,160
"""
    out_path = os.path.join(COLORS_OUT, f"KryonOS{label.replace(' ', '')}.colors")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"  ✓ Rendszer színséma: color-schemes/KryonOS{label.replace(' ', '')}.colors")


def main() -> None:
    print("KryonOS akcentszín-variánsok generálása...\n")
    for variant_id, label, accent_from, accent_to in ACCENTS:
        build_kwin_theme(variant_id, label, accent_from, accent_to)
        build_color_scheme(variant_id, label, accent_from, accent_to)
    print(f"\nKész: {len(ACCENTS)} akcentszín-variáns legyártva.")
    print("Új szín hozzáadásához bővítsd az ACCENTS listát ebben a fájlban.")


if __name__ == "__main__":
    main()
