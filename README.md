# TimeMachine ⏳ 🤖
A docker-compose based samba server compatible with MacOS's TimeMachine. 

Quickly deployable on Raspberry Pi.

![lint](https://github.com/cakeholeDC/timemachine/actions/workflows/yaml-lint.yml/badge.svg)

## Pre Reqs 👶 🛠
- [docker](https://docs.docker.com/desktop/install/linux-install/)
- External Storage Device, connected to docker host (Raspberry Pi)

## Setup ⚙️ 💾
### Step 1: Attach your external disk and identify the name of your device using `lsblk`
```shell
    $ lsblk  
    NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
    sda           8:0    0   3.6T  0 disk 
    └─sda1        8:1    0   3.6T  0 part 
    mmcblk0     179:0    0 119.4G  0 disk 
    ├─mmcblk0p1 179:1    0   512M  0 part /boot/firmware
    └─mmcblk0p2 179:2    0 118.9G  0 part /
```
In this example, the device name is `/dev/sda1`. 

We will refer to this as `$DEVICE` moving forward.

```shell
    $ export DEVICE=/dev/sda1
```
### Step 2: Create a directory to use as the mount point. 
We'll refer to this as `$MOUNT_POINT` moving forward

```shell
$ export MOUNT_POINT=$PWD/tm_data
$ mkdir $MOUNT_POINT
```
### Step 3: Create the mountpoint, using the variables from above.
```shell
$ sudo mount $DEVICE $MOUNT_POINT
```
To check your work, use `lsblk` again
```shell
$ lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda           8:0    0   3.6T  0 disk 
└─sda1        8:1    0   3.6T  0 part /path/to/mounted/tm_data
```
### Step 4: Prepare `.env`
```shell
$ cp example.env .env
```
Use the included convenience script to get the device size:

```shell
$ env DEVICE=$DEVICE ./device_get_size.sh
DEVICE = /dev/sda1
SIZE_MB = 3906982908

$ export SIZE_MB=3906982908
```
Edit the `.env` file

| Var | default | description |
| --- | ------- | ------------|
| TM_PASSWORD | timemachine | password to connect to the samba share | 
| TM_SHARENAME | timemachine | the name of the network share | 
| TM_DEVICE_MONUT_POINT | | set this to `$MOUNT_POINT` |
| TM_DEVICE_SIZE_MB | | the size of the share in Megabytes (MB); set this to `$SIZE_MB` | 


## Deploy 🐳 📦
1. `docker compose up -d`
    - Run `docker-compose logs -f` to watch the container logs

## Uninstall 🗑 🔥
1. `docker compose down -v`
1. unnount the drive: `sudo umount $DEVICE $MOUNT_PONIT`
    - this will remove the docker volumes but will not touch the data on the mounted disk

## Testing & QA 🔎 🧪
All testing has been done on the following hardware and software:
- Raspberry Pi 4B 4GB; RaspberryPi OS Lite (64bit)
- Raspberry Pi 4B 8GB; RaspberryPi OS Lite (64bit)
- Raspberry Pi 5 8GB; RaspberryPi OS (64bit)
