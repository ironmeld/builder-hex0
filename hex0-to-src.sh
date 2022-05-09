#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

HEX0=$1
SRC=${HEX0%.hex0}.src

{
  echo -n "src "
  wc -l "$HEX0"
  cat "$HEX0"
  echo "hex0 $HEX0 /dev/hda"
} > "$SRC"
