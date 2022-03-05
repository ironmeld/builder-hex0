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
Note that once the build is complete, the image will not build again if restarted unless
source code is applied again.

Or build the image manually:
```
cut builder-hex0.hex0 -f1 -d'#' | cut -f1 -d';' | xxd -r -p > builder-hex0.mbr
```

* cut will strip comments starting with pound or semicolon.
* xxd converts hex to binary.

### General Build Instructions
1. Convert builder-hex0.hex0 to 512 byte Master Boot Record
2. Append 20480 zero bytes for a total length of 20992 bytes
3. Write hex0 source at offset 10752.
    * The source must be zero terminated, so the maximum length is 10239 bytes.
4. Launch the PC with the disk image
5. Wait until the machine reboots and then halts
6. The disk image itself is the result of the build


## Machine Requirements

* x86-16 Processor
* PC compatible-BIOS


## The Hex0 Builder System Interface
There is no system interface provided to the Standard Library.

Library routines directly invoke the BIOS.

## The Hex0 Builder Standard Library
* halt() - does not return
* reboot() - does not return
* putc()
* puts()
* read_source()
* write_image()


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
A small shell to control the build process.


## Research Sources

### x18-16 Assembly
* http://www.mathemainzel.info/files/x86asmref.html

### Boot sector bootstraps
* https://justine.lol/sectorlisp2/  (lisp *interpreter*)
* https://codeberg.org/StefanK/MinimalBinaryBoot   (very small forth bootsectors)
* https://gitlab.com/giomasce/asmc  (Based on 6KB seed of G lang, Gets to C quickly)

### Boot loaders
* http://3zanders.co.uk/2017/10/13/writing-a-bootloader/ (switch to 32 bit mode)
* https://dev.to/frosnerd/writing-my-own-boot-loader-3mld  (reading from disk, switch to 32bit)
* https://www.ired.team/miscellaneous-reversing-forensics/windows-kernel-internals/writing-a-custom-bootloader  (memory chart)
* https://0x00sec.org/t/realmode-assembly-writing-bootable-stuff-part-2/2992 (lots of stuff on real BIOS boot complications)
* https://github.com/eatonphil/bootloaders/blob/main/README.md (keyboard interrupt handler)
* https://lists.nongnu.org/archive/html/qemu-devel/2012-07/msg01310.html (qemu drive geometry)
* https://stackoverflow.com/questions/15497842/read-a-write-a-sector-from-hard-drive-with-int-13h (read drive handle errors, print string)
* https://www.datarecoverytools.co.uk/data-recovery-vocabulary/vocabulary-a-e/bios-translation-modes
* https://dev.to/frosnerd/writing-my-own-boot-loader-3mld (disk read error handling)
* https://stackoverflow.com/questions/9057670/how-to-write-on-hard-disk-with-bios-interrupt-13h (CHS calculations for int 13)

### Tools
* https://github.com/copy/v86
* https://justine.lol/blinkenlights
