#!/usr/bin/env bash
# Helper for the rk322x box. Usage:
#   box.sh deploy     - install bin/retroarch-kms onto the box
#   box.sh launch <core.so> "<ROM>"  - run a game directly (ES paused, auto-restored)
#   box.sh es-restart - bring EmulationStation back
#   box.sh log        - tail the RA log (truncates first so you never read stale lines)
set -euo pipefail
BOX="${BOX:-root@192.168.0.216}"
DIR="$(cd "$(dirname "$0")/.." && pwd)"
# Use a normal known_hosts entry; do not disable host-key verification.
SSH="ssh -o BatchMode=yes $BOX"

case "${1:-}" in
  deploy)
    cat "$DIR/bin/retroarch-kms" | $SSH \
      'cat > /tmp/ra.bin && install -m755 /tmp/ra.bin /usr/local/bin/retroarch-kms && echo DEPLOYED'
    ;;
  launch)
    core="$2"; rom="$3"
    # Kernel truncates comm to "emulationstatio"; match the full command line.
    $SSH 'touch /home/lucca/.no-es; pkill -TERM -f "^/usr/local/bin/emulationstation" 2>/dev/null || true; \
      for i in $(seq 1 10); do pgrep -f "^/usr/local/bin/emulationstation" >/dev/null || break; sleep 1; done; \
      pgrep -f "^/usr/local/bin/emulationstation" >/dev/null && { echo "ES still running" >&2; exit 2; }; sleep 2'
    $SSH "runuser -u lucca -- nohup /usr/local/bin/retroarch-kms \
      --config /home/lucca/.config/retroarch/retroarch-kms.cfg \
      -L '$core' --fullscreen '$rom' >/tmp/ra-direct.log 2>&1 & sleep 3; \
      pgrep -x retroarch-kms && echo RUNNING"
    # auto-restore ES when the game quits
    $SSH 'nohup bash -c "while pgrep -x retroarch-kms >/dev/null; do sleep 5; done; rm -f /home/lucca/.no-es; systemctl restart getty@tty1" >/dev/null 2>&1 &'
    ;;
  es-restart)
    $SSH 'rm -f /home/lucca/.no-es; systemctl restart getty@tty1'
    ;;
  log)
    $SSH 'tail -n 40 /home/lucca/.config/retroarch/logs/retroarch.log'
    ;;
  *)
    sed -n '2,8p' "$0"; exit 1
    ;;
esac
