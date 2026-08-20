# KryonOS

SteamOS / Bazzite alapú, macOS-ihletésű asztali Linux disztribúció.

## ⚠️ Audit-eredmények (2026-08-04)

Átnéztem a projektet, összevetve azzal, amit a Bazzite ténylegesen
tartalmaz, a legkisebb részletekig. 3 valódi hibát/kockázatot
találtam és javítottam:

1. **Rossz Qt csomagnevek** — `qt5ct`/`plasma5-integration` szerepelt
   a Containerfile-ban, holott a Bazzite már Plasma 6 (Qt6) alapú.
   Javítva: `qt6ct` + `plasma-integration`.
2. **Veszélyes `/etc/os-release` felülírás** — az `ID=bazzite` mező
   kryonos-ra cserélése törhette volna a Bazzite belső mechanizmusait
   (ujust receptek, Bazzite Portal, hyfetch-alias), amik erre az ID-re
   támaszkodnak. Javítva: mostantól csak a NAME/PRETTY_NAME/LOGO
   cserélődik, az ID "bazzite" marad.
3. **A Latte Dock nem támogatja hivatalosan a Plasma 6-ot** (upstream
   KDE issue, megoldatlan; több disztró ki is vezette). Mivel a
   Bazzite Plasma 6-ot futtat, ez a legvalószínűbb pont, ahol a
   korábbi terv élesben elbukott volna. **Átterveztem:** az
   alapértelmezett dock-élmény mostantól a natív Plasma 6 panel
   dock-szerű konfigurációja (lebegő, középre igazított). A Latte NG
   community fork opcionálisan elérhető, lásd
   `docs/latte-dock-ng-optional.md`.

Amit **nem kellett** javítani, mert automatikusan öröklődik a
`FROM ghcr.io/ublue-os/bazzite:stable` base image-ből: Decky Loader,
HHD (Handheld Daemon), Gamescope session, ujust parancsrendszer,
Bazzite Portal, Bazaar app store, Distrobox, Waydroid, MangoHud,
vkBasalt, HDR/VRR, portolt SteamOS driverek/firmware-updaterek,
BTRFS SD-kártya patch-ek, SDGyroDSU, Homebrew-integráció — ezek mind
a base image részei, a mi rétegeink nem nyúlnak hozzájuk.

**Amit még mindig nem tudok garantálni valós tesztelés nélkül:** a
qdbus panel-scripting parancsok (`dock/kryonos-plasma-defaults.sh`),
az SDDM QML Qt6-kompatibilitása, és a Latte NG build-lépések — ezeket
mind jelöltem a kódban/dokumentációban "valós rendszeren ellenőrizendő"
megjegyzéssel.

---

- **Alap:** [Bazzite](https://bazzite.gg) (Fedora Atomic / ublue-os toolchain, immutable rendszer)
- **Játékkompatibilitás:** Steam + Proton/GE-Proton, ugyanaz a mechanizmus mint SteamOS-en
- **Felület:** KDE Plasma 6, macOS-szerű "glass effect" ablakok, globális menüsor, dock-szerű panel
- **Boot splash:** Plymouth téma a KryonOS logóval/névvel

## Könyvtárstruktúra

```
kryonos/
├── Containerfile                  # Fő image-definíció (Bazzite-ra épül)
├── .github/workflows/build.yml    # CI: image build + push + ISO generálás
├── plymouth/kryonos/              # Boot splash (logó + rendszernév)
│   ├── kryonos.plymouth
│   └── kryonos.script
├── kwin-theme/kryonos-glass/      # Aurorae ablak-dekoráció (glass effekt) — TODO
├── dock/
│   └── kryonos-plasma-defaults.sh # Első bejelentkezéskor futó beállító szkript
├── scripts/                       # Segéd build-szkriptek — TODO
└── docs/                          # Kiegészítő dokumentáció
```

## Gyors indulás — helyi build

```bash
# 1. Podman telepítése (ha még nincs)
sudo dnf install podman   # vagy: sudo apt install podman

# 2. Image build
cd kryonos
podman build -t localhost/kryonos:latest .

# 3. Tesztelés VM-ben (ajánlott: ne élő gépen próbáld ki először!)
#    A legegyszerűbb: bootc-image-builder-rel generálj egy QCOW2/ISO-t,
#    majd indítsd QEMU-ban.
```

## Amit még pótolni kell (a "TODO" lista)

A logó/wordmark/boot-spinner grafikák már készen vannak (lásd lent),
ezeket még saját magadnak kell elkészítened vagy beszerezned:

1. ~~`plymouth/kryonos/logo.png` + `wordmark.png`~~ — **kész**, a
   feltöltött KryonOS logóból kivágva és transzparens háttérrel
   kiexportálva
2. ~~`plymouth/kryonos/progress-1.png` … `progress-24.png`~~ — **kész**,
   egy márkaszínekkel (lila→kék) rajzolt "üstökös-farok" spinner
   animáció generálva
3. ~~Ikonkészlet~~ — **kész**, lásd lent
5. ~~Latte Dock layout~~ — **kész**, lásd lent

## Több akcentszín — nem csak egy "glass effect" (mint más OS-eken)

A `scripts/generate_accent_variants.py` a `kwin-theme/_template/` sablonból
**7 kész színvariánst** gyárt, mindegyik saját telepíthető Aurorae témaként
JELENIK MEG a Rendszerbeállítások → Ablak-dekorációk listában:

| Variáns ID | Név | Tónus |
|---|---|---|
| `kryonos-glass-purple` | Purple Nebula | lila→kék (alapértelmezett, a logóhoz igazítva) |
| `kryonos-glass-blue` | Arctic Blue | világoskék→sötétkék |
| `kryonos-glass-graphite` | Graphite | semleges szürke |
| `kryonos-glass-red` | Crimson | piros |
| `kryonos-glass-green` | Emerald | zöld |
| `kryonos-glass-pink` | Sakura | pink |
| `kryonos-glass-orange` | Sunset | narancs |

Ez a `color-schemes/` alá generált KDE `.colors` sémákkal párosulva **az
egész asztal** (kijelölések, gombok, linkek) is követi a választott
tónust — nem csak az ablakkeret, hanem rendszerszinten, ugyanúgy, ahogy
Windows 11 vagy macOS accent-color választója működik.

**Új szín hozzáadása:** nyisd meg a `scripts/generate_accent_variants.py`
fájlt, bővítsd az `ACCENTS` listát egy `(id, név, kezdőszín, végszín)`
sorral, majd futtasd újra:
```bash
python3 scripts/generate_accent_variants.py
```

## A `kryonos-glass` Aurorae téma (ablakkeretek) — már elkészült

A `kwin-theme/kryonos-glass/` mappa egy működő kiindulási Aurorae témát
tartalmaz, macOS-referencia alapján megtervezve:

- **`metadata.desktop`** — a téma regisztrációja, keret-vastagságok
  (32px címsor, vékony 1px oldalkeretek), gombméret/távolság
- **`decoration.svg`** — 9-patch sarkok/élek 12px sugarú lekerekítéssel,
  sötét, félig áttetsző alappal + finom felső highlight-csíkkal. **A
  tényleges blur/elmosás hatást ez NEM adja** (SVG erre nem képes) —
  azt a KWin compositor `blurEnabled=true` beállítása végzi (már
  bekapcsolva a `dock/kryonos-plasma-defaults.sh`-ban), az SVG csak
  a szín/forma réteget adja a blur fölé
- **`buttons.svg`** — a macOS "traffic light" gombok (piros/sárga/zöld),
  normal + hover állapottal (hoverkor megjelenik a ×/−/⤢ szimbólum,
  ahogy macOS-en is), plusz elszürkített inaktív-ablak variáns

**Telepítés teszteléshez:**
```bash
mkdir -p ~/.local/share/aurorae/themes/kryonos-glass
cp kwin-theme/kryonos-glass/* ~/.local/share/aurorae/themes/kryonos-glass/
# System Settings → Ablak-dekorációk → KryonOS Glass kiválasztása
```

**Finomítási pontok, ha élesben nem néz ki tökéletesen:**
- Az Aurorae SVG-motor kissé verziófüggő; ha a sarkok nem simulnak,
  nyisd meg Inkscape-ben és exportáld újra "Plain SVG" formátumban
- A gombok pozícióját (`ButtonMarginLeft`, `ButtonSpacing`) a
  `metadata.desktop`-ban lehet pixelre hangolni
- Ha teljesen natív macOS-mélységű blur kell (pl. dinamikus
  háttér-színkövetés), érdemes megnézni a **Bismuth** vagy egyedi
  KWin C++ effekt írását is — ez már túlmutat az Aurorae-n

## Ikonkészlet

Egy teljes, saját kézzel rajzolt ikonkészlet (több ezer app-ikon)
nem reális egy hobbiprojektben, ezért a gyakorlati megoldás egy
kétrétegű felépítés:

1. **Alaprétegben:** a [WhiteSur-icon-theme](https://github.com/vinceliuice/WhiteSur-icon-theme)
   (GPL-3.0, vinceliuice) — ez ad macOS Big Sur-stílusú kinézetet
   szinte minden alkalmazáshoz, telepítve `-t purple` (lila akcent, a
   KryonOS palettájához igazítva) és `-p` (KDE Plasma logó) kapcsolókkal,
   `KryonOS` néven (lásd Containerfile 3b lépés). **Ehhez semmit nem
   kell csinálnod** — build-időben automatikusan letöltődik és
   telepítődik.
2. **Brand-rétegben:** az `icons/kryonos-brand-overrides/` a saját
   K-logónkból generált ikonok, amik felülírják a rendszer-logó
   ikonokat (`start-here`, `distributor-logo`, `system-logo-fedora`) —
   ez jelenik meg pl. az alkalmazás-menüben vagy "About This System"
   nézetben.

**⚠️ Ismert korlát:** a K-logó egy részletes, 3D-s/metál grafika, ami
16-24px-es méretben (taskbar, kis ikonok) elmosódik/olvashatatlanná
válik — ezt leteszteltem, és őszintén jelzem: **nem néz ki jól ilyen
kis méretben**. A 48px+ méreteknél (asztali ikon, alkalmazásváltó,
"About System" ablak) viszont tisztán, élesen látszik. Ha ez zavaró,
egy egyszerűsített, lapos (kevesebb részlettel bíró) verziót érdemes
külön megrajzolni kifejezetten a kis méretekhez — ez már vektoros
grafikai munka, amit érdemes Inkscape-ben/Illustratorban elkészíteni.

**Licenc:** mivel a WhiteSur GPL-3.0 alatt van, és a teljes készletet
lényegében változtatás nélkül terjesztjük tovább, a KryonOS
ikon-rétegének is GPL-3.0-kompatibilisnek kell maradnia nyilvános
kiadás esetén — lásd `THIRD_PARTY_LICENSES.md`.

## SDDM bejelentkező képernyő

A `sddm-theme/kryonos/` egy QML-alapú, glassmorphism-stílusú
bejelentkező téma:

- **Glass kártya:** valódi háttér-elmosás (`ShaderEffectSource` +
  `FastBlur`), félig áttetsző sötét panel, ugyanaz a vizuális nyelv,
  mint az ablakkereteknél
- **Óra + dátum** felül, macOS lock screen stílusban
- **Két lágy, márkaszínű "glow" folt** a háttérben (lila/kék,
  a logó tónusaihoz igazítva)
- **Felhasználó-választó + jelszómező + session-választó**, és a
  bejelentkezés gomb a lila→kék akcent-gradienssel
- **Power gombok** (alvás/újraindítás/leállítás) jobb alsó sarokban

A `theme.conf`-ban állítható a háttérszín és az akcentszín — ha a
felhasználó a Latte/KWin résznél már beállított akcentszín-variánst
használ, ide is érdemes ugyanazt a hex-párt beírni, hogy a
bejelentkező képernyő is illeszkedjen.

**⚠️ Fontos, őszinte megjegyzés (ugyanaz a helyzet, mint a Latte
layout-nál):** az SDDM QML API Qt5 és Qt6 (Plasma 5 vs Plasma 6)
között **eltér** — pl. a `QtGraphicalEffects` modul Qt6 alatt
`Qt5Compat.GraphicalEffects` néven érhető el. A fájl most a Qt6/
Plasma 6 importot használja (a jelenlegi Bazzite ezt futtatja), de
**valós SDDM-teszt nélkül nem garantálom, hogy a blur-effekt és a
`sddm`/`userModel`/`sessionModel` globális objektumok pontosan úgy
viselkednek, ahogy leírtam** — az SDDM QML sandbox kicsit más
környezet, mint egy Plasma alkalmazás. Teszteléshez:

```bash
# Előnézet, tényleges bejelentkeztetés nélkül:
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/kryonos
```

Ha hibát dob (pl. hiányzó import vagy ismeretlen property), a hiba-
üzenet pontosan megmondja, melyik sort kell igazítani — ez tipikusan
gyors javítás, nem strukturális probléma.

## Dock

**⚠️ Terv-módosítás az audit után:** eredetileg Latte Dock-ot
terveztünk, de kiderült, hogy **az upstream Latte Dock nem támogatja
hivatalosan a Plasma 6-ot** (a Bazzite viszont már Plasma 6-ot
futtat) — lásd a fenti "Audit-eredmények" szekciót. Emiatt az
alapértelmezett megoldás mostantól a **natív Plasma 6 panel**
dock-szerű beállítása (lebegő, középre igazított, ezt végzi a
`dock/kryonos-plasma-defaults.sh` 4. lépése qdbus panel-scripttel).
Ez hivatalosan támogatott, nem igényel harmadik féltől származó,
bizonytalan jövőjű csomagot.

A `dock/latte/KryonOS.layout.latte` fájlt **megtartottam a repóban**,
mert:
- **Pozíció:** alul, középre igazítva (`alignment=2`)
- **Hover-zoom:** bekapcsolva, ~1.88x nagyítás rámutatáskor (`zoomLevel=88`)
- **Panel-átlátszóság + blur:** `panelTransparency=62`, `blurEnabled=true`
  — ez illeszkedik az ablakkeretek glass-hatásához
- **Alkalmazások:** Latte Spacer + Icon Tasks (futó/rögzített appok
  csoportosítva) + néhány előre rögzített indító (Dolphin fájlkezelő,
  Firefox, Steam, Konsole, Rendszerbeállítások)

...de ez **csak akkor releváns**, ha a `docs/latte-dock-ng-optional.md`
alapján telepíted a Plasma 6-kompatibilis community fork-ot (Latte
Dock NG). Anélkül ez a fájl jelenleg nem használható.

**⚠️ Fontos, őszinte megjegyzés a fájlról magáról:** a Latte `.latte`
layout fájl egy összetett KConfig formátum, amit ténylegesen a Latte
Dock maga generál GUI-s szerkesztéskor. Ezt a fájlt a dokumentált
formátum alapján, kézzel írtam meg — **valós KDE-munkameneten belüli
importálás előtt nem garantált, hogy 1:1 hibátlanul betöltődik**. Ha
az import után valami hiányzik vagy máshogy néz ki, a leggyorsabb
javítási út:

1. Importáld: `latte-dock-ng --import-layout dock/latte/KryonOS.layout.latte`
2. Ami nem stimmel, azt a Latte GUI-jában (jobbklikk a dockon →
   "Dock/Panel beállításai") igazítsd finomra
3. Exportáld vissza: Latte GUI → Layouts → Export, és cseréld le
   vele ezt a fájlt — így a következő build már a véglegesített
   verziót fogja tartalmazni

## Játékkompatibilitás (Windows-os játékok)

A Bazzite alap már tartalmazza:
- **Steam** natív telepítéssel
- **Proton** / **Proton-GE** (community fork, jobb kompatibilitás)
- **Gamescope** compositor (Big Picture / gamepad-mód, kézikonzol-szerű
  élményhez, ha valaha kézikonzol-hardverre is szánod)

Ezen a rétegen nincs teendőd — ez "ingyen" jön a Bazzite alapból.

## Branding lecserélése máshol

Az `/usr/lib/os-release` fájlt a Containerfile már felülírja, de érdemes
átnézni ezeket is, ha teljesen konzisztens brandinget akarsz:

- `/usr/share/plymouth/themes/kryonos/` — már kész (fenti TODO grafikákkal)
- GRUB boot menü szöveg/téma — `/boot/grub2/grub.cfg` generálásnál
- SDDM (bejelentkező képernyő) téma — kész, lásd a "SDDM bejelentkező képernyő" szekciót lent
- Alkalmazás "About" ablakok — általában az `/etc/os-release`-ből olvassák
  ki automatikusan, tehát ez már működik

## Frissítések — hogyan marad naprakész a KryonOS

A KryonOS **atomikus, image-alapú rendszer** (ugyanaz a modell, mint
Bazzite/Fedora Atomic): nem egyenként frissülnek a csomagok, hanem a
teljes rendszerkép cserélődik egységként, majd egy újraindítás
atomikusan átvált rá. A `/var` (felhasználói adatok) megosztott és
soha nem vész el frissítéskor; mindig van egy "előző, jó" deployment,
amire vissza lehet állni.

**Két külön frissítési kör van:**

1. **CI (a mi oldalunk):** a `.github/workflows/build.yml` hetente
   (hétfő hajnal) automatikusan újraépíti a KryonOS image-et a
   legfrissebb Bazzite alapból (`--pull=newer`), és felpusholja
   `ghcr.io/<felhasználó>/kryonos:latest` **és** egy dátumozott tag
   alá (pl. `:20260804`) — az utóbbi lehetővé teszi a régebbi,
   biztosan működő build-ekre való visszaállást.

2. **A végfelhasználó gépe:** miután egyszer rebase-elt a KryonOS
   image-re (lásd lent), az automatikus frissítés **magától a mi
   registry-nkből húz**, mert az `rpm-ostree`/`ublue-update` mindig
   azt a referenciát követi, amire a rendszer aktuálisan rebase-elve
   van — nem kell külön beállítani semmit, ez a Bazzite-tól örökölt
   mechanizmus generikusan működik bármilyen registry-re.

### Kezdeti telepítés / rebase egy meglévő Bazzite rendszerről

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/<felhasználó>/kryonos:latest
sudo systemctl reboot
```

### Frissítés (általában automatikus, de manuálisan is kikényszeríthető)

```bash
sudo rpm-ostree upgrade
sudo systemctl reboot   # csak az új deployment aktiválásához kell
```

### Visszaállás, ha egy frissítés problémát okoz

```bash
# Az előző (még bootolható) deployment-re állás:
sudo rpm-ostree rollback
sudo systemctl reboot

# Vagy: tartsd lenyomva Shift-et (BIOS) / Esc-et (UEFI) bootoláskor,
# és válaszd a GRUB menüben a "KryonOS — previous" bejegyzést
```

### Csomag-rétegezés (rpm-ostree layering) — óvatosan

A Containerfile-unkban lévő `RUN rpm-ostree install ...` lépések
**build-időben, a mi image-ünkbe** épülnek be — ez NEM ugyanaz, mintha
a végfelhasználó saját maga rétegezne csomagokat a saját gépén utólag.
Ha viszont a felhasználó saját maga is rétegez rá valamit
(`rpm-ostree install <csomag>`), azt érdemes tudnia:
- **lassítja a frissítéseket** (a rétegezett csomagokat minden
  frissítésnél újra kell komponálni a helyi RPM-ekből)
- **blokkolhatja a frissítést**, ha a rétegezett csomag függősége
  ütközik az új base image-mel — ilyenkor a csomagot el kell
  távolítani, hogy a frissítés folytatódhasson
- inkább Flatpak/Homebrew/Distrobox-ot érdemes használni mindenre,
  amire csak lehet, és az `rpm-ostree install`-t csak valódi
  rendszerszintű szükséglethez tartogatni — ez maga a Bazzite hivatalos
  ajánlása is, amit a KryonOS is örököl

## Következő lépések

1. Grafikai anyagok elkészítése (fenti TODO lista)
2. Aurorae glass-téma megírása
3. Helyi build + VM-es tesztelés
4. GitHub repo + Actions CI bekötése (a workflow már készen áll)
5. ISO generálás és USB-re írás valós hardveres teszthez
