#!/usr/bin/env bash
# Reversible governor A/B for issue #2. Usage: run-governor-ab.sh <performance|ondemand>
set -u

MODE="${1:?usage: run-governor-ab.sh <performance|ondemand>}"
BOX="${BOX:-root@192.168.0.216}"
SSH="ssh -o BatchMode=yes $BOX"
RESULTS="bench/results/2026-11-21"
HERE="$(cd "$(dirname "$0")" && pwd)"

PCSX=/usr/local/lib/libretro/pcsx_rearmed_libretro.so
SNES=/usr/lib/arm-linux-gnueabihf/libretro/snes9x_libretro.so
PSX_ROM='/roms/roms/psx/Crash Bandicoot.chd'
SNES_ROM='/roms/roms/snes/Super Metroid (Japan, USA) (En,Ja).sfc'

echo "=== governor A/B: $MODE ($(date +%H:%M:%S)) ==="
$SSH 'mkdir -p /tmp/bench' 
$SSH 'sh -s' < "$HERE/cpufreq.sh" save
$SSH 'sh -s' < "$HERE/cpufreq.sh" "$MODE"

cleanup() {
  echo "restoring governor ($(date +%H:%M:%S))"
  $SSH 'sh -s' < "$HERE/cpufreq.sh" restore || true
}
trap cleanup EXIT INT TERM

run_scene() {
  local label="$1" core="$2" rom="$3"
  echo "--- $label ($(date +%H:%M:%S)) ---"
  # SSH joins argv with spaces; quote the remote command string so paths with
  # spaces survive as single arguments.
  $SSH "bash -s -- --core '$core' --rom '$rom' --label '$label' \
    --frames 999999 --seconds 150 --strace" < "$HERE/run-scene.sh" || return 1
  scp -q -r "$BOX:/tmp/bench/$label" "$RESULTS/" || return 1
  BENCH_WARMUP=30 python3 "$HERE/analyze.py" "$RESULTS/$label" > "$RESULTS/$label.md" || return 1
  return 0
}

for rep in 1 2 3; do
  run_scene "psx3d-crash-gov-${MODE}-r${rep}" "$PCSX" "$PSX_ROM" || exit 1
  run_scene "snes-supermetroid-gov-${MODE}-r${rep}" "$SNES" "$SNES_ROM" || exit 1
done

echo "=== governor A/B $MODE finished ($(date +%H:%M:%S)) ==="
