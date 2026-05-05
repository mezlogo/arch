#!/usr/bin/env bash
sudo rm -rf /home/postinstall
pikaur -Scc
rm -rf ~/.*
rm -rf ~/*

sudo pacman -S --noconfirm nodejs npm
mkdir -p ~/repos
git clone https://github.com/mezlogo/deskmanager ~/repos/deskmanager
