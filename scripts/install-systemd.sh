#!/usr/bin/env bash
set -e

# Installs the timemachine-mount systemd service.
# Copies mount-drive.sh to /usr/local/bin and writes a unit file with
# the device and mount point baked in.
#
# Usage:
#   sudo ./install-systemd.sh              # interactive
#   sudo ./install-systemd.sh /dev/sda1   # non-interactive device selection

UNIT_NAME="timemachine-mount"
UNIT_FILE="/etc/systemd/system/${UNIT_NAME}.service"
INSTALL_SCRIPT="/usr/local/bin/mount-drive.sh"

if [ "$EUID" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

echo "======================================"
echo " TIMEMACHINE SYSTEMD INSTALL"
echo "======================================"
echo ""

# ---- Resolve paths ----
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/mount-drive.sh"

if [ ! -f "$SOURCE_SCRIPT" ]; then
  echo "ERROR: mount-drive.sh not found at $SOURCE_SCRIPT"
  exit 1
fi

# ---- Resolve mount point ----
ENV_FILE="$REPO_DIR/.env"
MOUNT_POINT="/tm_data"
if [ -f "$ENV_FILE" ]; then
  PARSED=$(grep -E '^TM_DEVICE_MOUNT_POINT=' "$ENV_FILE" | cut -d= -f2- | tr -d '"' || true)
  if [ -n "$PARSED" ]; then
    MOUNT_POINT="$PARSED"
  fi
fi

echo "Mount point: $MOUNT_POINT"
read -r -p "Use this mount point? (press Enter to accept, or type a new path): " MOUNT_OVERRIDE
if [ -n "$MOUNT_OVERRIDE" ]; then
  MOUNT_POINT="$MOUNT_OVERRIDE"
fi

# ---- Device selection ----
DEVICE=""
if [ -n "$1" ]; then
  DEVICE="$1"
else
  echo ""
  echo "Available devices:"
  echo ""
  lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,MODEL
  echo ""
  read -r -p "Enter device to mount (example: /dev/sda1): " DEVICE
fi

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

# ---- Confirm ----
echo ""
echo "  Device:      $DEVICE"
echo "  Mount point: $MOUNT_POINT"
echo "  Unit file:   $UNIT_FILE"
echo "  Script:      $INSTALL_SCRIPT"
echo ""
read -r -p "Install with these settings? (type YES): " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted."
  exit 1
fi

# ---- Install mount-drive.sh ----
echo ""
if [ -f "$INSTALL_SCRIPT" ]; then
  echo "mount-drive.sh already present at $INSTALL_SCRIPT — skipping copy."
else
  cp "$SOURCE_SCRIPT" "$INSTALL_SCRIPT"
  chmod +x "$INSTALL_SCRIPT"
  echo "Installed $INSTALL_SCRIPT"
fi

# ---- Write unit file ----
cat > "$UNIT_FILE" <<EOF
[Unit]
Description=Mount external USB drive for TimeMachine
After=local-fs.target
Before=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
Environment=TM_DEVICE_MOUNT_POINT=${MOUNT_POINT}
ExecStart=${INSTALL_SCRIPT} ${DEVICE}

[Install]
WantedBy=multi-user.target
EOF

echo "Wrote $UNIT_FILE"

# ---- Enable and start ----
systemctl daemon-reload
systemctl enable --now "$UNIT_NAME"

echo ""
echo "Done. Service status:"
systemctl status "$UNIT_NAME" --no-pager || true
