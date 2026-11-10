#!/bin/sh
# kiosk-desktop-once.sh — show the SDDM login screen for exactly one boot.
#
#   sudo kiosk-desktop-once              arm it and reboot now
#   sudo kiosk-desktop-once --no-reboot  arm it; reboot when you are ready
#   sudo kiosk-desktop-once --cancel     cancel an armed one-shot
#
# How it works: the next boot starts the greeter instead of autologging
# into the kiosk. The boot after that restores the autologin automatically.
# Nothing about the kiosk is changed permanently.
set -u

STATE=/var/lib/kiosk-boot-mode

[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }

case ${1:-} in
  --cancel)
    rm -f "$STATE/pending"
    echo "one-shot desktop boot cancelled"
    exit 0
    ;;
  --no-reboot|"")
    ;;
  *)
    echo "usage: $0 [--no-reboot|--cancel]" >&2
    exit 2
    ;;
esac

[ -f /etc/systemd/system/kiosk-boot-mode.service ] || {
  echo "kiosk-boot-mode.service is not installed; re-run setup-client.sh" >&2
  exit 1
}

install -d -m 0700 "$STATE"
: > "$STATE/pending"

echo "armed: the next boot will show the login screen"
echo "the boot after that returns to the kiosk"

if [ "${1:-}" != --no-reboot ]; then
  echo "rebooting..."
  systemctl reboot
fi
