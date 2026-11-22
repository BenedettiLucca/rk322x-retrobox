# Memory, swap and I/O audit (issue #11)

## Read-only inventory (collected 2026-11-21)

- Total RAM 970 MiB; idle ~162 MiB used, 619 MiB free, 252 MiB buff/cache, 807 MiB available.
- Swap: 485 MiB zram0, 0 used; `/var/log` on zram1; zram2 unused.
- Root filesystem: `/dev/mmcblk2p1` 6.9 GB, 2.5 GB used, 4.3 GB available (38% used).
- ROM library: `/dev/mmcblk0` 59.5 GB ext4, now mounted at `/roms` via UUID with 30 s timeout.
- PSX scenes are CHD; GBA Emerald is a 16 MB `.gba`; SNES Super Metroid is 3 MB.
- PCSX read-ahead option exists (`pcsx_rearmed_cd_readahead`); default not yet measured. The historical `333000` full-disc precache (~750 MB) must not become a default on 1 GB.

## Method

During PSX 3D, PSX 2D and GBA scenes collect `free -h`, `swapon --show`, `zramctl`, `vmstat 1`, `/proc/pressure/memory` if supported, and `/proc/<pid>/{status,io,smaps_rollup}`. Verify whether ES releases memory when it hands off to RA; do not kill essential services. Compare ISO/BIN/CHD only in supported formats on the same scene/media, controlling page cache and CPU decompression. Only tune read-ahead or zram with reproducible A/B and a reversible change.

## Status

Inventory complete; dynamic measurements pending after the #1 baseline matrix. Audio underruns remain uninstrumented (see #1/#6); avoid attributing crackle to CPU without data.

## Result (2026-11-22)

Dynamic data came from the 15 baseline runs (`bench/results/2026-11-21/`):

- RetroArch RSS stayed ~102–117 MB (SNES 102 MB, PSX 104–106 MB, GBA 117 MB).
  zram swap was 485 MiB with 0 used; no OOM, no pressure events, no swap-in.
- Page cache is shared with the mounted ROMS volume; all PSX scenes used CHD files
  successfully (`Crash Bandicoot.chd`, `CTR - Crash Team Racing.chd`,
  `PaRappa the Rapper.chd`). No ISO/BIN-vs-CHD A/B was run, so no claim about
  decompression cost is made.
- The installed PCSX core exposes no `cd_readahead` option in its `.opt`/`strings`
  inventory, so the ~750 MB precache warning from the issue is not applicable here.
- ES is terminated during benchmark launches (DRM master cannot be shared), so it
  holds no private memory while the game runs; no service was killed blindly.
- Audio latency A/B (`audio_latency=128`) was a null FPS result (#6); without an
  underrun counter, crackle cannot be attributed to buffering or CPU.

**Decision:** no memory, swap, zram, read-ahead or media-format change. Close #11 with a
negative result: 1 GB RAM is not the bottleneck; CPU/thermal saturation dominates.
