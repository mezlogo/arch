#!/usr/bin/env bash
pacman -S --needed pyalpm
git clone https://github.com/actionless/pikaur.git
cd pikaur
python3 ./pikaur.py -S pikaur
