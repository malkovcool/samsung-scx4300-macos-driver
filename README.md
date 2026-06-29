# Samsung SCX-4300 driver for modern macOS (Apple Silicon & Intel)

A working CUPS print driver for the **Samsung SCX-4300** laser MFP on current
macOS — tested on **macOS 26 "Tahoe" (Apple Silicon)**. Apple, Samsung,
Homebrew and Gutenprint no longer ship a usable driver for this 2007-era
printer, so this repository builds and installs one from the open-source
**SpliX** project.

> The SCX-4300 speaks **QPDL** — a host-based raster language, *not* PostScript
> or PCL. The "driver" is therefore a CUPS filter (`rastertoqpdl`) plus a PPD:
> the Mac renders each page and streams compressed QPDL to the printer over USB.

---

## Compatibility

| | |
|---|---|
| **Apple Silicon (arm64)** | Prebuilt binary included — no build step needed. |
| **Intel (x86_64)** | Build from source with one command (`./build.sh`). |
| macOS | 11 – 26 (tested on 26.5). |
| Connection | **USB**. |

---

## Install — Apple Silicon (quick)

```sh
git clone https://github.com/malkovcool/samsung-scx4300-macos-driver.git
cd samsung-scx4300-macos-driver
sudo ./install.sh
```

The script installs the filter, **auto-detects the printer's USB address**, and
creates a print queue called **Samsung SCX 4300 Series**.

## Install — Intel, or if you prefer to build it yourself

```sh
git clone https://github.com/malkovcool/samsung-scx4300-macos-driver.git
cd samsung-scx4300-macos-driver
./build.sh          # needs Xcode CLT + Homebrew; installs jbigkit, builds the filter
sudo ./install.sh
```

---

## Printing

Pick **Samsung SCX 4300 Series** in any app's print dialog, or use the terminal:

```sh
echo "hello" | lp -d Samsung_SCX_4300_Series
lp -d Samsung_SCX_4300_Series file.pdf
```

---

## What gets installed

- `/usr/libexec/cups/filter/rastertoqpdl` — the driver (CUPS raster → QPDL).
- A CUPS queue `Samsung_SCX_4300_Series` pointing at
  `usb://Samsung/SCX-4300%20Series?serial=…` (your printer's serial, detected automatically).
- CUPS copies the PPD into `/etc/cups/ppd/`.

Nothing is written to SIP-protected locations, and the configuration survives reboots.

---

## Troubleshooting

**Nothing prints; `lpstat` says "Filter failed"; the log shows `Sent 0 bytes`.**
The filter is missing — most often because a macOS update wiped
`/usr/libexec/cups/filter`. Just re-run `sudo ./install.sh`.

**Inspect the logs:**

```sh
lpstat -p Samsung_SCX_4300_Series
tail -f /var/log/cups/error_log          # more detail: sudo cupsctl --debug-logging
```

A healthy job logs `(.../rastertoqpdl) exited with no errors` and
`Sent <N> bytes…` with **N > 0**.

**The USB address changed** (different port or printer). The installer
re-detects it automatically; to look manually:

```sh
lpinfo -v | grep -i scx-4300
```

**Vertical stripes, faint lines, or smudges on the page.** That is **hardware,
not the driver** — a software fault produces obvious garbage or wrong scaling,
not a single consistent line. On the SCX-4300 the drum is built into the toner
cartridge (`MLT-D109S`):

1. Remove the cartridge, gently rock it horizontally a few times to redistribute toner, reinsert.
2. Clean the narrow laser-scanner (LSU) window with a dry, lint-free cloth.
3. Inspect the green drum for scratches; replace the cartridge if it is worn.

---

## Uninstall

```sh
sudo ./uninstall.sh
```

---

## How it works / building from source

The driver core is **SpliX** (`rastertoqpdl`), originally by Aurélien Croc.
`build.sh`:

1. installs `jbigkit` (provides `libjbig85`) via Homebrew,
2. downloads the exact SpliX **2.0.1** source (Debian `splix_2.0.1.orig.tar.gz`),
3. repoints the build's MacPorts paths (`/opt/local`) to your Homebrew prefix
   (`/opt/homebrew` on Apple Silicon, `/usr/local` on Intel),
4. runs `make`.

The result is a native `rastertoqpdl` that links the system `libcups` /
`libcupsimage`; JBIG is statically linked, so the binary has **no Homebrew
runtime dependency** (only a build-time one).

The CUPS filter chain when you print:

```
app → PDF → cgpdftoraster (CUPS raster) → rastertoqpdl (QPDL) → usb backend → printer
```

---

## Credits & license

- Driver core: **SpliX** © Aurélien Croc (AP²C) and contributors —
  built here from the Debian `splix 2.0.1` source package.
- This repository just makes SpliX build and install cleanly on modern macOS,
  with auto-detection and a prebuilt Apple-Silicon binary for convenience.
- Licensed under the **GNU GPL v2** — see [LICENSE](LICENSE), same as SpliX.

The prebuilt binary is a convenience; reproduce it yourself anytime with `./build.sh`.

---
---

# 🇷🇺 Драйвер Samsung SCX-4300 для современного macOS

Рабочий драйвер печати для лазерного МФУ **Samsung SCX-4300** на актуальном
macOS (проверено на **macOS 26 «Tahoe», Apple Silicon**). Ни Samsung, ни Apple,
ни Homebrew, ни Gutenprint больше не дают пригодного драйвера для этого принтера
2007 года, поэтому здесь он собирается из open-source проекта **SpliX**.

> SCX-4300 говорит на языке **QPDL** (host-based растр, не PostScript и не PCL).
> Поэтому «драйвер» — это CUPS-фильтр `rastertoqpdl` плюс PPD: Mac растеризует
> страницу и шлёт сжатый QPDL в принтер по USB.

## Совместимость
- **Apple Silicon (arm64):** готовый бинарник уже в репозитории, собирать не надо.
- **Intel (x86_64):** сборка из исходников одной командой (`./build.sh`).
- macOS 11–26 (проверено на 26.5). Подключение — **USB**.

## Установка — Apple Silicon (быстро)
```sh
git clone https://github.com/malkovcool/samsung-scx4300-macos-driver.git
cd samsung-scx4300-macos-driver
sudo ./install.sh
```
Скрипт ставит фильтр, **сам находит USB-адрес принтера** и создаёт очередь
печати **Samsung SCX 4300 Series**.

## Установка — Intel (или если хочешь собрать сам)
```sh
git clone https://github.com/malkovcool/samsung-scx4300-macos-driver.git
cd samsung-scx4300-macos-driver
./build.sh          # нужны Xcode CLT + Homebrew; поставит jbigkit и соберёт фильтр
sudo ./install.sh
```

## Печать
Выбери **Samsung SCX 4300 Series** в окне печати любого приложения, либо в терминале:
```sh
echo "привет" | lp -d Samsung_SCX_4300_Series
lp -d Samsung_SCX_4300_Series файл.pdf
```

## Если печать пропала
Чаще всего после крупного обновления macOS очищается каталог фильтров —
просто запусти снова `sudo ./install.sh`. Диагностика:
```sh
lpstat -p Samsung_SCX_4300_Series
tail -f /var/log/cups/error_log          # подробнее: sudo cupsctl --debug-logging
```
Признак успеха в логе: `(.../rastertoqpdl) exited with no errors` и `Sent <N> bytes` с N > 0.
`Sent 0 bytes` + `Filter failed` — фильтра нет, запусти установку заново.

## Вертикальная полоса / разводы на бумаге
Это **железо, а не драйвер** (драйвер либо печатает верно, либо выдаёт явный
мусор, а не одну ровную полосу). На SCX-4300 барабан встроен в картридж
(`MLT-D109S`):
1. Вынь картридж, плавно покачай горизонтально, вставь обратно.
2. Протри узкое окно лазера (LSU) сухой безворсовой тканью.
3. Осмотри зелёный барабан на царапины; если изношен — замени картридж.

## Удаление
```sh
sudo ./uninstall.sh
```

## Лицензия
Ядро драйвера — **SpliX** © Aurélien Croc, собрано из Debian-пакета `splix 2.0.1`.
Этот репозиторий лишь адаптирует сборку и установку под современный macOS.
Лицензия — **GNU GPL v2** (файл [LICENSE](LICENSE)), как и у SpliX.
