# Builder-Hex0 v1.0-prerelease
Builder-Hex0 is a builder with a hex0 compiler. It runs in the form of a bootable disk image.

It has these features:
* Minimal 32-bit mode POSIX kernel
* The kernel is less than 3K in size
* Built-in Minimal Shell
* Built-in `src` command to load source files
* Built-in `hex0` Compiler converts hex source to binary files
* Written in 2K lines of commented hex
* Bootstraps using a 16-bit "mini" boot kernel that is only 384 bytes

## Status

* Initial development goals have been reached.
  * It can build x86 [stage0-posix](https://github.com/oriansj/stage0-posix) up to a working M2-Mesoplanet compiler, which supports a subset of C
  * It can build itself

* For experienced developers
  * Natively written in hex0
  * All relative jumps were hand calculated
  * Includes nasm-like assembly comments for reference only
  * Minimal to no error checking

* Could be somewhat smaller (e.g. with relative calls and inlining)


## Why?

This kernel is for bootstrapping compilers without having to trust a prebuilt binary. You still have to trust that the hex codes provided represent the x86 opcodes in the comments. But verifying the opcodes have been encoded properly is a straightforward process that you are encouraged to do using your own methods. You can also convert the hex to binary by any method you prefer. A Makefile is provided to do all this for you, for convenience, but you are free to distrust that in favor of your own methods.


## Building with make

Run:

```
make
```

The Makefile does this:

* Builds the "mini" (384 byte) boot kernel "seed" using command line utilities (cut and xxd)
* Builds the "full" (3K) boot kernel "seed" using command line utilities.
* Builds the "mini" boot kernel using the mini boot kernel and verifies it matches the seed.
* Builds the full boot kernel using the self-built mini boot kernel and verifies it matches the seed.
* Builds the full boot kernel using the full boot kernel and verfies it matches the previous one built with self-built mini


## Manual Build Instructions

1. Convert builder-hex0.hex0 to binary using a method you trust
2. Append zero bytes to the image in multiples of 512 bytes (sectors)
3. Write the shell script for your build directly on partition 4 of the disk image
    * Partition 4 starts at sector 8 which is byte offset 3072 of the disk
    * The script must be zero terminated, so the maximum length is the image size minus 3072 bytes
    * See build.sh for guidance
4. Launch the PC with the disk image
5. Wait until the machine reboots
6. The disk image itself is the result of the build

Why put the source on partition 4? The idea was to reserve partitions 1 to 3 for writing a boot partition, another file system, and perhaps a partition for logs. The idea is that you could resize the partitions to meet your requirements (by altering the partition table in the MBR) and the kernel would support writing to any of the partitions (e.g. /dev/hda1). But that flexibility is not currently implemented. Currently, you can only write back to the disk as a whole by writing to "/dev/hda".


## Machine Requirements
* x86 32-bit Processor
* PC compatible-BIOS
   * Must support int 10h,AH=0Eh (Write character to console)
   * Must support int 13h,AH=02h (Read Sectors)
   * Must support int 13h,AH=03h (Write Sectors)
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
* waitpid
* execve
* chmod
* lseek
* brk
* chdir
* access
* mkdir


## Hacks

There are a few non-obvious techniques used to pull this off.

### BIOS access

The kernel runs in 32-bit mode but temporarily drops into 16-bit mode to access BIOS routines (for disk and console I/O).

### fork/execve/waitpid

The kernel "simulates" a spawn pattern with this pattern:
* Fork records the top of the stack and returns as child.
* execve moves the parent process image aside and runs the child in the same address space.
* When the child calls exit, the parent process and stack is restored and returns from the previous fork again, as parent
* The parent calls waitpid which returns success because the child is already finished

### File system

* All written files are kept in memory.
* Opening an existing file for write actually creates a new file. Only the most recent one is active.
* At the end, the file named "/dev/hda" is flushed to the disk and the length is output to the screen. This can be used to build an executable or a boot image, as you please.

## Limitations

* The source script cannot exceed 1M bytes. This can be increased in build.sh.
* Total system memory is limited to 256M bytes. This can be increased in build.sh.

* Only 3068 files can be created.
* The total size of all files cannot exceed 61,865,983 bytes.
* A file name is limited to 1K bytes.
* Opening an existing file for write creates a new (empty) file with the same name.
    * Only the most recent file with the same name can be opened for read.
* Absolute paths (starting with /) are not honored from subdirectories. (The cwd is always prefixed to a path.)
    * So, if you are writing to /dev/hda, you must open it from the top directory.
    * Or you can hack around this using a path like ..//dev/hda
* All processes share the same file descriptors (i.e. current read and write locations)

* Only one argument is parsed for processes launched by the internal shell
* A process launched by the internalshell cannot start with 's' or 'h'
* Process arguments can only be 255 bytes long + 1 terminating zero byte
* Only one child can be forked at a time.
* The maximum depth of nested fork/execve is 6 total processes (which does not include the internalshell)
* When a parent spawns a child, (only) an 8MB snapshot of the parent process is set aside
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
