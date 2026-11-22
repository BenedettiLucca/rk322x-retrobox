#!/bin/sh
# Change cpufreq for a reversible A/B on the box. Pipe over SSH:
#   ssh -o BatchMode=yes root@192.168.0.216 'sh -s' < scripts/bench/cpufreq.sh save
set -e

POLICY=/sys/devices/system/cpu/cpufreq/policy0
SAVE=/tmp/bench/cpufreq.saved

read_policy() {
  printf '%s %s %s\n' \
    "$(cat "$POLICY/scaling_governor")" \
    "$(cat "$POLICY/scaling_min_freq")" \
    "$(cat "$POLICY/scaling_max_freq")"
}

mkdir -p /tmp/bench

case "${1:-status}" in
  save)
    read_policy > "$SAVE"
    printf 'saved: %s\n' "$(cat "$SAVE")"
    ;;
  performance)
    [ -f "$SAVE" ] || read_policy > "$SAVE"
    echo performance > "$POLICY/scaling_governor"
    echo 1200000 > "$POLICY/scaling_min_freq"
    echo 1200000 > "$POLICY/scaling_max_freq"
    printf 'performance set; saved: %s\n' "$(cat "$SAVE")"
    ;;
  ondemand)
    [ -f "$SAVE" ] || read_policy > "$SAVE"
    echo ondemand > "$POLICY/scaling_governor"
    read min max < /dev/null 2>/dev/null || true
    set -- $(cat "$SAVE")
    echo "${2:-600000}" > "$POLICY/scaling_min_freq"
    echo "${3:-1200000}" > "$POLICY/scaling_max_freq"
    printf 'ondemand restored; saved: %s\n' "$(cat "$SAVE")"
    ;;
  restore)
    [ -f "$SAVE" ] || { echo "no saved cpufreq state" >&2; exit 1; }
    set -- $(cat "$SAVE")
    echo "$1" > "$POLICY/scaling_governor"
    echo "$2" > "$POLICY/scaling_min_freq"
    echo "$3" > "$POLICY/scaling_max_freq"
    printf 'restored: %s\n' "$(cat "$SAVE")"
    ;;
  status)
    printf 'current: %s\n' "$(read_policy)"
    [ -f "$SAVE" ] && printf 'saved:   %s\n' "$(cat "$SAVE")" || true
    ;;
  *)
    echo "usage: $0 {save|performance|ondemand|restore|status}" >&2
    exit 2
    ;;
esac
