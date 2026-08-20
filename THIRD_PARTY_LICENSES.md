# Harmadik féltől származó komponensek

A KryonOS a következő nyílt forráskódú projekteket használja fel
(build-időben letöltve, nem másolva ebbe a repóba):

## WhiteSur-icon-theme
- **Szerző:** vinceliuice
- **Forrás:** https://github.com/vinceliuice/WhiteSur-icon-theme
- **Licenc:** GPL-3.0-or-later
- **Felhasználás módja:** teljes egészében, változatlanul telepítve
  (`install.sh -n KryonOS -t purple -p`), ez adja az ikonkészlet ~99%-át
- **Saját hozzáadás:** a `icons/kryonos-brand-overrides/` alatti fájlok
  felülírják a rendszer-logó ikonokat (`start-here`, `distributor-logo`,
  `system-logo-fedora`) a KryonOS saját K-monogramjával

Mivel a WhiteSur GPL-3.0 alatt van, és mi a teljes ikonkészletet
változtatás nélkül (csak pár fájl felülírásával) terjesztjük tovább,
a KryonOS ikon-rétegének is **GPL-3.0 kompatibilisnek** kell maradnia,
és a fenti attribúciót meg kell tartani nyilvános kiadás esetén.

## Bazzite / ublue-os
- **Forrás:** https://github.com/ublue-os/bazzite
- **Licenc:** lásd a Bazzite repo LICENSE fájlját
- A KryonOS Containerfile-ja ezt használja `FROM` base image-ként

## bootc-image-builder
- **Forrás:** https://github.com/osbuild/bootc-image-builder
- Az ISO-generáláshoz használt eszköz a CI workflow-ban
