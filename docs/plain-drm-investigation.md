# #15 — RetroArch Plain DRM with direct RGB565 scanout (read-only phase)

Status: 2026-11-22 — complete with negative result. Both Plain DRM builds compiled and were deployed separately, but `video_driver="drm"` segfaults during video init before any page flip. No A/B is possible; keep the KMS/GLES2 stack.

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

## 6. Experiment 1 results (2026-11-22)

- The configure flag is `--enable-plain_drm` (underscore); `qb/config.params.sh` has
  `HAVE_PLAIN_DRM=no` by default. Two separate ARMv7 binaries were built from pinned
  RetroArch 1.22.2 and deployed without touching `/usr/local/bin/retroarch-kms`:
  - `/usr/local/bin/retroarch-plain-drm`: `--enable-plain_drm --enable-kms --enable-opengles ...`
  - `/usr/local/bin/retroarch-plain-drm-min`: `--enable-plain_drm --disable-kms --disable-opengles ...`
  Both report `Plain DRM - Video driver: yes` in `--features`.
- Smoke test with an appended `video_driver = "drm"` and the SNES 16-bit core (Super
  Metroid): both binaries **segfault (exit 139) immediately after
  `DRM_IOCTL_MODE_SETCRTC` succeeds**. Strace shows card0 open, capability set,
  resources/connector/CRTC queries, dumb-buffer create/addFB/mmap and SETCRTC all
  succeeding, then SIGSEGV at a null address. No `DRM_IOCTL_MODE_PAGE_FLIP` is issued.
- A menu-only launch (no core/game) segfaults identically, so the fault is in the
  plain-DRM video driver's init path, not in core loading or the RGB565 workaround.
- `dmesg` shows only repeated `EDID block 2 checksum is invalid` warnings from the
  mode set; no kernel Oops or Lima/rockchip-drm fault. This is a userspace crash in
  RetroArch's `gfx/drivers/drm_gfx.c`, reproducible with and without the KMS/EGL
  context compiled in.
- Source review of `drm_gfx.c` shows `drm_plane_setup()` requires an overlay plane
  with a compatible format and dereferences `plane_resources`/`plane` without a
  null check; on this RK3229 stack the plane setup path likely leaves one null.
  Investigating or patching that upstream code is out of scope for this issue's gate.

**Decision:** close #15 as completed-with-negative-result. Plain DRM is compiled and
active but never reaches a page flip, so direct RGB565 scanout cannot be proven or
measured here. The existing KMS + GLES2 + patched `gl2.c` path remains the only
working stack; the RGB565 conversion cost stays as a #4 measurement. No default,
config, DTB or kernel change was made; only two separate binaries were installed.
Do not retry unless a newer RetroArch revision fixes `drm_gfx.c` or a targeted
driver patch is funded/approved.
