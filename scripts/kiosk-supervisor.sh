#!/bin/sh
# kiosk-supervisor.sh — keep ScummVM running, forever.
#
# This is the parent process of the kiosk session. There is no desktop to
# fall back to: if ScummVM exits, for any reason, it is relaunched. That is
# what makes the "Quit" button harmless.
#
# ScummVM itself is configured with:
#   gui_return_to_launcher_at_exit=true   leaving a game returns to the list
#   confirm_exit=true                     quitting asks for confirmation
#
# The hidden admin key combo touches ~/.kiosk-admin-request and kills
# ScummVM; on the next loop this script sees the flag and opens a
# password-protected terminal instead of relaunching the game.
set -u

REQUEST="$HOME/.kiosk-admin-request"
fast_failures=0

while :; do
  if [ -e "$REQUEST" ]; then
    rm -f "$REQUEST"
    fast_failures=0
    /usr/local/bin/kiosk-admin.sh
    continue
  fi

  started=$(date +%s)
  /usr/local/bin/scummvm-kiosk.sh || true
  ran_for=$(( $(date +%s) - started ))

  # A normal quit gets an instant relaunch. A crash loop backs off so the
  # machine does not spin at 100% CPU forever.
  if [ "$ran_for" -lt 5 ]; then
    fast_failures=$(( fast_failures + 1 ))
  else
    fast_failures=0
  fi

  if [ "$fast_failures" -gt 5 ]; then
    sleep 10
  else
    sleep 1
  fi
done
