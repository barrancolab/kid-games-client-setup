#!/bin/sh
# make-manifest.sh — write a sha256 manifest for a directory tree.
#
#   ./make-manifest.sh /media/usb/games
#
# Produces /media/usb/games/manifest.sha256 with paths relative to the
# directory, so the tree can be verified after copying to another machine.
set -eu

dir=${1:-}
[ -n "$dir" ] || { echo "usage: $0 DIR" >&2; exit 2; }
[ -d "$dir" ] || { echo "not a directory: $dir" >&2; exit 1; }

cd "$dir"

# Skip the manifest itself, and keep the order stable.
find . -type f ! -name manifest.sha256 -print0 \
  | LC_ALL=C sort -z \
  | xargs -0 -r sha256sum > manifest.sha256

printf '%s files hashed into %s/manifest.sha256\n' \
  "$(wc -l < manifest.sha256)" "$dir"
