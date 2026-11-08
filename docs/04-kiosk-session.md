# 04 — Kiosk session

The client boots straight into ScummVM. There is no desktop, no panel, no
terminal, no browser, and no file manager in the child's path.

## Design

```
SDDM (autologin as 'games')
  └── kiosk.desktop  ->  /usr/local/bin/kiosk-session.sh
        ├── xset / xsetroot / unclutter      no blanking, black root, no cursor
        ├── openbox --config-file /etc/kiosk/openbox-rc.xml
        └── kiosk-supervisor.sh
              ├── scummvm-kiosk.sh           the game launcher, fullscreen
              └── kiosk-admin.sh             only when the hidden combo fired
```

Layers of protection, weakest to strongest:

1. **No desktop session is reachable.** The `games` user has exactly one
   X session available: `kiosk`.
2. **Openbox has no keybinds.** No Alt+Tab, no Alt+F4, no root menu, no
   workspace switching. Only the admin combo and the media keys.
3. **VT switching is disabled.** `XKBOPTIONS="srvrkeys:none"` in
   `/etc/default/keyboard` stops Ctrl+Alt+F1..F12.
4. **SysRq is off.** `kernel.sysrq = 0`.
5. **Ctrl+Alt+Del is masked.** `systemctl mask ctrl-alt-del.target`.
6. **ScummVM is relaunched if it exits.** Quitting the launcher just restarts
   it, so "Quit" leads nowhere.

None of this is a security boundary. A child with a screwdriver and a USB stick
wins. It is friction, and it is enough.

## Creating the games user

```bash
sudo useradd --create-home --shell /usr/sbin/nologin games
sudo passwd -l games          # no password, no login
```

`games` has no sudo. It owns `/home/games` and nothing else.

## ScummVM's own settings

`/home/games/.config/scummvm/scummvm.ini`:

```ini
[scummvm]
fullscreen=true
confirm_exit=true
gui_return_to_launcher_at_exit=true
savepath=/home/games/saves
extrapath=/opt/scummvm/extra
```

- `gui_return_to_launcher_at_exit=true` — leaving a game returns to the game
  list instead of closing ScummVM. This is what lets a child switch games.
- `confirm_exit=true` — quitting the launcher asks "Do you want to Quit?".
  A stray click does not end the session.

There is no option to remove the launcher's Quit button. The supervisor is the
answer: quitting returns to ScummVM within about a second.

## Installing

```bash
sudo ./scripts/install-kiosk.sh
sudo ./scripts/add-admin-grub-entry.sh
sudo reboot
```

`install-kiosk.sh` is idempotent.

## Admin access

Two independent hatches, both password-protected.

### Hidden key combo

**Ctrl+Alt+Shift+F12** inside the kiosk session. This:

1. kills ScummVM,
2. opens a fullscreen `xterm`,
3. runs `su - parent`, which asks for the admin password.

Wrong password: the terminal exits and ScummVM comes back. Nothing is
reachable without the password. Note that the game is interrupted as soon as
the combo is pressed — that is deliberate, so mashing the keys does not leave a
login prompt sitting on screen.

### GRUB admin console

`add-admin-grub-entry.sh` adds a "Admin console (no kiosk)" menu entry that
boots to `multi-user.target` — a plain text login, no X, no ScummVM. It also
hides the GRUB menu.

Hold **Esc** during power-on to reveal the menu, pick the admin entry, log in
as `parent`.

This hatch works even if the kiosk session is broken.

## Network

The client is offline by default. To enable networking for a maintenance
window:

```bash
sudo kiosk-network.sh on
# ... do the work ...
sudo kiosk-network.sh off
```

`off` runs `nmcli networking off` and blocks the radios with `rfkill`.
Autoconnect is never enabled.

## Acceptance

See `07-acceptance.md`. The key test: ten minutes of random input never reaches
a shell, a file manager, a settings app, or a login prompt.
