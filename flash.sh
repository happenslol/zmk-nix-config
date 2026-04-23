#!/usr/bin/env bash
set -euo pipefail

NAME="${1:-}"
HALF="${2:-}"

if [[ -z "$NAME" ]]; then
    echo "Usage: $0 <name> [left|right]" >&2
    exit 1
fi

BUILD_DIR="$(dirname "$(readlink -f "$0")")/build/$NAME"
if [[ -n "$HALF" ]]; then
    if [[ "$HALF" != "left" && "$HALF" != "right" ]]; then
        echo "Half must be 'left' or 'right', got: $HALF" >&2
        exit 1
    fi
    FIRMWARE="$BUILD_DIR/zmk_${HALF}.uf2"
    LABEL_DESC="$NAME ($HALF)"
else
    FIRMWARE="$BUILD_DIR/zmk.uf2"
    LABEL_DESC="$NAME"
fi

if [[ ! -f "$FIRMWARE" ]]; then
    echo "Firmware not found: $FIRMWARE" >&2
    echo "Run 'just build $NAME' first." >&2
    exit 1
fi

LABEL="NICENANO"
DEV="/dev/disk/by-label/$LABEL"

echo "[$LABEL_DESC] Waiting for $LABEL bootloader on USB (Ctrl-C to abort)..."
while [[ ! -e "$DEV" ]]; do
    sleep 0.3
done
REAL_DEV="$(readlink -f "$DEV")"
echo "[$LABEL_DESC] Detected $LABEL at $REAL_DEV."

MOUNT="$(findmnt -n -o TARGET "$REAL_DEV" || true)"
if [[ -z "$MOUNT" ]]; then
    echo "[$LABEL_DESC] Mounting via udisksctl..."
    udisksctl mount -b "$DEV" --no-user-interaction >/dev/null 2>&1 || true
    MOUNT="$(findmnt -n -o TARGET "$REAL_DEV" || true)"
fi

if [[ -z "$MOUNT" || ! -d "$MOUNT" ]]; then
    echo "[$LABEL_DESC] Failed to resolve mount point." >&2
    exit 1
fi

echo "[$LABEL_DESC] Copying $(basename "$FIRMWARE") to $MOUNT ..."
cp "$FIRMWARE" "$MOUNT/" || true
sync
echo "[$LABEL_DESC] Flash complete. Bootloader will auto-reboot."

# Wait for the device to disappear so a subsequent flash invocation
# doesn't immediately pick up the same device.
while [[ -e "$DEV" ]]; do
    sleep 0.3
done
