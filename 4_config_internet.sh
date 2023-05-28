#!/usr/bin/env bash

sudo systemctl disable --now systemd-networkd.socket
sudo systemctl enable --now systemd-resolved.service
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now systemd-timesyncd.service
