#!/usr/bin/env bash

if [ -d /etc/iwd ]; then
  sudo cp main.conf /etc/iwd/main.conf
  sudo systemctl enable --now iwd
else
  sudo cp 20-wired.network /etc/systemd/network/20-wired.network
  sudo systemctl enable --now systemd-networkd
fi

sudo systemctl enable --now systemd-resolved

echo SystemMaxUse=50M | sudo tee --append /etc/systemd/journald.conf