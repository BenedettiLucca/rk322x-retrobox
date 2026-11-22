# Kernel, DTB and driver audit (issue #9)

## Read-only inventory (collected 2026-11-21)

- Kernel: `6.18.60-current-rockchip`, armv7l, SMP Fri Oct 30 12:06:41 UTC 2026.
- DTB compatible: `rockchip,rk3229`. Boot cmdline includes `video=HDMI-A-1:1920x1080@60De`.
- cpufreq: `cpufreq-dt`, governor `ondemand`, OPPs 600/816/1008/1200 kHz; thermal load lowers `scaling_max_freq` to 1008000 kHz.
- Thermal: `cpu-thermal` zone0, trip points 90/95/105 °C; observed 89 °C under short load.
- GPU: `lima 20000000.gpu`, Mali-400 MP2 version 1.1.0, devfreq `simple_ondemand` 200–400 MHz.
- Mesa 25.0.7, libdrm 2.4.124, EGL 1.7.0, GLES2 1.7.0.
- RGA: `rockchip-rga 20060000.rga`, HW 0x04.01, `/dev/video0` (see #16).
- DRM: card0 HDMI-A-1 (25 modes), card1 non-KMS, renderD128. Lima initializes cleanly; no DRM errors in dmesg.

## Decision

Do **not** change DTB, kernel, OPPs, voltages or regulators. Lima and HDMI are proven working by the color-bar and 2048-core tests (see `docs/lima-rgb565-fix.md`). The PSX bottleneck is CPU-side, not a driver misconfiguration. Any future Mesa/kernel experiment requires a full image backup and a tested removable-media/serial recovery path (#9 gate C). No proprietary Mali driver substitution.

## Deliverables

This document plus `bench/results/2026-11-21/system.json` are the version inventory with sanitized logs. Close #9 as a completed audit with a negative result for risky changes unless new evidence contradicts it.

## Result (2026-11-22)

- No DTB, kernel, OPP, voltage, regulator or boot-cmdline change was made. The only box
  change outside the repo was the ROMS fstab UUID fix and fsck (Phase 0), with backup.
- Lima 1.1.0 / Mesa 25.0.7 renders the 2048 (XRGB8888) core and color bars correctly;
  the 16-bit failure was isolated to three RetroArch `gl2.c` paths and worked around
  there (`docs/lima-rgb565-fix.md`). Plain DRM and native PCSX paths also failed in
  userspace (#15/#12), not in the kernel driver.
- Governor A/B (#2) showed thermal capping regardless of governor; kernel-side
  throttling is expected behaviour at 89–90 °C, not a misconfiguration.
- `dmesg` during all experiments showed only repeated harmless EDID checksum warnings
  and no DRM/Lima Oops or hotplug failure.
- Upstream bug report was not filed: no minimal, deterministic Mesa reproducer was
  produced (no compiler/GLES probe on the box; see #5). Negative result archived.

**Decision:** keep the current kernel/DTB/Mesa stack. Close #9 as completed with a
negative result for risky driver/kernel changes; revisit only with new evidence and a
tested recovery image.
