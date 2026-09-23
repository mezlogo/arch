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
Usage: ${0} [-hai] <hostname> <root_partition> <username>

Configure hostname, timezone, locales, root/user passwords, sudo for
the wheel group, and a systemd-boot UKI for a fresh Arch installation.

Arguments:
  hostname         System hostname (written to /etc/hostname)
  root_partition   Block device of the root filesystem, e.g. /dev/vda2
  username         Unprivileged user to create (added to wheel)

Options:
  -h               Display this help and exit
  -a               Embed AMD microcode (/boot/amd-ucode.img) into the UKI
  -i               Embed Intel microcode (/boot/intel-ucode.img) into the UKI
EOF
}

die() { echo "Error: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Preconditions
# ---------------------------------------------------------------------------

(( EUID == 0 )) || die "must be run as root"

[[ -d /etc/systemd ]] \
    || die "this script must be run inside the installed system (arch-chroot)"

# ---------------------------------------------------------------------------
# Parse options
# ---------------------------------------------------------------------------

UCODE_IMAGE=""
while getopts ':hai' opt; do
    case "$opt" in
        h) show_usage; exit 0 ;;
        a) UCODE_IMAGE="/boot/amd-ucode.img" ;;
        i) UCODE_IMAGE="/boot/intel-ucode.img" ;;
        \?) die "unknown option: -$OPTARG (see -h)" ;;
    esac
done
shift $((OPTIND - 1))

[[ $# -eq 3 ]] || { show_usage; exit 1; }

HOSTNAME="$1"
ROOT_PARTITION="$2"
USERNAME="$3"

[[ -b "$ROOT_PARTITION" ]] \
    || die "$ROOT_PARTITION is not a block device"

[[ -n "$HOSTNAME" ]] || die "hostname must not be empty"
[[ -n "$USERNAME" ]] || die "username must not be empty"

# ---------------------------------------------------------------------------
# Hostname
# ---------------------------------------------------------------------------
echo "#>> Setting hostname $HOSTNAME"
echo "$HOSTNAME" > /etc/hostname

# ---------------------------------------------------------------------------
# Timezone
# ---------------------------------------------------------------------------
echo "#>> Setting timezone to Europe/Moscow"
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
# Console keymap
# ---------------------------------------------------------------------------
# The sd-vconsole hook warns loudly if /etc/vconsole.conf is missing.
# 'us' is a safe default; change to 'ru' if you prefer.
if [[ ! -f /etc/vconsole.conf ]]; then
    echo "#>> Writing /etc/vconsole.conf"
    echo 'KEYMAP=us' > /etc/vconsole.conf
fi

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
echo "#>> Setting password for $USERNAME"
passwd "$USERNAME"

echo "#>> Granting wheel sudo privileges"
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel
visudo -cf /etc/sudoers.d/wheel || die "invalid sudoers syntax"

# ---------------------------------------------------------------------------
# Kernel command line
# ---------------------------------------------------------------------------
echo "#>> Writing /etc/kernel/cmdline"
ROOT_PARTUUID="$(blkid -s PARTUUID -o value "$ROOT_PARTITION")"
[[ -n "$ROOT_PARTUUID" ]] \
    || die "could not read PARTUUID from $ROOT_PARTITION"
echo "root=PARTUUID=${ROOT_PARTUUID} rw" > /etc/kernel/cmdline

# ---------------------------------------------------------------------------
# UKI preset
# ---------------------------------------------------------------------------
# Copy the shipped linux-lts.preset, then append an override line if a
# microcode image was requested. In mkinitcpio preset files a later
# assignment wins, so appending is safe even though the preset ships
# with default_options commented out.

echo "#>> Installing linux-lts.preset"
install -m 0644 "$SCRIPT_DIR/linux-lts.preset" /etc/mkinitcpio.d/linux-lts.preset

if [[ -n "$UCODE_IMAGE" ]]; then
    [[ -f "$UCODE_IMAGE" ]] \
        || die "requested microcode image $UCODE_IMAGE not found; did 1_install_base.sh run with the matching -a/-i?"
    echo "#>> Embedding microcode into UKI: $UCODE_IMAGE"
    echo "default_options=\"--microcode ${UCODE_IMAGE}\"" \
        >> /etc/mkinitcpio.d/linux-lts.preset
fi

# ---------------------------------------------------------------------------
# systemd-boot
# ---------------------------------------------------------------------------
echo "#>> Installing systemd-boot"
# /efi is formatted as FAT32, Unix file permissions doesn't work here, HOWEVER this can fix warning for just better health.
chmod 700 /efi/loader
bootctl install

echo "#>> Installing /efi/loader/loader.conf"
install -d -m 0755 /efi/loader
install -m 0644 "$SCRIPT_DIR/template/loader.conf" /efi/loader/loader.conf

# The ESP is FAT32 and therefore has no Unix permissions; the loader
# directory is readable by anyone who can mount the ESP. systemd-boot
# stores a random seed in /efi/loader/random-seed and warns when that
# path is world-accessible, because the seed is trivially poisonable.
# Restricting the mount-side permissions (which only apply to the
# currently-mounted filesystem, not to the FAT directory entries
# themselves) silences the warning for the running system.
if [[ -d /efi/loader ]]; then
    chmod 700 /efi/loader
fi

# ---------------------------------------------------------------------------
# Generate the UKI
# ---------------------------------------------------------------------------
echo "#>> Generating unified kernel image"
mkinitcpio -P

echo
echo "#>> Base configuration complete."
echo "#>> Verify the UKI with:"
echo "     lsinitcpio /efi/EFI/Linux/arch-linux-lts.efi | grep -i microcode"
echo "     strings /efi/EFI/Linux/arch-linux-lts.efi | grep -m1 root="
echo "#>> Next: ./4_config_mirrors.sh"
