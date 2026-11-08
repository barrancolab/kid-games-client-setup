#!/usr/bin/env bash
# add-admin-grub-entry.sh — add a "boot to a text console" GRUB entry.
#
# Run as root on the thin client:
#
#   sudo ./scripts/add-admin-grub-entry.sh
#
# This is the recovery hatch that does not depend on the kiosk session
# starting. It boots the same kernel into multi-user.target, giving a normal
# getty login on tty1 with no X server and no ScummVM.
#
# It also hides the GRUB menu so a child does not see the choice. Hold Esc
# (UEFI) or Shift (BIOS) during power-on to reveal it.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }

kernel=$(ls -1 /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1)
initrd=$(ls -1 /boot/initrd.img-* 2>/dev/null | sort -V | tail -1)
[ -n "$kernel" ] || { echo "no kernel found in /boot" >&2; exit 1; }
[ -n "$initrd" ] || { echo "no initrd found in /boot" >&2; exit 1; }

root_uuid=$(findmnt -no UUID /)
[ -n "$root_uuid" ] || { echo "could not read the root filesystem UUID" >&2; exit 1; }

kernel_path=${kernel#/boot/}
initrd_path=${initrd#/boot/}

cat > /etc/grub.d/40_admin_console <<EOF
#!/bin/sh
exec tail -n +3 \$0

menuentry 'Admin console (no kiosk)' --class ubuntu --class gnu-linux --class gnu --class os {
    load_video
    insmod gzio
    insmod part_gpt
    insmod ext2
    search --no-floppy --fs-uuid --set=root $root_uuid
    linux /boot/$kernel_path root=UUID=$root_uuid ro systemd.unit=multi-user.target
    initrd /boot/$initrd_path
}
EOF
chmod 0755 /etc/grub.d/40_admin_console

# Hide the menu; GRUB_RECORDFAIL_TIMEOUT stops a failed boot from parking
# the machine on a menu forever.
for kv in GRUB_TIMEOUT=0 GRUB_TIMEOUT_STYLE=hidden GRUB_RECORDFAIL_TIMEOUT=0; do
  key=${kv%%=*}
  if grep -q "^${key}=" /etc/default/grub; then
    sed -i "s|^${key}=.*|${kv}|" /etc/default/grub
  else
    printf '%s\n' "$kv" >> /etc/default/grub
  fi
done

update-grub

echo "Admin console entry installed for kernel $kernel_path"
echo "Hold Esc during power-on to show the GRUB menu."
