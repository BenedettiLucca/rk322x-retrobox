# Testing and recovery safety

Applies to every benchmark, deploy, display-mode experiment, or driver/kernel investigation on the RK322x box.

## Golden rules

1. **Nothing is changed without a backup and a tested rollback.**
2. **The box has a serial console on `ttyS2,115200n8`.** Use it for any test that can break video output or DRM master.
3. **ES/DRM handoff must be restored after every test**, even on failure or timeout.
4. **No ROM, BIOS, save state, screenshot, or personal data goes into git.** Sanitize logs (no IPs, usernames, absolute home paths).
5. **One variable at a time.** No optimization without a controlled A/B using the #1 methodology.

## Backups

```sh
# On the box, before touching the binary or config:
cp /usr/local/bin/retroarch-kms /usr/local/bin/retroarch-kms.bak-$(date +%F-%H%M)
cp ~/.config/retroarch/retroarch-kms.cfg ~/.config/retroarch/retroarch-kms.cfg.bak-$(date +%F-%H%M)
# Known-good pre-RGB565-fix binary already present:
#   /usr/local/bin/retroarch-kms.bak-565
# fstab backup from Phase 0:
#   /etc/fstab.bak-20261121
```

## ES / direct-launch lifecycle

- ES is started by `/home/lucca/.bash_profile` only on `tty1`, in a loop guarded by `~/.no-es`.
- `touch ~/.no-es` pauses the loop; ES may be stopped cleanly afterwards.
- Direct RA needs DRM master, so ES must be stopped first. Run RA as `lucca` (`runuser -u lucca -- ...`).
- Restore with:
  ```sh
  rm -f ~/.no-es
  systemctl restart getty@tty1
  ```
- Prefer `pkill -TERM -x emulationstation` and a short wait. `kill -9` only as a last resort, and log it.

Safe launch pattern (implemented in `scripts/bench/run-scene.sh`):

```sh
touch /home/lucca/.no-es
pkill -TERM -x emulationstation || true
sleep 1
timeout "$seconds" runuser -u lucca -- "$RA_BIN" --config "$RA_CFG" ... >log 2>&1 || true
rm -f /home/lucca/.no-es
systemctl restart getty@tty1
```

## Display / DRM safety

- Known-good mode: 1920×1080@60. Boot cmdline contains `video=HDMI-A-1:1920x1080@60De`.
- `video_fullscreen="false"` in `retroarch-kms.cfg` prevents RA from switching to a bad mode. Keep it.
- **Never** select 640×480@75 (black screen) or 1080×120 (black screen history).
- 1280×720@60 is present in EDID and may be tested only with a return path to 1080p60.
- Inspect connector/CRTC names with `modetest -c`; do not hardcode connector ID 48.
- Before any mode change: serial console ready, backup config, watchdog/timeout, and a command to restore 1080p60.
- After any failure: `modetest -s <connector>:1920x1080-60` (needs DRM master; pause ES), then restore ES.

## Rollback of the RetroArch binary

```sh
# If a new binary fails to open the display:
install -m755 /usr/local/bin/retroarch-kms.bak-<timestamp> /usr/local/bin/retroarch-kms
/usr/local/bin/retroarch-kms --version
rm -f ~/.no-es
systemctl restart getty@tty1
```

## Thermal

- Idle `cpu-thermal` has been observed near 74 °C. Log temperature during every run.
- Pause and report above ~85 °C. Do not change voltage, OPPs, DTB, or thermal settings.
- CPU governor changes must be auto-restored with a `trap` on exit.

## Benchmark hygiene

- Same scene/save state, core, BIOS, ROM, config, resolution, governor, and media for baseline and variant.
- 30 s warmup; 120 s measurement windows; at least 3 repetitions.
- Report mean/median FPS, p95/p99 frametime, temperature, per-thread CPU, RAM, and audio underruns.
- State explicitly when instrumentation is absent (e.g. `perf`, `eglinfo`, screen capture).

## Privileges and network

- Use `BOX_HOST`/`BOX_USER` for remote commands; keep the host key in `~/.ssh/known_hosts`.
- Do not use `StrictHostKeyChecking=no` or `UserKnownHostsFile=/dev/null` as defaults.
- Root is currently required for `/usr/local/bin` and `getty@tty1`; least-privilege `lucca` + narrow sudo is a tracked goal, not a blocker.
