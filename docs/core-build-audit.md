# Core build audit (issue #7)

## Current inventory (read-only, from `bench/results/2026-11-21/system.json`)

| System | Core | Path prefix | Size (B) | SHA256 (prefix) |
|---|---|---|---:|---|
| psx | PCSX-ReARMed | `/usr/local/lib/libretro/` | 1,566,612 | `81f3b435d53a` |
| nds | Desmume2015 | `/usr/local/lib/libretro/` | 2,419,304 | `d87e07fcdda8` |
| saturn | Yabause | `/usr/local/lib/libretro/` | 1,365,672 | `d64db835ec6b` |
| snes | Snes9x | `/usr/lib/arm-linux-gnueabihf/libretro/` | 1,532,420 | `dca37d718fa9` |
| nes | Nestopia | `/usr/lib/arm-linux-gnueabihf/libretro/` | 3,349,472 | `cb96adf6539d` |
| gba | mGBA | `/usr/lib/arm-linux-gnueabihf/libretro/` | 1,598,580 | `60d70f87eb58` |
| gb/gbc | Gambatte | `/usr/lib/arm-linux-gnueabihf/libretro/` | 255,788 | `e9dc0b41516b` |
| gg/ms | PicoDrive | `/usr/local/lib/libretro/` | 1,114,128 | `f2a52308c99c` |
| md | Genesis Plus GX | `/usr/lib/arm-linux-gnueabihf/libretro/` | 2,652,928 | `99ff56d5fb07` |
| pce | Mednafen PCE Fast | `/usr/local/lib/libretro/` | 694,832 | `43e2b9b5ee89` |
| arcade | MAME2003+ | `/usr/local/lib/libretro/` | 28,261,288 | `87fc4d4bc2ed` |
| fba | FBNeo | `/usr/local/lib/libretro/` | 42,172,504 | `19edf8cb16c4` |

`/usr/local/lib/libretro` cores are buildbot `armv7-neon-hf` lineage; `/usr/lib/arm-linux-gnueabihf/libretro` cores are Debian armhf packages. This must be confirmed on the box with `file`, `readelf -h -A`, and `ldd` before any A/B claim.

## Method

For each of 3–4 candidates (PCSX-ReARMed, Snes9x, mGBA, PicoDrive):

1. Record exact `.so` path, SHA256, package/commit/tag, `file`, `readelf -h -A`, `ldd`, core version, exposed options.
2. Confirm EABI hard-float, ARMv7, NEON from ELF attributes; do not force flags on dependencies.
3. Compare buildbot vs Debian vs a local source-equivalent build pinned to the same commit. Experimental flags: `-O2` vs `-O3`, `-mcpu=cortex-a7`, `-mfpu=neon-vfpv4` where supported, always `-mfloat-abi=hard`; LTO only if build/link is stable.
4. Benchmark with the #1 harness: same game/scene/BIOS/core options, ≥3 reps, 30 s warmup, 120 s window; record page-flip FPS, p95/p99 frametime, thread CPU, RAM, audio, save-state behaviour.
5. Keep local build scripts pinned with SHA256 and a rollback path. Never commit ROMs/BIOS.

## Decision gate

Only adopt a rebuilt core if it shows a reproducible gain without graphics/audio/save regressions. Otherwise close with a negative/untested matrix and keep the shipped core. Build capability: host Docker binfmt now supports `linux/arm/v7` (`docker run --rm --platform linux/arm/v7 debian:trixie uname -m` → `armv7l`).
