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

all: BUILD/builder-hex0-self-built.bin BUILD/builder-hex0-x86-stage1.img

# The (full) builder-hex0 built by a (full) builder-hex0 (built by the mini builder)
BUILD/builder-hex0-self-built.bin: BUILD/builder-hex0-mini-built.bin BUILD/builder-hex0.src build.sh | BUILD
	# params: boot sectors to use, shell source to append, name of binary to extract
	(cd BUILD && ../build.sh builder-hex0-mini-built.bin builder-hex0.src builder-hex0-self-built.bin)
	# verify that the self-built binary is the same as the mini-built binary
	(cd BUILD && diff builder-hex0-self-built.bin builder-hex0-mini-built.bin)

BUILD/builder-hex0.src: builder-hex0.hex0 hex0-to-src.sh | BUILD
	# create directory so we can write into it
	echo "src 0 /dev" > $@
	./hex0-to-src.sh ./builder-hex0.hex0 >> $@


# The "full" builder-hex0 built by the self-built mini builder
BUILD/builder-hex0-mini-built.bin: BUILD/builder-hex0-mini-self-built.bin builder-hex0.hex0 build-mini.sh BUILD/builder-hex0-seed.bin | BUILD
	# params: boot sectors to use, source to append, size of binary to extract, name of extracted binary
	(cd BUILD && ../build-mini.sh builder-hex0-mini-self-built.bin ../builder-hex0.hex0 3584 builder-hex0-mini-built.bin)
	# verify that it matches the seed
	(cd BUILD && diff builder-hex0-seed.bin builder-hex0-mini-built.bin)


# builder-hex0-mini built by the mini builder built by the seed mini bulder
BUILD/builder-hex0-mini-self-built.bin: BUILD/builder-hex0-mini-seed-built.bin builder-hex0-mini.hex0 build-mini.sh | BUILD
	# params: boot sectors to use, source to append, size of binary to extract, name of extracted binary
	(cd BUILD && ../build-mini.sh builder-hex0-mini-seed-built.bin ../builder-hex0-mini.hex0 512 builder-hex0-mini-self-built.bin)
	# verify that the self-built mini builder is the same as the seed-built binary
	(cd BUILD && diff builder-hex0-mini-seed-built.bin builder-hex0-mini-self-built.bin)


# builder-hex0-mini built by the seed mini builder
BUILD/builder-hex0-mini-seed-built.bin: BUILD/builder-hex0-mini-seed.bin builder-hex0-mini.hex0 build-mini.sh | BUILD
	# params: boot sectors to use, source to append, size of binary to extract, name of binary to extract
	(cd BUILD && ../build-mini.sh builder-hex0-mini-seed.bin ../builder-hex0-mini.hex0 512 builder-hex0-mini-seed-built.bin)
	# verify that the binary built by the seed binary is the same as the seed binary
	(cd BUILD && diff builder-hex0-mini-seed.bin builder-hex0-mini-seed-built.bin)


# builder-hex0-mini seed built using command line utilities
BUILD/builder-hex0-mini-seed.bin: builder-hex0-mini.hex0 | BUILD
	# uses cut to strip comments starting with pound or semicolon.
	# uses xxd to convert hex to binary
	cut builder-hex0-mini.hex0 -f1 -d'#' | cut -f1 -d';' | xxd -r -p > BUILD/builder-hex0-mini-seed.bin

# builder-hex0 seed built using command line utilities
BUILD/builder-hex0-seed.bin: builder-hex0.hex0 | BUILD
	# uses cut to strip comments starting with pound or semicolon.
	# uses xxd to convert hex to binary
	cut builder-hex0.hex0 -f1 -d'#' | cut -f1 -d';' | xxd -r -p > BUILD/builder-hex0-seed.bin

# stage1 has an img extension to match other files in https://github.com/oriansj/bootstrap-seeds/tree/master/NATIVE/x86
BUILD/builder-hex0-x86-stage1.img: builder-hex0-x86-stage1.hex0 | BUILD
	cut builder-hex0-x86-stage1.hex0 -f1 -d'#' | cut -f1 -d';' | xxd -r -p > BUILD/builder-hex0-x86-stage1.img

BUILD:
	mkdir BUILD

clean:
	rm -rf BUILD
	make -C hex2 clean

# Make does not check whether PHONY targets already exist as files or dirs.
# It just invokes their recipes when they are targeted, no questions asked.
.PHONY: clean
