#!/usr/bin/bash
set -euo pipefail

MARKER="$HOME/.config/.kryonos-defaults-applied"
if [ -f "$MARKER" ]; then
    exit 0
fi

kwriteconfig5 --file kwinrc --group Plugins --key blurEnabled true
kwriteconfig5 --file kwinrc --group Plugins --key contrastEnabled true
kwriteconfig5 --file kwinrc --group Compositing --key Backend OpenGL
kwriteconfig5 --file kwinrc --group Compositing --key GLCore true

kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 \
    --key theme "__aurorae__svg__kryonos-glass-purple"
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 \
    --key ButtonsOnLeft "XIA"
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 \
    --key ButtonsOnRight ""

plasma-apply-colorscheme KryonOSPurpleNebula 2>/dev/null || \
    kwriteconfig5 --file kdeglobals --group General --key ColorScheme "KryonOS Purple Nebula"

kwriteconfig5 --file kdeglobals --group "KDE Action Restrictions" \
    --key action/menubar true

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

if command -v latte-dock-ng >/dev/null 2>&1; then
    mkdir -p "$HOME/.config/latte"
    cp /usr/share/kryonos/latte/kryonos-dock.layout.latte \
       "$HOME/.config/latte/KryonOS.layout.latte" 2>/dev/null || true
    kwriteconfig5 --file lattedockrc --group UniversalSettings \
        --key currentLayout "KryonOS"
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
        var allPanels = panels();
        for (var i = 0; i < allPanels.length; i++) {
            if (allPanels[i].location == "bottom") { allPanels[i].hiding = "autohide"; }
        }
    ' 2>/dev/null || true
fi

kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 \
    --key BorderSize "None"

kwriteconfig5 --file kdeglobals --group Icons --key Theme "KryonOS"

plasma-apply-wallpaperimage /usr/share/wallpapers/KryonOS/contents/images/1920x1080.png 2>/dev/null || \
    kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments \
        --group 1 --group Wallpaper --group org.kde.image --group General \
        --key Image "file:///usr/share/wallpapers/KryonOS/contents/images/1920x1080.png"

mkdir -p "$HOME/.config" && touch "$MARKER"
echo "KryonOS Plasma alapbeállítások alkalmazva. Jelentkezz ki/be a teljes hatáshoz."
