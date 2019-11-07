#!/bin/bash
cp -r "$(dirname ${BASH_SOURCE[0]})" /mnt/tmp
arch-chroot /mnt
