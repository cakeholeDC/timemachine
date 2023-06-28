# Timemachine
A docker-compose based samba server compatible with MacOS's TimeMachine. Quickly deployable on Raspberry Pi.

## Pre Reqs
- docker & docker-compose
- Raspberry Pi, already setup and configured for wifi

## Setup
1. Attach your external disk
1. Identify the name of your device by running the `lsblk` command. 
    - The output will look something like the folowing:
    ```
    NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    sda           8:16   1 10G  0 disk 
    └─sda1        8:17   1 10G  0 part 
      ```
    - In this example, the device name is `/dev/sda1`
1. Create a directory disk to use as the mount point
    - `mkdir ./tm_data`
1. Create the mountpoint, using the name of the device from above.
    - `sudo mount /dev/sda1 ./tm_data`
1. Prepare `.env`
    - `cp example.env .env`
1. Configure `.env`
    1. `TM_PASSWORD` - password to connect to the samba share
    1. `TM_SHARENAME` - the name of the share (ex: `timemachine.home.arpa`)
    1. `TM_DEVICE_MOUNT_POINT` - full path to the mountpoint created during setup
    1. `TM_DEVICE_SIZE_MB` - the size of the share in Megabytes (MB) (ex: 1024)

## Deploy
1. `docker compose up -d`
    - Run `docker-compose logs -f` to watch the container logs

## Uninstall
1. `docker-compose down -v`
1. unnount the drive: `sudo umount /dev/sdb1 ./tm_data`
    - this will remove the docker volumes but will not touch the data on the mounted disk
