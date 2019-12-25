#!/usr/bin/env bash
pacman -Syu base-devel git --noconfirm --needed

git clone https://github.com/actionless/pikaur

cd pikaur

makepkg -fsri
