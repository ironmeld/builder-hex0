#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BIN="$1"
SRC="$2"
ARTIFACT="$3"

IMG=builder-hex0.img
LOG="build.log"


# Create empty disk image for up to 1M of source
dd if=/dev/zero of="$IMG" bs=512 count=2056

# Add binary boot sectors
dd if="$BIN" of="$IMG" bs=512 conv=notrunc

# Apply source
dd if="$SRC" of="$IMG" bs=512 seek=8 conv=notrunc

# Launch build
qemu-system-x86_64 -m 256M -nographic -drive file="$IMG",format=raw --no-reboot | tee "$LOG"

# Extract the result
HEXLEN=$(tail -1 "$LOG" | tr -d '\r')

if [[ "$HEXLEN" = ERROR* ]]; then
    >&2 echo "Build failed."
    result=1
else
    ARTIFACT_LENGTH=$(printf "%d\n" $((16#$HEXLEN)))
    echo "$ARTIFACT_LENGTH"
    # Extract the result
    dd if="$IMG" of="$ARTIFACT" bs=1 count="$ARTIFACT_LENGTH" status=none
    result=0
fi

# Remove spent image
rm -f "$IMG"

exit "$result"
