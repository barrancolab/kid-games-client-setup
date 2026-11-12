# 03 — Installing Lubuntu

## Boot the installer

1. Plug the verified installer USB into the Wyse.
2. Power on, tap **F12**, choose the **UEFI: Lexar** entry.
3. Unplug Ethernet. The client should never fetch updates during install.

## If the disk will not erase

The previous OS on this machine was **Proxmox**, which leaves an LVM volume
group called `pve`. Calamares refuses to touch a disk whose mappings are
active, and `wipefs` reports `device or resource busy`.

Fix, on the live session:

```bash
sudo swapoff -a
sudo vgchange -an
sudo zpool export -a 2>/dev/null
sudo dmsetup remove_all

sudo wipefs -a /dev/sda
```

`dmsetup remove_all` is the step that usually clears it.

If it is still busy, bypass the check:

```bash
sudo dd if=/dev/zero of=/dev/sda bs=1M count=64 conv=fsync
sudo partprobe /dev/sda
```

Do this in one session — if you reboot the live medium, the `pve` VG can
reactivate and you are back to `EBUSY`.

## Installer choices

| Step | Choice |
| --- | --- |
| Installation type | **Minimal installation** |
| Disk | Erase whole disk, single ext4 root, no LVM, no encryption |
| Swap | None, or a swap file — 8 GB RAM makes swap irrelevant |
| Third-party drivers | **No** |
| Download updates while installing | **No** |
| Hostname | `kiosk` |
| User | your own account (administrator), e.g. `admin` |
| Ubuntu Pro / Livepatch | Skip |

Do **not** create the `kiosk` user here. It is created in phase 3, after the
kiosk scripts are in place.

## First boot

1. Remove the installer USB.
2. Log in as your account.
3. Confirm the machine is offline and record the disk:

```bash
lsblk -d -o NAME,SIZE,ROTA,TRAN,MODEL,SERIAL
ip address
rfkill list
```

Expected: `ip address` shows only `lo`; `rfkill list` shows Wi-Fi and Bluetooth
blocked or absent.

4. Put the machine's disk model into `manifests/versions.example.md`.

## Finish the install from the USB payload

The payload on the USB's `writable` partition is self-contained: the repo, the
ScummVM package, every missing library, and the game data. No network is
needed on the client.

Plug the USB into the client, open a terminal as your account, and run:

```bash
sudo /media/$USER/writable/kiosk-payload/kid-games-client-setup/scripts/setup-client.sh
```

That one command:

1. installs the offline `.deb` set (unclutter, xterm, SDL2, audio libs),
2. creates the locked `kiosk` user,
3. links `/opt/scummvm/scummvm`,
4. runs `install-kiosk.sh` (Openbox session, SDDM autologin, hardening),
5. adds the GRUB admin-console entry,
6. copies the games to `/home/kiosk/Games`,
7. registers them with ScummVM,
8. writes `manifest.sha256`, and
9. turns networking off.

Then `sudo reboot`.

If the USB mounts somewhere else, pass the payload path explicitly:

```bash
sudo ./scripts/setup-client.sh /media/$USER/writable/kiosk-payload
```

## Copy the repo onto the client (optional)

Only needed if you want the repo on the client after setup:

```bash
cp -r /media/$USER/writable/kiosk-payload/kid-games-client-setup ~/
```

The repo contains no game data and no ISOs, so it is small enough to carry on
the same stick as the games.
