# Makefile for the builder-hex0 project
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
#
# * Files with .hex0 extension is source code to be compiled
# * Files with .src extension are build scripts with source code included.
#
# * Files with .bin extension consist of the bootable/executable part of a
#   hard disk image. They are not functional by themselves.
# * Files with .img extension are hard disk images that consist of the .bin
#   bootable/executable with a .src (for full builds) or .hex0 (for mini builds)
#   file appended to it, making it ready to build.
#
#
# The "mini" builder takes .hex0 files and can build itself and can also
# build the full builder.
#
# The "full" builder takes .src files which are primitive shell scripts and
# can build itself and other compilers.


# The (full) builder-hex0 built by a (full) builder-hex0 (built by the mini builder)
builder-hex0-self-built.bin: builder-hex0-mini-built.bin builder-hex0.src build.sh
	# params: boot sectors to use, shell source to append, name of binary to extract
	./build.sh builder-hex0-mini-built.bin builder-hex0.src builder-hex0-self-built.bin
	# verify that the self-built binary is the same as the mini-built binary
	diff builder-hex0-self-built.bin builder-hex0-mini-built.bin
	rm -f build.log

builder-hex0.src: builder-hex0.hex0 hex0-to-src.sh
	./hex0-to-src.sh ./builder-hex0.hex0


# The "full" builder-hex0 built by the self-built mini builder
builder-hex0-mini-built.bin: builder-hex0-mini-self-built.bin builder-hex0.hex0 build-mini.sh builder-hex0-seed.bin
	# params: boot sectors to use, source to append, size of binary to extract, name of extracted binary
	./build-mini.sh builder-hex0-mini-self-built.bin builder-hex0.hex0 3072 builder-hex0-mini-built.bin
	# verify that it matches the seed
	diff builder-hex0-seed.bin builder-hex0-mini-built.bin


# builder-hex0-mini built by the mini builder built by the seed mini bulder
builder-hex0-mini-self-built.bin: builder-hex0-mini-seed-built.bin builder-hex0-mini.hex0 build-mini.sh
	# params: boot sectors to use, source to append, size of binary to extract, name of extracted binary
	./build-mini.sh builder-hex0-mini-seed-built.bin builder-hex0-mini.hex0 512 builder-hex0-mini-self-built.bin
	# verify that the self-built mini builder is the same as the seed-built binary
	diff builder-hex0-mini-seed-built.bin builder-hex0-mini-self-built.bin


# builder-hex0-mini built by the seed mini builder
builder-hex0-mini-seed-built.bin: builder-hex0-mini-seed.bin builder-hex0-mini.hex0 build-mini.sh
	# params: boot sectors to use, source to append, size of binary to extract, name of binary to extract
	./build-mini.sh builder-hex0-mini-seed.bin builder-hex0-mini.hex0 512 builder-hex0-mini-seed-built.bin
	# verify that the binary built by the seed binary is the same as the seed binary
	diff builder-hex0-mini-seed.bin builder-hex0-mini-seed-built.bin


# builder-hex0-mini seed built using command line utilities
builder-hex0-mini-seed.bin: builder-hex0-mini.hex0
	# uses cut to strip comments starting with pound or semicolon.
	# uses xxd to convert hex to binary
	cut builder-hex0-mini.hex0 -f1 -d'#' | cut -f1 -d';' | xxd -r -p > builder-hex0-mini-seed.bin

# builder-hex0 seed built using command line utilities
builder-hex0-seed.bin: builder-hex0.hex0
	# uses cut to strip comments starting with pound or semicolon.
	# uses xxd to convert hex to binary
	cut builder-hex0.hex0 -f1 -d'#' | cut -f1 -d';' | xxd -r -p > builder-hex0-seed.bin


clean:
	rm -f -- *.bin *.img *.src *.log

# Make does not check whether PHONY targets already exist as files or dirs.
# It just invokes their recipes when they are targeted, no questions asked.
.PHONY: clean
