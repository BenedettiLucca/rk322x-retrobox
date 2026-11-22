# Benchmark methodology (issue #1)

This document defines the repeatable measurement procedure used for all performance
investigations in this repository. It is the single source of truth for scene
selection, run parameters, metrics, and privacy rules.

## 1. Principles

- **One variable at a time.** A/B runs differ only in the option under test.
- **Same scene.** Same game, save state / start point, BIOS, core, core options,
  global config, resolution, governor, audio settings and input state.
- **Warmup + equal windows.** 30 s warmup, then three 120 s measurement windows.
- **Real hardware only.** No llvmpipe, no desktop X11, no QEMU performance claims.
- **No redistributed assets.** ROMs, BIOS and save states stay on the box outside git.
  Only hashes, game names and sanitized logs are committed.
- **Thermal honesty.** The box reaches ~89 °C and thermally drops from 1.2 GHz to
  1.008 GHz within ~20 s of emulation. All results are **thermal-limited** by design;
  temperature and per-CPU frequency are recorded in every run.

## 2. Hardware and software under test

| Item | Value |
|---|---|
| Board | Tomate MCD-121, RK3229 (4× Cortex-A7) |
| RAM / swap | 970 MiB, 485 MiB zram |
| Kernel | `6.18.60-current-rockchip`, armv7l |
| GPU / driver | Mali-400 MP2, Lima 1.1.0, Mesa 25.0.7, libdrm 2.4.124 |
| RetroArch | 1.22.2 (git `7872266`), KMS + EGL + OpenGLES, GCC 14.2.0 32-bit |
| Display | HDMI-A-1, 1920×1080@60 (boot cmdline `video=HDMI-A-1:1920x1080@60De`) |
| Governor | `ondemand`, 1.2 GHz max / 1.008 GHz when throttled |
| Config | `/home/lucca/.config/retroarch/retroarch-kms.cfg` |

## 3. Fixed scenes

| ID | System | Core | Scene | Purpose |
|---|---|---|---|---|
| `psx3d-crash1` | PSX | `/usr/local/lib/libretro/pcsx_rearmed_libretro.so` | `Crash Bandicoot.chd`, first level / fixed save state | dense 3D, CPU-bound PCSX path |
| `psx3d-ctr` | PSX | same | `CTR - Crash Team Racing.chd`, fixed race | dense 3D, different renderer load |
| `psx2d-parappa` | PSX | same | `PaRappa the Rapper.chd`, first song | 2D + rhythm/audio-sensitive |
| `snes-sm` | SNES | `/usr/lib/arm-linux-gnueabihf/libretro/snes9x_libretro.so` | `Super Metroid (Japan, USA) (En,Ja).sfc`, fixed room | 16-bit RGB565 2D baseline |
| `gba-emerald` | GBA | `/usr/lib/arm-linux-gnueabihf/libretro/mgba_libretro.so` | `Pokemon - Emerald Version (USA, Europe).gba`, fixed scene | 16-bit RGB565 2D, different core |

PSX titles are CHD; `Crash Bandicoot 3 - Warped (Europe).bin` has no `.cue` and is not
used until a matching cue is generated. No ROM/BIOS bytes are stored in git.

## 4. Running a scene

From a host with SSH access to `root@192.168.0.216`:

```bash
ssh -o BatchMode=yes root@192.168.0.216 'bash -s -- \
  --core /usr/local/lib/libretro/pcsx_rearmed_libretro.so \
  --rom "/roms/roms/psx/Crash Bandicoot.chd" \
  --label psx3d-crash1-rep1 --frames 999999 --seconds 150 --strace' \
  < scripts/bench/run-scene.sh
```

`run-scene.sh`:

1. writes a temporary appended config containing `config_save_on_exit = "false"`
   (and any `--vsync` override), so the active config is never modified;
2. touches `~/.no-es` and terminates EmulationStation by full command line
   (the kernel truncates `comm` to `emulationstatio`, so `-x` matching fails);
3. waits for ES to exit and for DRM master to be released, then launches RA as
   `lucca` with a deliberately unreachable `--max-frames` and an outer
   `timeout` of `--seconds + 5` (default 150 s = 30 s warmup + 120 s window);
4. samples temperature, total CPU, RSS and per-CPU frequency every second;
5. optionally records `ioctl` and `openat` calls with `strace`;
6. captures the RA exit code into `status.json`, prints the log tail on failure,
   and always restores ES via `~/.no-es` removal + `systemctl restart getty@tty1`.

To measure raw throughput without VSync pacing, pass `--vsync false`; this is a
diagnostic A/B input for #6, not the default configuration.

## 5. Analysis

```bash
scp -r root@192.168.0.216:/tmp/bench/psx3d-crash1-rep1 bench/results/2026-11-21/
BENCH_WARMUP=30 python3 scripts/bench/analyze.py bench/results/2026-11-21/psx3d-crash1-rep1*
```

`analyze.py` discards the first `BENCH_WARMUP` seconds from both the 1 s samples and
the strace page-flip timestamps, then reports:

- **Delivered FPS**: mean/median/p95/p99 of DRM page-flip intervals. This counts
  frames actually presented to the display, not emulator internal frames.
- **CPU / thread**: total `%CPU` summed over `/proc/<pid>/task` threads.
- **Temperature and per-CPU frequency**: evidence of thermal throttling.
- **RSS**: approximate resident set of the RA process.
- **VA-bound frame splitting**: page-flip deltas > 5 ms are excluded from the
  interval table so long stalls do not corrupt the pacing statistics.

## 6. Metrics and interpretation

| Question | Metric | Caveat |
|---|---|---|
| Is the display pacing at 60 Hz? | page-flip interval mean/median/p99 | With VSync on, a slow core reduces this; it is not pure emulation speed. |
| Is the core CPU-bound? | CPU near one full thread, page flips equal core frames | A7 quad; a single dynarec thread near 100% points to emulation, not GPU. |
| Is thermal throttling active? | frequency dropping from 1200 to 1008 MHz, temp ≥ 88 °C | All current A/B runs are thermal-limited; compare only runs with similar profiles. |
| Is memory pressure present? | RSS, swap/zram, page faults (#11 later) | Not part of #1 baseline. |
| Are audio underruns occurring? | ALSA/RA log messages | Not yet instrumented; added in later issues when needed. |
| Where is time inside the frame? | core vs widening vs upload vs swap | Requires instrumented build (#4), not the production binary. |

`--max-frames` guarantees the number of core frames but its wall time includes startup;
`frames_per_s_wall` in `meta.json` is therefore **not** a raw throughput figure. Use
page-flip intervals (VSync on) or a dedicated instrumented build for that.

## 7. Completion criteria for #1

- This methodology document and `scripts/benchmark-collect.sh` exist.
- At least one baseline run per scene in §3, three reps each, 30 s warmup, 120 s window.
- Per run: exit status, page-flip statistics, temperature, CPU, RSS, frequency series.
- A Markdown summary ranks bottlenecks by evidence and states thermal limitations.
- No ROM, BIOS, save state, personal path or IP is committed.
