#!/bin/sh
# kiosk-boot-mode.sh — systemd helper for kiosk-desktop-once.sh.
#
# Runs before the display manager on every graphical boot. It implements a
# single-boot state machine:
#
#   armed  (pending) -> save the kiosk autologin, write a no-autologin
#                       sddm.conf for this boot, remember that we did so
#   next   (active)  -> put the kiosk autologin back, then forget
#
# The saved copy lives in /var/lib/kiosk-boot-mode, which is root-only.
set -u

STATE=/var/lib/kiosk-boot-mode
SDDM_CONF=/etc/sddm.conf
SAVED=$STATE/saved-sddm.conf

mkdir -p "$STATE"
chmod 0700 "$STATE" 2>/dev/null || true

restore_kiosk() {
  if [ -f "$SAVED" ]; then
    cp -a "$SAVED" "$SDDM_CONF"
    echo "kiosk-boot-mode: kiosk autologin restored"
  fi
  rm -f "$SAVED" "$STATE/active"
}

disable_autologin() {
  cp -a "$SDDM_CONF" "$SAVED" 2>/dev/null || true
  cat > "$SDDM_CONF" <<'EOF'
# Temporary, written by kiosk-boot-mode.sh for a single boot.
# kiosk-boot-mode.sh restores the kiosk autologin on the next boot.
[Autologin]
User=
Session=
Relogin=false
EOF
  chmod 0644 "$SDDM_CONF"
  : > "$STATE/active"
  echo "kiosk-boot-mode: greeter enabled for this boot"
}

# If a desktop-once boot is ending, undo it first. This also handles the
# case where the user re-armed the one-shot while still in desktop mode.
if [ -e "$STATE/active" ]; then
  restore_kiosk
fi

if [ -e "$STATE/pending" ]; then
  rm -f "$STATE/pending"
  disable_autologin
fi
