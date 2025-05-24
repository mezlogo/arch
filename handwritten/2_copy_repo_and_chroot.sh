#!/bin/bash
mkdir -p /mnt/home/postinstall
cp -r "$(dirname ${BASH_SOURCE[0]})" /mnt/home/postinstall
arch-chroot /mnt
