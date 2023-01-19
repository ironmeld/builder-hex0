# Builder-Hex0 v1.0-prerelease
Builder-Hex0 is a builder with a hex0 compiler. It runs in the form of a bootable disk image.

It has these features:
* Minimal 32-bit mode POSIX kernel
* The kernel is less than 3.5K in size
* Built-in Minimal Shell
* Built-in `src` command to load source files
* Built-in `hex0` Compiler converts hex source to binary files
* Written in 2K lines of commented hex
* Bootstraps using a 16-bit "mini" boot kernel that is only 384 bytes

## Status

* Initial development goals have been reached.
  * It can build itself.
  * It can build x86 [stage0-posix](https://github.com/oriansj/stage0-posix) up to a working M2-Mesoplanet compiler.
  * It can build [live-bootstrap](https://github.com/fosslinux/live-bootstrap) up to tcc-0.9.26.

* For experienced developers
  * Natively written in hex0
  * All relative jumps were hand calculated
  * Includes nasm-like assembly comments for reference only
  * Minimal to no error checking

* Could be somewhat smaller (e.g. with relative calls and inlining)


## Why?

This kernel is for bootstrapping compilers without having to trust a prebuilt binary. You still have to trust that the hex codes provided represent the x86 opcodes in the comments. But verifying the opcodes have been encoded properly is a straightforward process that you are encouraged to do using your own methods. You can also convert the hex to binary by any method you prefer. A Makefile is provided to do all this for you, for convenience, but you are free to distrust that in favor of your own methods.


## Building with make

The build requires qemu-system-x86_64 with kvm enabled.

Run:

```
make
```

If you do not have kvm enabled you can build without it using the following command
but a larger build will be extremely slow:
```
ENABLE_KVM= make
```

The Makefile does this:

* Builds the "mini" (384 byte) boot kernel "seed" using command line utilities (cut and xxd)
* Builds the "full" (3K) boot kernel "seed" using command line utilities.
* Builds the "mini" boot kernel using the mini boot kernel and verifies it matches the seed.
* Builds the full boot kernel using the self-built mini boot kernel and verifies it matches the seed.
* Builds the full boot kernel using the full boot kernel and verfies it matches the previous one built with self-built mini


## Manual Build Instructions

1. Create a disk image filled with zeros in multiples of 512 bytes.
2. Convert builder-hex0.hex0 to binary using a method you trust.
3. Append the build shell script to the binary.
4. Write the resulting file to the disk image, starting at offset 0.
5. Launch the PC with the disk image.
6. Wait until the machine reboots.
7. The disk image itself is the result of the build.

See build.sh for further guidance on the above instructions.


## Machine Requirements
* x86 32-bit Processor
* 2GB of memory
* PC compatible-BIOS
   * Must support int 10h,AH=0Eh (Write character to console)
   * Must support int 13h,AH=02h (Read Sectors)
   * Must support int 13h,AH=03h (Write Sectors)
   * Must support int 13h,AH=08h (Read Drive Parameters)
   * Must support int 15h,0x2401 (A20 activation)
* Disk large enough to hold kernel and build script with source files


## The Builder Shell
The builder shell is the first "process" to start although it is really just a function embedded in the kernel.

This internal shell reads commands from standard input.
The kernel provides this input by reading the contents of the disk starting right after the kernel, starting with sector 8,
which can be thought of as the first partition (/dev/hda1).

Essentially, the kernel starts by executing the equivalent of this command:
```
cat /dev/hda1 | internalshell
```

The internal shell includes two built-in commands:
* src: create source file from stdin.
* hex0: compile hex0 file to binary file.

The internal shell is also able to execute any file that has previously been written (by hex0). Note that the internal shell only supports parsing exactly one argument that it will pass to the command. This is enough to support executing a new shell and passing it the name of a shell script to run.


### The src command

```
src $number_of_bytes $filename
```
Read N bytes from standard input and write to a file.

Example:
```
src 27 foo.hex0
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

System calls are implemented with a POSIX i386 ABI interface.
System calls are accessed via interrupt 0x80.

The following system calls are implemented to some extent:
* exit
* fork
* read
* write
* open
* close
* waitpid
* execve
* chmod
* lseek
* brk
* chdir
* access
* mkdir
* wait4
* getcwd


## Hacks

There are a few non-obvious techniques used to pull this off.

### BIOS access

The kernel runs in 32-bit mode but temporarily drops into 16-bit mode to access BIOS routines (for disk and console I/O).

### fork/execve/waitpid

The kernel "simulates" a spawn pattern with this pattern:
* Fork snapshots the process image and stack and returns as child.
* execve overlays the child in the same address space as the parent.
* When the child calls exit, the parent process and stack is restored and returns from the previous fork again, as parent
* The parent calls waitpid which returns success because the child is already finished

### File system

* All written files are kept in memory.
* Opening an existing file for write actually creates a new file. Only the most recent one is active.
* At the end, the file named "/dev/hda" is flushed to the disk and the length is output to the screen. This can be used to build an executable or a boot image, as you please.

## Limitations

* Only 14332 files can be created.
* The total size of all files cannot exceed 536,870,911 bytes.
* A file name is limited to 1K bytes.
* Opening an existing file for write creates a new (empty) file with the same name.
    * Only the most recent file with the same name can be opened for read.

* Only one argument is parsed for processes launched by the internal shell
* A process launched by the internalshell cannot start with 's' or 'h'
* Each process argument can only be 255 bytes long + 1 terminating zero byte
* Only one child can be forked at a time.
* Each process cannot exceed 670,793,728 bytes of memory
* The total memory for all processes cannot exceed 805,306,368 bytes of memory
* waitpid returns zero from the child, regardless of the child's actual exit code.

* Unimplemented syscalls always succeed (eax = 0).
    * chdir always succeeds, regardless of whether the directory was previously created or not.
    * chmod permissions are not saved or checked.

* Violating a limit will likely result in a random, mysterious failure or crash.


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
