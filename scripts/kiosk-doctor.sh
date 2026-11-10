#!/usr/bin/env bash
# kiosk-doctor.sh — find out why the kiosk session did not start, repair the
# usual causes, and leave a report on the USB stick.
#
#   sudo /mnt/kiosk/kiosk-payload/kiosk-doctor.sh
#
# Safe to re-run. It does not reboot; it prints what to do at the end.
set -uo pipefail

GAMES_USER=${GAMES_USER:-kiosk}
GAMES_HOME=/home/$GAMES_USER
SCUMMVM_DIR=${SCUMMVM_DIR:-/opt/scummvm}
SELF_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -d "$SELF_DIR/kid-games-client-setup" ]; then
  REPO_DIR=$SELF_DIR/kid-games-client-setup
elif [ -f "$SELF_DIR/../config/kiosk.desktop" ]; then
  REPO_DIR=$(cd "$SELF_DIR/.." && pwd)
else
  REPO_DIR=""
fi
DEBS_DIR=""
if [ -d "$SELF_DIR/debs" ]; then
  DEBS_DIR=$SELF_DIR/debs
elif [ -n "$REPO_DIR" ] && [ -d "$REPO_DIR/../debs" ]; then
  DEBS_DIR=$(cd "$REPO_DIR/.." && pwd)/debs
fi
REPORT=/root/kiosk-report.txt

say() { printf '\n==> %s\n' "$*"; }
section() { printf '\n===== %s =====\n' "$*" | tee -a "$REPORT"; }
run() { printf '$ %s\n' "$*" | tee -a "$REPORT"; eval "$*" 2>&1 | tee -a "$REPORT"; }

[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }
: > "$REPORT"

ADMIN_USER=${ADMIN_USER:-${SUDO_USER:-}}
if [ -z "$ADMIN_USER" ] || [ "$ADMIN_USER" = root ]; then
  ADMIN_USER=$(awk -F: '$3 >= 1000 && $3 < 65534 { print $1; exit }' /etc/passwd)
fi

# ---------------------------------------------------------------- diagnose
section "system"
run date
run 'uname -a'
run 'echo "running as: $(id -un)"'
run 'loginctl list-sessions --no-legend'

section "display manager"
run 'readlink -f /etc/systemd/system/display-manager.service'
run 'systemctl is-enabled sddm 2>&1'
run 'systemctl is-enabled lightdm 2>&1'
run 'systemctl status display-manager --no-pager -l 2>&1 | head -25'

section "sddm configuration"
run 'ls -la /etc/sddm.conf /etc/sddm.conf.d/ /usr/lib/sddm/sddm.conf.d/ 2>&1'
for f in /etc/sddm.conf /usr/lib/sddm/sddm.conf.d/*.conf /etc/sddm.conf.d/*.conf; do
  [ -f "$f" ] || continue
  printf '\n--- %s ---\n' "$f" | tee -a "$REPORT"
  cat "$f" | tee -a "$REPORT"
done

section "session entries"
run 'ls -la /usr/share/xsessions/ /usr/local/share/xsessions/ 2>&1'
run 'cat /usr/share/xsessions/kiosk.desktop 2>&1'

section "kiosk account"
run 'getent passwd kiosk'
run 'id kiosk 2>&1'
run 'ls -ld /home/kiosk /home/kiosk/Games /home/kiosk/.config/scummvm 2>&1'
run 'grep -x /usr/sbin/nologin /etc/shells || echo "nologin NOT in /etc/shells"'

section "kiosk files"
run 'ls -l /usr/local/bin/kiosk-session.sh /usr/local/bin/kiosk-supervisor.sh \
  /usr/local/bin/kiosk-admin.sh /usr/local/bin/kiosk-admin-request.sh \
  /usr/local/bin/kiosk-volume.sh /usr/local/bin/kiosk-network.sh \
  /usr/local/bin/scummvm-kiosk.sh /etc/kiosk/openbox-rc.xml \
  /etc/kiosk/admin-user 2>&1'

section "scummvm"
run 'ls -l /opt/scummvm/scummvm /usr/games/scummvm 2>&1'
run '/opt/scummvm/scummvm --version 2>&1 | sed -n 1p'
run 'cat /home/kiosk/.config/scummvm/scummvm.ini 2>&1'

section "sddm journal (this boot)"
run 'journalctl -u sddm -b --no-pager 2>&1 | tail -150'

section "autologin-related lines"
run 'journalctl -u sddm -b --no-pager 2>&1 | grep -iE "autologin|session|kiosk|unable|fail|error" | tail -40'

# ---------------------------------------------------------------- repair
say "applying repairs"

# 1. kiosk account, with a nologin shell and a locked password.
if id "$GAMES_USER" >/dev/null 2>&1; then
  current_shell=$(getent passwd "$GAMES_USER" | cut -d: -f7)
  if [ "$current_shell" != /usr/sbin/nologin ]; then
    say "setting $GAMES_USER shell to nologin (was $current_shell)"
    usermod -s /usr/sbin/nologin "$GAMES_USER"
  fi
else
  say "creating $GAMES_USER"
  useradd --create-home --user-group --shell /usr/sbin/nologin "$GAMES_USER"
  passwd -l "$GAMES_USER" >/dev/null 2>&1
fi
grep -qxF /usr/sbin/nologin /etc/shells 2>/dev/null \
  || printf '/usr/sbin/nologin\n' >> /etc/shells

install -d -o "$GAMES_USER" -g "$GAMES_USER" -m 0755 \
  "$GAMES_HOME" "$GAMES_HOME/Games" "$GAMES_HOME/saves" \
  "$GAMES_HOME/.config/scummvm"

# 2. ScummVM path.
if [ ! -x "$SCUMMVM_DIR/scummvm" ]; then
  install -d -m 0755 "$SCUMMVM_DIR"
  ln -sfn /usr/games/scummvm "$SCUMMVM_DIR/scummvm"
fi

# 3. Reinstall the kiosk files from the payload, if the repo is present.
if [ -n "$REPO_DIR" ] && [ -x "$REPO_DIR/scripts/install-kiosk.sh" ]; then
  say "re-running install-kiosk.sh from the payload"
  ADMIN_USER="$ADMIN_USER" OFFLINE_DEBS="$DEBS_DIR" \
    "$REPO_DIR/scripts/install-kiosk.sh" 2>&1 | tee -a "$REPORT"
else
  say "payload repo not found; skipping reinstall"
fi

# 4. Force autologin at the highest-precedence location. SDDM reads
#    /usr/lib/sddm/sddm.conf.d, then /etc/sddm.conf.d, then /etc/sddm.conf,
#    so this overrides anything the installer wrote.
say "forcing autologin in /etc/sddm.conf"
backup=/root/kiosk-backup
install -d -m 0700 "$backup"
if [ -f /etc/sddm.conf ] && [ ! -f "$backup/sddm.conf" ]; then
  cp -a /etc/sddm.conf "$backup/sddm.conf"
fi
cat > /etc/sddm.conf <<EOF
# Managed by kiosk-doctor.sh — this file is read last by SDDM and therefore
# overrides every autologin setting in /etc/sddm.conf.d/.
[Autologin]
User=$GAMES_USER
Session=kiosk
Relogin=true
EOF

# 5. Make sure SDDM is the display manager.
systemctl enable sddm >/dev/null 2>&1 || true
systemctl disable lightdm >/dev/null 2>&1 || true

# ---------------------------------------------------------------- report
section "what changed"
run 'ls -l /etc/sddm.conf /etc/sddm.conf.d/10-kiosk.conf /usr/share/xsessions/kiosk.desktop 2>&1'
run 'getent passwd kiosk'

usb_mount=""
usb_dev=$(blkid -L writable 2>/dev/null || true)
if [ -n "$usb_dev" ]; then
  usb_mount=$(findmnt -no TARGET "$usb_dev" 2>/dev/null || true)
  if [ -z "$usb_mount" ]; then
    mkdir -p /mnt/kiosk
    if mount "$usb_dev" /mnt/kiosk 2>/dev/null; then
      usb_mount=/mnt/kiosk
    fi
  fi
fi

if [ -n "$usb_mount" ]; then
  cp "$REPORT" "$usb_mount/kiosk-report.txt"
  chmod 0644 "$usb_mount/kiosk-report.txt"
  say "report written to $usb_mount/kiosk-report.txt"
else
  say "could not find the USB; report is at $REPORT"
fi

say "done"
cat <<EOF

Autologin has been forced to user '$GAMES_USER', session 'kiosk'.
Reboot to test:

    sudo reboot

If the kiosk still does not appear, bring the USB stick back and the report
at its root (kiosk-report.txt) will say why.

Recovery if the screen stays black: hold Esc at power-on and choose
"Admin console (no kiosk)", then log in as $ADMIN_USER.

EOF
