#!/usr/bin/env bash
# install-kiosk.sh — turn a Lubuntu install into the ScummVM kiosk.
#
# Run as root on the thin client, from a checkout of this repository:
#
#   sudo ./scripts/install-kiosk.sh
#
# Idempotent: safe to re-run after editing the kiosk scripts.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX=/usr/local/bin
KIOSK_ETC=/etc/kiosk
GAMES_USER=${GAMES_USER:-games}
GAMES_HOME=/home/$GAMES_USER
SCUMMVM_DIR=${SCUMMVM_DIR:-/opt/scummvm}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
say() { printf '==> %s\n' "$*"; }

[ "$(id -u)" -eq 0 ] || die "run as root"

id "$GAMES_USER" >/dev/null 2>&1 \
  || die "user '$GAMES_USER' does not exist; create it first (see docs/04-kiosk-session.md)"

[ -x "$SCUMMVM_DIR/scummvm" ] \
  || die "$SCUMMVM_DIR/scummvm not found; install ScummVM first (see docs/05-scummvm.md)"

say "installing packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends \
  openbox sddm unclutter xterm x11-xserver-utils dbus-x11

say "installing kiosk scripts into $PREFIX"
install -d -m 0755 "$PREFIX" "$KIOSK_ETC"
for s in kiosk-session.sh kiosk-supervisor.sh kiosk-admin.sh \
         kiosk-admin-request.sh kiosk-volume.sh kiosk-network.sh \
         scummvm-kiosk.sh make-manifest.sh verify-manifest.sh; do
  install -m 0755 "$REPO_DIR/scripts/$s" "$PREFIX/$s"
done

say "installing kiosk configuration into $KIOSK_ETC"
install -m 0644 "$REPO_DIR/config/openbox-rc.xml" "$KIOSK_ETC/openbox-rc.xml"

say "installing the X session entry"
install -d -m 0755 /usr/share/xsessions
install -m 0644 "$REPO_DIR/config/kiosk.desktop" /usr/share/xsessions/kiosk.desktop

say "configuring SDDM autologin"
install -d -m 0755 /etc/sddm.conf.d
install -m 0644 "$REPO_DIR/config/10-kiosk.conf" /etc/sddm.conf.d/10-kiosk.conf
systemctl enable sddm
systemctl disable lightdm 2>/dev/null || true

say "hardening"
install -d -m 0755 /etc/systemd/logind.conf.d
install -m 0644 "$REPO_DIR/config/99-kiosk-logind.conf" \
  /etc/systemd/logind.conf.d/99-kiosk.conf
install -m 0644 "$REPO_DIR/config/99-kiosk-sysctl.conf" /etc/sysctl.d/99-kiosk.conf
sysctl -q --system

# Ctrl+Alt+F1..F12 must not switch virtual terminals.
if grep -q '^XKBOPTIONS=' /etc/default/keyboard; then
  sed -i 's|^XKBOPTIONS=.*|XKBOPTIONS="srvrkeys:none"|' /etc/default/keyboard
else
  printf 'XKBOPTIONS="srvrkeys:none"\n' >> /etc/default/keyboard
fi

systemctl mask ctrl-alt-del.target 2>/dev/null || true
systemctl disable unattended-upgrades 2>/dev/null || true

say "preparing $GAMES_HOME"
install -d -o "$GAMES_USER" -g "$GAMES_USER" -m 0755 "$GAMES_HOME"
install -d -o "$GAMES_USER" -g "$GAMES_USER" -m 0755 \
  "$GAMES_HOME/Games" "$GAMES_HOME/saves" "$GAMES_HOME/.config/scummvm"

INI="$GAMES_HOME/.config/scummvm/scummvm.ini"
if [ ! -e "$INI" ]; then
  cat > "$INI" <<EOF
[scummvm]
fullscreen=true
confirm_exit=true
gui_return_to_launcher_at_exit=true
savepath=$GAMES_HOME/saves
extrapath=$SCUMMVM_DIR/extra
EOF
  chown "$GAMES_USER:$GAMES_USER" "$INI"
  chmod 0644 "$INI"
fi

say "done"
cat <<EOF

Kiosk installed.

  reboot        SDDM autologins '$GAMES_USER' straight into ScummVM
  admin shell   Ctrl+Alt+Shift+F12, then the admin user's password
  network       sudo $PREFIX/kiosk-network.sh on|off
  games         $GAMES_HOME/Games

EOF
