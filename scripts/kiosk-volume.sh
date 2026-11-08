#!/bin/sh
# kiosk-volume.sh — volume up/down/mute, for the media keys.
#
# Tries PipeWire (wpctl) first, then PulseAudio (pactl), then plain ALSA.
set -u

step=${KIOSK_VOLUME_STEP:-5}

usage() {
  echo "usage: $0 up|down|mute" >&2
  exit 2
}

[ $# -eq 1 ] || usage

if command -v wpctl >/dev/null 2>&1; then
  case $1 in
    up)   wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}%+" ;;
    down) wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}%-" ;;
    mute) wpctl set-mute   @DEFAULT_AUDIO_SINK@ toggle ;;
    *)    usage ;;
  esac
elif command -v pactl >/dev/null 2>&1; then
  case $1 in
    up)   pactl set-sink-volume @DEFAULT_SINK@ "+${step}%" ;;
    down) pactl set-sink-volume @DEFAULT_SINK@ "-${step}%" ;;
    mute) pactl set-sink-mute   @DEFAULT_SINK@ toggle ;;
    *)    usage ;;
  esac
elif command -v amixer >/dev/null 2>&1; then
  case $1 in
    up)   amixer -q sset Master "${step}%+" ;;
    down) amixer -q sset Master "${step}%-" ;;
    mute) amixer -q sset Master toggle ;;
    *)    usage ;;
  esac
else
  echo "no audio mixer found (wpctl, pactl, amixer)" >&2
  exit 1
fi
