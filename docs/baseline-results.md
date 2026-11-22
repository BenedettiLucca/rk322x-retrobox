# Baseline results — issue #1

Date: 2026-11-21. Box: `rk322x-box` (RK3229, 4× Cortex-A7, Mali-400/Lima, 1 GB).
Harness: `scripts/bench/run-scene.sh` + `scripts/bench/run-baseline.sh`, analyzed with
`BENCH_WARMUP=30 python3 scripts/bench/analyze.py`.

## Method

- 5 fixed scenes × 3 reps = 15 runs, all `status=ok` (exit 0 or expected 124 from the
  time-window `timeout`).
- Each run: 150 s wall = 30 s warmup (discarded in analysis) + 120 s measurement window.
- `--max-frames=999999` is deliberately unreachable; the outer `timeout` defines the window.
- `strace -e trace=ioctl,openat` records `DRM_IOCTL_MODE_PAGE_FLIP`; delivered FPS is derived
  from page-flip intervals, not from `--max-frames`.
- Sampler writes 1 s series of temperature, total CPU (thread sum), RSS and per-CPU frequency.
- Thermal policy (user-approved): proceed and document. Every run sat at the 90 °C trip and
  throttled from 1.2 GHz to ~1.008 GHz. **All numbers below are thermal-limited.**

## Results (mean across 3 reps)

| Scene | Delivered FPS (page flips) | p95 frame interval | p99 frame interval | CPU total | Temp mean/max | RSS |
|---|---:|---:|---:|---:|---:|---:|
| PSX 3D — Crash Bandicoot | 17.7 (19.0 / 15.0 / 19.0) | 124 ms | 168 ms | 96% | 88.8 / 90.0 °C | 106 MB |
| PSX 3D — CTR | 19.2 | 101 ms | 111 ms | 95% | 88.8 / 90.0 °C | 106 MB |
| PSX 2D — PaRappa | 23.3 | 80 ms | 96 ms | 86% | 89.0 / 90.3 °C | 104 MB |
| SNES — Super Metroid | 23.4 | 62 ms | 68 ms | 99% | 88.3 / 88.3 °C | 102 MB |
| GBA — Emerald | 27.0 | 55 ms | 63 ms | 95% | 88.7 / 88.8 °C | 117 MB |

Notes:

- The Crash Bandicoot `r2` outlier (15.03 fps, p99 266 ms) occurred during an early run with a
  concurrent stale process; `r1` and the clean `r3` rerun agree at ~19 fps.
- CPU total is the sum of all RetroArch threads and frequently exceeds one full core
  (~100–104%), indicating a single A7 thread saturated plus helper threads.
- Page-flip intervals are far from the 60 Hz HDMI refresh; the box is not GPU-fill limited at
  1080p60 (Lima scales without extra cost), it is waiting for emulated frames.
- Memory stays ~100–117 MB RSS with 485 MiB zram unused; no swapping or OOM observed.
- Audio underruns were not instrumented; per-stage frame-time attribution (emulation vs
  RGB565 conversion vs `glTexSubImage2D` vs swap/VSync) needs the instrumented build in #4.

## Bottleneck list, ordered by evidence

1. **CPU / thermal (strong evidence).** All scenes saturate one A7 thread (95–104% total CPU)
   and run at the 90 °C trip with clocks reduced to ~1.008 GHz. PSX 3D is the slowest at
   ~19 fps. Governor/OPP A/B is tracked in #2.
2. **Emulation throughput, not display fill (strong evidence).** Page flips track emulated
   frame production (19–27 fps) rather than a fixed 60 Hz cadence; 1080p60 HDMI is already
   active and Mali-400 scaling is not the limiter. VSync/threaded experiments are #6/#17.
3. **RGB565 conversion cost (unquantified).** The RGBA8888 widening in the patched `gl2.c`
   is present in every 16-bit core; its per-frame cost is not yet separated. #4 will measure it.
4. **Memory / I/O (low evidence of impact).** ~100–117 MB RSS, no swap use. #11 will collect
   disk/page-cache detail.
5. **Audio (not measured).** No underrun counter in the current harness; #6/#11 will add it.

## #1 closure checklist

- [x] `docs/benchmark-methodology.md` (method, scenes, safety)
- [x] `scripts/bench/collect-system.sh`, `run-scene.sh`, `analyze.py`, `run-baseline.sh`
- [x] `bench/results/2026-11-21/system.json` (version/hash/config inventory)
- [x] 5 scenes × 3 reps, 30 s warmup, 120 s windows, status/page flips/temp/CPU/RSS/freq
- [x] This bottleneck summary with thermal limitations
- [x] No ROM/BIOS/save-state/personal data or IP committed

**Recommendation:** close #1 as completed. The baseline is reproducible and sufficient to gate
the rest of Phase A; all downstream comparisons must use the same harness and state the
thermal limitation.
