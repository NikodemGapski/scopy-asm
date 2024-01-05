%ifndef MACRO_EXIT
%define MACRO_EXIT

%macro exit 1
	jmp %%start

%%SYS_EXIT equ 60

%%start:
	mov eax, %%SYS_EXIT
	mov rdi, %1
	syscall
%endmacro

%endif