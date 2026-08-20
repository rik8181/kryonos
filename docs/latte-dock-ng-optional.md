# [Opcionális] Latte Dock NG telepítése

**Ez nem szükséges** a KryonOS működéséhez — az alapértelmezett dock-
élményt a natív Plasma 6 panel adja (lásd `dock/kryonos-plasma-defaults.sh`).
Ezt csak akkor olvasd, ha kifejezetten a Latte-féle parabolikus
zoom-animációt akarod, és hajlandó vagy egy harmadik féltől származó
community fork-ot forrásból buildelni.

## Háttér

Az upstream KDE Latte Dock **hivatalosan nem támogatja a Plasma 6-ot**
(lásd: https://invent.kde.org/plasma/latte-dock/-/issues/134 — nyitva,
megoldatlan). Több disztró (pl. Solus) ezért ki is vezette.

Létezik viszont egy aktívan karbantartott közösségi fork:
**Latte Dock NG** (https://github.com/ruizhi-lab/latte-dock-ng),
kifejezetten Plasma 6.5+ / Wayland-only célra, GPL-3.0 licenc alatt.

## Build lépések (Fedora Atomic / Bazzite alapon)

```bash
# Build-függőségek (csak az image-build alatt, nem marad a végleges
# rendszerben, ha layered csomagként telepíted)
sudo rpm-ostree install cmake extra-cmake-modules qt6-qtbase-devel \
    kf6-plasma-devel kf6-kwindowsystem-devel git

git clone https://github.com/ruizhi-lab/latte-dock-ng.git
cd latte-dock-ng
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
sudo make install
```

**⚠️ Ezt nem teszteltem valós Bazzite/Fedora Atomic rendszeren** — a
fenti a projekt saját build-dokumentációja alapján összeállított,
általános CMake-es minta. Az immutable (rpm-ostree) rendszereken a
`make install` közvetlen futtatása a `/usr` alá **nem ajánlott
gyakorlat** (az ostree commit-rendszeren kívül esik, frissítéskor
elveszhet) — helyesebb megoldás egy saját RPM csomag készítése és azt
a Containerfile-ban `rpm-ostree install`-lal telepíteni, vagy a
buildet Containerfile `RUN` lépésként elvégezni image build-időben.

Ha ezt az utat választod, és sikerül működésre bírnod, a
`dock/kryonos-plasma-defaults.sh` már tartalmaz egy előkészített
`if command -v latte-dock-ng` ágat, ami automatikusan átvált rá.
