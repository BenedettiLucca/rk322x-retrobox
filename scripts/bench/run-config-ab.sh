#!/bin/bash
# Run a one-variable RetroArch config A/B on the box using run-scene.sh.
# Usage: run-config-ab.sh <label> <remote-append-cfg-path>
set -euo pipefail

label="${1:?label required}"
cfg="${2:?remote append config path required}"

core="/usr/local/lib/libretro/pcsx_rearmed_libretro.so"
rom="/roms/roms/psx/Crash Bandicoot.chd"
results="bench/results/2026-11-21"
mkdir -p "$results"

for rep in 1 2 3; do
  id="${label}-r${rep}"
  echo "=== $id ($(date +%H:%M:%S)) ==="
  ssh -o BatchMode=yes root@192.168.0.216 \
    "bash -s -- --core '$core' --rom '$rom' --label '$id' \
     --frames 999999 --seconds 150 --append '$cfg' --strace" \
    < scripts/bench/run-scene.sh
  scp -q -r "root@192.168.0.216:/tmp/bench/$id" "$results/"
  BENCH_WARMUP=30 python3 scripts/bench/analyze.py "$results/$id" > "$results/$id.md"
  echo "ok: $results/$id.md"
done
