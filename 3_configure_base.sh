#!/bin/bash

echo ${1:?not null} > /etc/hostname

#set the time zone
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

#locale
echo -e 'en_US.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8' > /etc/locale.gen
locale-gen

echo 'LANG=en_US.UTF-8' > /etc/locale.conf

passwd

bootctl install

cp -r "$(dirname ${BASH_SOURCE[0]})/template/loader.conf" /boot/loader/

PARTUUID=$(blkid -s PARTUUID -o value /dev/sda2) envsubst < template/arch.conf > /boot/loader/entries/arch.conf
