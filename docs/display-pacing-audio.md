# KMS/HDMI, VSync, threading and audio — issue #6

Date: 2026-11-22. Harness: #1 time-window method (150 s = 30 s warmup + 120 s window,
3 reps, strace page flips). All results are thermal-limited (~89–90 °C, 1.2 → ~1.008 GHz).

## Inventory (read-only)

- Connector 48 `HDMI-A-1` exposes 25 EDID modes: 1920×1080@60/50/24/120,
  1280×720@60/50/100/120, 720×480@59.94, 640×480@**75 only**, etc. Never select
  640×480@75 or 1080p120 (history of black screens).
- Active CRTC: 1920×1080@60, fixed by boot cmdline `video=HDMI-A-1:1920×1080@60De`.
- RetroArch config: `video_driver="kms"`, `video_fullscreen="false"` (no mode switch),
  `video_vsync="true"`, `video_threaded="false"`, `video_smooth="false"`,
  `video_frame_delay="0"`, `audio_driver="alsa"`, `audio_sync="true"`,
  `audio_latency="64"`.
- `modetest -c` lists connectors only; the live mode is in
  `/sys/kernel/debug/dri/0/state`. A plain `modetest -s 48:1280x720-60` while ES was
  paused did **not** change the CRTC (fbcon kept 1920×1080); a persistent mode-holder
  (`-v`) would fight RA for DRM master, so the 720p A/B was abandoned and 1080p60
  restored. No boot-cmdline change was made.

## A/B results (PSX 3D Crash Bandicoot unless stated)

| Variant | FPS (mean of 3, page flips) | p95 interval | CPU total | Temp mean/max | Decision |
|---|---:|---:|---:|---:|---|
| Baseline | ~19.0 | ~105 ms | ~96% | 88.8 / 90.0 °C | reference |
| `video_vsync=false` | 14.34 / 14.48 / 14.31 (~14.4) | ~123 ms | 96–100% | 86.7 / 88.6 °C | Reject: KMS pacing conflict |
| `video_threaded=true` | 27.76 / 27.59 / 27.45 (~27.6) | ~55 ms | 107–113% | 88.8 / 90.0 °C | Strong gain on PSX 3D |
| `video_threaded=true`, SNES Super Metroid | 24.61 / 24.57 / 24.49 (~24.6 vs 23.4 baseline) | ~65 ms (vs ~62) | 115–121% | 88.4 / 89.2 °C | Small gain, worse p95 |

| `audio_latency=128` | 18.99 / 19.09 / 19.14 (~19.07) | ~105 ms | 101–105% | 87.3 / 89.2 °C | Null result: keep 64 |

Audio underrun instrumentation is still absent, so the only measurable effect is the
null FPS/frametime result above; no claim about audible crackling can be made.

## Interpretation

- Disabling VSync is clearly harmful with this KMS backend: page flips drop from ~19/s
  to ~14/s. Keep `video_vsync=true`.
- Threaded video gives a reproducible **+45%** delivered FPS on the PSX 3D scene with
  much lower p95 frame interval (105 → 55 ms). CPU rises by ~10 points but stays
  within the thermal envelope. On SNES the gain is small (~+5%) and p95 is slightly
  worse, so any profile must be per-system.
- The gain is consistent with moving the blocking `eglSwapBuffers`/page-flip wait off
  the emulation thread; this directly addresses bottleneck #2 in `docs/baseline-results.md`.
- Input-lag and audio-glitch trade-offs could not be instrumented here (no frame-timing
  probe or underrun counter); a user-visible check is required before making
  `video_threaded=true` a global default.

## Decision

Close #6 as completed with a concrete optional profile and three null/blocked results:

- **Keep live defaults** `video_vsync=true`, `video_threaded=false`, `audio_latency=64`.
- **Optional PSX profile:** `video_threaded=true` (via `--append`) gives a reproducible
  ~+45% delivered FPS and lower p95 on PSX 3D, with ~10 points more CPU. Do not apply
  globally: SNES gain is small and p95 worsens slightly. Input lag/audio glitches were
  not instrumented, so this is opt-in pending a user-visible check.
- **Rejected:** `video_vsync=false` (~14 fps, KMS pacing conflict) and
  `audio_latency=128` (null FPS/frametime result).
- **Blocked:** 720p A/B — `modetest -s` cannot change the CRTC while fbcon holds it,
  and a persistent mode-holder would conflict with RA's DRM master. 1080p60 restored;
  no boot-cmdline or unsafe mode was used.
