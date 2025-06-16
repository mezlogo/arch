#!/usr/bin/env bash

systemctl disable systemd-networkd.socket
systemctl disable systemd-resolved.service
systemctl enable NetworkManager.service
systemctl enable systemd-timesyncd.service
