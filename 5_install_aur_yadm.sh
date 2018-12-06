#!/usr/bin/env bash

function build_pacaur {
    download_and_install() {
        curl -o PKGBUILD "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$1" && makepkg --skippgpcheck --needed --noconfirm -is
    }

    download_and_install cower

    download_and_install pacaur
}

sudo pacman -Syu base-devel expac yajl git --noconfirm --needed

pacman -Q pacaur 2> /dev/null || build_pacaur

pacaur -S yadm-git --noconfirm --noedit --needed

yadm st 2>/dev/null || yadm clone https://github.com/mezlogo/configuration
