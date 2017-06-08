#!/bin/sh
# format $DISK as GPT, GUID Partition Table

timedatectl set-ntp true

echo "Disk: $DISK"
sgdisk -Z $DISK

sgdisk -n 0:0:+300M -t 0:ef00 $DISK
sgdisk -n 0:0:+"$ROOT_SIZE"G -t 0:8300 $DISK
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
sed -ni '/Ru/{n;p;}' /etc/pacman.d/mirrorlist

genfstab -U /mnt >> /mnt/etc/fstab

#install necessary
pacstrap /mnt base