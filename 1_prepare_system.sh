#!/bin/bash
# format $DISK as GPT, GUID Partition Table

DISK=$1
ROOT_SIZE=$2

[[ ! -b $DISK ]] && { echo "Disk: $DISK should be a block device"; exit -1; }

[[ ! "$ROOT_SIZE" =~ ^[0-9]+$ ]] && { echo "Root size: $ROOT_SIZE should be a number"; exit -1; }

timedatectl set-ntp true

sgdisk -Z ${DISK:?not null}

sgdisk -n 0:0:+300M -t 0:ef00 $DISK
sgdisk -n 0:0:+"${ROOT_SIZE:?not null}"G -t 0:8300 $DISK
sgdisk -n 0:0:0 -t 0:8300 $DISK

sgdisk -p $DISK

# inform the OS of partition table changes
partprobe $DISK
fdisk -l $DISK

# format patitions
mkfs.fat -F32 "$DISK"1
mkfs.ext4 "$DISK"2
mkfs.ext4 "$DISK"3

mount "$DISK"2 /mnt

mkdir /mnt/boot
mount "$DISK"1 /mnt/boot

mkdir /mnt/home
mount "$DISK"3 /mnt/home

#Select the nearest mirrors
sed -ni.bak '/Ru/{n;p;}' /etc/pacman.d/mirrorlist

#install necessary
pacstrap /mnt base base-devel linux linux-headers intel-ucode

genfstab -U /mnt > /mnt/etc/fstab
