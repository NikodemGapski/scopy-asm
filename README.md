# Scopy

An Assembly project for the Computer Architecture and Operating Systems university course.

## Problem statement

Write a program in nasm which takes two file paths as arguments (`in_file` and `out_file`) and writes to `out_file` a *translation* of the `in_file` contents.

### Translation
Let's call a byte that's either 's' or 'S' an s-byte.

The translation is defined as follows:
- If the current byte isn't an s-byte, then simply copy it.
- Otherwise copy the byte, but preceeding it with the number of non s-bytes between this byte and the previous s-byte in in_file (unless the number is 0, then skip the number).

## Technical requirements

The program will be compiled with `make` (for compilation details see the makefile).

Try to achieve the lowest number of bytes possible for the executable.