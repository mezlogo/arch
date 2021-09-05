#!/usr/bin/env bash

show_usage() {
    cat << EOF
Usage: ${0} [-hai] hostname root_partition username
Config hostname, time zone, locales, root password, bootloader, user

-h          Display help
-a          Install AMD microcodes
-i          Install INTEL microcodes

EOF
}

options=$(getopt hai ${*})

if [ $? != 0 ] ; then show_usage; exit 1; fi
eval set -- "${options}"

UCODES=""
while true; do
    case $1 in
    -h) show_usage; exit 0 ;;
    -a) UCODES="initrd  /amd-ucode.img" ;;
    -i) UCODES="initrd  /intel-ucode.img" ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

[[ $# -lt 3 ]] && show_usage && exit 1;

HOSTNAME="$1"
ROOT_PARTITION="$2"
USERNAME="$3"

[[ ! -b $ROOT_PARTITION ]] && echo "Disk: $ROOT_PARTITION should be a block device" && exit 1

echo "$HOSTNAME" > /etc/hostname

ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

echo -e 'en_US.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8' > /etc/locale.gen
locale-gen

echo 'LANG=en_US.UTF-8' > /etc/locale.conf

passwd

bootctl install

cp -r "$(dirname ${BASH_SOURCE[0]})/template/loader.conf" /boot/loader/

PARTUUID=$(blkid -s PARTUUID -o value $ROOT_PARTITION) INIT_UCODE="$UCODES" envsubst < template/arch.conf > /boot/loader/entries/arch.conf

useradd -m -G wheel -s /bin/bash "$USERNAME"

passwd "$USERNAME"

if ! grep '^%wheel' /etc/sudoers ; then echo '%wheel      ALL=(ALL) ALL' >> /etc/sudoers ; fi