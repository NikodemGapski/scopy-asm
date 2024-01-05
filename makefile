.PHONY: all clean

all: scopy

scopy: scopy.asm
	nasm -f elf64 -w+all -w+error -o $@.o $<
	ld --fatal-warnings -o $@ $@.o

run:
	rm -f out_file
	strace ./scopy in_file out_file

clean:
	rm -f scopy.o scopy