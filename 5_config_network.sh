#!/usr/bin/env bash

systemctl enable systemd-networkd
systemctl enable systemd-resolved
systemctl enable iwd
timedatectl set-ntp true
