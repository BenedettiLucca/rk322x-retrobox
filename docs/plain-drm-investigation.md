# #15 — RetroArch Plain DRM with direct RGB565 scanout (read-only phase)

Status: 2026-11-21 — Experiment 0 (read-only) complete; Experiment 1 (separate build) pending ARMv7 build capability.

## 1. Hypothesis

RetroArch 1.22.2 contains an independent `drm` video driver (`gfx/drivers/drm_gfx.c`) that can allocate `DRM_FORMAT_RGB565` dumb buffers and scan them out with `drmModeSetPlane`/page flips. If the Rockchip VOP plane accepts RGB565 and scales, `video_driver="drm"` could avoid both the CPU RGB565→RGBA8888 conversion (#4) and GLES texture upload. This is **not** zero-copy: dumb-buffer allocation/copy, extra buffers and page-flip overhead remain. It is a separate binary, not a default switch.

## 2. Experiment 0 — read-only DRM inventory

Collected from the box with `modetest -c`, `modetest -p`, `/sys/class/drm`, `uname`, package versions:

| Item | Value |
|---|---|
| Kernel | `6.18.60-current-rockchip`, armv7l, compatible `rockchip,rk3229` |
| DRM cards | `/dev/dri/card0` (KMS, HDMI-A-1), `/dev/dri/card1` (non-KMS), `/dev/dri/renderD128` |
| Connector | `HDMI-A-1`, id **48** (do not hardcode elsewhere), 25 EDID modes |
| Active CRTC | id 46, 1920×1080@60 |
| Known-good mode | 1920×1080@60; 1280×720@60 also in EDID |
| Never select | 640×480@75 (black-screen history), 1920×1080@120 |
| Primary plane | id 33, formats include `XR24 AR24 XB24 AB24 RG24 BG24` **RG16 BG16** NV12/NV21/NV16/NV61/NV24/NV42/NV15/NV20/NV30 |
| Overlay plane | id 38, also lists RG16/BG16 |
| Scaling | `modetest -p` did not expose an obvious scaling property; must be verified with atomic properties or by a test pattern. Listing RG16 does **not** prove usable RGB565 scanout. |
| Graphics stack | Mesa 25.0.7 (`libegl-mesa0`, `libgbm1`, `libgl1-mesa-dri`, `mesa-libgallium`), libdrm 2.4.124, lima 1.1.0 (Mali-400 MP2, gp/pp0/pp1) |

Commands (safe, read-only):

```bash
ssh -o BatchMode=yes root@192.168.0.216 'modetest -c | head -80'
ssh -o BatchMode=yes root@192.168.0.216 'modetest -p'
ssh -o BatchMode=yes root@192.168.0.216 \
  'for f in /sys/class/drm/card0-*/modes; do echo "== $f"; cat "$f"; done'
```

## 3. Experiment 1 — separate build (pending)

1. Pin the RetroArch revision to the exact current build: `1.22.2`, git `7872266`.
2. In the ARMv7 build container, run `./configure --help | grep -i drm` to find the flag that enables `HAVE_PLAIN_DRM` (do **not** assume `--enable-kms` enables it; the KMS EGL context and Plain DRM video driver are different code paths).
3. Build an additional binary, e.g. `retroarch-plain-drm`, with `video_drm` compiled in. Do not overwrite `/usr/local/bin/retroarch-kms` or the shared config.
4. Verify recognition: `retroarch-plain-drm --features | grep -i drm`; run with an isolated config (`video_driver="drm"`) and `--appendconfig` so `config_save_on_exit=false`.
5. Smoke test order: RGB565 2D core at native resolution (Snes9x + Super Metroid) → XRGB8888 core (2048) → PCSX-ReARMed. Validate colours, pitch/stride, aspect/viewport, page flips, audio, OSD/menu, Xbox controller, and ES return.
6. Recovery: `~/.no-es`, `systemctl restart getty@tty1`, serial console `ttyS2`, known-good 1080p60 boot cmdline. Never select modes outside EDID.

## 4. A/B plan (after smoke test)

Same core/ROM/BIOS/scene/governor/config, `run-scene.sh` with 30 s warmup + 120 s window, ≥3 reps. Compare against the GLES2 baseline (#1): delivered FPS from page flips, p95/p99 frametime, per-thread CPU, RSS, temp/freq, buffer-copy/page-flip time (strace DRM ioctls), visual glitches. A gain in frametime without a gain in emulation speed must be reported as such.

## 5. Gate / closure criteria

- Plain DRM compiled and active — no llvmpipe/GLES fallback (verify renderer/features).
- RGB565 plane/framebuffer/scaling proven or infeasibility documented with logs.
- PSX + 2D RGB565 video/input/audio/ES return correct.
- Quantitative comparison with the GLES stack, separating CPU conversion, copy and GPU work.
- Display/tty1 recovery and rollback tested **before** any default change.
- Only make it the default if there is a material gain and acceptable menu/shader/overlay trade-offs; otherwise close with a negative-result decision.
