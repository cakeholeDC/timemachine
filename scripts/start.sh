#!/usr/bin/env bash
set -e

# Starts the TimeMachine Docker stack.
# Verifies the drive is mounted before bringing the container up,
# since the container's healthcheck depends on the mount being present.
#
# Usage:
#   ./scripts/start.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

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
echo " TIMEMACHINE START"
echo "======================================"
echo ""

# ---- Verify .env exists ----
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env not found at $ENV_FILE"
  echo ""
  echo "Create it from the example and fill in your values:"
  echo "  cp .env.example .env"
  exit 1
fi

# ---- Verify Docker daemon is running ----
if ! docker info > /dev/null 2>&1; then
  echo "ERROR: Docker daemon is not running."
  echo ""
  echo "Start it with: sudo systemctl start docker"
  exit 1
fi

# ---- Verify drive is mounted ----
# The container bind-mounts $MOUNT_POINT at /opt/timemachine. If the drive
# isn't mounted here first, the container starts against an empty directory.
echo "Checking drive mount at $MOUNT_POINT..."

if ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
  echo ""
  echo "ERROR: $MOUNT_POINT is not mounted."
  echo ""
  echo "Mount the drive first, then re-run this script:"
  echo "  sudo ./scripts/mount-drive.sh"
  exit 1
fi

echo "  Drive mounted. ✓"

# ---- Ensure healthcheck marker exists ----
# mount-drive.sh creates this file. If it's missing (e.g. manual mount),
# the container will start but report unhealthy until the file appears.
if [ ! -f "$MOUNT_POINT/.drive-mounted" ]; then
  echo ""
  echo "WARNING: healthcheck marker missing at $MOUNT_POINT/.drive-mounted"
  if touch "$MOUNT_POINT/.drive-mounted" 2>/dev/null; then
    echo "  Marker created. ✓"
  else
    echo "  Could not create marker — run as root or create it manually:"
    echo "    sudo touch $MOUNT_POINT/.drive-mounted"
    echo "  The container will start but report unhealthy until the marker exists."
  fi
fi

echo ""

# ---- Start the stack ----
# docker compose up -d starts the container in the background (detached).
# The image pulls automatically on first run — this may take a minute.
echo "Starting Docker stack..."
echo "  $ docker compose up -d"
echo ""
cd "$REPO_DIR"
docker compose up -d

echo ""
echo "Container status:"
docker compose ps

echo ""
echo "To watch logs: docker compose logs -f"
