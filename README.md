# Builder-Hex0 v0.1-prerelease
Builder-Hex0 is a builder with a hex0 compiler.

## Status
In development and not ready for any purpose.

## Quick Start

To build the image:
```
make
```

Or build the image manually:
```
cut builder-hex0.hex0 -f1 -d'#' | cut -f1 -d';' | xxd -r -p > builder-hex0.img
```

* cut will strip comments starting with pound or semicolon.
* xxd converts hex to binary.
