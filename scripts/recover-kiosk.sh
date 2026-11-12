#!/usr/bin/env bash
# recover-kiosk.sh — undo a kiosk autologin that loops, from the live USB.
#
# Boot the installer USB, choose "Try Lubuntu", open a terminal, then:
#
#   sudo mkdir -p /mnt/usb
#   sudo mount -L writable /mnt/usb
#   sudo /mnt/usb/kiosk-payload/recover-kiosk.sh
#
# It finds the installed system on the internal disk, removes the kiosk
# autologin, and restores the normal desktop autologin. It does not touch
# any game data.
set -uo pipefail

say() { printf '\n==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "run with sudo"

rootfs=$(findmnt -no FSTYPE /)
case "$rootfs" in
  overlay|squashfs) ;;
  *) die "this must run from the live USB (root is $rootfs). Boot the installer USB and choose 'Try Lubuntu'." ;;
esac

# ---------------------------------------------------------------- find root
say "looking for the installed Lubuntu system"

# Skip the disk this script is running from, not "every USB disk": some
# thin clients have their internal storage on a USB DOM.
self_dir=$(cd "$(dirname "$0")" && pwd)
boot_part=$(findmnt -no SOURCE --target "$self_dir" 2>/dev/null || true)
boot_disk=""
if [ -n "$boot_part" ]; then
  boot_disk=$(lsblk -no PKNAME "$boot_part" 2>/dev/null | head -1)
fi

candidates=()
while read -r name type fstype; do
  [ "$type" = part ] || continue
  case "$fstype" in ext4|ext3|btrfs|xfs) ;; *) continue ;; esac
  dev=/dev/$name
  parent=$(lsblk -no PKNAME "$dev" 2>/dev/null | head -1)
  [ -n "$parent" ] || continue
  [ -n "$boot_disk" ] && [ "$parent" = "$boot_disk" ] && continue
  candidates+=("$dev")
done < <(lsblk -rno NAME,TYPE,FSTYPE)

[ ${#candidates[@]} -gt 0 ] || die "no internal ext4 partition found"

ROOT=""
for dev in "${candidates[@]}"; do
  mkdir -p /mnt/root
  if mount "$dev" /mnt/root 2>/dev/null; then
    if [ -f /mnt/root/etc/os-release ] \
       && grep -qiE 'lubuntu|ubuntu' /mnt/root/etc/os-release \
       && [ -d /mnt/root/etc ]; then
      ROOT=/mnt/root
      say "installed system: $dev -> /mnt/root"
      break
    fi
    umount /mnt/root
  fi
done

[ -n "$ROOT" ] || die "could not find the installed Lubuntu root"

admin=$(awk -F: '$3 >= 1000 && $3 < 65534 { print $1; exit }' "$ROOT/etc/passwd")
[ -n "$admin" ] || admin=admin

session=Lubuntu
[ -f "$ROOT/usr/share/xsessions/Lubuntu.desktop" ] || session=lxqt

# ---------------------------------------------------------------- back up
backup="$ROOT/root/kiosk-recovery-backup"
mkdir -p "$backup"
for f in etc/sddm.conf etc/sddm.conf.d/10-kiosk.conf etc/sddm.conf.d/zz-kiosk.conf; do
  if [ -f "$ROOT/$f" ]; then
    cp -a "$ROOT/$f" "$backup/$(basename "$f")"
    say "backed up $f"
  fi
done

# ---------------------------------------------------------------- disable
say "removing the kiosk autologin"
rm -f "$ROOT/etc/sddm.conf.d/10-kiosk.conf" \
      "$ROOT/etc/sddm.conf.d/zz-kiosk.conf"

# Neutralise any other drop-in that still points at the kiosk user.
for f in "$ROOT"/etc/sddm.conf.d/*.conf; do
  [ -f "$f" ] || continue
  if grep -qE '^\s*(User|Session|Relogin)=' "$f"; then
    cp -a "$f" "$backup/" 2>/dev/null || true
    sed -i -E 's/^\s*(User|Session|Relogin)=/# \1=/' "$f"
    say "neutralised autologin keys in $(basename "$f")"
  fi
done

# A pending one-shot boot or an in-flight desktop-once boot must not
# rewrite the autologin after we leave.
rm -rf "$ROOT/var/lib/kiosk-boot-mode"
rm -f "$ROOT/etc/systemd/system/graphical.target.wants/kiosk-boot-mode.service"

say "restoring the desktop autologin for $admin"
cat > "$ROOT/etc/sddm.conf" <<EOF
[Autologin]
User=$admin
Session=$session
EOF

# ---------------------------------------------------------------- sanity
say "checking the display manager"
ln -sf /usr/lib/systemd/system/sddm.service \
  "$ROOT/etc/systemd/system/display-manager.service" 2>/dev/null || true
ln -sf /lib/systemd/system/graphical.target \
  "$ROOT/etc/systemd/system/default.target" 2>/dev/null || true

sync
umount /mnt/root || true

say "done"
cat <<EOF

The kiosk autologin is gone. The machine will boot back into the
Lubuntu desktop as '$admin'.

Reboot now, then run the fixed setup from the desktop:

    sudo /mnt/kiosk/kiosk-payload/kid-games-client-setup/scripts/setup-client.sh

EOF
