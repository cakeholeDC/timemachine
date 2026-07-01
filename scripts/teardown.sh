#!/usr/bin/env bash
set -e

# Stops the TimeMachine Docker stack and unmounts the drive.
# Removing volumes (-v) clears Samba state but does NOT touch backup data
# on the mounted disk — that data lives at $MOUNT_POINT on the host.
#
# Usage:
#   sudo ./scripts/teardown.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ "$EUID" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

# ---- Read mount point from .env ----
ENV_FILE="$REPO_DIR/.env"
MOUNT_POINT="/tm_data"
if [ -f "$ENV_FILE" ]; then
  PARSED=$(grep -E '^TM_DEVICE_MOUNT_POINT=' "$ENV_FILE" | cut -d= -f2- | tr -d '"' || true)
  if [ -n "$PARSED" ]; then
    MOUNT_POINT="$PARSED"
  fi
fi

echo "======================================"
echo " TIMEMACHINE TEARDOWN"
echo "======================================"
echo ""
echo "This will:"
echo "  1. Stop the container and remove Docker volumes (Samba state)"
echo "  2. Unmount the drive at $MOUNT_POINT"
echo ""
echo "Your backup data on the drive is NOT affected."
echo ""
read -r -p "Proceed? (type YES): " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted."
  exit 1
fi

echo ""

# ---- Stop the stack ----
# docker compose down stops and removes containers.
# -v also removes the named volumes declared in docker-compose.yml
# (var-lib-samba, var-cache-samba, run-samba). These hold Samba's
# runtime state and will be recreated fresh on the next start.
echo "Stopping Docker stack..."
echo "  $ docker compose down -v"
echo ""
cd "$REPO_DIR"
docker compose down -v

echo ""

# ---- Unmount the drive ----
if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
  echo "Unmounting $MOUNT_POINT..."
  echo "  $ umount $MOUNT_POINT"
  umount "$MOUNT_POINT"
  echo "  Unmounted. ✓"
else
  echo "Drive is not mounted at $MOUNT_POINT — skipping unmount."
fi

echo ""
echo "Done. It is now safe to disconnect the drive."
