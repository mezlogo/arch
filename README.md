# Arch linux installation scripts

Repo contains step-by-step guide and scripts for installation arch linux:
- loader: UEFI `systemd-boot`
- partition: gpt/ext4
- kernel: `linux`
- network: `NetworkManager` 
- aur: `pikaur`


## 1. how to create virtual kvm/qemu for test

```sh
disk_name="archvm.qcow2"
iso_name="archlinux.iso"
qemu-img create -f qcow2 "$disk_name" 10G
qemu-system-x86_64 -cpu host -smp 4 -enable-kvm -bios /usr/share/edk2-ovmf/x64/OVMF.fd -boot d -cdrom "$iso_name" -hda "$disk_name" -m 4096
```

## 2. prepare inside archiso

- open `/etc/pacman.conf`: `vim /etc/pacman.conf`
- comment `CheckSpace`
- uncomment `ParallelDownloads`
- install git: `pacman -Sy git`
- clone repo: `git clone https://github.com/mezlogo/arch`


## 3. install packages

- config pacman and mirrors: `./0_useful_preparation.sh`
- install base. Arguments depend on your system, for instance:
  - amd `-a` notebook with nvme storage `-n` and wifi `-w`, with only two partitions `0`: `./1_install_base.sh -anw /dev/nvme0n1 0`
  - qemu/kvm with dedicated root partition of 4 gb: `./1_install_base.sh /dev/sda 4`
- chroot: `./2_copy_repo_and_chroot.sh`

## 4. chroot: create user, etc

- create user, hostname, locale
  - for amd notebook: `./3_configure_base.sh -a mobilestation /dev/nvme0n1p2 mezlogo`
  - vm: `./3_configure_base.sh virtvm /dev/sda2 vagrant`
- exit and reboot

## 5. after reboot

- test rfkill
- exec `/home/postinstall/4_config_internet.sh`
- exec `/home/postinstall/5_config_mirrors.sh`
- copy to home and install pikaur `./6_install_pikaur.sh`
- install pikaur using pikaur `pikaur -Syu pikaur`
- remove junk: `rm -rf ~/.local ~/.cache ~/pikaur`
