#!/bin/sh
# kiosk-admin.sh — password-protected admin shell.
#
# Started by the supervisor when the hidden key combo is pressed. It opens a
# fullscreen terminal and asks for the admin user's password. Without that
# password there is no way past this point.
#
# Override the admin account with ADMIN_USER=name.
set -u

ADMIN_USER=${ADMIN_USER:-parent}

exec xterm -fullscreen -fa Monospace -fs 12 \
  -e su - "$ADMIN_USER"
