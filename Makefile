# Makefile for the Builder-Hex0 project
#
# This makefile is provided for convenience for those who are using a
# virtual machine and do not want to construct and launch the initial
# disk image by hand.
#
# Providing steps for constructing the initial disk image for every
# possible machine is outside the scope of this project.
#
# To address criticism that "using a makefile to automate a bootstrap
# process is cheating", this is only provided for convenience
# for those who want to "cheat".
#

# The Builder-Hex0 x86 disk image.
#
builder-hex0.img: builder-hex0.mbr
	dd if=/dev/zero of=builder-hex0.img bs=512 count=41
	dd if=builder-hex0.mbr of=builder-hex0.img bs=512 count=1 conv=notrunc
	dd if=builder-hex0.hex0 of=builder-hex0.img bs=512 seek=21 conv=notrunc

# $@ means the target
# $^ means the dependencies
# uses cut to strip comments starting with pound or semicolon.
# uses xxd to convert hex to binary
builder-hex0.mbr: builder-hex0.hex0
	cut $^ -f1 -d'#' | cut -f1 -d';' | xxd -r -p > $@
	[ `wc -c $@ | cut -f1 -d' '` = "512" ] || (ls -l $@;rm $@;exit 1)

clean:
	rm -f builder-hex0.mbr builder-hex0.img

self-rebuild: builder-hex0.img
	qemu-system-x86_64 -nographic -drive file=builder-hex0.img,format=raw
	# extract the new mbr
	dd if=builder-hex0.img of=builder-hex0.mbr.new bs=512 count=1 status=none
	# ensure the new mbr is the same as the original
	diff builder-hex0.mbr builder-hex0.mbr.new
	rm builder-hex0.mbr.new

# Make does not check whether PHONY targets already exist as files or dirs.
# It just invokes their recipes when they are targeted, no questions asked.
.PHONY: clean run self-rebuild
