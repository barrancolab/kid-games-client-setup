# 01 — Hardware

## Dell Wyse 5060

| Item | Value |
| --- | --- |
| CPU | AMD GX-424CC (quad-core, 2.4 GHz) |
| GPU | Radeon R5E (GCN 1.x, integrated) |
| RAM | 8 GB DDR3L — confirmed installed |
| Internal storage | 64–128 GB flash — confirm with `lsblk -d -o NAME,SIZE,ROTA,MODEL` |
| Video out | DisplayPort (adapter to HDMI if needed) |
| Audio | DisplayPort audio, or the rear 3.5 mm jack |

`ROTA=0` in `lsblk` means non-rotating media (eMMC or SSD). `ROTA=1` means a
spinning disk, which changes the noise and power expectations but not the
build.

The internal disk may appear as `/dev/sda` **or** `/dev/mmcblk0` (eMMC). Always
identify by model and serial, never by letter.

## BIOS

- **F2** — setup
- **F12** — one-time boot menu

Settings to apply:

- UEFI boot on; legacy/CSM off if the installer cooperates
- Secure Boot **off** (the installer is signed, but disabling it avoids
  surprises)
- USB boot enabled
- Network boot (PXE) **off**
- Wake-on-LAN **off**
- AC power recovery: **power on** — the box should come back after a power cut
- Set a BIOS password if the machine is somewhere a child can reach the power
  button and a keyboard

## Peripherals

- **Gamepad:** wired Xbox 360/One-style pads work through SDL with no setup.
  Test the pad in ScummVM's keymapper if a game ignores it.
- **Keyboard/mouse:** needed for installation and admin only. They are not part
  of the child session, but leaving them plugged in is fine — the kiosk blocks
  everything they could reach.
- **Speakers:** TV audio over DisplayPort is simplest; otherwise the rear jack.

## Pre-install checklist

- [ ] `lsblk -d -o NAME,SIZE,ROTA,MODEL,SERIAL` recorded in
      `manifests/versions.example.md`
- [ ] BIOS settings applied
- [ ] Ethernet unplugged
- [ ] Installer USB prepared and verified (see `02-offline-staging.md`)
