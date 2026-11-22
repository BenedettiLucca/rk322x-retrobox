# #5 — Lima/Mali-400 RGB565, EGLImage and upload-path investigation

Status: investigation plan. No console change yet.

## Hypothesis

The RGB565-to-RGBA8888 CPU widening in `patches/gl2.c-lima-patched` is a workaround for a Lima/GLES2 path that cannot sample 16-bit textures or 16-bit EGLImages. If Lima actually accepts `GL_RGB565` textures or GBM/EGLImage imports when the right internal format/modifier/stride is used, the widening (~2 ms/frame at 640x478x60) can be removed. If not, the workaround must stay and the negative result should be archived (and reported upstream if a real driver bug is reproduced).

## Evidence already collected

From `docs/lima-rgb565-fix.md` and `bench/results/2026-11-21/system.json`:

- Kernel `6.18.60-current-rockchip`, compatible `rockchip,rk3229`, Lima `1.1.0` (`mali400 version major 1 minor 1`), Mesa `25.0.7`, libdrm `2.4.124`, libEGL/libGLESv2 `1.7.0`.
- Three failed paths in RA 1.22.2 `gfx/drivers/gl2.c`:
  1. `GL2_KMS_FRAMES` GBM lend attaches the core 16-bit buffer as EGLImage; Lima samples black.
  2. EGL-images renderchain (`GL2_CHAIN_FLAG_EGL_IMAGES`): `image_buffer_write` fails every frame → `[GL] Failed to create EGL image`, texture never updated.
  3. Regular GLES upload declared 16-bit textures with internal format `GL_RGB565`; Lima samples black.
- Working path: keep `base_size=2` but force `GL_RGBA/GL_RGBA/GL_UNSIGNED_BYTE` and widen with `gl2_rgb565_to_rgba8888()` into `gl->conv_buffer`.
- Wrong turn already recorded: unsized `GL_RGB` internal format → `GL: Invalid enum`, RA exits. Keep sized formats.

## Step 1 — exact extension inventory

`eglinfo` and `es2_info` are not installed on the box. Either install them temporarily (approved diagnostic packages) or cross-build a small probe on the host with the pinned ARMv7 QEMU image. The probe must create the *same* KMS/GBM/EGL/GLES2 context RA uses and print:

- `EGL_VERSION`, `EGL_VENDOR`, `EGL_CLIENT_APIS`, `EGL_EXTENSIONS`.
- `GL_VERSION`, `GL_VENDOR`, `GL_RENDERER`, `GL_SHADING_LANGUAGE_VERSION`, `GL_EXTENSIONS`.
- Relevant extensions: `EGL_KHR_image_base`, `EGL_KHR_image_pixmap`, `EGL_KHR_gl_texture_2D_image`, `EGL_EXT_image_dma_buf_import`, `EGL_EXT_image_dma_buf_import_modifiers`, `GL_OES_EGL_image`, `GL_OES_EGL_image_external`, `GL_EXT_texture_format_BGRA8888`, `GL_OES_rgb8_rgba8`, `GL_OES_texture_half_float`.
- DRM mode and plane format list from `modetest -c`/`-p`; record connector/CRTC/plane names, not fixed IDs.

## Step 2 — minimal reproducer outside RetroArch

Build a standalone GLES2 program (not RA) that runs on the box with the KMS/GBM/EGL path and tests, in order:

1. **Control:** 32-bit RGBA8888 `glTexImage2D`/`glTexSubImage2D`, draw a textured quad, read pixels or use a known color-TV pattern; confirm Lima renders correctly.
2. **16-bit texture:** internal format `GL_RGB565`, format `GL_RGB`, type `GL_UNSIGNED_SHORT_5_6_5`; upload a test pattern; call `glGetError()` after every step; capture `dmesg` and any Mesa debug output (`MESA_DEBUG=1`, `LIBGL_ALWAYS_SOFTWARE=0`).
3. **Sized vs unsized:** repeat with `GL_RGB`/`GL_UNSIGNED_SHORT_5_6_5` only if step 2 is inconclusive; expect `Invalid enum` from past evidence.
4. **EGLImage path:** if the extension inventory allows it, create a GBM BO with `DRM_FORMAT_RG16`, import as EGLImage, bind with `glEGLImageTargetTexture2DOES`, render and check. Vary pitch/stride alignment and modifiers if exposed.
5. **Channel order/dataspace:** test RG16 vs BG16 and any `EGL_GL_COLORSPACE_*`/dataspace attributes the driver accepts.

Each case logs exact inputs, `glGetError()`/`eglGetError()`, renderer strings and dmesg. No ROM/BIOS involved.

## Step 3 — shader reconstruction alternative

If native 16-bit sampling is unavailable but a supported 32-bit texture is, evaluate a GLES2 fragment shader that reconstructs RGB565 bits from a widened RGBA8 texture (or sends packed bits through RGBA8 channels). Mali-400 is a GLES2/Utgard part with limited mediump/highp precision; bit-exact decomposition via `floor`/`fract` is **not** proven. Prioritize color fidelity over cleverness; any visual difference must be documented with comparison screenshots (captured outside git).

## Step 4 — decision and measurement

- If a native path works: produce a minimal, reversible `gl2.c` patch, run the same A/B as #4 (3 loads, same RA binary otherwise) and report delta ms/FPS plus no-black-screen checks for all RGB565 cores, 2048/XRGB8888, menu and resolution changes.
- If all paths fail: archive the reproducer, logs and format/path matrix; file an upstream Mesa/Lima bug with versions, reproducer and dmesg if the behavior looks like a driver bug; keep the widening workaround and state that native RGB565 on Lima is not viable here.
- Compare end-to-end cost against the CPU widening result from #4; do not introduce EGLImage/lend/`GL_RGB565` reintroduction.

## Close criteria

Format/path matrix with deterministic reproducer and logs; explicit keep-workaround / adapt-RA / open-Mesa-bug decision; evidence that all three original fixes stay intact.
