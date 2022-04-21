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

# The Builder-Hex0 x86 image with no source
# $< means "first dependency"
builder-hex0.img: builder-hex0.bin
	dd if=/dev/zero of=$@ bs=512 count=2056
	dd if=$< of=$@ bs=512 conv=notrunc

# $@ means the target
# $^ means the dependencies
# uses cut to strip comments starting with pound or semicolon.
# uses xxd to convert hex to binary
builder-hex0.bin: builder-hex0.hex0
	cut $^ -f1 -d'#' | cut -f1 -d';' | xxd -r -p > $@
	# if not right size, show the length then remove it
	[ `wc -c $@ | cut -f1 -d' '` = "3584" ] || (ls -l $@;rm $@;exit 1)

recursive: builder-hex0.img

# Build self with image and verify results
check: builder-hex0.img builder-hex0.hex0
	# Copy the original system portion. This must be reproduced byte-for-byte.
	dd if=builder-hex0.img of=builder-hex0-system.bin bs=512 count=7
	# Create a build instance
	cp builder-hex0.img self-build.img
	echo -n "src " > input.src
	wc -l ./builder-hex0.hex0 >> input.src
	cat ./builder-hex0.hex0 >> input.src
	echo "hex0 ./builder-hex0.hex0 /dev/hda" >> input.src
	# Apply source
	dd if=input.src of=self-build.img bs=512 seek=8 conv=notrunc
	# Launch build
	qemu-system-x86_64 -m 256M -nographic -drive file=self-build.img,format=raw || stty sane

	# Extract the new system
	dd if=self-build.img of=self-build-system.bin bs=512 count=7 status=none
	# Ensure the new system is the same as the original
	diff self-build-system.bin builder-hex0-system.bin
	rm builder-hex0-system.bin self-build.img self-build-system.bin

clean:
	rm -f builder-hex0.bin builder-hex0.img builder-hex0-system.bin self-build-system.bin self-build.img

# Make does not check whether PHONY targets already exist as files or dirs.
# It just invokes their recipes when they are targeted, no questions asked.
.PHONY: check clean
