# rk322x-retrobox

Everything done to turn a **Tomate MCD-121 TV box** (Rockchip RK322X: 4× Cortex-A7
@1.4 GHz, Mali-400 MP2, 1 GB RAM) into a GPU-accelerated retro emulation console
on mainline Linux (Armbian/Debian trixie, Mesa lima driver), driven by an
**Xbox 360 Wireless Controller**.

Host on LAN: `root@192.168.0.216` (`rk322x-box`), EmulationStation on tty1.

## Stack

| Layer | Choice | Why |
|---|---|---|
| OS | Armbian (Debian trixie, armv7) | mainline kernel = lima GPU driver |
| GPU driver | Mesa **lima** (GLES2 only) | Mali-400 Utgard; no Vulkan, no GLES3 |
| Frontend | EmulationStation (SDL2, own GLES2 context) | works on KMS/GBM out of the box |
| Emulator | **custom RetroArch 1.22.2**, KMS video + GLES2 | Debian's RA has no KMS driver and renders in software; see [docs/retroarch-lima-build.md](docs/retroarch-lima-build.md) |
| Cores | libretro buildbot `armv7-neon-hf` + Debian's | PCSX-ReARMed, Snes9x, PicoDrive, Genesis Plus GX, mGBA, Gambatte, Nestopia, mame2003+, FBNeo, DeSmuME 2015, Yabause, mednafen_pce_fast, 2048 (test) |
| Input | udev driver + autoconfig | see [docs/controller.md](docs/controller.md) |

## The big fix (read this first)

Debian's RetroArch had no KMS driver → llvmpipe software rendering → PSX
unplayable (~96 % of one core). We built RA with `--enable-kms --enable-opengles
--disable-opengl ...` and hit the real bug: **every 16-bit (RGB565) core rendered
a black screen** on lima. Root cause + fix: [docs/lima-rgb565-fix.md](docs/lima-rgb565-fix.md).
The patched source is [patches/gl2.c-lima-patched](patches/gl2.c-lima-patched),
the built binary is [bin/retroarch-kms](bin/retroarch-kms) (also installed on the
box at `/usr/local/bin/retroarch-kms`).

## Layout

| Path | Contents |
|---|---|
| `bin/` | final `retroarch-kms` binary (armv7, md5 `67b808f4959e0fac65a223914f6b0945`-lineage, see git log) |
| `patches/` | full patched `gfx/drivers/gl2.c` (drop-in for RA 1.22.2, git `7872266`) |
| `config/` | Xbox 360 Wireless Receiver autoconfig (udev indices decoded from evdev) |
| `docs/` | build instructions, lima fix writeup, controller mapping, display/mode notes |
| `scripts/` | deploy + direct-launch helpers used against the box |

## Current state on the box

- All 14 ES systems launch via `retroarch-kms --config ~/.config/retroarch/retroarch-kms.cfg`
- PSX frameskip restored to `0` (GPU does the scaling now)
- Hotkeys: **Guide+Start** = quit, **Guide+Select** = RA menu, **Start+Select** = RA menu (built-in combo)
- ES restart loop pauses via `~/.no-es` flag file while a game holds the display

## Known limits

- PSX is CPU-bound: emulated R3000A on 4×A7 lands at "playable, not perfect".
  Tuning knobs left to try: `pcsx_rearmed_psxclock`, SPU reverb off.
- Dreamcast/N64/PSP/DS-touch: no viable armv7 core or needs stylus.
- No Vulkan, no GLES3 → no glcore cores, no DuckStation/SwanStation HW render
  (and its dynarec loses to PCSX-ReARMed's NEON one on A7 anyway).
- Gamescope impossible (Vulkan-only compositor; PanVK doesn't cover Mali-400).

Related but separate: the `mcd121/` port kit in the `btv-b13-optimization` repo
(Nuvio 4K streaming work for the same hardware family).
