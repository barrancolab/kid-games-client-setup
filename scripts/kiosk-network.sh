#!/bin/sh
# kiosk-network.sh — soft airgap switch.
#
#   kiosk-network.sh on    bring networking up (maintenance window)
#   kiosk-network.sh off   take it back down (normal state)
#   kiosk-network.sh       report current state
#
# Run as root. The client is offline by default; this is the only supported
# way to put it online, and it must be turned off again afterwards.
set -u

usage() {
  echo "usage: $0 [on|off|status]" >&2
  exit 2
}

[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }

radio_off() {
  nmcli radio wifi off 2>/dev/null || true
  nmcli radio wwan off 2>/dev/null || true
  rfkill block wifi bluetooth wwan 2>/dev/null || true
}

case ${1:-status} in
  on)
    rfkill unblock wifi bluetooth wwan 2>/dev/null || true
    nmcli networking on 2>/dev/null || true
    nmcli radio wifi on 2>/dev/null || true
    echo "networking ON — remember to run '$0 off' when finished"
    ;;
  off)
    nmcli networking off 2>/dev/null || true
    radio_off
    echo "networking OFF"
    ;;
  status)
    ;;
  *)
    usage
    ;;
esac

echo "--- interfaces ---"
ip -brief address 2>/dev/null || ip address
echo "--- radios ---"
rfkill list 2>/dev/null || true
