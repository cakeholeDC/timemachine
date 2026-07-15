#!/usr/bin/env bash
set -e

# Mounts an external USB drive to the TimeMachine bind-mount point
# and creates a .drive-mounted marker file for the Docker healthcheck.
#
# Usage:
#   sudo ./mount-drive.sh                    # interactive device selection
#   sudo ./mount-drive.sh /dev/sda1          # non-interactive
#   sudo ./mount-drive.sh /dev/disk/by-uuid/...  # by UUID


MOUNT_POINT="${TM_DEVICE_MOUNT_POINT:-/tm_data}"

if [ "$EUID" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

echo "======================================"
echo " EXTERNAL DRIVE MOUNT TOOL"
echo "======================================"
echo ""

# ---- Show available block devices ----
echo "Available devices:"
echo ""
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,MODEL
echo ""

# ---- Device selection UX ----
DEVICE=""

if [ -n "$1" ]; then
  DEVICE="$1"
else
  echo "Enter device to mount (example: /dev/sda1)"
  read -r DEVICE
fi

# ---- Validation loop ----
while true; do
  if [ -z "$DEVICE" ]; then
    echo "No device provided."
  elif [ ! -b "$DEVICE" ]; then
    echo "Invalid device: $DEVICE"
  else
    break
  fi

  echo ""
  lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
  echo ""
  read -r -p "Re-enter device: " DEVICE
done

# ---- Safety check: already mounted at target ----
if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
  echo "ERROR: $MOUNT_POINT is already a mount point."
  echo "Unmount it first or check if the drive is already accessible at: $(findmnt -n -o TARGET "$MOUNT_POINT" 2>/dev/null || echo "$MOUNT_POINT")"
  exit 1
fi

# ---- Confirm ----
echo ""
echo "You selected: $DEVICE"
read -r -p "Mount this device at $MOUNT_POINT? (type YES): " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted."
  exit 1
fi

# ---- Mount ----
echo ""
echo "Mounting $DEVICE at $MOUNT_POINT..."
mkdir -p "$MOUNT_POINT"
mount "$DEVICE" "$MOUNT_POINT"

# ---- Create healthcheck marker ----
touch "$MOUNT_POINT/.drive-mounted"

# ---- Report size ----
# VOLUME_SIZE_LIMIT accepts a value + unit (e.g. "500 G", "2 T", "500000 M").
# We suggest G (gigabytes) as a round number; use T for terabyte-scale drives.
SIZE_G=$(lsblk -b -dn -o SIZE "$DEVICE" | awk '{printf "%d\n", $1/1024/1024/1024}')

echo ""
echo "Done."
echo "  Device:  $DEVICE"
echo "  Mount:   $MOUNT_POINT"
echo "  Marker:  $MOUNT_POINT/.drive-mounted"
echo ""
echo "Add to your .env:"
echo "  TM_DEVICE_MOUNT_POINT=$MOUNT_POINT"
echo "  TM_VOLUME_SIZE_LIMIT=${SIZE_G} G"
echo ""
echo "  (TM_VOLUME_SIZE_LIMIT accepts G, T, or M — e.g. \"2 T\" or \"500 G\")"
