#!/usr/bin/env bash

show_usage() {
    cat << EOF
Usage: ${0} [-ain] path_to_disk root_size
Create 2 or 3 partions and install necessary packages
When root_size equals 0, then no seprate home partition would be created

-h          Display help
-a          Install AMD microcodes
-i          Install INTEL microcodes
-n          Install on nvme device: adds suffix 'p'

EOF
}

options=$(getopt hainw ${*})

if [ $? != 0 ] ; then show_usage; exit 1; fi
eval set -- "${options}"

PACKAGES=(base base-devel pacman-contrib linux linux-headers linux-firmware git neovim networkmanager openssh)
NVME_PREFIX=""
while true; do
    case $1 in
    -h) show_usage; exit 0 ;;
    -a) PACKAGES+=(amd-ucode) ;;
    -i) PACKAGES+=(intel-ucode) ;;
    -n) NVME_PREFIX="p" ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

[[ $# -lt 2 ]] && show_usage && exit 1;

BLOCK_DEVICE="$1"
ROOT_SIZE="$2"

[[ ! -b $BLOCK_DEVICE ]] && echo "Disk: $BLOCK_DEVICE should be a block device" && exit 1
[[ ! "$ROOT_SIZE" =~ ^[0-9]+$ ]] && echo "Root size: $ROOT_SIZE should be an integer" && exit 1

timedatectl set-ntp true

sgdisk -Z $BLOCK_DEVICE

sgdisk -n 0:0:+300M -t 0:ef00 $BLOCK_DEVICE

if (( "$ROOT_SIZE" > 0 )); then
  sgdisk -n 0:0:+"$ROOT_SIZE"G -t 0:8300 $BLOCK_DEVICE
  sgdisk -n 0:0:0 -t 0:8300 $BLOCK_DEVICE
else
  sgdisk -n 0:0:0 -t 0:8300 $BLOCK_DEVICE
fi

sgdisk -p $BLOCK_DEVICE

partprobe $BLOCK_DEVICE

mkfs.fat -F32 "${BLOCK_DEVICE}${NVME_PREFIX}"1
mkfs.ext4 "${BLOCK_DEVICE}${NVME_PREFIX}"2

mount "${BLOCK_DEVICE}${NVME_PREFIX}"2 /mnt

mkdir /mnt/boot
mkdir /mnt/home

mount "${BLOCK_DEVICE}${NVME_PREFIX}"1 /mnt/boot

if (( "$ROOT_SIZE" > 0 )); then
  mkfs.ext4 "${BLOCK_DEVICE}${NVME_PREFIX}"3
  mount "${BLOCK_DEVICE}${NVME_PREFIX}"3 /mnt/home
fi

pacstrap /mnt "${PACKAGES[@]}"

genfstab -U /mnt > /mnt/etc/fstab
