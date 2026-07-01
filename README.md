# TimeMachine
A docker-compose based Samba server compatible with macOS Time Machine.
Powered by [mbentley/docker-timemachine](https://github.com/mbentley/docker-timemachine).

Quickly deployable on Raspberry Pi.

![yaml-lint](https://github.com/cakeholeDC/timemachine/actions/workflows/yaml-lint.yml/badge.svg)
![shellcheck](https://github.com/cakeholeDC/timemachine/actions/workflows/shellcheck.yml/badge.svg)

## Prerequisites
- [Docker](https://docs.docker.com/desktop/install/linux-install/)
- External storage device connected to the Docker host (Raspberry Pi)

## Setup

### Step 1: Mount the drive
Attach your external disk, then run:

```shell
sudo ./scripts/mount-drive.sh
```

The script shows available devices, prompts for selection, mounts the drive, and prints the
values you'll need for your `.env`:

```
Done.
  Device:  /dev/sda1
  Mount:   /tm_data
  Marker:  /tm_data/.drive-mounted

Add to your .env:
  TM_DEVICE_MOUNT_POINT=/tm_data
  TM_VOLUME_SIZE_LIMIT=3726 G

  (TM_VOLUME_SIZE_LIMIT accepts G, T, or M — e.g. "2 T" or "500 G")
```

You can also pass the device directly to skip the prompt:

```shell
sudo ./scripts/mount-drive.sh /dev/sda1
```

### Step 2: Configure `.env`
```shell
cp .env.example .env
```

Edit `.env` with the values printed by the mount script:

| Variable | Default | Description |
|---|---|---|
| `TM_PASSWORD` | `timemachine` | Password to connect to the Samba share |
| `TM_SHARENAME` | `timemachine.home.arpa` | Network share name |
| `TM_DEVICE_MOUNT_POINT` | `/tm_data` | Path where the drive is mounted |
| `TM_VOLUME_SIZE_LIMIT` | `500 G` | Time Machine backup quota — value + unit (e.g. `2 T`, `500 G`, `1000 M`). Printed by mount script. |

### Step 3: Start the stack
```shell
./scripts/start.sh
```

The script verifies the drive is mounted before bringing the container up, then prints container status. To watch logs: `docker compose logs -f`

## Boot persistence (optional)
To automatically mount the drive and start the container on boot:

```shell
sudo ./scripts/install-systemd.sh
```

The script prompts for the device (or accepts it as an argument), installs `mount-drive.sh`
to `/usr/local/bin`, writes a systemd unit with your device and mount point baked in, then
enables and starts the service.

## Troubleshooting

### Container is unhealthy
The healthcheck verifies the drive is mounted. If the drive was disconnected or remounted,
run the mount script to restore the mount and recreate the healthcheck marker:

```shell
sudo ./scripts/mount-drive.sh
```

The container will return to healthy within 30 seconds — no restart needed.

## Uninstall
```shell
sudo ./scripts/teardown.sh
```

Stops the container, removes Docker volumes (Samba state), and unmounts the drive. Your backup data on the disk is not affected.

## Tested hardware
- Raspberry Pi 4B 4GB — Raspberry Pi OS Lite (64-bit)
- Raspberry Pi 4B 8GB — Raspberry Pi OS Lite (64-bit)
- Raspberry Pi 5 8GB — Raspberry Pi OS (64-bit)
