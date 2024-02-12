# Development Notes

Note that there is a checklist at the bottom of this file that summarizes all the steps necessary to build and test properly.

## hex2 to hex0

For some programs, development is done in hex2 and then converted to hex0 with comments preserved.
You can use the hex2tohex0.py utility. This can also be run with hex2tohex0.sh which will do the conversion and verify that resulting hex0 was created properly by cross-checking it with the hex2 executable from stage0-posix.

## Kernel variations

The builder-hex0 kernel is shipped in two forms: as a full kernel with an included boot loader called `builder-hex0` and as a stage 2 kernel called `builder-hex0-x86-stage2`. The full kernel loads from disk as binary code and starts at address 0x7C00 but the stage 2 kernel starts at 0x7E00 and is loaded from the disk as hex0 source code. The stage 2 kernel is loaded/compiled by a stage 1 boot loader called `builder-hex0-x86-stage1` which starts in memory at address 0x7C00.

## MBR Alignment

For builder-hex0, the two MBR identifier bytes must be located at 0x7DFE and so the `past_MBR` label must be located at 0x7E00. If you add or remove code prior to that label you will need to relocate the two MBR identifier bytes and `past_MBR`the label.


## Increasing the size of the kernel

If the size of the kernels change significantly, you will need to adjust some hard coded numbers.

This applies if the following changes:
   * The binary size of the builder-hex0 kernel padded to 512 bytes.
   * The binary kernel for stage 1 (builder-hex0-x86-stage1) kernel padded to 512 bytes.
   * The size of the source code for stage 2 (builder-hex0-x86-stage2.hex0) padded to 512 bytes.

### Builder-hex0 Binary Size Adjustment

If the binary size of the builder-hex0 kernel changes, the `Makefile` rule for `BUILD/builder-hex0-mini-built.bin` will need to be changed. Change the line that runs build-mini.sh to pass the size of the resulting binary kernel. (The "mini" builder does not output the size of the artifact it builds so we have to tell the script the size of the artifact to extract from the disk image.)

You must also change the sector to start reading src. This is in the internalshell function. This should be set to the size of the builder-hex0 binary in sectors (which is 8 at the time of this writing). Note there are two values in that function, one for the single stage kernel and one for stage 2. Change the first one.


### Single Stage Binary Size Adjustment

The binary size of the single stage kernel (builder-hex0) is padded so that its size is a multiple of 512, which is the size of a disk sector. If you add enough code that causes the binary size of the single stage kernel to cross into the next sector you must pad it to the end of the sector and you have to make another change to the single stage kernel because the single stage kernel must read its own code (except the first sector) from the disk. You must change the number of sectors to read the kernel in the `kernel_main` function. The number of sectors is the size of the kernel binary divided by 512 and then subtract one. You subtract one because the BIOS already loads the first sector and so the rest of the kernel is read starting at LBA sector 1 (which is the second sector because LBA is zero-based).

You must also change the location where the `internalshell` function starts reading input. You need to do this because the internalshell reads input starting right after the kernel on the disk, so the starting location varies depending on the size of the kernel. The starting location is set at the beginning of the `internalshell` function. The value should be the total number of sectors for the kernel plus one. Note that there are two values: a starting location for the single stage kernel (builder-hex0) and a starting location for a stage 2 (builder-hex0-x86-stage2) kernel. Change the first one.

### Stage 2 Source Size Adjustment

If the kernel is loaded by builder-hex0-x86-stage1 then it is loaded as hex0 source code which is converted to binary and runs as stage 2. The location that the `internalshell` function of the stage 2 kernel reads input from is on the first sector *after* the stage 2 source code on the disk. Therefore, you need to determine how many sectors is needed to store builder-hex0-x86-stage2.hex0. You can typically divide the file size by 512, rounded down to the nearest integer, and add one. You don't need to add one if the size of the kernel source is an exact multiple of 512, which is possible but very unlikely. After determining the number of sectors, you must add 1 (or the size of the stage 1 kernel in sectors) and set the total value near the beginning of the internalshell function. Note there are two values, one for single stage and one for stage 2. Change the second one.


## Build and Test Checklist

```
# Follow these steps after you have made changes to `builder-hex0.hex2` and/or `builder-hex0-x86-stage1.hex2`.

# Convert hex2 files to hex0:
$ ./hex2tohex0.sh builder-hex0 0x7C00
$ ./hex2tohex0.sh builder-hex0-x86-stage1 0x7C00
# The stage2 version of builder-hex0 just starts at a different address:
$ cp builder-hex0.hex2 builder-hex0-x86-stage2.hex2
$ ./hex2tohex0.sh builder-hex0-x86-stage2 0x7E00

# Test changes locally
$ make test

# builder-hex0 is used by the live-bootstrap project so it is a good idea to run the
# following commands to test your changes with that project. Note the paths and commands
# used by live-bootstrap are subject to change.
$ (cd ~/ && git clone https://github.com/fosslinux/live-bootstrap && cd live-bootstrap && git submodule update --init --recursive)
$ cp builder-hex0-x86-stage1.hex0 ~/live-bootstrap/builder-hex0
$ cp builder-hex0-x86-stage2.hex0 ~/live-bootstrap/builder-hex0
$ (cd ~/live-bootstrap;./rootfs.py --qemu)

# After testing, the hex2 and hex0 files can be committed with the following commands.
$ git add builder-hex0.hex2 builder-hex0.hex0
$ git add builder-hex0-x86-stage1.hex2 builder-hex0-x86-stage1.hex0
# DO NOT git add builder-hex0-x86-stage2.hex2. This is just a temporary copy of builder-hex0.hex2
# which is used to generate the hex0 file for stage2.
$ git add builder-hex0-x86-stage2.hex0
```
