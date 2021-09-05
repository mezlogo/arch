# Arch linux installation scripts.

## Supported configurations:

| hostname | microarch | additionals |
| --- | --- | --- |
| mobilestation | amd | iwd |
| homestation | amd | - |
| workstation | intel | - |
| virtualstation | - | - |

## Inputs and outputs:

- Passed block device ($FIRST_ARG) will be totally erased and partitioned into three blocks:
  - boot: 300mb
  - root: $SECOND_ARG
  - home: rest
- For the last script there are two args: $USER_NAME and $HOST_NAME

## Steps:
  
1) Preparation:

- sync pacman database and install git: `pacman -Sy git`

- clone this repo and change dir: `git clone http://github.com/mezlogo/arch && cd arch`

2) Installation:

- `./1_install_base.sh /dev/vda 10`

- copy configs and change root: `./2_copy_repo_and_chroot.sh`

- change directory to `cd /home/postinstall`

- write hostname, set timezone and so on by executing `./3_configure_base.sh virtualstation /dev/vda2 mezlogo`

3) Post install:

- turn on inet: `sudo ip link set enp0s3 up && sudo systemctl start dhcpcd@enp3s0`

- install pikaur: `./4_install_pikaur.sh`
