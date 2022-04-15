# Builder-Hex0 v0.1-prerelease
Builder-Hex0 is a builder with a hex0 compiler.

It has these features:
* Less than 3 kilobytes of code
* Bootable disk image file
* Minimal POSIX kernel
* Minimal Shell
* `src` command to write source files
* `hex0` Compiler

## Status
* In development
* Most development goals have been reached.
* Experienced developers could take a look
* Minimal support available

## Quick Start

To build an image that is ready to build (builder-hex0.img):

```
make
```

You can also build the boot sectors manually:
```
cut builder-hex0.hex0 -f1 -d'#' | cut -f1 -d';' | xxd -r -p > builder-hex0.bin
```
* cut will strip comments starting with pound or semicolon.
* xxd converts hex to binary.

To run a self check:
```
make check
```

The self check takes source code for the build image and rebuilds the build image.
Note that once the build is complete, the image will not build again if restarted unless
source code is applied again.

### General Build Instructions
1. Convert builder-hex0.hex0 to binary
2. Append zero bytes for a total length of 1052672 bytes
3. Place the shell script for your build directly on partition 4 of the disk image
    * Partition 4 starts at sector 7 which is byte offset 3072 of the disk
    * The script must be zero terminated, so the maximum length is 1048575 bytes (+1 zero byte)
    * See the `check` target in the Makefile for guidance
4. Launch the PC with the disk image
5. Wait until the machine reboots and then halts
6. The disk image itself is the result of the build


## Machine Requirements
* x86 32 bit Processor
* PC compatible-BIOS
   * Must support int 10h,AH=0Eh (Write character to console)
   * Must support int 13h,AH=02h (Read Sectors)
   * Must support int 13h,AH=08h (Read Drive Parameters)
   * Must support int 15h,0x2401 (A20 activation)


## The Builder Shell
The builder shell is the first "process" to start although it is really just a function embedded in the kernel.

This internal shell reads commands from standard input.
The kernel provides this input by reading the contents of the fourth disk partition.

Essentially, the kernel starts by executing the equivalent of this command:
```
cat /dev/hda4 | internalshell
```

The internal shell supports two commands:
* src: create source file from stdin.
* hex0: compile hex0 file to binary file.

The internal shell will also execute any file that has previously been written (by hex0).


### The src command

```
src $number_of_lines $filename 
```
Read N lines from standard input and write to a file.

Example:
```
src 4 foo.hex0
45 23 23
23 45
53 55
53 55
```

### The hex0 command

The hex0 command implements a compiler for the Hex0 language. 
The hex0 language is described later in this document.

```
hex0 $input_hex0_file $output_binary_file
```

Reads hex0 from the input file, converts to binary, and writes to the output file.


## The Hex0 Builder System Interface

System calls are implemented with a linux i386 ABI interface.
System calls are accessed via interrupt 0x80.

The following system calls are implemented to some extent:
* exit
* fork
* read
* write
* open
* waitpid
* execve
* chmod
* lseek
* brk


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

## OS Development
* https://wiki.osdev.org/Main_Page
* http://asm.sourceforge.net/articles/startup.html (initial stack structure for executables)

### Tools
* https://github.com/copy/v86
* https://justine.lol/blinkenlights
