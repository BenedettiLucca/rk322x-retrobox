#!/bin/bash
# Controlled RetroArch scene runner for the RK322x box.
# Run as root on the box. Pauses ES, runs RA as lucca, samples the system,
# and always restores ES/tty1 on exit.
set -euo pipefail

RA_BIN="${RA_BIN:-/usr/local/bin/retroarch-kms}"
RA_CFG="${RA_CFG:-/home/lucca/.config/retroarch/retroarch-kms.cfg}"
RA_USER="${RA_USER:-lucca}"
HOME_DIR="/home/lucca"
NO_ES="$HOME_DIR/.no-es"

# Time-based windows: frames are set high so the timeout controls the run.
# Default 150 s = 30 s warmup + 120 s measurement; analyze.py filters the warmup.
core="" rom="" label="" frames="999999" seconds="150" append="" vsync="" out=""
strace=0
while [ $# -gt 0 ]; do
  case "$1" in
    --core) core="$2"; shift 2 ;;
    --rom) rom="$2"; shift 2 ;;
    --label) label="$2"; shift 2 ;;
    --frames) frames="$2"; shift 2 ;;
    --seconds) seconds="$2"; shift 2 ;;
    --append) append="$2"; shift 2 ;;
    --vsync) vsync="$2"; shift 2 ;;
    --strace) strace=1; shift ;;
    --out) out="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$core" ] && [ -f "$core" ] || { echo "--core must exist" >&2; exit 2; }
[ -n "$rom" ] && [ -f "$rom" ] || { echo "--rom must exist" >&2; exit 2; }
[ -n "$label" ] || { echo "--label is required" >&2; exit 2; }
[ -x "$RA_BIN" ] || { echo "missing $RA_BIN" >&2; exit 2; }

out="${out:-/tmp/bench/$label}"
mkdir -p "$out"
log="$out/ra.log"
samples="$out/samples.csv"
meta="$out/meta.json"
append_file="$out/append.cfg"
: > "$log"
: > "$samples"
echo "time_s,ra_pid,temp_c,cpu_pct,rss_kb,freq0_khz,freq1_khz,freq2_khz,freq3_khz" > "$samples"

# Build appended config: never persist changes to the main config.
: > "$append_file"
echo 'config_save_on_exit = "false"' >> "$append_file"
[ -n "$vsync" ] && echo "video_vsync = \"$vsync\"" >> "$append_file"
[ -n "$append" ] && [ -f "$append" ] && cat "$append" >> "$append_file"

ES_PAUSED=0
cleanup() {
  set +e
  rm -f "$NO_ES"
  if [ "$ES_PAUSED" -eq 1 ]; then
    systemctl restart getty@tty1 >/dev/null 2>&1 || true
  fi
  echo "cleanup done"
}
trap cleanup EXIT INT TERM

# Cooldown gate: do not start a new measurement above ~85 C (safety doc).
for _ in $(seq 1 12); do
  t0=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
  [ "$t0" -lt 85000 ] && break
  sleep 5
done

# Hand off DRM master from ES. Wait for ES to actually exit before starting RA.
touch "$NO_ES"
ES_PAUSED=1
# The kernel truncates comm to 15 chars ("emulationstatio"), so match the full
# command line with -f rather than the process name.
pkill -TERM -f '^/usr/local/bin/emulationstation' >/dev/null 2>&1 || true
for _ in $(seq 1 20); do
  pgrep -f '^/usr/local/bin/emulationstation' >/dev/null 2>&1 || break
  sleep 1
done
if pgrep -f '^/usr/local/bin/emulationstation' >/dev/null 2>&1; then
  echo "emulationstation ignored SIGTERM for 20 s; using SIGKILL" >&2
  pkill -KILL -f '^/usr/local/bin/emulationstation' >/dev/null 2>&1 || true
  sleep 2
fi
if pgrep -f '^/usr/local/bin/emulationstation' >/dev/null 2>&1; then
  echo "emulationstation did not exit; aborting" >&2
  exit 2
fi
# Give the kernel driver a moment to release DRM master.
sleep 2

if pgrep -x retroarch-kms >/dev/null 2>&1; then
  echo "retroarch-kms is already running; aborting" >&2
  exit 2
fi

cmd=(runuser -u "$RA_USER" -- "$RA_BIN" --config "$RA_CFG" --appendconfig "$append_file")
[ "${NO_FULLSCREEN:-0}" = "1" ] || cmd+=(--fullscreen)
cmd+=(-L "$core" "$rom" --max-frames="$frames")
if [ "$strace" -eq 1 ]; then
  cmd=(strace -f -tt -e trace=ioctl,openat -o "$out/strace.log" "${cmd[@]}")
fi

sampler() {
  local pid t temp cpu rss f freqs
  while true; do
    pid=$(pgrep -x retroarch-kms | head -1 || true)
    if [ -n "$pid" ]; then
      t=$(date +%s)
      temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
      cpu=$(ps -L -p "$pid" -o pcpu= 2>/dev/null | awk '{s+=$1} END{printf "%.1f", s+0}')
      rss=$(awk '/VmRSS/{print $2}' "/proc/$pid/status" 2>/dev/null || echo 0)
      freqs=""
      for i in 0 1 2 3; do
        f=$(cat "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq" 2>/dev/null || echo 0)
        freqs="$freqs,$f"
      done
      echo "$t,$pid,$temp,$cpu,$rss$freqs" >> "$samples"
    fi
    sleep 1
  done
}
sampler &
sampler_pid=$!

start=$(date +%s)
set +e
timeout --signal=TERM "$((seconds + 5))" "${cmd[@]}" > "$log" 2>&1
rc=$?
set -e
end=$(date +%s)
kill "$sampler_pid" 2>/dev/null || true
wait "$sampler_pid" 2>/dev/null || true

python3 - "$meta" "$label" "$start" "$end" "$frames" "$core" "$rom" "$out" "$rc" <<'PY'
import json, sys
meta, label, start, end, frames, core, rom, out, rc = sys.argv[1:]
elapsed = int(end) - int(start)
data = {
    'label': label, 'start': int(start), 'end': int(end), 'elapsed_s': elapsed,
    'frames_requested': int(frames),
    'frames_per_s_wall': round(int(frames) / elapsed, 3) if elapsed else None,
    'core': core, 'rom': rom, 'out': out, 'exit_code': int(rc),
    'status': 'ok' if int(rc) in (0, 124) else 'failed',
    'note': 'time window controlled by timeout; rc 124 is expected; frames_per_s_wall includes startup; use strace page flips for delivered FPS',
}
open(meta, 'w').write(json.dumps(data, indent=2))
PY
printf '{"status":"%s","exit_code":%d}\n' \
  "$( [ "$rc" -eq 0 ] || [ "$rc" -eq 124 ] && echo ok || echo failed )" "$rc" > "$out/status.json"

if [ "$rc" -ne 0 ] && [ "$rc" -ne 124 ]; then
  echo "retroarch exited with $rc; last 25 log lines:" >&2
  tail -n 25 "$log" >&2
fi

echo "scene finished: $out (status=$( [ "$rc" -eq 0 ] || [ "$rc" -eq 124 ] && echo ok || echo failed ))"
