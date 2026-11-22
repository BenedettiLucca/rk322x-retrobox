# PCSX-ReARMed options — issue #3

Date: 2026-11-21. All runs used the #1 harness (150 s = 30 s warmup + 120 s window,
3 reps, strace page flips, 1 s sampler). Every number is thermal-limited (~89–90 °C,
1.2 GHz → ~1.008 GHz).

## Core provenance

- Path: `/usr/local/lib/libretro/pcsx_rearmed_libretro.so`, 1,566,612 bytes,
  SHA256 `81f3b435d53ab50f646712939034a139f62ec7b6a11b6010b717629fddb9c0f0`.
- ELF 32-bit ARM, EABI5, hard-float ABI (`0x5000400`), BuildID
  `b142a0d0b29c342e51ef0dceece4f41249791833`, not stripped.
- `readelf -A`: `Tag_CPU_name: 7-A`, `Tag_CPU_arch: v7`, Thumb-2, VFPv3, NEONv1,
  VFP register args — an `armv7-neon-hf` build (details in `docs/core-build-audit.md`).
- Exposed options were confirmed from `strings` on the exact `.so`, not invented.
  This core has **no** `spu_thread`, `drc_thread` or GPU-software options; those
  parts of #3 are not applicable and were discarded.

## A/B results

| Option change | Scene | FPS baseline → variant | CPU baseline → variant | p95 baseline → variant | Decision |
|---|---|---:|---:|---:|---|
| `pcsx_rearmed_drc=disabled` | PSX 3D Crash Bandicoot | ~19.0 → 10.9 | ~96% → ~119% | ~105 ms → ~148 ms | Keep `enabled` |
| `pcsx_rearmed_drc=disabled` | PSX 2D PaRappa | 23.3 → 13.1 | ~86% → ~114% | ~80 ms → ~115 ms | Keep `enabled` |
| `pcsx_rearmed_neon_enhancement_enable=enabled` | PSX 3D Crash Bandicoot | ~19.0 → 8.86 | ~96% → ~115% | ~105 ms → ~270 ms | Keep `disabled` |
| `pcsx_rearmed_spu_reverb=disabled` | PSX 3D Crash Bandicoot | ~19.0 → 18.8 | ~96% → ~100% | ~105 ms → ~108 ms | Keep `enabled` (null result) |

All variants had `status=ok` and 3 reps (after fixing an SSH quoting bug and an ES
shutdown race in the harness). The original `PCSX-ReARMed.opt` was backed up and
restored; final read-back: `drc=enabled`, `neon_enhancement_enable=disabled`,
`spu_reverb=enabled`, `frameskip=0`, `psxclock=57`.

## Notes and limits

- Dynarec is essential: disabling it costs ~44% FPS on both 2D and 3D scenes and
  pushes CPU past one full core.
- The NEON "enhancement" option is a net loss on this core/build/SoC; it more than
  halves delivered FPS. This matches its reputation as a correctness/quality toggle
  rather than a speed toggle.
- SPU reverb off is within noise; no reason to degrade audio.
- `psxclock` alternatives (50/45/40), `frameskip=1`, and per-game GPU options were
  **not** A/B tested: no evidence of benefit, and these change timing/quality. Keep
  the conservative defaults; any change must be per-game with a visual check.
- The dynarec/NEON/SPU results are from one 3D scene plus one 2D scene for dynarec;
  PaRappa also covers the audio-sensitive case qualitatively (no underrun counter).

## Decision

Close #3 as completed-with-negative-result: the installed core is already the
best-performing supported configuration. No `.opt` change is recommended. Future
PSX gains must come from reducing CPU work elsewhere (#4 conversion, #6 pacing,
#7 compiler/build) or from cooling; no unsupported option keys were introduced.
