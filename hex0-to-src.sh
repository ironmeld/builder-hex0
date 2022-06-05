#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

HEX0=$1

{
  echo -n "src "
  wc -c "$HEX0"
  cat "$HEX0"
  echo "hex0 $HEX0 /dev/hda"
}
