#!/usr/bin/env bash

sudo sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --needed pacman-contrib
curl -s "https://archlinux.org/mirrorlist/?country=RU&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 -
