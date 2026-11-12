# 02 — Offline staging

Everything the client needs is prepared on an internet-connected machine and
carried over on USB. The client itself is offline by default.

## What goes on the installer USB

| Item | Value |
| --- | --- |
| ISO | `lubuntu-26.04.1-desktop-amd64.iso` |
| Size | 3,927,552,000 bytes |
| SHA256 | `a8038585420f2270845549c6f493e0ec98e68d4b2c49571cbe500a4b5fab3062` |

Download and verify:

```bash
cd ~/Downloads/lubuntu-26.04.1
curl -L -O https://cdimage.ubuntu.com/lubuntu/releases/26.04.1/release/lubuntu-26.04.1-desktop-amd64.iso
curl -L -O https://cdimage.ubuntu.com/lubuntu/releases/26.04.1/release/SHA256SUMS
sha256sum -c <(grep 'lubuntu-26.04.1-desktop-amd64.iso' SHA256SUMS)
```

**Do not flash until that prints `OK`.** Flashing a partially downloaded ISO
produces a USB that boots into a broken installer, and the damage is not
obvious from `lsblk`.

Flash to the whole disk, by-id path:

```bash
sudo dd if=lubuntu-26.04.1-desktop-amd64.iso \
  of=/dev/disk/by-id/usb-Your_USB_Drive_SERIAL-0:0 \
  bs=4M status=progress oflag=sync conv=fsync
sync
```

Verify the result at the filesystem level, not just the partition table:

```bash
M="/run/media/$USER/Lubuntu 26.04.1 LTS amd64"
cd "$M" && grep -E 'casper/(minimal\.squashfs|initrd)$' md5sum.txt | md5sum -c -
```

## The two install variants

The ISO ships two rootfs images and Calamares picks one:

| | Minimal | Standard |
| --- | --- | --- |
| Packages | 1,654 | +323 |
| Firefox | no | yes (snap) |
| snapd | no | yes |
| LibreOffice | no | yes |
| LXQt desktop | yes | yes |
| openbox, sddm | yes | yes |
| Games | none | none |

**Always choose Minimal.** It has no browser and no Snap store.

## Game acquisition (Steam, staging machine only)

Steam is a download tool, never part of the client. For each title:

1. Install it on the staging machine.
2. Find the data directory under
   `~/.local/share/Steam/steamapps/common/`.
3. Copy **only** the game data files — not the bundled ScummVM, not `Source/`,
   not the Steam Linux Runtime.
4. Verify with `scummvm --detect --path=<dir>`.
5. Run it headless once to confirm it starts.
6. Record it in `manifests/games.tsv`.

Freddi Fish 1 is the worked example: five files (`Freddi.he0`–`Freddi.he4`,
102 MB) are the entire payload. The bundled ScummVM 2.0.0 and the 227 MB Steam
Runtime are discarded.

## Verified titles

| Title | App ID | ScummVM GameID | Linux | Status |
| --- | --- | --- | --- | --- |
| Freddi Fish 1 | 283940 | `scumm:freddi` | yes | verified |
| Freddi Fish 2 | 294530 | `scumm:freddi2` | yes | compatible |
| Freddi Fish 3 | 294540 | `scumm:freddi3` | yes | compatible |
| Freddi Fish 4 | 294550 | `scumm:freddi4` | yes | compatible |
| Freddi Fish 5 | 294570 | `scumm:freddicove` | yes | compatible |
| Maze Madness | 284020 | `scumm:maze` | yes | compatible |
| Water Worries | 294580 | `scumm:water` | yes | compatible |
| Pajama Sam 1 | 283960 | `scumm:pajama` | yes | compatible |
| Pajama Sam 2 | 292780 | `scumm:pajama2` | yes | compatible |
| Pajama Sam 3 | 292800 | `scumm:pajama3` | yes | compatible |
| Sock Works | 292840 | `scumm:socks` | yes | compatible |
| Lost & Found | 292860 | `scumm:lost` | yes | compatible |
| Games to Play | 317020 | `scumm:pjgames` | yes | compatible |
| **Pajama Sam 4** | 292820 | — | **no** | **excluded** |

Pajama Sam 4 has no Linux build and no ScummVM support. Do not buy or copy it.

## USB layout for the client

```
/games/
  Freddi Fish 1/
    Freddi.he0 … Freddi.he4
  Pajama Sam 1/
    ...
manifest.sha256
```

Generate and verify the manifest with the scripts in this repo:

```bash
./scripts/make-manifest.sh /media/usb/games
./scripts/verify-manifest.sh /media/usb/games
```
