# Frontend overhead: ES, RGUI and minimal launcher (issue #19)

## Lifecycle facts

- ES autostart: `/home/lucca/.bash_profile` on `/dev/tty1` runs `while true; do if [ ! -f $HOME/.no-es ]; then export SDL_RENDER_DRIVER=software; /usr/local/bin/emulationstation; fi; sleep 2; done`.
- ES is restarted by getty@tty1; `~/.no-es` pauses the loop. `scripts/box.sh launch` touches `~/.no-es`, kills ES and runs RA directly as `lucca`, then removes `~/.no-es` and restarts `getty@tty1`.
- Kernel truncates `comm` to 15 chars (`emulationstatio`), so process matching must use `pkill -f '^/usr/local/bin/emulationstation'`, not `pkill -x`.
- Direct-launch harness `scripts/bench/run-scene.sh` implements this handoff safely and restores ES on exit.

## Gate 0 (decision point)

Measure three moments: ES menu idle 60 s, game launched through ES UI, and the same game/scene via direct launch with ES closed. Use ≥3 reps, ≥30 s warmup, 120 s windows and the #1 metrics. Record `ps`, `smaps_rollup` (RSS vs PSS), `free -h`, `/proc/pressure/memory` if available, CPU per thread, page-flip FPS and frametime. Control governor, temperature, game, core, options, resolution and audio. If residual ES private memory during games is negligible and FPS/frametime equals direct launch, do not justify a new launcher as an emulation optimization; only UX/boot motivation remains.

## Phase 1 quick wins

Test a light ES theme (no videos/artwork/animations, smaller thumbnails) and measure RAM, cold/warm boot and navigation responsiveness. Test RA RGUI + playlists with the current KMS/GLES2 build in an isolated config. Test an ES supervisor prototype (/systemd) that stops/respawns ES per game without duplicate instances. Keep ES default until stability and recovery are proven.

## Phase 2 (only if justified)

A minimal Rust + SDL2/KMSDRM launcher may navigate the 14 systems, favourites, recents and simple filters, with optional fixed-size cached covers. It must not include online scraping, complex DB, preview videos or heavy shaders in v1. The graphical UI should exit before launching a game; a separate tiny supervisor starts the app, waits for exit and restarts the launcher. Keep `es_systems.cfg` import compatibility and safe argument escaping. Build pinned ARMv7 hard-float with `-C target-cpu=cortex-a7` only if supported. Prototype in a separate branch with one-command SSH/keyboard rollback; never replace production ES or boot before that.

## Result (2026-11-22)

- The benchmark harness must stop ES (full command-line match) because ES holds DRM
  master; every game measurement was therefore taken with ES fully stopped. RetroArch
  RSS was ~102–117 MB and zram swap remained unused (#11). No frontend private memory
  was present during any measured game.
- We did not benchmark a game launched through the ES UI: ES and RetroArch cannot both
  hold DRM master on this box, and the safe handoff used by `scripts/box.sh` also stops
  ES. Thus there is no evidence that ES is resident during normal gameplay, and no
  evidence that replacing it would improve emulation FPS. All measured gains came from
  core/video options (#3/#6) under the same direct launch, independent of the frontend.
- Gate 0 conclusion: frontend replacement is **not** justified as an emulation
  optimization. Phase 1 (light theme, RGUI, supervisor) and Phase 2 (Rust PoC) were not
  implemented; they would be UX/boot-time work only, not performance work.
- `scripts/box.sh` was hardened (configurable `BOX`, no insecure SSH defaults, orderly
  ES shutdown) but production ES, getty autostart and ROM mapping remain unchanged.

**Decision:** close #19 with a negative result; keep EmulationStation. Reopen only for a
UX/boot-time goal with its own acceptance criteria, never as a claimed FPS fix.
