# Arch linux installation scripts

This is an old version of written by hand collection of scripts.

This repo contains semi-automation scripts for installing arch linux from scratch.

Table of content:
1. about goals and results
2. installation
3. post-installation
4. examples

## 1. goals and results

The goal of `scripts` is to help with complex process of installation archlinux under `archiso`.

The goal of this `README.md` is to describe how to do it in pleasant way.

By the end of this installation you'll get the:
- `GPT` formatted disk
- with `ext4` partiotion
- standart `linux` kernel
- standart UEFI boot loader `systemd-boot`
- `NetworkManager` for internet access
- `ly` for TUI login screen (display manager)
- `pikaur` for AUR wrapper

## 2. installation

Preparation:
- download `archiso`
- burn iso to flash drive
- boot installation media

### 2.1. connect to iso using ssh

Installing by separate computer using ssh connection has lots of benefits:
- your desktop can use bluetooth mouse and keyboard
- your computer can output to a bigger external screen
- your computer can have a browser and even copy-paste support - it drastically simplify troubleshooting while installation

`archiso` already has an `openssh` package installed AND even `sshd.service` up and running by default!

So, you just need to:
- [server] change a root password by `passwd`
- [server] if wireless connection: connect to the internet using `iwctl`
- [server] if real hardware: get your local ip address by `ip a`
- [client] make sure `~/.ssh/known_hosts` does not contain any record with desired ip
- [client] connect: `ssh -l root ${IP_ADDRESS} -p 22`

note for vm: almost each vm hypervisor has a port forwarding and NAT networking

note for `qemu`: forward port with `-nic user,hostfwd=tcp::${LOCAL_PORT}-:22`

### 2.2. get this repo

- sync package manager and install git: `pacman -Sy git`
- clone this repo: `git clone http://github.com/mezlogo/arch`

### 2.3. find out a target disk

Execute `lsblk` and choose your disk. BEWARE this is the most important part, cos' you will format (erase) all disk content

### 2.4. go step-by-step

- search and choose top 5 fastest pacman repository mirrors: `./0_useful_preparation.sh`
- write new GPT partition table, reformat /boot as fat32 and root as ext4, install linux on the disk:

An AMD ucodes, `/dev/sda` - virtual disk and one partiotion for both: root and home dirs exmaple: `./1_install_base.sh -a /dev/sda 0`

- chroot to new os: `./2_copy_repo_and_chroot.sh`
- init locale, timezone, hostname, bootloader and create user: `/home/postinstall/3_configure_base.sh [-ai] $HOSTNAME $ROOT_PARTITION $USERNAME`

An AMD ucodes, `/dev/sda2` as an root partition, `virtarch` is a hostname and `mezlogo` as a user will be `cd /home/postinstall; ./3_configure_base.sh -a virtarch /dev/sda2 mezlogo`

- update mirrors list for fresh installed arch: `./4_config_mirrors.sh`
- enabling network services: `./5_config_network.sh`
- enabling ssh server, if you want to continue installation process using separate computer `./6_config_ssh_server.sh`
- shutdown and reboot into fresh installed disk
- reconnect with your ssh client
- install pikaur from source code: `/home/postinstall/7_install_pikaur.sh`
- install nodejs, npm and deskmanager, and cleanup: `/home/postinstall/8_install_deskmanager_and_cleanup.sh`
