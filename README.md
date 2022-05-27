# Arch linux installation scripts

This repo describes how to install minimal yet functional arch linux configuration:
- `linux-zen` as a kernel
- optional `iwd` for wireless support
- network by `iwd` or `systemd-networkd` services
- `pikaur` as an AUR helper
- useful tuning after install

I use those scripts as a base for my personal notebook, home desktop and office desktop.

## Disk configuration notes:

- ONLY uefi/gpt configuration supported
- one and only one disk could be used and only full erase mode
- nvme supported
- no swap partition available, due to arch wiki note: `There is no performance difference between using a swap partition and a contiguous swap file.`, so when you want you can create `a contiguous swap file`

Partition table would be like:
- boot: 300mb
- root(ext4): $SECOND_ARG
- home(ext4): rest

If you pass `$SECOND_ARG` as `0` there would not be a separate home partition.


## Installation

### Preparetion

#### Download and burn flash drive

```sh
month="$(date +%m)"
iso_name="archlinux.iso"
flash_drive="/dev/sdd" # find out your flash with lsblk
curl -s -o "$iso_name" "https://mirror.yandex.ru/archlinux/iso/2022.$month.01/archlinux-2022.$month.01-x86_64.iso"
sudo dd if="$iso_name" of="$flash_drive"
```

#### Test with virtual machine

```sh
disk_name="archvm.qcow2"
iso_name="archlinux.iso"
qemu-img create -f qcow2 "$disk_name" 10G
qemu-system-x86_64 -cpu host -smp 4 -enable-kvm -bios /usr/share/edk2-ovmf/x64/OVMF.fd -boot d -cdrom "$iso_name" -hda "$disk_name" -m 4096
```

#### Inside booted iso

##### Connect wireless if needed

```sh
#test status of rfkill
rfkill
#if needed unblock wlan
rfkill unblock wlan
#test wifi
iwctl station wlan show
iwctl station wlan scan
iwctl station wlan get-networks
iwctl station wlan connect $YOUR_WIFI
iwctl station wlan show
ip a
```

##### Install git and clone repo

- open `/etc/pacman.conf`: `vim /etc/pacman.conf`
- comment `CheckSpace`
- uncomment `ParallelDownloads`
- install git: `pacman -Sy git`
- clone repo: `git clone https://github.com/mezlogo/arch`

##### Do magic

- config pacman and mirrors: `./0_useful_preparation.sh`
- install base. Arguments depend on your system, for instance:
  - amd `-a` notebook with nvme storage `-n` and wifi `-w`, with only two partitions `0`: `./1_install_base.sh -anw /dev/nvme0n1 0`
  - qemu/kvm with dedicated root partition of 4 gb: `./1_install_base.sh /dev/sda 4`
- chroot: `./2_copy_repo_and_chroot.sh`
- create user, hostname, locale
  - for amd notebook: `./3_configure_base.sh -a mobilestation /dev/nvme0n1p2 mezlogo`
  - vm: `./3_configure_base.sh virtvm /dev/sda2 vagrant`
- exit and reboot

#### Inside installed os

##### Configure internet

###### Wifi configuration

- check rfkill
- connect to wifi using `iwctl`

###### Wired configuration

- write device name to `main.conf`
- exec `./4_config_internet.sh`

### After install

Configure mirrors, pacman conf and journald: `./5_after_install.sh`

##### Install pikaur

Just execute `./6_install_pikaur.sh`
