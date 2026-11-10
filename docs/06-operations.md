# 06 — Operations

## Adding a game

1. On the staging machine, install the title in Steam.
2. Locate its data directory and copy only the engine files to the USB:
   `/games/<Title>/`.
3. Test it on the staging machine:

   ```bash
   scummvm --detect --path="/games/<Title>"
   ```

4. Copy to the client: `/home/kiosk/Games/<Title>/`.
5. Fix ownership: `sudo chown -R kiosk:kiosk "/home/kiosk/Games/<Title>"`.
6. Add it: `sudo -u kiosk /usr/local/bin/scummvm-kiosk.sh --add --path=...`
7. Launch it once and check audio, input, save, and load.
8. Record it in `manifests/games.tsv`.

## Backing up saves

Saves live in `/home/kiosk/saves/`. They are small.

```bash
sudo tar czf /media/usb/saves-$(date +%F).tar.gz -C /home/kiosk saves
```

Do this monthly, and before any change to the machine.

## Maintenance window (network)

```bash
sudo kiosk-network.sh on
sudo apt update && sudo apt full-upgrade
sudo kiosk-network.sh off
ip address          # must show only lo
```

Update `manifests/versions.example.md` afterwards and re-run the acceptance
tests. Never leave the machine networked after the window closes.

## Getting the desktop for exactly one boot

The kiosk autologins, so there is no greeter to pick a session from. To get
one, arm the one-shot and reboot:

```bash
sudo kiosk-desktop-once
```

The next boot starts SDDM normally and you can choose the **Lubuntu** session.
The boot after that restores the kiosk autologin automatically, so no cleanup
is needed.

- Arm it without rebooting now: `sudo kiosk-desktop-once --no-reboot`
- Cancel before rebooting: `sudo kiosk-desktop-once --cancel`

This works from the kiosk admin shell (`Ctrl+Alt+Shift+F12`) and from the
GRUB "Admin console (no kiosk)" entry. It only rewrites `/etc/sddm.conf` for
that one boot; the saved kiosk config is restored before SDDM starts again.

## Rebuilding the client

1. Reflash the installer USB from the verified ISO.
2. Install Lubuntu minimal.
3. Copy this repo over.
4. `sudo ./scripts/install-kiosk.sh`
5. `sudo ./scripts/add-admin-grub-entry.sh`
6. Copy games from the master USB and re-add them.
7. Verify with `verify-manifest.sh`.

## Troubleshooting

### Installer will not erase the disk

Proxmox leftovers. See `03-lubuntu-install.md`.

### `wipefs: device or resource busy`

Active LVM or device-mapper. `sudo dmsetup remove_all`, then retry.

### Kiosk boots to a black screen

The session started but ScummVM did not. Log in via the GRUB admin console:

```bash
journalctl -u sddm -b
sudo -u kiosk /usr/local/bin/scummvm-kiosk.sh
```

### ScummVM restarts constantly

It is crashing on startup. Run it as `kiosk` from the admin console and read
the output. A missing game path or an unreadable save directory are the usual
causes.

### Game audio is missing

```bash
sudo -u kiosk pactl info
sudo -u kiosk wpctl status
```

The `kiosk` user needs access to the audio session. On PipeWire this normally
works; if not, add `kiosk` to the `audio` group.

### Controller not detected

Check `lsusb` and `evtest`. ScummVM reports joysticks in its log at startup.

### Forgot the admin password

Boot the GRUB admin console, log in as your admin account. If that password is also lost,
boot a live USB and `chroot` — the machine is not bricked, just inconvenient.
