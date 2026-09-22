#!/usr/bin/env bash
#
# 3_configure_base.sh - Configure hostname, timezone, locales, users,
#                       sudo access, and systemd-boot UKI for a fresh
#                       Arch Linux installation. Run inside arch-chroot.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_usage() {
    cat << EOF
Usage: ${0} [-hai] hostname root_partition username
Config hostname, time zone, locales, root password, bootloader, user

-h          Display help
-a          Install AMD microcodes
-i          Install INTEL microcodes

EOF
}

options=$(getopt -o hai -- "$@")
if [ $? != 0 ]; then show_usage; exit 1; fi
eval set -- "${options}"

# Microcode image path embedded into the UKI via mkinitcpio.
UCODE_IMAGE=""
while true; do
    case "$1" in
    -h) show_usage; exit 0 ;;
    -a) UCODE_IMAGE="/boot/amd-ucode.img" ;;
    -i) UCODE_IMAGE="/boot/intel-ucode.img" ;;
    --) shift; break ;;
    esac
    shift
done

[[ $# -lt 3 ]] && show_usage && exit 1

HOSTNAME="$1"
ROOT_PARTITION="$2"
USERNAME="$3"

[[ ! -b "$ROOT_PARTITION" ]] \
    && echo "Disk: $ROOT_PARTITION should be a block device" && exit 1

# ---------------------------------------------------------------------------
# Hostname
# ---------------------------------------------------------------------------
echo "#>> Setting hostname $HOSTNAME"
echo "$HOSTNAME" > /etc/hostname

# ---------------------------------------------------------------------------
# Timezone
# ---------------------------------------------------------------------------
echo "#>> Setting timezone"
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# ---------------------------------------------------------------------------
# Locales
# ---------------------------------------------------------------------------
echo "#>> Generating locales"
printf 'en_US.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8\n' > /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# ---------------------------------------------------------------------------
# Root password
# ---------------------------------------------------------------------------
echo "#>> Setting password for root"
passwd

# ---------------------------------------------------------------------------
# User account + sudo
# ---------------------------------------------------------------------------
echo "#>> Creating user $USERNAME"
if id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME already exists, skipping useradd"
else
    useradd -m -G wheel -s /bin/bash "$USERNAME"
fi
passwd "$USERNAME"

echo "#>> Granting wheel sudo privileges"
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel

# ---------------------------------------------------------------------------
# UKI / systemd-boot
# ---------------------------------------------------------------------------
echo "#>> Configuring UKI"
echo "root=PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PARTITION") rw" \
    > /etc/kernel/cmdline

# Install mkinitcpio preset. When a microcode image is selected we append
# default_options so mkinitcpio embeds it into the generated UKI. Appending
# is safe because later assignments override earlier ones in preset files,
# and the shipped preset has default_options commented out.
cp "$SCRIPT_DIR/linux-lts.preset" /etc/mkinitcpio.d/linux-lts.preset

bootctl install

mkdir -p /efi/loader
cp "$SCRIPT_DIR/template/loader.conf" /efi/loader/loader.conf

mkinitcpio -P
