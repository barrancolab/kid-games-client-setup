# Kid Games Client — Dell Wyse 5060

An offline, kid-proof ScummVM gaming box built on a Dell Wyse 5060 thin client
running Lubuntu.

The client is **offline by default**: networking is disabled for normal use, so
the child never has a network connection, a browser, or a route to the
internet. An adult can deliberately enable the network from the admin console
for maintenance, then disable it again. Games and software normally arrive on a
USB stick prepared on a separate internet-connected machine.

## Design goals

- **Offline by default** — no Wi-Fi, no Ethernet, no Bluetooth during a kid
  session. Networking is off unless an adult enables it from the admin console.
- **Kid-proof** — boots straight into a fullscreen ScummVM launcher. No desktop,
  panel, terminal, browser, or file manager.
- **Recoverable** — a verified master USB can rebuild the machine; save games
  are backed up on a schedule.
- **Reproducible** — OS version, ScummVM version, game list, settings, and
  checksums are recorded in this repo.

## Locked decisions

| Decision        | Choice                                             |
| --------------- | -------------------------------------------------- |
| Session         | Full kiosk: autologin → ScummVM                    |
| Hardware        | 8 GB RAM confirmed; 64–128 GB flash storage        |
| Software scope  | ScummVM only (no emulators, no native Linux games) |
| OS              | Lubuntu 26.04.1 LTS                                |
| Network         | Off by default; admin-console toggle only          |
| Admin access    | Hidden key combo + GRUB "admin console" + live USB |

## Bill of materials

| Item                    | Notes                                                        |
| ----------------------- | ------------------------------------------------------------ |
| Dell Wyse 5060          | AMD GX-424CC, Radeon R5E                                     |
| Storage                 | 64–128 GB flash already fitted. Confirm type/size (see below). |
| DDR3L SO-DIMM           | 8 GB — confirmed installed.                                   |
| DisplayPort → HDMI      | Or DP cable, depending on the TV/monitor.                    |
| USB gamepad             | Wired Xbox 360/One-style pads work out of the box via SDL.   |
| Powered speakers        | Or TV audio over DisplayPort/HDMI.                           |
| Master USB stick        | 32 GB+, holds ISO, ScummVM, manifests, recovery image.       |
| Transfer USB stick      | 64–128 GB, holds game data for the client.                   |
| USB keyboard + mouse    | Only for setup and admin; not part of the kid session.       |

## Repository layout

```
README.md                     This file
PLAN.md                       Phased build plan, risks, acceptance criteria
docs/
  01-hardware.md              Wyse 5060 notes, BIOS, peripherals, storage
  02-offline-staging.md       Preparing the USB on the internet machine
  03-lubuntu-install.md       Installing Lubuntu offline
  04-kiosk-session.md         Kiosk design, escape hardening, admin access
  05-scummvm.md               ScummVM install, config, games, controller
  06-operations.md            Adding games, backups, reimaging, troubleshooting
  07-acceptance.md            Test matrix and sign-off checklist
scripts/
  install-kiosk.sh            Install kiosk files on the client (root)
  kiosk-session.sh            X session entry point
  kiosk-supervisor.sh         Relaunch loop + admin shell handoff
  kiosk-admin.sh              Hidden key combo handler
  kiosk-volume.sh             Volume up/down/mute helper
  scummvm-kiosk.sh            ScummVM launcher wrapper
  make-manifest.sh            Generate sha256 manifest for a directory
  verify-manifest.sh          Verify a sha256 manifest
  add-admin-grub-entry.sh     Add the GRUB admin-console boot entry
config/
  kiosk.desktop               X session file for SDDM
  10-kiosk.conf               SDDM autologin config
  99-kiosk-logind.conf        Block VT switching, ignore suspend keys
  99-kiosk-sysctl.conf        Disable magic SysRq
  openbox-rc.xml              Minimal Openbox config + hidden admin keybind
manifests/
  games.example.tsv           Example game inventory format
  versions.example.md         Example version/checksum record
```

## Build order

1. Read [PLAN.md](PLAN.md) for the phase-by-phase roadmap.
2. Inventory and prepare the hardware — [docs/01-hardware.md](docs/01-hardware.md).
3. Build the offline USB kit on the internet machine —
   [docs/02-offline-staging.md](docs/02-offline-staging.md).
4. Install Lubuntu on the thin client —
   [docs/03-lubuntu-install.md](docs/03-lubuntu-install.md).
5. Install and harden the kiosk session —
   [docs/04-kiosk-session.md](docs/04-kiosk-session.md).
6. Install ScummVM and curate games —
   [docs/05-scummvm.md](docs/05-scummvm.md).
7. Run the acceptance tests —
   [docs/07-acceptance.md](docs/07-acceptance.md).
8. Freeze the build, take a recovery image, and tag the repo.

## What must never be committed

- Game data, ISOs, disk images, installers, AppImages, or ROMs.
- Passwords, Wi-Fi keys, or BIOS passwords.
- Anything copyrighted or personally identifying.

`.gitignore` covers the common cases. Checksums and version notes belong in
`manifests/`.

## Status

| Phase | State |
| ----- | ----- |
| Plan and repo scaffold | done |
| Hardware inventory | partial — RAM confirmed, storage to confirm |
| Offline staging USB | installer USB flashed and verified |
| Lubuntu install | not started |
| Kiosk session | scripts and configs written, not yet installed |
| ScummVM + games | Freddi Fish 1 verified on staging |
| Acceptance + freeze | not started |
