# Display / KMS notes & box operations

## Mode selection pitfalls

The monitor's EDID (600×340 mm, 25 modes) lists `1920x1080` five times
(120/60/60/50/24 Hz) and `640x480` **only at 75 Hz**. RA's KMS driver matches
resolution, not refresh, and happily picked `640x480@75` (monitor stayed black)
or could pick `1080p@120`. Fixes applied in `retroarch-kms.cfg`:

```
video_fullscreen  = "false"   # do not switch modes at all
video_fullscreen_x = "0"      # (explicit 0s; either is enough)
video_fullscreen_y = "0"
```

RA then renders into the **current** mode set at boot:
`video=HDMI-A-1:1920x1080@60De` on the kernel cmdline. 1080p60 costs nothing —
the Mali scales.

Useful KMS debugging on the box:

```sh
modetest -c                        # list connectors/modes
modetest -s 48:1920x1080-60 -v     # hold test pattern (needs DRM master: pause ES)
cat /sys/kernel/debug/dri/0/state  # live CRTC/connector state
timeout 4 strace -p $(pgrep retroarch-kms) 2>&1 | grep -oE "DRM_IOCTL_[A-Z_]+" | sort | uniq -c
# healthy: PAGE_FLIP ~60/s, LIMA_GEM_SUBMIT streaming
```

`modetest` without `-v` exits instantly (EOF on stdin). It also needs ES paused
or it steals DRM master back — see `.no-es` below.

## ES / display handoff

- ES runs on tty1 under a getty autologin; a loop restarts it when it dies.
- To run RA directly (bypassing ES): `touch ~/.no-es`, kill ES, launch as user
  `lucca` (needs card0 master), and afterwards `rm ~/.no-es; systemctl restart getty@tty1`.
- ES only re-reads `es_systems.cfg` at start — restart ES after editing launchers.
- All systems were switched with:
  `sed -i "s|<command>retroarch -L |<command>retroarch-kms --config /home/lucca/.config/retroarch/retroarch-kms.cfg -L |g" /etc/emulationstation/es_systems.cfg`

## RetroArch configs on the box

| File | Purpose |
|---|---|
| `~/.config/retroarch/retroarch.cfg` | Debian RA (software fallback), sdl2 driver |
| `~/.config/retroarch/retroarch-kms.cfg` | copy of the above + `video_driver = "kms"`, no mode switch, gamepad combo |
| `~/.config/retroarch/config/PCSX-ReARMed/PCSX-ReARMed.opt` | `frameskip = 0` (GPU era), `psxclock = 57` |
| `~/.config/retroarch/logs/retroarch.log` | append-per-run; **truncate before debugging** or you read stale errors |

Backup binary of the pre-fix (RGB565) build on the box:
`/usr/local/bin/retroarch-kms.bak-565`.

## Perf snapshots (2026-11-20/21)

- Software era: RA = 96 % of one core at 480p, unplayable.
- GPU era: total CPU 72–86 % **idle** at 1080p60 while a game runs.
- PSX remains CPU-bound (dynarec), "playable, not perfect".
