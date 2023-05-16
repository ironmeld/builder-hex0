#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

STAGE1="$1"
STAGE2="$2"
SRC="$3"
ARTIFACT="$4"

IMG="builder-hex0-x86-stages.img"
LOG="build.log"
ENABLE_KVM="${ENABLE_KVM--enable-kvm}"

# Create empty 1056MB disk image.
# (1024 cylinders * 32 heads * 63 sectors * 512 bytes/sector)
dd if=/dev/zero of="$IMG" bs=512 count=2064384

# Write the stage1 boot seed
dd if=$STAGE1 of="$IMG" conv=notrunc

# Write the MBR identifier
dd if=<(printf \\x55\\xAA) of="$IMG" seek=510 bs=1 count=2 conv=notrunc

# Place stage2 starting at sector 2
dd if="$STAGE2" of="$IMG" seek=1 bs=512 conv=notrunc

# Place source starting at sector 148
dd if="$SRC" of="$IMG" seek=147 bs=512 conv=notrunc

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
