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
GAMES_USER=${GAMES_USER:-kiosk}
GAMES_HOME=/home/$GAMES_USER
SCUMMVM_DIR=${SCUMMVM_DIR:-/opt/scummvm}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
say() { printf '==> %s\n' "$*"; }

[ "$(id -u)" -eq 0 ] || die "run as root"

# The account the hidden admin hatch drops into. Defaults to whoever ran
# sudo, then to the first regular account on the box.
ADMIN_USER=${ADMIN_USER:-${SUDO_USER:-}}
if [ -z "$ADMIN_USER" ] || [ "$ADMIN_USER" = root ]; then
  ADMIN_USER=$(awk -F: '$3 >= 1000 && $3 < 65534 { print $1; exit }' /etc/passwd)
fi
[ -n "$ADMIN_USER" ] || die "could not determine the admin account; set ADMIN_USER=name"
id "$ADMIN_USER" >/dev/null 2>&1 \
  || die "admin user '$ADMIN_USER' does not exist"
[ "$ADMIN_USER" != "$GAMES_USER" ] \
  || die "admin user and kiosk user are both '$GAMES_USER'"

id "$GAMES_USER" >/dev/null 2>&1 \
  || die "user '$GAMES_USER' does not exist; create it first (see docs/04-kiosk-session.md)"

# 'games' is a stock system account (uid 5, home /usr/games) on Ubuntu. If the
# kiosk user resolved to that, autologin would use a system uid and the wrong
# home, and the session would fail. Refuse rather than build a broken kiosk.
kiosk_uid=$(id -u "$GAMES_USER")
[ "$kiosk_uid" -ge 1000 ] \
  || die "user '$GAMES_USER' has uid $kiosk_uid; it must be a normal user (uid >= 1000)"

[ -x "$SCUMMVM_DIR/scummvm" ] \
  || die "$SCUMMVM_DIR/scummvm not found; install ScummVM first (see docs/05-scummvm.md)"

export DEBIAN_FRONTEND=noninteractive

# Only touch apt when something is actually missing. On a client that was
# prepared offline, every package is already installed and this whole block
# is skipped, so no network is needed.
missing_pkgs=()
for p in openbox sddm unclutter xterm x11-xserver-utils dbus-x11; do
  dpkg-query -W -f='${Status}' "$p" 2>/dev/null \
    | grep -q 'install ok installed' || missing_pkgs+=("$p")
done

if [ ${#missing_pkgs[@]} -gt 0 ]; then
  say "installing packages: ${missing_pkgs[*]}"
  if [ -n "${OFFLINE_DEBS:-}" ] && [ -d "$OFFLINE_DEBS" ]; then
    apt-get install -y --no-install-recommends "$OFFLINE_DEBS"/*.deb
  else
    apt-get update -qq
    apt-get install -y --no-install-recommends "${missing_pkgs[@]}"
  fi
else
  say "all kiosk packages already installed"
fi

say "installing kiosk scripts into $PREFIX"
install -d -m 0755 "$PREFIX" "$KIOSK_ETC"
for s in kiosk-session.sh kiosk-supervisor.sh kiosk-admin.sh \
         kiosk-admin-request.sh kiosk-volume.sh kiosk-network.sh \
         scummvm-kiosk.sh make-manifest.sh verify-manifest.sh; do
  install -m 0755 "$REPO_DIR/scripts/$s" "$PREFIX/$s"
done

say "installing kiosk configuration into $KIOSK_ETC"
install -m 0644 "$REPO_DIR/config/openbox-rc.xml" "$KIOSK_ETC/openbox-rc.xml"
printf '%s\n' "$ADMIN_USER" > "$KIOSK_ETC/admin-user"
chmod 0644 "$KIOSK_ETC/admin-user"

say "installing the X session entry"
install -d -m 0755 /usr/share/xsessions
install -m 0644 "$REPO_DIR/config/kiosk.desktop" /usr/share/xsessions/kiosk.desktop

say "configuring SDDM autologin"
install -d -m 0755 /etc/sddm.conf.d
install -m 0644 "$REPO_DIR/config/10-kiosk.conf" /etc/sddm.conf.d/10-kiosk.conf

# Lubuntu's installer writes its own [Autologin] (User=<admin>,
# Session=Lubuntu) into /etc/sddm.conf. SDDM reads that file *after* every
# drop-in, so it wins. Back it up once and write ours there.
if [ -f /etc/sddm.conf ] && [ ! -f "$KIOSK_ETC/sddm.conf.orig" ]; then
  cp -a /etc/sddm.conf "$KIOSK_ETC/sddm.conf.orig"
fi
cat > /etc/sddm.conf <<EOF
# Managed by install-kiosk.sh. SDDM reads this file after sddm.conf.d/,
# so this overrides the desktop autologin written by the installer.
[Autologin]
User=$GAMES_USER
Session=kiosk
Relogin=true
EOF
chmod 0644 /etc/sddm.conf

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
  admin shell   Ctrl+Alt+Shift+F12, then the password for '$ADMIN_USER'
  network       sudo $PREFIX/kiosk-network.sh on|off
  games         $GAMES_HOME/Games

EOF
