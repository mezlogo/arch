#!/usr/bin/env bash
#
# lspci_firmware.sh - print which linux-firmware split packages to install
#                     based on the wired/wireless devices lspci reports.
#
set -euo pipefail

wired=$(lspci -nn | grep -i 'ethernet' || true)
wireless=$(lspci -nn | grep -i 'network controller' || true)

print_firmware() {
    case "$1" in
        *Intel*)               echo "linux-firmware-intel" ;;
        *Realtek*)             echo "linux-firmware-realtek" ;;
        *MediaTek*)            echo "linux-firmware-mediatek" ;;
        *Qualcomm*|*Atheros*)  echo "linux-firmware-atheros" ;;
        *Broadcom*)            echo "linux-firmware-broadcom" ;;
        *Virtio*)              echo "(none - virtio is built into the kernel)" ;;
        *)                     echo "linux-firmware" ;;
    esac
}

if [[ -n "$wired" ]]; then
    echo "wired device:"
    echo "$wired"
    echo "install: $(print_firmware "$wired")"
else
    echo "wired device: none"
fi

echo

if [[ -n "$wireless" ]]; then
    echo "wireless device:"
    echo "$wireless"
    echo "install: $(print_firmware "$wireless")"
else
    echo "wireless device: none"
fi
