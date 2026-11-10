#!/bin/sh
# kiosk-session.sh — X session entry point for the kiosk.
#
# Installed to /usr/local/bin and started by SDDM as the 'kiosk' user.
# It brings up a bare Openbox (no panel, no desktop icons) and then hands
# the session over to the supervisor, which owns the ScummVM relaunch loop.
set -eu

# No screen blanking, no DPMS, no screensaver.
xset s off -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Black root window instead of a wallpaper or desktop icons.
xsetroot -solid black 2>/dev/null || true

# Hide the mouse pointer after two idle seconds.
unclutter -idle 2 -root >/dev/null 2>&1 &

openbox --config-file /etc/kiosk/openbox-rc.xml &
openbox_pid=$!

# If the supervisor ever exits, take the window manager with it so the
# session ends cleanly instead of leaving a bare X server running.
trap 'kill "$openbox_pid" 2>/dev/null || true' EXIT INT TERM

exec /usr/local/bin/kiosk-supervisor.sh
