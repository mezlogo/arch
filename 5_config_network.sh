#!/usr/bin/env bash

cp *.network /etc/systemd/network/

systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable iwd
timedatectl set-ntp true

ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl mask network-online.target
