#!/bin/sh
# scummvm-kiosk.sh — launch ScummVM in fullscreen with the kiosk config.
#
# Any extra arguments are passed through, so this can also be used
# interactively, e.g.:
#
#   scummvm-kiosk.sh --add --path=/home/games/Games/Freddi\ Fish\ 1
set -u

GAMES_HOME=${GAMES_HOME:-/home/games}
SCUMMVM_DIR=${SCUMMVM_DIR:-/opt/scummvm}

exec "$SCUMMVM_DIR/scummvm" \
  --config="$GAMES_HOME/.config/scummvm/scummvm.ini" \
  --savepath="$GAMES_HOME/saves" \
  --fullscreen \
  "$@"
