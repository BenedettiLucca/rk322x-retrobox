#!/usr/bin/env bash
# Run the #1 baseline matrix on the RK322x box: 3 reps x 5 fixed scenes.
# Each run: 150 s wall (30 s warmup + 120 s measurement), strace page flips.
set -u
HOST=${BOX_HOST:-root@192.168.0.216}
DATE=${BENCH_DATE:-2026-11-21}
RESULTS="bench/results/$DATE"
SSH="ssh -o BatchMode=yes $HOST"
mkdir -p "$RESULTS"

PCSX=/usr/local/lib/libretro/pcsx_rearmed_libretro.so
SNES=/usr/lib/arm-linux-gnueabihf/libretro/snes9x_libretro.so
MBA=/usr/lib/arm-linux-gnueabihf/libretro/mgba_libretro.so

scenes=(
  "psx3d-crash|$PCSX|/roms/roms/psx/Crash Bandicoot.chd"
  "psx3d-ctr|$PCSX|/roms/roms/psx/CTR - Crash Team Racing.chd"
  "psx2d-parappa|$PCSX|/roms/roms/psx/PaRappa the Rapper.chd"
  "snes-supermetroid|$SNES|/roms/roms/snes/Super Metroid (Japan, USA) (En,Ja).sfc"
  "gba-emerald|$MBA|/roms/roms/gba/Pokemon - Emerald Version (USA, Europe).gba"
)

for entry in "${scenes[@]}"; do
  IFS='|' read -r label core rom <<<"$entry"
  for rep in 1 2 3; do
    id="${label}-r${rep}"
    if [ -f "$RESULTS/$id/status.json" ] && [ -f "$RESULTS/$id.md" ] \
       && grep -q '"status":"ok"' "$RESULTS/$id/status.json"; then
      echo "=== skip $id (already complete) ==="
      continue
    fi
    echo "=== $id ($(date +%H:%M:%S)) ==="
    $SSH "bash -s -- --core '$core' --rom \"$rom\" --label '$id' --frames 999999 --seconds 150 --strace" \
      < scripts/bench/run-scene.sh || echo "WARN: $id returned nonzero" >&2
    scp -q -r "$HOST:/tmp/bench/$id" "$RESULTS/" || echo "WARN: scp $id failed" >&2
    BENCH_WARMUP=30 python3 scripts/bench/analyze.py "$RESULTS/$id" > "$RESULTS/$id.md" 2>&1 || true
  done
done
echo "baseline matrix complete: $RESULTS"
