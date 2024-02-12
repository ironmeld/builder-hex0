#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

HEX0=$1

{
  echo -n "src "
  echo -n $(wc -c "$HEX0" | awk '{print $1}')
  echo " $HEX0"
  cat "$HEX0"
  echo "hex0 $HEX0 /dev/hda"
}
