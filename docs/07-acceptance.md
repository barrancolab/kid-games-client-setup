# 07 — Acceptance

Run this with a child present. Pass/fail only; no partial credit.

## Boot

| # | Test | Pass |
| --- | --- | --- |
| 1 | Cold boot reaches the ScummVM launcher in under 40 s | |
| 2 | No login prompt appears | |
| 3 | No desktop, panel, dock, or wallpaper appears at any point | |
| 4 | Reboot returns to the launcher | |
| 5 | Power cycle during idle returns to the launcher | |

## Escape attempts

Ten minutes of deliberate mashing, with a keyboard and mouse attached.

| # | Input | Expected | Pass |
| --- | --- | --- | --- |
| 6 | Alt+Tab, Alt+F4, Super, Super+D | nothing | |
| 7 | Ctrl+Alt+F1 … F12 | nothing | |
| 8 | Ctrl+Alt+Backspace | nothing | |
| 9 | Ctrl+Alt+Del | nothing | |
| 10 | Alt+SysRq+REISUB | nothing | |
| 11 | Right-click on the game list | no root menu | |
| 12 | ScummVM Quit button | back to ScummVM in ~1 s | |
| 13 | ScummVM Quit, repeatedly | never reaches a desktop | |
| 14 | Ctrl+Alt+Shift+F12, then Ctrl+C / Ctrl+D / Enter | no shell without the password | |

## Games

Repeat for every installed title.

| # | Test | Pass |
| --- | --- | --- |
| 15 | Launches from the launcher | |
| 16 | Runs fullscreen, no window border | |
| 17 | Audio plays, volume keys work | |
| 18 | Gamepad controls the game | |
| 19 | Save works, and the save survives a reboot | |
| 20 | Load works | |
| 21 | Returning to the launcher works, and the game can be relaunched | |

## Network

| # | Test | Pass |
| --- | --- | --- |
| 22 | `ip address` shows only `lo` | |
| 23 | `rfkill list` shows Wi-Fi/Bluetooth blocked or absent | |
| 24 | `kiosk-network.sh on` brings the link up | |
| 25 | `kiosk-network.sh off` brings it down and it stays down after reboot | |

## Admin

| # | Test | Pass |
| --- | --- | --- |
| 26 | Hidden combo asks for a password | |
| 27 | Wrong password returns to ScummVM | |
| 28 | Correct password gives a shell as `parent` | |
| 29 | GRUB menu is hidden at boot | |
| 30 | Esc at power-on reveals the menu | |
| 31 | "Admin console (no kiosk)" boots to a text login | |

## Soak

| # | Test | Pass |
| --- | --- | --- |
| 32 | Two hours of play without a crash | |
| 33 | Five power cycles without intervention | |
| 34 | Deliberate power loss while idle recovers | |
| 35 | Saves are intact after the above | |

## Freeze

- [ ] `manifests/games.tsv` matches what is installed
- [ ] `manifests/versions.example.md` records the real versions
- [ ] `make-manifest.sh` / `verify-manifest.sh` pass on the master USB
- [ ] Disk image taken and checksum verified
- [ ] Recovery card written and stored with the master USB
- [ ] Repo tagged `v1.0`
