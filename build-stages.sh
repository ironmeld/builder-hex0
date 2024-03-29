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

# Place stage2 starting at sector LBA sector 1
dd if="$STAGE2" of="$IMG" seek=1 bs=512 conv=notrunc

# Place source after size of stage2 in sectors plus one for stage1 plus one because LBA is zero based
STAGE2_LEN=$(wc -c $STAGE2 | awk '{print $1}')
if [ $((STAGE2_LEN % 512)) = 0 ]; then
    STAGE2_SECTORS=$((STAGE2_LEN / 512))
else
    STAGE2_SECTORS=$((STAGE2_LEN / 512 + 1))
fi
SRC_LBA_SECTOR=$((STAGE2_SECTORS + 1))

# Place source starting at LBA sector after stage1 and stage2
dd if="$SRC" of="$IMG" seek=$SRC_LBA_SECTOR bs=512 conv=notrunc

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
