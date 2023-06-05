# Development Notes

## hex2 to hex0

For some programs, development is done in hex2 and then converted to hex0 with comments preserved.
You can use the hex2tohex.py utility. This can also be run with hex2tohex0.sh which will do the conversion and verify that resulting hex0 was created properly by cross-checking it with the hex2 executable from stage0-posix.

## Kernel variations

The builder-hex0 kernel is shipped in two forms: as a full kernel with an included boot loader called `builder-hex0` and as a stage 2 kernel called `builder-hex0-x86-stage2`. The full kernel loads from disk as binary code and starts at address 0x7C00 but the stage 2 kernel starts at 0x7E00 and is loaded from the disk as hex0 source code. The stage 2 kernel is loaded/compiled by a stage 1 boot loader called `builder-hex0-x86-stage1` which starts in memory at address 0x7C00.

## MBR Alignment

For builder-hex0, the two MBR identifier bytes must be located at 0x7DFE and so the `past_mbr` label must be located at 0x7E00. If you add or remove code prior to that label you will need to relocate the two MBR identifier bytes and `past_mbr`the label.


## Increasing the size of the kernel

If you increase the size of the binary kernel (for stage 1) or kernel source (for stage 2) you must make changes to the code to account for this.

### Stage 1 Size Adjustment

The binary size of a stage 1 kernel is padded so that its size is a multiple of 512, which is the size of a disk sector. If you add enough code that causes the binary size of a stage 1 kernel to cross into the next sector you must pad it to the end of the sector and you have to make another change to the stage 1 kernel because the stage 1 kernel must read its own code (except the first sector) from the disk. You must change the number of sectors to read the kernel in the `kernel_main` function. The number of sectors is the size of the kernel binary divided by 512 and then subtract one. You subtract one because the BIOS already loads the first sector and so the rest of the kernel is read starting at sector 2.

You must also change the location where the `internalshell` function starts reading input. You need to do this because the internalshell reads input starting right after the kernel on the disk, so the starting location varies depending on the size of the kernel. The starting location is set at the beginning of the `internalshell` function. The value should be the total number of sectors for the kernel plus one. Note that there are two values: a starting location for stage 1 kernel and a starting location for a stage 2 kernel. Change the first one.

### Stage 2 Size Adjustment

If the kernel is loaded by builder-hex0-x86-stage1 then it is loaded as hex0 source code which is converted to binary and runs as stage 2. The location that the `internalshell` function of the stage 2 kernel reads input from is on the first sector  *after* the stage 2 source code on the disk. Therefore, you need to determine how many sectors is needed to store builder-hex0-x86-stage2.hex0. You can typically divide the file size by 512 and add one. You don't need to add one if the size of the kernel source is an exact multiple of 512, which is possible but very unlikely. After determining the number of sectors, you must add 2 and total and set this value near the beginning of the internalshell function. Note there are two values, one for stage 1 and one for stage 2. Change the second one.

Also, change the `build-stages.sh` script. Change the seek offset in the `dd` command after the `Place source ...` comment.
