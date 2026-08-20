# ============================================================
# KryonOS — Containerfile
# Alap: Bazzite (Fedora Atomic / ublue-os toolchain)
# Cél: SteamOS-szerű Windows-játék kompatibilitás (Proton/Steam Play)
#      + macOS-szerű "glass effect" KDE Plasma felület
# ============================================================
#
# Build (helyben, teszteléshez):
#   podman build -t localhost/kryonos:latest .
#
# Build (GitHub Actions-ben, ublue-os sablon alapján):
#   lásd .github/workflows/build.yml
#
# A base image cseréje:
#   - Asztali/kézikonzol jelleg (Steam Deck-szerű): ghcr.io/ublue-os/bazzite-deck:stable
#   - Általános asztali gép (nvidia GPU-val):        ghcr.io/ublue-os/bazzite-nvidia:stable
#   - Általános asztali gép (AMD/Intel GPU):          ghcr.io/ublue-os/bazzite:stable
# ============================================================

FROM ghcr.io/ublue-os/bazzite:stable

# ------------------------------------------------------------
# 1. Metaadatok / branding alapok
# ------------------------------------------------------------
LABEL org.opencontainers.image.title="KryonOS"
LABEL org.opencontainers.image.description="SteamOS/Bazzite-alapú, macOS-ihletésű asztali Linux disztribúció Windows-játék kompatibilitással"
LABEL org.opencontainers.image.vendor="KryonOS Project"

# ------------------------------------------------------------
# 1b. ⚠️ KERÜLŐÚT egy ISMERT, NYITOTT bootc-image-builder hibához
# (osbuild/bootc-image-builder issue #1188, kifejezetten Bazzite ellen
# bejelentve, 2026 január óta megoldatlan): az ISO-generálás
# "depsolve" fázisa elszáll, ha egy engedélyezett repó helyi
# fájl-elérési útra mutató GPG-kulcsot használ
# (gpgkey=file:///etc/pki/rpm-gpg/...), mert a bootc-image-builder
# saját depsolve-környezete nem éri el ezt a helyi fájlt, még ha az
# image-ben egyébként létezik is. A "terra-mesa" repó (kiegészítő
# multimédia-kodekek, amik már telepítve vannak a Bazzite alapban)
# ebbe a hibába fut.
#
# Megoldás: letiltjuk ezt a repót a saját image-ünkben. Ez NEM távolít
# el semmilyen már telepített csomagot — csak azt jelenti, hogy ez a
# repó többé nem lesz lekérdezve (se boot közben, se ISO-buildkor).
# Ha valaha kézzel akarnál `rpm-ostree install`-lal terra-mesa-s
# csomagot rétegezni, előbb vissza kell kapcsolnod:
#   sudo sed -i '/\[terra-mesa\]/,/^\[/{s/enabled=0/enabled=1/}' \
#     /etc/yum.repos.d/terra*.repo
RUN dnf config-manager --set-disabled terra-mesa 2>/dev/null \
    || dnf5 config-manager setopt terra-mesa.enabled=0 2>/dev/null \
    || grep -rl '\[terra-mesa\]' /etc/yum.repos.d/ | xargs -r sed -i \
        '/\[terra-mesa\]/,/^\[/{s/^enabled=1/enabled=0/}' \
    && ostree container commit

# ------------------------------------------------------------
# 2. Csomagok: dock/blur/glass-effect függőségek, fontok
# ------------------------------------------------------------
# ⚠️ JAVÍTVA (első build hiba alapján): a `plymouth-plugin-script`
# csomag hiányzott — enélkül a "script" Plymouth-motor (amit a
# kryonos.plymouth ModuleName=script sora kér) nem elérhető, és a
# `plymouth-set-default-theme -R kryonos` erre a hibára fut:
# "/usr/lib64/plymouth/script.so does not exist". Ez egy jól ismert,
# gyakori Fedora-hiba script-alapú Plymouth témáknál.
#
# ⚠️ AUDIT-MEGÁLLAPÍTÁS: a Latte Dock (upstream, KDE) NEM támogatja
# a Plasma 6-ot — a fejlesztők hivatalosan leállították a Plasma 6
# portolást (invent.kde.org/plasma/latte-dock issue #134, "Plasma 6
# port" — nyitva, nincs hivatalos megoldás), több disztró (pl. Solus)
# ki is vezette emiatt. Mivel a Bazzite már Plasma 6-ot futtat, a
# `latte-dock` csomag telepítése VALÓSZÍNŰLEG NEM FOG MŰKÖDNI vagy
# nem is lesz elérhető a repóban.
#
# Emiatt a dock-koncepciót ÁTTERVEZTEM: az alapértelmezett út mostantól
# a NATÍV Plasma 6 panel dock-szerű konfigurálása (lebegő, középre
# igazított, csak-ikon módú tálca) — lásd dock/kryonos-plasma-defaults.sh.
# Ez hivatalosan támogatott, stabil, és nem igényel harmadik féltől
# származó, kockázatos csomagot.
#
# Ha mégis a Latte-féle parabolikus zoom-animációt akarod, egy aktívan
# karbantartott KÖZÖSSÉGI FORK létezik kifejezetten Plasma 6.5+/Wayland
# alá: https://github.com/ruizhi-lab/latte-dock-ng (GPL-3.0). Ez NINCS
# benne a Fedora repókban, forrásból kell buildelni — lásd
# docs/latte-dock-ng-optional.md a build-lépésekért, ha ezt választod.
RUN rpm-ostree install \
        kvantum \
        kde-gtk-config \
        plasma-integration \
        qt6ct \
        plymouth-plugin-script \
    && ostree container commit

# ------------------------------------------------------------
# 3. Saját fájlok bemásolása az image-be
# ------------------------------------------------------------
# Plymouth boot splash (a rendszer neve/logója bootoláskor)
COPY plymouth/kryonos /usr/share/plymouth/themes/kryonos

# KWin / Aurorae ablak-dekoráció — MINDEN akcentszín-variáns bemásolva,
# hogy Rendszerbeállítások → Ablak-dekorációk alatt mind választható
# legyen (nem csak egy "glass effect", hanem több tónus is)
COPY kwin-theme/kryonos-glass-purple   /usr/share/aurorae/themes/kryonos-glass-purple
COPY kwin-theme/kryonos-glass-blue     /usr/share/aurorae/themes/kryonos-glass-blue
COPY kwin-theme/kryonos-glass-graphite /usr/share/aurorae/themes/kryonos-glass-graphite
COPY kwin-theme/kryonos-glass-red      /usr/share/aurorae/themes/kryonos-glass-red
COPY kwin-theme/kryonos-glass-green    /usr/share/aurorae/themes/kryonos-glass-green
COPY kwin-theme/kryonos-glass-pink     /usr/share/aurorae/themes/kryonos-glass-pink
COPY kwin-theme/kryonos-glass-orange   /usr/share/aurorae/themes/kryonos-glass-orange

# A megfelelő rendszerszintű színsémák (Rendszerbeállítások → Színek),
# hogy az egész asztal — gombok, kijelölések, linkek — kövesse a
# kiválasztott akcentet, nem csak az ablakkeret
COPY color-schemes /usr/share/color-schemes

# ------------------------------------------------------------
# 3b. Ikonkészlet: WhiteSur (GPL-3.0, vinceliuice) mint teljes
#     lefedettségű alap, "KryonOS" néven telepítve, lila akcenttel +
#     KDE Plasma logóval. Lásd THIRD_PARTY_LICENSES.md.
# ------------------------------------------------------------
RUN git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/whitesur-icons \
    && cd /tmp/whitesur-icons \
    && ./install.sh -n KryonOS -t purple -p -d /usr/share/icons \
    && rm -rf /tmp/whitesur-icons \
    && ostree container commit

# Saját brand-ikonok rétegezése a WhiteSur-alap TETEJÉRE: csak a
# rendszer-logó ikonokat (menü/start/about-system) írjuk felül a
# KryonOS K-monogrammal, minden más ikon a WhiteSur-ból marad.
COPY icons/kryonos-brand-overrides/ /usr/share/icons/KryonOS/

# SDDM bejelentkező képernyő (glass-kártya, akcentszín-gradiens gomb)
COPY sddm-theme/kryonos /usr/share/sddm/themes/kryonos
RUN mkdir -p /etc/sddm.conf.d \
    && printf '[Theme]\nCurrent=kryonos\n' > /etc/sddm.conf.d/kryonos-theme.conf \
    && ostree container commit

# Alapértelmezett Plasma beállítások (blur bekapcsolva, globális menüsor,
# dock pozíció, stb.) — lásd docs/plasma-defaults.md a részletekért
COPY dock/kryonos-plasma-defaults.sh /usr/libexec/kryonos-plasma-defaults.sh

# Latte Dock alapértelmezett layout (macOS-stílusú alsó dock, nagyítással)
COPY dock/latte/KryonOS.layout.latte /usr/share/kryonos/latte/kryonos-dock.layout.latte

# A fenti szkript automatikus futtatása minden felhasználó első
# bejelentkezésekor (XDG autostart bejegyzés)
COPY dock/kryonos-first-login.desktop /etc/xdg/autostart/kryonos-first-login.desktop

# ------------------------------------------------------------
# 4. Plymouth téma aktiválása + branding szkript futtatása build alatt
# ------------------------------------------------------------
RUN plymouth-set-default-theme -R kryonos \
    && chmod +x /usr/libexec/kryonos-plasma-defaults.sh \
    && ostree container commit

# ------------------------------------------------------------
# 5. /etc/os-release finomhangolása — CSAK a megjelenített nevet és
#    brandinget cseréljük, az ID mezőt SZÁNDÉKOSAN "bazzite" marad!
#
#    Miért? Mert a Bazzite számos belső mechanizmusa (ujust receptek,
#    a Bazzite Portal, a hyfetch logó-alias, a frissítő/rebase
#    szkriptek) az ID=bazzite értéket vizsgálja futásidőben, hogy
#    eldöntse, Bazzite-alapon fut-e. Ha ezt felülírnánk kryonos-ra,
#    ezek a beépített funkciók törhetnek — a felhasználó pl. nem
#    tudna a Bazzite Portal-lal frissíteni vagy Decky-t telepíteni.
#    A NAME/PRETTY_NAME/LOGO cseréje elég ahhoz, hogy a rendszer
#    mindenhol "KryonOS"-ként jelenjen meg (neofetch, About System,
#    stb.), miközben a Bazzite-kompatibilitás megmarad.
# ------------------------------------------------------------
RUN sed -i \
        -e 's/^NAME=.*/NAME="KryonOS"/' \
        -e 's/^PRETTY_NAME=.*/PRETTY_NAME="KryonOS (Bazzite alapon)"/' \
        -e 's/^LOGO=.*/LOGO=kryonos-logo/' \
        -e 's/^ANSI_COLOR=.*/ANSI_COLOR="0;38;2;168;85;247"/' \
        /usr/lib/os-release \
    && grep -q '^VARIANT=' /usr/lib/os-release \
        && sed -i 's/^VARIANT=.*/VARIANT="KryonOS Desktop"/' /usr/lib/os-release \
        || echo 'VARIANT="KryonOS Desktop"' >> /usr/lib/os-release \
    && ostree container commit
