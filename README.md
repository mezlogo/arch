Arch installation guide by mezlogo

Scripts contain arch linux, systemd boot, gpt, boot & root & home partitions.

1) Preparation:

- sync pacman database: `pacman -Sy`

- make pacman ignore space: `sed -i 's/CheckSpace/#CheckSpace/' /etc/pacman.conf`

- install git: `pacman -S git`

- clone this repo: `git clone http://github.com/mezlogo/arch`

2) Installation

- run first script with ROOT_SIZE and DISK variables, for instance: `./1_prepare_system.sh /dev/sda 20`

- copy configs and change root

- in your installed arch run finishing scripts

3) Post install:

- turn on inet: `sudo systemctl start dhcpcd@enp3s0`