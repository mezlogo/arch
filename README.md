Arch installation guide by mezlogo

Scripts contain arch linux, systemd boot, gpt, boot & root & home partitions.

1) Preparation

- wi-fi connection, for instance:
```
    link set $WIFI_DEVICE_NAME up
    wpa_passphrase $WIFI_SPOT_NAME $WIFI_PASSWORD > wifi.conf
    wpa_supplicant -B -i $WIFI_DEVICE_NAME -c wifi.conf
    dhcpcd $WIFI_DEVICE_NAME
```
- sync pacman database
`pacman -Sy`

- make pacman ignore space
`sed 's/CheckSpace/#CheckSpace/' /etc/pacman.conf`

- install git
`pacman -S git`

- clone this repo
`git clone http://github.com/mezlogo/arch`

2) Installation

- run first script with ROOT_SIZE and DISK variables, for instance:
`ROOT_SIZE=20 DISK=/dev/sda ./1_prepare_system.sh`

- run addiional script if you need wi-fi apps

- copy configs and change root

- in your installed arch run finishing scripts
