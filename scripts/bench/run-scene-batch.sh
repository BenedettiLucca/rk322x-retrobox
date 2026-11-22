#!/usr/bin/env bash
# Run N repetitions of a single scene through run-scene.sh, copy results and analyze.
# Usage: run-scene-batch.sh LABEL CORE ROM [REPS]
set -u
label=$1
core=$2
rom=$3
reps=${4:-3}
append=${5:-}
out=/tmp/bench
results=bench/results/2026-11-21

for rep in $(seq 1 "$reps"); do
  id="${label}-r${rep}"
  echo "=== $id ($(date +%H:%M:%S)) ==="
  # SSH joins argv with spaces, so pass one pre-quoted remote command string.
  args=(--core "$core" --rom "$rom" --label "$id" --frames 999999 --seconds 150 --strace)
  [ -n "$append" ] && args+=(--append "$append")
  remote_cmd='bash -s --'
  [ "${NO_FULLSCREEN:-0}" = "1" ] && remote_cmd="NO_FULLSCREEN=1 $remote_cmd"
  for a in "${args[@]}"; do printf -v remote_cmd '%s %q' "$remote_cmd" "$a"; done
  ssh -o BatchMode=yes root@192.168.0.216 "$remote_cmd" < scripts/bench/run-scene.sh || echo "WARN: $id runner exited $?"
  mkdir -p "$results/$id"
  scp -q -r "root@192.168.0.216:$out/$id/." "$results/$id/" || echo "WARN: scp failed for $id"
  if [ -f "$results/$id/status.json" ]; then
    BENCH_WARMUP=30 python3 scripts/bench/analyze.py "$results/$id" > "$results/$id.md" || true
  fi
done
