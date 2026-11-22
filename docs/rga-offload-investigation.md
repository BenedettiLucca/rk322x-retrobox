# #16 — Rockchip RGA availability and conversion-offload viability

Status: 2026-11-21 — Stage 1 (read-only presence check) complete; Stage 2 (ROI reproducer) pending.

## 1. Question

The RK322X may expose a Rockchip RGA 2D engine for copy/format-conversion/scaling. If it is usable from userspace, it might offload the RGB565→RGBA8888 conversion. But setup/import/wait costs may exceed the ~2 ms/frame scalar conversion (#4), especially at PSX 240p frame sizes. Presence alone proves nothing.

## 2. Stage 1 — read-only findings (from `system.json` and box inspection)

| Item | Value |
|---|---|
| SoC | `rockchip,rk3229` (RK322X family) |
| Kernel | `6.18.60-current-rockchip`, armv7l |
| DT node | `/proc/device-tree/...` / sysfs `20060000.rga` present |
| Driver | `rockchip-rga 20060000.rga: HW Version: 0x04.01` |
| Devices | `/dev/video0` is the RGA; `/dev/video1-3`, `/dev/video-dec1`, `/dev/video-dec3` also present |
| lsmod/dmesg | RGA driver bound; `rockchip-pm-domain ... sync_state() pending due to 20060000.rga` |
| Tooling | `v4l2-ctl` **absent** on the box; can be temporarily installed (approved) |

Read-only commands used:

```bash
ssh -o BatchMode=yes root@192.168.0.216 'uname -a; tr "\0" "\n" < /proc/device-tree/compatible'
ssh -o BatchMode=yes root@192.168.0.216 'ls -l /dev/video*; find /sys/bus/platform/devices -maxdepth 1 -iname "*rga*"'
ssh -o BatchMode=yes root@192.168.0.216 'dmesg | grep -i rga'
```

## 3. Stage 1b — interface to confirm

- Confirm driver API: V4L2 mem2mem (`v4l2-ctl --list-devices`, `--list-formats-out`/`--list-formats`), DRM/dma-buf import, or vendor ioctl.
- Determine supported source/destination formats (expect RGB565 → RGBA8888 or XRGB8888), stride/alignment constraints, mmap/dma-buf import, cache coherence, and permissions for the `lucca` user.
- Absence of a `/dev/video*` node alone would not prove absence; here the node exists, but functional support still needs testing.
- Do **not** infer RGA capability from a generic RK322x DTS; use the actual node and driver binding.

## 4. Stage 2 — isolated ROI reproducer (pending)

1. Write a small ARMv7 userspace probe that allocates/imports buffers through the confirmed interface, submits one RGB565→RGBA8888 blit, and measures full latency: allocation/import, CPU→DMA copy, queue/dequeue, waits, cache sync.
2. Compare against the scalar/NEON converter from #4 at two frame sizes: PSX 640×478 and SNES 256×224, with odd/even widths and varied pitches. ≥1000 reps, median/p95.
3. If #15 proves direct RGB565 DRM scanout works, RGA may be unnecessary for the display path — record that before integrating.
4. Only after a robust end-to-end gain, evaluate integration (GL texture import, reusable buffers, fences) without breaking the three RGB565 black-screen workarounds. Do **not** assume RGB565 EGLImage import works on Lima (proven failure).
5. Record maintenance cost, mainline compatibility and DTB dependency.

## 5. Gate / closure criteria

- RGA presence and interface proven or discarded with logs (Stage 1 done for presence; interface pending).
- Format/operator matrix and transfer path documented.
- End-to-end latency A/B vs scalar/NEON on the real box.
- Close as *not planned* if no consistent gain or if complexity/bug risk outweighs it.
- No kernel/DTB/firmware changes without the recoverable-boot plan from #9.

## 6. Result (2026-11-22)

Stage 1 confirmed the hardware node and driver (`rockchip-rga 20060000.rga`, HW version
0x04.01, exposed as `/dev/video0`), but the userspace interface was never established:
`v4l2-ctl` is not installed on the box, no V4L2 mem2mem/dma-buf probe was written,
and no format/stride matrix was produced. Stage 2 was therefore not started.

The two routes that could have justified the work are both closed:

- #15 (direct RGB565 DRM plane scanout) failed in userspace — both pinned Plain DRM
  builds segfault after `DRM_IOCTL_MODE_SETCRTC`; there is no working no-conversion path
  to compare against.
- #4 (scalar/NEON converter) showed no robust win; standalone conversion is ~13 ms at
  640x478 and NEON is at best equal. RGA setup/queue/cache-sync cost would have to beat
  that, with no evidence it can.

**Decision:** close #16 as not planned / negative result. Presence proven, ROI unproven,
cost and DTB/mainline dependency not justified while the CPU/thermal bottleneck dominates.
No kernel, DTB or firmware change; reopen only if #4 instrumentation shows conversion is a
top bottleneck and a V4L2/dma-buf reproducer proves sub-ms blits.
