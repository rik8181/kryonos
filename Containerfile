# ============================================================
# KryonOS — Containerfile
# Alap: Bazzite (Fedora Atomic / ublue-os toolchain)
# Cél: SteamOS-szerű Windows-játék kompatibilitás (Proton/Steam Play)
#      + macOS-szerű "glass effect" KDE Plasma felület
# ============================================================

FROM ghcr.io/ublue-os/bazzite:stable

# ------------------------------------------------------------
# 1. Metaadatok / branding alapok
# ------------------------------------------------------------
LABEL org.opencontainers.image.title="KryonOS"
LABEL org.opencontainers.image.description="SteamOS/Bazzite-alapú, macOS-ihletésű asztali Linux disztribúció Windows-játék kompatibilitással"
LABEL org.opencontainers.image.vendor="KryonOS Project"

# ------------------------------------------------------------
# 1b. Kerülőút a bootc-image-builder #1188 hibájához (terra-mesa repó)
# ------------------------------------------------------------
COPY scripts/disable-terra-mesa-repo.py /tmp/disable-terra-mesa-repo.py
RUN python3 /tmp/disable-terra-mesa-repo.py \
    && rm -f /tmp/disable-terra-mesa-repo.py \
    && ostree container commit

# ------------------------------------------------------------
# 2. Csomagok: dock/blur/glass-effect függőségek, fontok
# ------------------------------------------------------------
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
COPY plymouth/kryonos /usr/share/plymouth/themes/kryonos

COPY kwin-theme/kryonos-glass-purple   /usr/share/aurorae/themes/kryonos-glass-purple
COPY kwin-theme/kryonos-glass-blue     /usr/share/aurorae/themes/kryonos-glass-blue
COPY kwin-theme/kryonos-glass-graphite /usr/share/aurorae/themes/kryonos-glass-graphite
COPY kwin-theme/kryonos-glass-red      /usr/share/aurorae/themes/kryonos-glass-red
COPY kwin-theme/kryonos-glass-green    /usr/share/aurorae/themes/kryonos-glass-green
COPY kwin-theme/kryonos-glass-pink     /usr/share/aurorae/themes/kryonos-glass-pink
COPY kwin-theme/kryonos-glass-orange   /usr/share/aurorae/themes/kryonos-glass-orange

COPY color-schemes /usr/share/color-schemes

# ------------------------------------------------------------
# 3b. Ikonkészlet: WhiteSur alap + saját brand-felülírások
# ------------------------------------------------------------
RUN git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/whitesur-icons \
    && cd /tmp/whitesur-icons \
    && ./install.sh -n KryonOS -t purple -p -d /usr/share/icons \
    && rm -rf /tmp/whitesur-icons \
    && ostree container commit

COPY icons/kryonos-brand-overrides/ /usr/share/icons/KryonOS/

# Ugyanezeket a hicolor (fallback) témába is bemásoljuk — így akkor is a
# KryonOS logó jelenik meg a tálcán/menüben, ha a Kickoff widget esetleg
# a hicolor-ból, nem az aktív témából próbálja betölteni.
COPY icons/hicolor-brand-overrides/ /usr/share/icons/hicolor/

# Alapértelmezett háttérkép (saját, egyedi KryonOS grafika)
COPY wallpaper/KryonOS /usr/share/wallpapers/KryonOS

# Alkalmazás-menü feliratok átbrandelése (pl. "Bazzite Portal" ->
# "KryonOS Portal") — CSAK a megjelenítési szöveget cseréli, a
# mögöttes parancsokat/Exec sorokat nem.
COPY scripts/rebrand-desktop-entries.py /tmp/rebrand-desktop-entries.py
RUN python3 /tmp/rebrand-desktop-entries.py \
    && rm -f /tmp/rebrand-desktop-entries.py \
    && ostree container commit

# SDDM bejelentkező képernyő
COPY sddm-theme/kryonos /usr/share/sddm/themes/kryonos
RUN mkdir -p /etc/sddm.conf.d \
    && printf '[Theme]\nCurrent=kryonos\n' > /etc/sddm.conf.d/kryonos-theme.conf \
    && ostree container commit

COPY dock/kryonos-plasma-defaults.sh /usr/libexec/kryonos-plasma-defaults.sh
COPY dock/latte/KryonOS.layout.latte /usr/share/kryonos/latte/kryonos-dock.layout.latte
COPY dock/kryonos-first-login.desktop /etc/xdg/autostart/kryonos-first-login.desktop

# ------------------------------------------------------------
# 4. Plymouth téma aktiválása + initramfs kényszerített újragenerálása
# ------------------------------------------------------------
RUN plymouth-set-default-theme -R kryonos \
    && chmod +x /usr/libexec/kryonos-plasma-defaults.sh \
    && dracut --force --regenerate-all \
    && ostree container commit

# ------------------------------------------------------------
# 5. /etc/os-release finomhangolása
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
