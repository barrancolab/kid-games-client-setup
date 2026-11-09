#!/bin/sh
# kiosk-admin.sh — password-protected admin shell.
#
# Started by the supervisor when the hidden key combo is pressed. It opens a
# fullscreen terminal and asks for the admin user's password. Without that
# password there is no way past this point.
#
# Override the admin account with ADMIN_USER=name, otherwise use the account
# recorded at install time.
set -u

ADMIN_USER=${ADMIN_USER:-$(cat /etc/kiosk/admin-user 2>/dev/null)}
if [ -z "$ADMIN_USER" ]; then
  ADMIN_USER=$(awk -F: '$3 >= 1000 && $3 < 65534 { print $1; exit }' /etc/passwd)
fi

[ -n "$ADMIN_USER" ] || {
  echo "no admin account configured" >&2
  sleep 3
  exit 1
}

exec xterm -fullscreen -fa Monospace -fs 12 \
  -e su - "$ADMIN_USER"
