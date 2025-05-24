# install arch using predefined declarative config and archinstall tool

0. ssh into installation media
1. update pacman: `pacman -Sy`
2. update one package `archinstall`: `pacman -S archinstall`
3. execute script: `archinstall --config-url https://github.com/mezlogo/arch/raw/refs/heads/master/vm-hypr-arch-configuration.json`
4. reboot
5. install yay: `sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si`
