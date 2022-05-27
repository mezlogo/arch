#!/usr/bin/env bash


if pacman -Q iwd; then
  sudo rfkill unblock wlan
  sudo systemctl enable --now iwd
  sudo cp main.conf /etc/iwd/main.conf
  sudo systemctl restart iwd
  sudo cp 20-wireless.network /etc/systemd/network/20-wireless.network
else
  sudo cp 20-wired.network /etc/systemd/network/20-wired.network
fi

sudo systemctl enable --now systemd-networkd

#sudo systemctl enable --now systemd-resolved

echo SystemMaxUse=50M | sudo tee --append /etc/systemd/journald.conf
