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

## Machine Requirements

* `x86_64` processor starting in 16-bit real mode
* PC compatible-BIOS

To run the image under `qemu-system-x86_64`:
```
make run
```

## The Hex0 Builder Operating System
TBD

## The Hex0 Builder Standard Library
reboot() - does not return

## The Hex0 Language
TBD

## The Hex0 Compiler
TBD

## The Hex0 Shell
TBD

## How to Build
TBD

## Wish List for the Next System
TBD
