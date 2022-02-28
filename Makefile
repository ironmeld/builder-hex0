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
# $@ means the target
# $^ means the dependencies
builder-hex0.img: builder-hex0.hex0
	# use cut to strip comments starting with pound or semicolon.
	# use xxd to convert hex to binary
	cut $^ -f1 -d'#' | cut -f1 -d';' | xxd -r -p > $@

clean:
	rm -f builder-hex0.img

# Make does not check whether PHONY targets already exist as files or dirs.
# It just invokes their recipes when they are targeted, no questions asked.
.PHONY: clean
