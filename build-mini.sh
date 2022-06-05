#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BIN="$1"
HEX0="$2"
ARTIFACT_LEN="$3"
ARTIFACT="$4"

IMG=builder-hex0-mini.img

# Create empty disk image for up to 64K of source
dd if=/dev/zero of="$IMG" bs=512 count=129

# Add binary boot sectors
dd if="$BIN" of="$IMG" bs=512 conv=notrunc

# Apply source
dd if="$HEX0" of="$IMG" bs=512 seek=1 conv=notrunc

# Launch build
qemu-system-x86_64 -m 256M -nographic -drive file="$IMG",format=raw --no-reboot

# Extract the result
dd if="$IMG" of="$ARTIFACT" bs=1 count="$ARTIFACT_LEN" status=none
