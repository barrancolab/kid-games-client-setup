# Build Plan

Goal: a Dell Wyse 5060 that powers on into a curated, fullscreen ScummVM game
launcher for young children, with no network access and no easy path to a
desktop.

## Guiding constraints

1. **The client is never online.** Everything is staged on an internet-connected
   machine and carried over on USB.
2. **Frozen beats patched.** An airgapped box has a tiny attack surface. Pin the
   OS and ScummVM versions, record them, and rebuild from the master USB rather
   than applying updates.
3. **Test games before they reach the client.** ScummVM compatibility is
   per-title and per-release. A game that is not verified on the staging machine
   does not go on the USB.
4. **Assume a determined four-year-old.** Escape prevention is layered: no
   desktop, no terminal, blocked VT switching, relaunch loop. It is friction,
   not a security boundary — physical access always wins.
5. **Make recovery boring.** Saves are backed up; the whole SSD can be restored
   from an image in under an hour.

## Phase 0 — Inventory and decisions (half a day)

- [x] Confirm RAM: 8 GB installed.
- [ ] Confirm storage type and exact size (`lsblk -d -o NAME,SIZE,ROTA,MODEL,TRAN`,
      `sudo smartctl -i /dev/sdX`). 64 or 128 GB is plenty for ScummVM.
- [ ] Confirm BIOS access: `F2` setup, `F12` boot menu; note any BIOS password.
- [ ] Decide the display output (DisplayPort vs VGA) and audio path.
- [ ] Confirm a wired USB gamepad is detected on a test machine.
- [ ] Choose the target age band (e.g. 3–6) and a first game list of 8–15 titles.
- [ ] Verify each candidate is supported by the current ScummVM release.
- [ ] Decide the save-backup cadence (suggest: monthly, plus before adding games).

**Exit criteria:** a written game list, a hardware checklist, and no open
questions about ports or storage.

## Phase 1 — Build the offline staging kit (one day, internet machine)

- [ ] Download the Lubuntu LTS ISO and verify its checksum and signature.
- [ ] Download the pinned ScummVM Linux build (AppImage or static tarball) and
      verify its checksum.
- [ ] Acquire games from DRM-free sources where possible (Humble Bundle, GOG).
- [ ] For each Steam title, locate the data directory, test it with ScummVM on
      the staging machine, and record the result.
- [ ] Normalize folder names and strip files ScummVM does not need.
- [ ] Write the game inventory (`manifests/games.tsv`) and version record.
- [ ] Generate `manifest.sha256` for the whole USB and verify it on a second
      machine.

**Exit criteria:** `verify-manifest.sh` passes on a clean machine; every game on
the USB has been launched successfully on the staging machine.

## Phase 2 — Install Lubuntu (1–2 hours)

- [ ] Set BIOS: UEFI, Secure Boot off if needed, USB boot on, AC power recovery
      on, PXE/Wake-on-LAN off, Wi-Fi/Bluetooth off if present.
- [ ] Boot the installer USB and install Lubuntu with the minimal profile.
- [ ] Create `parent` (sudo) only; create `games` later.
- [ ] Partition: single ext4 root, no separate home, swap file or zram.
- [ ] First boot with the Ethernet cable unplugged.
- [ ] Disable networking, Bluetooth, and NTP; set clock and timezone manually.
- [ ] Remove or disable `snapd`, `unattended-upgrades`, and `apport` if present.

**Exit criteria:** `ip address` shows only `lo`; `rfkill list` shows everything
blocked; the machine boots to a desktop with no network errors.

## Phase 3 — Kiosk session (2–4 hours)

- [ ] Create the `games` user (no sudo, random password).
- [ ] Install ScummVM to `/opt/scummvm` and the wrapper to `/usr/local/bin`.
- [ ] Install the kiosk scripts and configs with `scripts/install-kiosk.sh`.
- [ ] Configure SDDM autologin to the `kiosk` X session.
- [ ] Apply escape hardening: `srvrkeys:none`, `DontVTSwitch=yes`, masked
      `ctrl-alt-del.target`, `kernel.sysrq=0`, no panel or desktop icons.
- [ ] Add the GRUB admin-console entry and hide the GRUB menu.
- [ ] Cap volume and disable screen blanking.
- [ ] Test the key-mash matrix in `docs/07-acceptance.md`.

**Exit criteria:** ten minutes of random input never reaches a shell, file
manager, settings app, or login prompt; a reboot returns to ScummVM.

## Phase 4 — Games (1–2 hours per batch)

- [ ] Copy game data to `/home/games/Games/<Title>/` and fix ownership.
- [ ] Add each game in ScummVM; confirm the detected target and engine version.
- [ ] Configure per-game options: subtitles, speech/music/SFX volume, autosave,
      difficulty where available.
- [ ] Test launch, input, audio, save, load, and quit/relaunch.
- [ ] Order the launcher for the child: favorites first, consistent naming.

**Exit criteria:** every title passes the per-game checklist; the launcher fits
on one screen without scrolling for the favorites.

## Phase 5 — Acceptance and freeze (half a day)

- [ ] Run the full acceptance matrix with a child present.
- [ ] Soak test: two hours of play, several power cycles, one deliberate power
      loss while idle.
- [ ] Back up saves to the master USB.
- [ ] Take a compressed disk image of the SSD to the master USB and verify it
      restores to a spare disk (or at least verify the image checksum).
- [ ] Write a one-page recovery card and tape it inside the case or keep it with
      the master USB.
- [ ] Record versions, checksums, and the final game list in `manifests/`.
- [ ] Tag the repo `v1.0`.

**Exit criteria:** all acceptance tests pass; a full reimage has been rehearsed
or verified; the recovery card exists.

## Phase 6 — Ongoing

- [ ] Add games quarterly through the admin console workflow.
- [ ] Back up saves monthly and before any change.
- [ ] Rebuild the image annually from the frozen kit, or when a game requires a
      newer ScummVM.
- [ ] Never connect the client to a network, even "just for a minute".

## Risks and mitigations

| Risk | Impact | Mitigation |
| ---- | ------ | ---------- |
| Steam game data is wrapped, encrypted, or not ScummVM-compatible | Game unusable | Test on the staging machine first; prefer Humble/GOG DRM-free builds |
| Wyse UEFI quirks block the installer | Cannot install | Fall back to legacy BIOS boot; disable Secure Boot |
| AppImage needs FUSE, which is missing | ScummVM will not start | Use the static tarball, or run with `APPIMAGE_EXTRACT_AND_RUN=1` |
| Child finds the admin key combo | Desktop access as `games` | Combo is obscure; `games` has no sudo; full admin still needs the GRUB console |
| Power loss during a save | Corrupt save | ext4 journal, autosave where supported, monthly backups |
| SSD fills up | Cannot add games | 128 GB SSD, inventory sizes, prune before adding |
| No security updates | Theoretically vulnerable | Airgapped, no browser, no untrusted media, frozen and rebuilt |
| BIOS settings changed by a child | Boot failure | BIOS password, locked case if needed |

## Timeline

| Week | Work |
| ---- | ---- |
| 1 | Phase 0 and Phase 1: inventory, staging USB, game verification |
| 2 | Phase 2 and Phase 3: install, kiosk, escape testing |
| 3 | Phase 4: games, per-game tuning |
| 4 | Phase 5: acceptance, backups, recovery image, tag `v1.0` |

## Definition of done

- Cold boot reaches the game launcher in under 40 seconds with no login prompt.
- The machine has no network interfaces other than loopback.
- A child cannot reach a shell, file manager, settings app, or the desktop.
- Every curated game launches, plays audio, accepts input, and saves/loads.
- The controller works in every game.
- Saves survive a reboot and a power cycle.
- The master USB rebuilds the machine from scratch.
- The repo records exact versions, checksums, and the game list.
