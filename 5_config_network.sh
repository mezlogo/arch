#!/usr/bin/env bash

systemctl disable systemd-networkd.socket
systemctl enable systemd-resolved.service
systemctl enable NetworkManager.service
systemctl enable systemd-timesyncd.service
