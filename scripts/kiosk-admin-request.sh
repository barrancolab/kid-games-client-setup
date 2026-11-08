#!/bin/sh
# kiosk-admin-request.sh — raise the admin-shell flag and stop ScummVM.
#
# Bound to Ctrl+Alt+Shift+F12 in /etc/kiosk/openbox-rc.xml. The supervisor
# sees the flag on its next loop and runs kiosk-admin.sh instead of
# relaunching the game.
set -u

: > "$HOME/.kiosk-admin-request"
pkill -x scummvm 2>/dev/null || true
