#!/usr/bin/env bash
set -euo pipefail

make clean
make
cd BUILD

git clone https://github.com/oriansj/bootstrap-seeds
SEED_DIR=bootstrap-seeds/POSIX/x86

# create dev directory so we can write /dev/hda
echo "src 0 /dev" > hex0.src

cp $SEED_DIR/hex0_x86.hex0 .
../hex0-to-src.sh ./hex0_x86.hex0 >> hex0.src

../build-stages.sh builder-hex0-x86-stage1.img ../builder-hex0-x86-stage2.hex0 hex0.src hex0-seed
diff $SEED_DIR/hex0-seed hex0-seed

echo "Multi-stage test successful."
