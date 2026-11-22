# #12 — Standalone PCSX-ReARMed vs RetroArch KMS frontend overhead

Status: investigation plan. No switch of default launcher.

## Hypothesis

Part of the PS1 CPU load may come from RetroArch's frontend/video/audio/menu layers rather than PCSX-ReARMed itself. A standalone PCSX-ReARMed build with a direct KMS/GBM/EGL/GLES2 backend could remove that overhead. The counter-hypothesis is that standalone PCSX on RK322x only has X11/SDL software paths, or that its code revision/compiler differs enough that any FPS delta is not frontend overhead.

## Constraints

- Do not assume a native KMS backend exists. Inspect the upstream source at a pinned revision before building anything.
- The installed libretro core is `pcsx_rearmed_libretro.so` (SHA256 in `system.json`); a standalone binary will not be bit-identical. Any comparison must separate frontend overhead from revision/compiler/options differences.
- Must keep GLES/Lima acceleration, Xbox 360 controller, audio, user BIOS/ROM, no X11/Wayland desktop and no llvmpipe software fallback.

## Step 1 — backend feasibility (read-only)

On the host, clone the pinned PCSX-ReARMed upstream revision and inventory:

- Linux backends in the source tree (`frontend/`, platform directories): does it support KMS/DRM/GBM/EGL directly, or only X11/SDL/fbdev?
- Which renderer paths exist (GLES2 vs desktop GL vs software) and which libraries they require.
- Build system and flags; whether a 32-bit ARMv7 hard-float cross build is realistic with the pinned QEMU image.
- Controller/audio dependencies; whether Xbox 360 wireless via xpad/evdev works without X11.
- Record exact commit, submodules and dependency versions.

If no accelerated KMS/EGL/GLES2 path exists, close this track with a negative result: standalone is infeasible without X11/software rendering, which would violate the project constraints.

## Step 2 — instrument the current Libretro path

Use the #1 harness and, where possible, `strace -tt -e trace=ioctl` to separate time inside the core from:

- `glTexSubImage2D`/RGB565 widening (already attributed in #4),
- `eglSwapBuffers`/DRM page flips,
- audio callback/ALSA writes,
- menu/input polling.

`perf` is not installed; if PMU access is unavailable, state that instrumentation is absent and rely on ioctl timing plus CPU totals. Do not claim per-function attribution without a measurement.

## Step 3 — controlled comparison (only if Step 1 is feasible)

If a standalone accelerated build exists:

- Use the same PCSX source revision where possible, same `SCPH1001.BIN`, same game/CHD, same fixed scene, same resolution/viewport, same governor, same audio settings, same media.
- Run ≥3 reps per side with the #1 methodology (30 s warmup, 120 s measured window, time-based `timeout`), record effective FPS/page flips, p95/p99 frametime, per-thread CPU, audio underruns, input latency and temperature.
- Compare menu, input, save states, save/load, media swap, hotkeys and ES/tty1 lifecycle — not FPS alone.
- Verify from logs that Lima is the renderer (no llvmpipe/software fallback).

## Step 4 — decision

- If standalone is equivalent or infeasible: close with evidence; future optimization belongs in Libretro/RA.
- If standalone gives a material, reproducible gain without regressions: document exact build/deploy, rollback to RA, and do not change the default solely on FPS.

## Close criteria

Backends identified or infeasibility documented; GPU acceleration proof; side-by-side numbers with no software fallback; explicit decision (stay RA / alternative) with rollback.
