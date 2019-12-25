#!/bin/bash
cp -r "$(dirname ${BASH_SOURCE[0]})" /mnt/home/aur
arch-chroot /mnt
