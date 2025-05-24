#!/usr/bin/env bash

sudo pacman -S --needed gnome gnome-extra noto-fonts-emoji ttf-joypixels pipewire-jack gnu-free-fonts noto-fonts

sudo systemctl enable gdm.service
