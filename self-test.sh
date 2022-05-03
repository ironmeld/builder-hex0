#!/usr/bin/env bash

set -e

# Copy the original system portion. This must be reproduced byte-for-byte.
dd if=builder-hex0.img of=builder-hex0-system.bin bs=512 count=6
# Create a build instance
cp builder-hex0.img self-build.img

{
  # prepare self build 
  echo -n "src "
  wc -l ./builder-hex0.hex0
  cat ./builder-hex0.hex0
  echo "hex0 ./builder-hex0.hex0 /dev/hda"
} > input.src

# Apply source
dd if=input.src of=self-build.img bs=512 seek=8 conv=notrunc

# Launch build
qemu-system-x86_64 -m 256M -nographic -drive file=self-build.img,format=raw --no-reboot | tee build.log

# Get result
lengthhex=$(tail -1 build.log | tr -d '\r')

if [[ "$lengthhex" = ERROR* ]]; then
    echo "Self-build check failed!"
    result=1
else
    length=$(printf "%d\n" $((16#$lengthhex)))
    echo "$length"
    # Extract the result
    dd if=self-build.img of=self-build-system.bin bs=1 count="$length" status=none
    # Ensure the new system is the same as the original
    diff self-build-system.bin builder-hex0-system.bin
    echo "Self-build check completed successfully!"
    result=0
fi

rm -f builder-hex0-system.bin self-build.img self-build-system.bin
exit "$result"
