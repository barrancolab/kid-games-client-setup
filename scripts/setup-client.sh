#!/usr/bin/env bash
# setup-client.sh — finish a fresh Lubuntu install and turn it into the kiosk.
#
# Run as root, straight from the USB payload:
#
#   sudo /media/parent/writable/kiosk-payload/kid-games-client-setup/scripts/setup-client.sh
#
# The payload directory is found next to this repository (../debs, ../games).
# Pass it explicitly if the layout differs:
#
#   sudo ./scripts/setup-client.sh /path/to/kiosk-payload
#
# Everything here works without a network. It is idempotent: re-running it
# will not duplicate games or overwrite an existing ScummVM config.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAYLOAD_DIR="${1:-$(cd "$REPO_DIR/.." && pwd)}"
DEBS="$PAYLOAD_DIR/debs"
GAMES_SRC="$PAYLOAD_DIR/games"

GAMES_USER=${GAMES_USER:-games}
GAMES_HOME=/home/$GAMES_USER
SCUMMVM_DIR=${SCUMMVM_DIR:-/opt/scummvm}
INI="$GAMES_HOME/.config/scummvm/scummvm.ini"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
say() { printf '\n==> %s\n' "$*"; }

[ "$(id -u)" -eq 0 ] || die "run as root"
[ -d "$DEBS" ]      || die "no debs directory at $DEBS"
[ -d "$GAMES_SRC" ] || die "no games directory at $GAMES_SRC"

# ---------------------------------------------------------------- packages
say "installing packages from $DEBS (no network needed)"
export DEBIAN_FRONTEND=noninteractive
apt-get install -y --no-install-recommends "$DEBS"/*.deb

[ -x /usr/games/scummvm ] || die "scummvm was not installed"

# ---------------------------------------------------------------- games user
if id "$GAMES_USER" >/dev/null 2>&1; then
  say "user '$GAMES_USER' already exists"
else
  say "creating user '$GAMES_USER'"
  useradd --create-home --shell /usr/sbin/nologin "$GAMES_USER"
  passwd -l "$GAMES_USER" >/dev/null
fi

# SDDM's PAM stack may consult /etc/shells; nologin must be listed there for
# the account to be accepted, while still refusing interactive logins.
grep -qxF /usr/sbin/nologin /etc/shells 2>/dev/null \
  || printf '/usr/sbin/nologin\n' >> /etc/shells

# ---------------------------------------------------------------- scummvm
say "pointing $SCUMMVM_DIR at the installed binary"
install -d -m 0755 "$SCUMMVM_DIR"
ln -sfn /usr/games/scummvm "$SCUMMVM_DIR/scummvm"
scummvm_out=$("$SCUMMVM_DIR/scummvm" --version 2>&1)
scummvm_version=${scummvm_out%%$'\n'*}
printf '%s\n' "$scummvm_version"

# ---------------------------------------------------------------- kiosk
say "installing the kiosk session"
OFFLINE_DEBS="$DEBS" "$REPO_DIR/scripts/install-kiosk.sh"

say "adding the GRUB admin console entry"
"$REPO_DIR/scripts/add-admin-grub-entry.sh"

# ---------------------------------------------------------------- games
say "copying games into $GAMES_HOME/Games"
install -d -o "$GAMES_USER" -g "$GAMES_USER" -m 0755 "$GAMES_HOME/Games"
for src in "$GAMES_SRC"/*/; do
  [ -d "$src" ] || continue
  name=$(basename "$src")
  dest="$GAMES_HOME/Games/$name"
  if [ -d "$dest" ]; then
    say "already present: $name"
  else
    cp -a "$src" "$dest"
    say "copied: $name"
  fi
done
chown -R "$GAMES_USER:$GAMES_USER" "$GAMES_HOME/Games"

# ---------------------------------------------------------------- register
say "registering games with ScummVM"
[ -f "$INI" ] || die "ScummVM config missing: $INI"

registered=0
for src in "$GAMES_HOME"/Games/*/; do
  [ -d "$src" ] || continue
  path=${src%/}
  if grep -qF "path=$path" "$INI"; then
    say "already registered: $(basename "$path")"
    continue
  fi
  sudo -u "$GAMES_USER" env SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy \
    "$SCUMMVM_DIR/scummvm" --config="$INI" --add --recursive --path="$path"
  registered=$((registered + 1))
done

# --add turns aspect correction off for these 4:3 games; turn it back on so
# they are pillarboxed instead of stretched across a 16:9 TV.
sed -i 's/ noAspect//g' "$INI"
chown "$GAMES_USER:$GAMES_USER" "$INI"

# ---------------------------------------------------------------- manifest
say "writing a checksum manifest"
"$REPO_DIR/scripts/make-manifest.sh" "$GAMES_HOME/Games"

# ---------------------------------------------------------------- offline
say "making sure networking is off"
"$REPO_DIR/scripts/kiosk-network.sh" off || true

# ---------------------------------------------------------------- summary
say "done"
printf 'games user      %s (locked password, nologin shell)\n' "$GAMES_USER"
printf 'scummvm         %s\n' "$scummvm_version"
printf 'registered now  %s new game(s)\n' "$registered"
printf 'games directory %s\n' "$GAMES_HOME/Games"
printf 'admin shell     Ctrl+Alt+Shift+F12, then the parent password\n'
printf 'admin boot      hold Esc at power-on, pick "Admin console (no kiosk)"\n'
printf '\nReboot to start the kiosk:\n\n  sudo reboot\n\n'
