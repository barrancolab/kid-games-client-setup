# 05 — ScummVM

## Install

Use the pinned Ubuntu 26.04 build, not the distro package, so the version is
recorded and reproducible.

```bash
# on the staging machine, download and verify
curl -LO https://downloads.scummvm.org/frs/scummvm/2026.4.0/scummvm_2026.4.0-1_ubuntu26_04_amd64.deb
curl -LO https://downloads.scummvm.org/frs/scummvm/2026.4.0/scummvm_2026.4.0-1_ubuntu26_04_amd64.deb.sha256
sha256sum -c scummvm_2026.4.0-1_ubuntu26_04_amd64.deb.sha256
```

Then on the client:

```bash
sudo dpkg -i scummvm_2026.4.0-1_ubuntu26_04_amd64.deb
sudo apt-get -f install
sudo mkdir -p /opt/scummvm
sudo ln -sf /usr/games/scummvm /opt/scummvm/scummvm   # or copy the binary
```

Check:

```bash
/opt/scummvm/scummvm --version
```

## Adding games

Game data lives in `/home/games/Games/<Title>/`. Add each one once:

```bash
sudo -u games /usr/local/bin/scummvm-kiosk.sh --add --recursive \
  --path="/home/games/Games/Freddi Fish 1"
```

Or interactively from the launcher: **Add Game** → pick the folder.

Verify the detected target:

```bash
sudo -u games /opt/scummvm/scummvm \
  --config=/home/games/.config/scummvm/scummvm.ini \
  --detect --path="/home/games/Games/Freddi Fish 1"
```

Expected for Freddi Fish 1: GameID `scumm:freddi`, target `freddi-win`. The
target is the section name in `scummvm.ini`; the GameID identifies the engine.

## Per-game settings worth changing

| Setting | Why |
| --- | --- |
| Subtitles on | Kids read along; also helps with muted audio |
| Speech volume up, music down | Dialogue carries the game |
| Autosave on | Power cuts and stray quits |
| Aspect ratio correction | 4:3 games look right on a 16:9 TV |
| Original save/load menus | Simpler than ScummVM's |

Set these in **Options** from inside the game so they are stored per-target.

## Controller

ScummVM maps a wired Xbox-style pad out of the box. If a game ignores it, open
**Options → Keymaps** and bind the pad's A/B to left/right click.

Test every game with the pad, not the mouse. A game that only works with a
mouse is a game a four-year-old cannot play.

## Verified payload sizes

| Game | Files | Size |
| --- | --- | --- |
| Freddi Fish 1 | `Freddi.he0`–`he4` | 102 MB |

Record new titles in `manifests/games.tsv` as you add them.

## What not to copy

From a Steam install, skip:

- `ScummVM_Linux/` — a bundled ScummVM 2.0.0 that needs `libpng12`,
  `libtheoradec` and `libsndio` and will not run on a modern system
- `Source/` — the upstream source archives
- `SteamLinuxRuntime/` — 227 MB that ScummVM never uses
- `Saves/` — empty placeholder

Only the engine data files matter.
