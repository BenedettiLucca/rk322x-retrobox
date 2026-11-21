# The lima RGB565 black-screen fix

Symptom: 32-bit cores (2048 = XRGB8888) displayed fine; **every RGB565 core
(PCSX-ReARMed, Snes9x, PicoDrive, mGBA...) rendered a permanently black screen**
while the pipeline was provably working (CRTC active, ~36 page-flips/s, lima
GEM_SUBMIT jobs streaming, core BIOS loaded, CD image parsed).

Proven early, to avoid re-chasing:
- `modetest -s 48:1920x1080-60 -v` showed color bars → HDMI/KMS fine
- RA with the 2048 core displayed → RA + GLES2 + shaders fine
- The PCSX run log showed `SET_PIXEL_FORMAT: RGB565` → only the 16-bit path broken

## Root cause (three layers deep)

RetroArch 1.22.2 `gfx/drivers/gl2.c` uploads software-core frames through up to
three different zero-copy/fast paths before the plain `glTexSubImage2D` one:

1. **`GL2_KMS_FRAMES` lend** (`egl_gbm_frames_attach` at the top of
   `gl2_renderchain_copy_frame`): the core's 16-bit buffer is attached directly
   to the texture as a GBM/EGLImage and the function **returns**. On lima,
   sampling an RGB565 EGLImage = black.
2. **EGL-images renderchain** (`GL2_CHAIN_FLAG_EGL_IMAGES`):
   `ctx_driver->image_buffer_write` then `glEGLImageTargetTexture2DOES`.
   For 565 frames `image_buffer_write` fails every frame →
   `[GL] Failed to create EGL image` → early return, texture never updated.
3. The regular GLES upload block declares 16-bit textures as internal
   `GL_RGB565`, which lima samples as black as well.

## The fix (all in `gl2.c`, guarded by `HAVE_OPENGLES`)

1. `gl2_renderchain_copy_frame`: skip the GBM lend when `base_size == 2`
   (`if (gl->kms_frames && gl->base_size != 2)`).
2. Renderchain setup: force `chain->flags &= ~GL2_CHAIN_FLAG_EGL_IMAGES` on GLES
   builds (the original condition was also accidentally made unconditional in an
   intermediate attempt — beware when re-patching).
3. `gl2_set_texture_fmts`: 16-bit case uses `GL_RGBA / GL_RGBA /
   GL_UNSIGNED_BYTE` (keeps `base_size = 2` so conversion logic still triggers).
4. New helper `gl2_rgb565_to_rgba8888()` widens the frame into `gl->conv_buffer`
   and uploads it from the **live GLES upload block** (the `#else` slow-path
   block further down in the file is dead code on GLES builds — a patch placed
   there compiles to nothing; ask me how I know).

Cost: ~2 ms/frame of CPU for the widening at PSX resolutions (640×478×60) —
nothing next to the emulation itself. All 16-bit cores now ride the same
proven path as 32-bit ones.

## Verification breadcrumb

The shipped patch logs one-shot lines on first frame:
`[lima] gl2_frame frame=... hw_fbo=0`, `[lima] copy_frame bs=2 chainflags=0`,
`[lima] widening 565->rgba8888 640x478`. If a future core shows black, check
those three lines first — they tell you exactly which path executed.

## Wrong turns (don't repeat)

- `internalFormat = GL_RGB` (unsized) for 565 → `GL: Invalid enum` at init,
  RA exits. Keep sized formats.
- Patching the desktop-only `#else` branch: never compiled on GLES.
- "Inverting" a flag condition with `#ifndef` around the checks: on GLES the
  bare `if (!(HW_RENDER_USE))` was always true → flag force-set.
- Two concurrent `make`s in one container (docker restart re-runs the original
  CMD) raced and produced a broken binary; also `-j8` under QEMU OOM-killed the
  container. Build once, `-j4`, in a fresh container.
