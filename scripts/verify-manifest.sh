#!/bin/sh
# verify-manifest.sh — verify a sha256 manifest written by make-manifest.sh.
#
#   ./verify-manifest.sh /media/usb/games
set -eu

dir=${1:-}
[ -n "$dir" ] || { echo "usage: $0 DIR" >&2; exit 2; }
[ -f "$dir/manifest.sha256" ] \
  || { echo "no manifest.sha256 in $dir" >&2; exit 1; }

cd "$dir"
sha256sum -c manifest.sha256
