hex2: hex2_linker.o hex2_word.o hex2.c
	gcc -I M2libc -D__M2__ $^ -o $@

hex2_linker.o:
	gcc -c hex2_linker.c

hex2_word.o:
	gcc -c hex2_word.c

clean:
	rm -f hex2 *.o
