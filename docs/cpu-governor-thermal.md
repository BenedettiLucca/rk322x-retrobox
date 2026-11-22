# #2 — CPU frequency, governor, thermal and GPU clocks (RK322x)

Status: inventory complete; governor A/B pending (will run after the #1 baseline matrix so the two experiments do not interfere).

## Inventory (2026-11-21, `scripts/bench/collect-system.sh`, `bench/results/2026-11-21/system.json`)

- SoC compatible: `rockchip,rk3229` (RK322X family), 4× Cortex-A7, kernel `6.18.60-current-rockchip`, armv7l.
- Boot cmdline fixes HDMI to `1920x1080@60De` and sets `coherent_pool=2M`; no GPU/CPU OPP overrides.
- cpufreq policy0: driver `cpufreq-dt`, governor `ondemand`, available governors `conservative ondemand userspace powersave performance schedutil`.
- Available OPPs: `600000 816000 1008000 1200000` kHz. `cpuinfo_max_freq = 1200000`, but at inventory time `scaling_max_freq = 1008000` and `scaling_cur_freq = 1008000` — the policy cap had already dropped from 1.2 GHz to 1.008 GHz under thermal load.
- Thermal zone0 `cpu-thermal`: 89.166 °C at inventory; trip points observed earlier: 90 °C, 95 °C, 105 °C. Short SNES smoke tests reached 89.2 °C and PSX 3D reached 90.0 °C, so all current measurements are thermal-limited (user-approved policy: proceed, document throttling).
- GPU devfreq `20000000.gpu`: governor `simple_ondemand`, `cur_freq = 400000000`, min 200 MHz, max 400 MHz. Lima 1.1.0 (`gp/pp0/pp1 mali400 version major 1 minor 1`) with 64 KiB L2.
- Memory: 970 MiB total, 485 MiB zram swap (little used), PSI near zero.
- DRM: `card0` is the KMS device (`RockChip Soc DRM`, driver `rockchip`); `card1` is not KMS. HDMI-A-1 (connector 48) exposes 1920×1080@60 and 1280×720@60 among its 25 modes, plus unsafe 640×480@75 and 1080p120 which must never be selected.

## A/B protocol (to run after #1)

1. Use one fixed scene (PSX 3D Crash Bandicoot) and the #1 time-window harness: 150 s = 30 s warmup + 120 s measurement, 3 reps per arm, strace page flips, 1 s sampler of per-CPU freq, temperature and CPU.
2. Arms, one variable at a time:
   - `ondemand` (as-found baseline; restore this at the end).
   - `performance` with `scaling_max_freq` left at the advertised `cpuinfo_max_freq` (1.2 GHz), never above it.
3. Before changing anything, save the exact original governor/min/max for every policy; after the last run restore them and verify with a read-back.
4. No voltage, OPP, DTB or boot-cmdline changes. No overclock. Stay within the 600–1200 kHz OPP list.
5. Stop and cool down if temperature exceeds ~90 °C for a sustained period; record any throttle transitions from the 1 s freq series.

## Deliverables

- 1 s time series and 2 min / 15 min snapshots for each arm (per-CPU freq, per-thread CPU, temp, delivered FPS).
- Table of real clocks/governor, throttling evidence and a reversible recommendation.
- Close as `completed` with the evidence; if `performance` gives no stable FPS gain under thermal throttling, close with a negative result recommending keeping `ondemand`.
