My installation arch linux guide.

1) Preparation:

- sync pacman database and install git: `pacman -Sy git`

- clone this repo and change dir: `git clone http://github.com/mezlogo/arch /tmp/arch && cd /tmp/arch`

2) Installation

- run first script with $PATH_TO_DISK $ROOT_SIZE_IN_GB variables, for instance: `./1_prepare_system.sh /dev/sda 20`

- copy configs and change root: `./2_copy_repo_and_chroot.sh`

- NOW you're in your installed arch run finishing scripts

- change directory to `cd /home/postinstall`

- write hostname, set timezone and so on by executing `HOSTNAME=myhostname ./3_configure_base.sh`

- create user: `USERNAME=borsh ./4_create_user.sh`

3) Post install:

- turn on inet: `sudo ip link set enp0s3 up && sudo systemctl start dhcpcd@enp3s0`

- install pikaur: `./5_install_pikaur.sh`
