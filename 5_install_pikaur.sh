#!/usr/bin/env bash
sudo pacman -Syu base-devel git --noconfirm --needed

git clone https://github.com/actionless/pikaur /tmp/pikaur

cd /tmp/pikaur

makepkg -fsri