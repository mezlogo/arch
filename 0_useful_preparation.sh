#!/usr/bin/env bash

sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -Sy --needed --noconfirm reflector
reflector --country RU --protocol https --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
pacman -Sy
