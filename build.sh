#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

BIN="$1"
SRC="$2"
ARTIFACT="$3"

IMG="builder-hex0.img"
INPUT="input.bin"
LOG="build.log"
ENABLE_KVM="${ENABLE_KVM--enable-kvm}"

# Create empty 1056MB disk image.
# (1024 cylinders * 32 heads * 63 sectors * 512 bytes/sector)
dd if=/dev/zero of="$IMG" bs=512 count=2064384

# Append builder binary with source to create input
cat "$BIN" "$SRC" > "$INPUT"

# Place input at the beginning of disk input
dd if="$INPUT" of="$IMG" conv=notrunc

# Launch build
qemu-system-x86_64 $ENABLE_KVM -m 4G -nographic -machine kernel-irqchip=split -drive file="$IMG",format=raw --no-reboot | tee "$LOG"

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
