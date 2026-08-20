#!/usr/bin/bash
# ============================================================
# KryonOS — alapértelmezett Plasma "macOS-glass" konfiguráció
# ============================================================
# Ezt a szkriptet a felhasználó első bejelentkezésekor futtatjuk
# (pl. egy .desktop autostart bejegyzésen keresztül), mert a
# kwriteconfig5-el végzett módosítások a felhasználói profilra
# vonatkoznak, nem az image-re.
# ============================================================

set -euo pipefail

# Csak az ELSŐ bejelentkezéskor fusson le — utána a felhasználó saját
# testreszabásait nem írjuk felül minden induláskor.
MARKER="$HOME/.config/.kryonos-defaults-applied"
if [ -f "$MARKER" ]; then
    exit 0
fi

# --- 1. KWin: Blur + átlátszóság (a "glass effect" alapja) ---
kwriteconfig5 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig5 --file kwinrc --group Plugins --key contrastEnabled true
kwriteconfig5 --file kwinrc --group Compositing --key Backend OpenGL
kwriteconfig5 --file kwinrc --group Compositing --key GLCore true

# --- 2. Ablak-dekoráció: alapértelmezett akcentszín-variáns ---
# (a logó lila→kék tónusát tükrözi; a felhasználó bármikor átválthat
# a Rendszerbeállítások → Ablak-dekorációk alatt a többi variánsra:
# kryonos-glass-blue / -graphite / -red / -green / -pink / -orange)
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 \
    --key theme "__aurorae__svg__kryonos-glass-purple"
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 \
    --key ButtonsOnLeft "XIA"
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 \
    --key ButtonsOnRight ""

# --- 2b. Rendszerszintű színséma összehangolása ugyanerre a tónusra ---
# (kijelölések, gombok, linkek is a KryonOS Purple Nebula sémát kapják;
# váltás: Rendszerbeállítások → Megjelenés → Színek)
plasma-apply-colorscheme KryonOSPurpleNebula 2>/dev/null || \
    kwriteconfig5 --file kdeglobals --group General --key ColorScheme "KryonOS Purple Nebula"

# --- 3. Globális menüsor (macOS-stílus: menü felül, nem az ablakban) ---
kwriteconfig5 --file kdeglobals --group "KDE Action Restrictions" \
    --key action/menubar true
# A "Global Menu" widget hozzáadását a panel-layoutban kell elvégezni
# (lásd docs/panel-layout.md — export/import-olható .layout.js fájllal)

# --- 4. Dock: NATÍV Plasma 6 panel, dock-szerűen konfigurálva ---
# (a Latte Dock helyett — lásd Containerfile 2. lépés magyarázatát:
# az upstream Latte nem támogatja hivatalosan a Plasma 6-ot). Ez a
# beépített panel-scripting API-t használja (ugyanaz, amit a Plasma
# saját "Panel Behavior" GUI-ja is használ a háttérben), hogy a
# meglévő alsó panelt lebegővé, középre igazítottá, csak-ikon módúvá
# tegye — vizuálisan közelítve a macOS dock-hatást, hivatalosan
# támogatott eszközökkel.
qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
    var allPanels = panels();
    for (var i = 0; i < allPanels.length; i++) {
        var p = allPanels[i];
        if (p.location == "bottom") {
            p.floating = true;
            p.alignment = "center";
            p.height = 58;
            p.lengthMode = "fit";
        }
    }
' 2>/dev/null || true

# --- 4b. [OPCIONÁLIS] Latte Dock NG (közösségi fork, Plasma 6.5+/
#     Wayland-only) — CSAK akkor fusson, ha a rendszeren telepítve van
#     (lásd docs/latte-dock-ng-optional.md). Ha nincs telepítve, ez a
#     blokk némán kihagyásra kerül, és a fenti natív panel marad
#     érvényben.
if command -v latte-dock-ng >/dev/null 2>&1; then
    mkdir -p "$HOME/.config/latte"
    cp /usr/share/kryonos/latte/kryonos-dock.layout.latte \
       "$HOME/.config/latte/KryonOS.layout.latte" 2>/dev/null || true
    kwriteconfig5 --file lattedockrc --group UniversalSettings \
        --key currentLayout "KryonOS"
    # Ha Latte NG fut, a natív panelt inkább rejtsük el, hogy ne legyen
    # két dock egyszerre.
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
        var allPanels = panels();
        for (var i = 0; i < allPanels.length; i++) {
            if (allPanels[i].location == "bottom") { allPanels[i].hiding = "autohide"; }
        }
    ' 2>/dev/null || true
fi

# --- 5. Lekerekített ablaksarkok + finom árnyék (kiegészíti a decor témát) ---
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 \
    --key BorderSize "None"

# --- 6. Ikonkészlet (WhiteSur-alap, KryonOS néven telepítve + saját
#        brand-logó felülírásokkal — lásd Containerfile 3b lépés) ---
kwriteconfig5 --file kdeglobals --group Icons --key Theme "KryonOS"

mkdir -p "$HOME/.config" && touch "$MARKER"
echo "KryonOS Plasma alapbeállítások alkalmazva. Jelentkezz ki/be a teljes hatáshoz."
