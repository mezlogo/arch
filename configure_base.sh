#!/bin/sh

#set the time zone
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

#locale
RU_LOCALE='ru_RU.UTF-8 UTF-8'
EN_LOCALE='en_US.UTF-8 UTF-8'
echo -e "$EN_LOCALE\n$RU_LOCALE" > /etc/locale.gen
locale-gen

echo "LANG=$EN_LOCALE" > /etc/locale.conf

echo "arch" > /etc/hostname

passwd

bootctl install

cp -f /usr/share/systemd/bootctl/loader.conf /boot/loader/
echo 'editor 0' >> /boot/loader/loader.conf

cp /usr/share/systemd/bootctl/arch.conf /boot/loader/entries/
I=$(blkid -s PARTUUID -o value /dev/sda2)
sed -i "s/^options.*/options root=PARTUUID=$I rw/"