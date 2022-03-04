# Builder-Hex0 v0.1-prerelease
Builder-Hex0 is a builder with a hex0 compiler.

## Status
In development and not ready for any purpose.

## Quick Start

To build the builder binary (builder-hex0.mbr), and an image that is ready to build (builder-hex0.img):

```
make
```

To launch the build image under QEMU:
```
make self-rebuild
```

The self-rebuild takes source code for the build image and rebuilds the build image.
Note that once the build is complete, the machine will not build again if restarted unless
source code is applied again.

Or build the image manually:
```
cut builder-hex0.hex0 -f1 -d'#' | cut -f1 -d';' | xxd -r -p > builder-hex0.mbr
```

* cut will strip comments starting with pound or semicolon.
* xxd converts hex to binary.

### General Build Instructions
1. Convert builder-hex0.hex0 to 512 byte Master Boot Record
2. Append 10240 zero bytes
3. Place hex0 source at the 21st sector (offset 10752)
4. Launch the PC with the disk image
5. Wait until the machine reboots and then halts
6. The disk image itself is the result of the build


## Machine Requirements

* `x86_64` processor starting in 16-bit real mode
* PC compatible-BIOS


## The Hex0 Builder Operating System


## The Hex0 Builder Standard Library
halt() - does not return
reboot() - does not return
putc()
puts()

## The Hex0 Language
Grammar form: https://www.crockford.com/mckeeman.html

### Grammar

```
hex0
    hexlines

hexlines
    hexline
    hexline hexlines

hexline
    ws_or_hex
    ws_or_hex nl
    ws_or_hex comment nl
    comment nl
    nl

ws_or_hex
    ws_or_hex_char
    ws_or_hex_char ws_or_hex

ws
    ' '
    '0009'

hexdigit
    'a' . 'f'
    'A' . 'F'
    '0' . '9'

nl
    '\n'

comment
    '#' characters
    ';' characters

characters
    character
    character characters

character
    '0020' . '00FF' - '000A' - '0000'
```

## The Hex0 Compiler
The compiler runs automatically when the machine boots.

## The Hex0 Shell
There is no shell in this release.

## Wish List for the Next System
TBD
