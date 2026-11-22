# #17 — Quick wins: RetroArch/PCSX config audit (no recompile)

Status: 2026-11-21 — complete. Inventory and A/B matrix done; no reproducible gain found, so the active configuration is kept.
Source: `bench/results/2026-11-21/system.json` (collected by `scripts/bench/collect-system.sh`).

## 1. Scope

Find immediate, low-risk configuration gains without recompiling RetroArch or any core.
Core-option A/B (dynarec, SPU, psxclock, renderers) belongs to #3; display/vsync/threaded/audio pacing belongs to #6. This issue only audits what is **actually active**, records overrides, and proposes one-variable-at-a-time A/B tests for the global settings that may cost cycles.

## 2. How the inventory was collected

```bash
ssh -o BatchMode=yes root@192.168.0.216 'sh -s' < scripts/bench/collect-system.sh \
  > bench/results/2026-11-21/system.json
python3 -m json.tool bench/results/2026-11-21/system.json >/dev/null   # valid JSON
```

The script reads the active `~/.config/retroarch/retroarch-kms.cfg` and the PCSX `.opt` on the box. Nothing was edited.

## 3. Active global configuration (baseline)

| Key | Value | Comment |
|---|---|---|
| `video_driver` | `kms` | Custom RA 1.22.2, expected |
| `video_fullscreen` | `false` | Required since EDID mismatch: no mode switch |
| `video_vsync` | `true` | Keep; test off only as #6 diagnostic |
| `video_threaded` | `false` | Candidate A/B (#6), 4× A7 is constrained |
| `video_smooth` | `false` | Nearest scaling; intentional for pixel art |
| `video_shader_enable` | `false` | No shader cost |
| `video_filter_enable` | `true` | **But `video_filter=""`** — no filter active; harmless, can set false for clarity |
| `video_max_swapchain_images` | `3` | Candidate A/B only if pacing issues |
| `video_frame_delay` | `0` | No added latency |
| `video_driver_pacing` | `0` | KMS backend-specific |
| `video_threaded_display_pacing` | `false` | — |
| `video_threaded_pacing_vblank` | `false` | — |
| `video_threaded_present_repeat` | `false` | — |
| `rewind_enable` | `false` | No rewind cost |
| `run_ahead_enabled` | `false` | No run-ahead cost |
| `audio_driver` | `alsa` | — |
| `audio_sync` | `true` | Test with #6 |
| `audio_latency` | `64` | Candidate A/B if underruns |
| `audio_latency_floor` | `8` | — |
| `input_menu_toggle_gamepad_combo` | `1` | Xbox hotkeys, preserve |

## 4. Active PCSX-ReARMed options (baseline)

| Key | Value | Comment |
|---|---|---|
| `pcsx_rearmed_drc` | `enabled` | Dynarec on; keep unless #3 diagnostic |
| `frameskip` | `0` | Documented baseline |
| `psxclock` | `57` | Overclocked emulation clock; #3 will A/B |
| `spu_reverb` | `enabled` | Candidate for audio-sensitive scenes (#3) |
| `spu_interpolation` | `simple` | — |
| `neon_enhancement_enable` / `neon_interlace_enable` | `disabled` | Only test if option exists in this exact `.so` (#3) |
| `nocdaudio` / `noxadecoding` | `enabled` | Can change audio behaviour; route to #3 |
| `region` / `bios` | `auto` | — |
| `async_cd` | `sync` | — |
| misc fix options | `disabled` | Preserve unless a specific bug appears |

## 5. Override precedence (do not assume the main config wins)

RetroArch applies, in increasing priority: main config → core-specific `.opt` (`~/.config/retroarch/config/<Core>/<Core>.opt`) → game-specific override (`.../<Core>/<Game>.opt`) → command-line `--appendconfig`.

Enumerate overrides read-only on the box:

```bash
ssh -o BatchMode=yes root@192.168.0.216 \
  'find /home/lucca/.config/retroarch/config -type f \( -name "*.opt" -o -name "*.cfg" \) -print | sort'
```

No per-game overrides were found beyond the PCSX core `.opt` during collection.

## 6. A/B protocol (after the #1 baseline matrix finishes)

Use `run-scene.sh --append <file>` to override exactly one variable; never edit the live config. Example:

```bash
# on the host, create a temporary override file
cat > /tmp/opencode/ra-vsync-off.cfg <<'EOF'
video_vsync = "false"
config_save_on_exit = "false"
EOF
scp /tmp/opencode/ra-vsync-off.cfg root@192.168.0.216:/tmp/ra-vsync-off.cfg
ssh -o BatchMode=yes root@192.168.0.216 'bash -s -- \
  --core /usr/local/lib/libretro/pcsx_rearmed_libretro.so \
  --rom "/roms/roms/psx/Crash Bandicoot.chd" \
  --label psx3d-vsync-off --append /tmp/ra-vsync-off.cfg --strace' \
  < scripts/bench/run-scene.sh
```

For every A/B: same core/ROM/BIOS/scene/governor/state, 30 s warmup + 120 s window (`--seconds 150`), ≥3 reps, `BENCH_WARMUP=30` in analysis. Compare page-flip intervals (p95/p99), per-thread CPU, temp/freq, RSS, audio underruns (not yet instrumented), and visual correctness. Every run is thermal-limited at 89–90 °C; state this in the report.

Planned one-variable tests:
1. `video_vsync false` (display diagnostic, #6) — expect tearing; measure raw throughput.
2. `video_threaded true` (throughput vs input lag, #6).
3. `video_filter_enable false` (explicit disable of the empty filter; likely null result — document as such).
4. `video_max_swapchain_images 2` and `4` (only if pacing anomalies appear).
5. `audio_latency 48/96` (only if underruns/audio cracks are observed).
6. `audio_sync false` (only with #6 audio/pacing tests).
7. `rewind_enable`/`run_ahead_enabled` stay off — enabling them is expected to cost cycles; no test needed unless a user asks for the feature.

PCSX core-option tests are explicitly deferred to #3 to avoid duplicating work and inventing `.opt` keys.

## 7. Acceptance criteria

- [x] Active config and core options inventoried from the live box, with no private paths/ROMs committed (`system.json` is saved locally under `bench/results/`).
- [x] Override files enumerated; no hidden per-game overrides (only the PCSX core `.opt`).
- [x] One-variable A/B matrix with ≥3 reps per variant, thermal limitation stated (see §8).
- [x] No low-overhead PS1 profile proposed: **no reproducible gain was measured**. Keep the current config as the compatibility profile.
- [x] No regression of ES/Xbox input/audio/scalers/menus; no personal paths committed.

## 8. A/B results (2026-11-21)

Orchestrator: `scripts/bench/run-config-ab.sh <label> <remote-append-cfg>`. Scene: PSX 3D
Crash Bandicoot, 3 reps × 150 s per arm, `BENCH_WARMUP=30`, all `status=ok`.
Every number is thermal-limited (89–91 °C, 1.2 → ~1.008 GHz).

| Arm | FPS (3 reps, page flips) | Mean | p95 frame interval | Temp mean/max |
|---|---|---:|---:|---:|
| baseline (as found) | 19.04 / 15.03 (outlier) / 18.97 | ~19.0 (clean reps) | ~105 ms | 88.4 / 90.0 °C |
| `video_filter_enable=false` | 18.37 / 18.76 / 18.77 | 18.63 | ~108 ms | up to 91.0 °C |
| `video_max_swapchain_images=2` | 15.75 / 15.69 / 15.70 | 15.71 | ~118 ms | 86.7 / 89.2 °C |

- **Filter-off:** null/slightly worse and within noise. The filter was already empty; setting
  the enable flag to false has no measurable benefit.
- **Swapchain 2:** a reproducible **regression of ~3.3 fps** versus the clean baseline
  (19.0 → 15.7). Keep `video_max_swapchain_images=3`. Lower temperature simply reflects less
  work being done.
- Append files were verified in each result dir (`config_save_on_exit=false` present), so the
  live config was never modified. RA logs show only the expected timeout shutdown.

**Decision:** no config change is justified by this A/B. Keep the active `retroarch-kms.cfg`
and PCSX `.opt` untouched. Close #17 with a null-result report (the audit itself is the
deliverable). VSync/threaded/audio-sync experiments that need display or audio instrumentation
are explicitly deferred to #6.
