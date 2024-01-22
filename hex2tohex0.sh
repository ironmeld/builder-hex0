#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# This script runs a python script to convert a hex2 program to hex0
# while preserving comments.
#
# It also verifies the resulting hex0, when converted to binary,
# is the same binary you get by running hex2 from stage0-posix
# on the original hex2 file.
#

# Examples:
# ./hex2tohex0.sh builder-hex0 0x7C00
# ./hex2tohex0.sh builder-hex0-x86-stage1 0x7C00
#
# Create stage2:
# cp builder-hex0.hex2 builder-hex0-x86-stage2.hex2
# ./hex2tohex0.sh builder-hex0-x86-stage2 0x7E00

PROGRAM=$1
BASE_ADDR=$2

HEX2=./hex2/hex2
if ! [ -f "${HEX2}" ]; then
    echo "WARNING: The file ${HEX2} does not exist!"
    echo "This script will now run 'make -C hex2' to create the hex2 compiler."
    make -C hex2
fi

python3 hex2tohex0.py ${PROGRAM}.hex2 ${PROGRAM}.hex0 ${BASE_ADDR}
${HEX2} --file ${PROGRAM}.hex2 --output ${PROGRAM}.hex2.bin --base-address ${BASE_ADDR} --little-endian

cut ${PROGRAM}.hex0 -f1 -d'#' | cut -f1 -d';' | xxd -r -p > ${PROGRAM}.bin

od -tx1 ${PROGRAM}.hex2.bin > ${PROGRAM}.hex2.hex
od -tx1 ${PROGRAM}.bin > ${PROGRAM}.hex
diff -u ${PROGRAM}.hex2.hex ${PROGRAM}.hex

diff -u ${PROGRAM}.hex2.bin ${PROGRAM}.bin


git diff ${PROGRAM}.hex0 || true
cut ${PROGRAM}.hex0 -f1 -d'#' | cut -f1 -d';' | xxd -r -p > hex2.bin
echo "This file must be a multiple of 512:"
ls -l hex2.bin
rm -f -- *.hex *.bin
