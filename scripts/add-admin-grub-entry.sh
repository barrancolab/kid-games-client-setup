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

# Keep the menu invisible, but leave a few seconds in which Esc/Shift
# reveals it. A zero timeout makes the admin hatch unreachable on UEFI
# machines that do not catch the key in time.
for kv in GRUB_TIMEOUT=3 GRUB_TIMEOUT_STYLE=hidden GRUB_RECORDFAIL_TIMEOUT=3; do
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
