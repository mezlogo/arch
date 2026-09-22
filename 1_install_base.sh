#!/usr/bin/env bash
#
# 1_install_base.sh - Partition the target disk, format the partitions,
#                     mount them under /mnt, and pacstrap the base system.
#
# Layout (GPT):
#   1. EFI System Partition (FAT32)        512 MiB   -> mounted at /efi
#   2. Swap (optional)                     N GiB
#   3. Root (ext4)                         remainder
# When swap_size=0 there is no swap partition and root becomes partition 2.
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

show_usage() {
    cat <<'EOF'
Usage: ./1_install_base.sh [-ain] <block_device> <swap_size_gib>

Partition <block_device> with a GPT table, create a FAT32 EFI System
Partition, an optional swap partition, and a root partition. Format and
mount them, then install the base system into /mnt.

Arguments:
  block_device     Target disk (e.g. /dev/sda, /dev/nvme0n1, /dev/mmcblk0)
  swap_size_gib    Swap partition size in GiB (use 0 to skip swap)

Options:
  -h               Display this help and exit
  -a               Install AMD microcode (amd-ucode)
  -i               Install INTEL microcode (intel-ucode)
  -n               Force NVMe-style 'p' partition suffix. Normally
                   auto-detected for devices whose name ends with a digit.
EOF
}

die() { echo "Error: $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Require root
# ---------------------------------------------------------------------------

(( EUID == 0 )) || die "must be run as root"

# ---------------------------------------------------------------------------
# Parse options
# ---------------------------------------------------------------------------

PACKAGES=(
    base
    base-devel
    pacman-contrib
    linux-lts
    linux-lts-headers
    linux-firmware
    git
    neovim
    iwd
    openssh
    sudo
    efibootmgr
    mkinitcpio
    iptables
)

FORCE_NVME_PREFIX=""
while getopts ':hain' opt; do
    case "$opt" in
        h) show_usage; exit 0 ;;
        a) PACKAGES+=(amd-ucode) ;;
        i) PACKAGES+=(intel-ucode) ;;
        n) FORCE_NVME_PREFIX="p" ;;
        \?) die "unknown option: -$OPTARG (see -h)" ;;
    esac
done
shift $((OPTIND - 1))

[[ $# -ge 2 ]] || { show_usage; exit 1; }

BLOCK_DEVICE="$1"
SWAP_SIZE="$2"

# ---------------------------------------------------------------------------
# Validate inputs
# ---------------------------------------------------------------------------

[[ -b "$BLOCK_DEVICE" ]] \
    || die "$BLOCK_DEVICE is not a block device"

[[ "$SWAP_SIZE" =~ ^[0-9]+$ ]] \
    || die "swap size '$SWAP_SIZE' must be a non-negative integer"

# Refuse to touch a disk that is currently in use.
if lsblk -n -o MOUNTPOINT "$BLOCK_DEVICE" | grep -q .; then
    die "$BLOCK_DEVICE or one of its partitions is mounted"
fi

mountpoint -q /mnt \
    && die "/mnt is already a mountpoint; unmount it first"

# ---------------------------------------------------------------------------
# Partition naming convention
# ---------------------------------------------------------------------------
# NVMe, MMC, loop and other devices whose name ends with a digit use
# '<dev>p<N>' for partitions; SATA/SCSI/virtio use '<dev><N>'.

if [[ -n "$FORCE_NVME_PREFIX" ]]; then
    NVME_PREFIX="$FORCE_NVME_PREFIX"
elif [[ "$BLOCK_DEVICE" =~ [0-9]$ ]]; then
    NVME_PREFIX="p"
else
    NVME_PREFIX=""
fi

# ---------------------------------------------------------------------------
# Enable NTP in the live environment
# ---------------------------------------------------------------------------

timedatectl set-ntp true

# ---------------------------------------------------------------------------
# Partition the disk
# ---------------------------------------------------------------------------

echo "#>> Wiping and partitioning $BLOCK_DEVICE"
sgdisk --zap-all "$BLOCK_DEVICE"
wipefs --all "$BLOCK_DEVICE" >/dev/null

sgdisk -n 0:0:+512MiB   -t 0:ef00 -c 0:EFI  "$BLOCK_DEVICE"

ROOT_PARTNUM=2
if (( SWAP_SIZE > 0 )); then
    sgdisk -n 0:0:+"${SWAP_SIZE}GiB" -t 0:8200 -c 0:swap "$BLOCK_DEVICE"
    ROOT_PARTNUM=3
fi

sgdisk -n 0:0:0 -t 0:8300 -c 0:root "$BLOCK_DEVICE"

sgdisk -p "$BLOCK_DEVICE"

partprobe "$BLOCK_DEVICE"
udevadm settle

# ---------------------------------------------------------------------------
# Resolve partition paths and verify they exist
# ---------------------------------------------------------------------------

BOOT_PARTITION="${BLOCK_DEVICE}${NVME_PREFIX}1"
SWAP_PARTITION="${BLOCK_DEVICE}${NVME_PREFIX}2"
ROOT_PARTITION="${BLOCK_DEVICE}${NVME_PREFIX}${ROOT_PARTNUM}"

[[ -b "$BOOT_PARTITION" ]] || die "expected partition $BOOT_PARTITION not found"
[[ -b "$ROOT_PARTITION" ]] || die "expected partition $ROOT_PARTITION not found"
if (( SWAP_SIZE > 0 )); then
    [[ -b "$SWAP_PARTITION" ]] || die "expected swap partition $SWAP_PARTITION not found"
fi

# ---------------------------------------------------------------------------
# Format
# ---------------------------------------------------------------------------

echo "#>> Formatting $BOOT_PARTITION as FAT32"
mkfs.fat -F32 -n EFI "$BOOT_PARTITION"

if (( SWAP_SIZE > 0 )); then
    echo "#>> Initializing swap on $SWAP_PARTITION"
    mkswap -L swap "$SWAP_PARTITION"
    swapon "$SWAP_PARTITION"
fi

echo "#>> Formatting $ROOT_PARTITION as ext4"
mkfs.ext4 -L root "$ROOT_PARTITION"

# ---------------------------------------------------------------------------
# Mount
# ---------------------------------------------------------------------------

echo "#>> Mounting root at /mnt"
mount "$ROOT_PARTITION" /mnt

echo "#>> Mounting EFI at /mnt/efi"
mount --mkdir "$BOOT_PARTITION" /mnt/efi

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

echo "#>> Installing packages: ${PACKAGES[*]}"
pacstrap --needed --noconfirm /mnt "${PACKAGES[@]}"

echo "#>> Writing /etc/fstab"
genfstab -U /mnt > /mnt/etc/fstab

echo
echo "#>> Base system installed."
echo "#>> Next: ./2_copy_repo_and_chroot.sh"
