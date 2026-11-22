# RGB565 → RGBA8888 NEON evaluation — issue #4

Date: 2026-11-22. Standalone microbenchmark on the RK322X box (Cortex-A7, ~1.0 GHz
thermal-limited). Source: `bench/rgb565-bench.c`; built in a pinned ARMv7 hard-float
container with `gcc -O2 -mcpu=cortex-a7 -mfpu=neon -mfloat-abi=hard`.

## Method

- Deterministic 565 pattern covering 5→8 and 6→8 expansion edges; every output is
  checked byte-for-byte against the scalar reference (`memcmp` each rep).
- 2000 reps per size; median/p95/min reported after sorting rep times.
- Sizes: 640×478 (PSX 640×478 frame), 641×479 (odd dimensions/tail path),
  320×240 (typical 2D core).
- NEON path uses `vld1q_u16` + shift/mask/narrow + `vst4_u8` (RGBA byte order) with a
  scalar tail for non-multiple-of-8 pixels.

## Results (median ms / p95 ms)

| Size | Scalar | NEON | Verdict |
|---|---:|---:|---|
| 640×478 (305,920 px) | 12.97 / 16.71 | 13.26 / 17.30 | NEON ~2% slower |
| 641×479 (307,039 px) | 13.10 / 16.52 | 13.36 / 16.76 | NEON ~2% slower; odd-tail correct |
| 320×240 (76,800 px) | 3.33 / 4.13 | 3.17 / 4.23 | ~5% faster median, p95 no better |

Pixel-perfect validation passed for all sizes and both paths, including 5→8/6→8
expansion, alpha=255 and odd-width tails.

## Interpretation and decision

- The NEON intrinsics are **not** a robust win on this Cortex-A7: no gain at PSX frame
  size, a small median-only gain at 320×240, and p95 unchanged or worse. The added
  complexity and maintenance cost are not justified.
- The standalone conversion itself costs ~13 ms at 640×478 on a thermally capped A7,
  higher than the earlier ~2 ms estimate in `docs/lima-rgb565-fix.md`. That estimate
  was not from this standardized microbench; this number is memory-bandwidth bound
  (source+dst+ref ~3.6 MB, well beyond the 64 KiB L2).
- This is a **converter** benchmark, not an in-RetroArch attribution: it does not
  separate emulation, `glTexSubImage2D`, draw and `eglSwapBuffers`. Those require the
  instrumented `gl2.c` build originally proposed in #4. With the large, reproducible
  gain already obtained from `video_threaded=true` (#6), no further RA patch was made.
- **Close #4 with a negative result for the NEON patch.** Keep the existing scalar
  `gl2_rgb565_to_rgba8888()` converter and all three RGB565 black-screen workarounds
  in `patches/gl2.c-lima-patched` untouched. No EGLImage/GL_RGB565 reintroduction,
  no buffer-management changes. If a future profiling effort shows conversion is the
  dominant cost, revisit with an instrumented build rather than this standalone NEON
  path.
