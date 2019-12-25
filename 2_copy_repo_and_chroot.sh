#!/bin/bash
cp -r "$(dirname ${BASH_SOURCE[0]})" /mnt/home/postinstall
arch-chroot /mnt
