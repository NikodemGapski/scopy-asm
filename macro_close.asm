%ifndef MACRO_CLOSE
%define MACRO_CLOSE

; Exit the file with specified fd, if error occurred, store it in r10.
%macro close 1
	jmp %%start

%%SYS_CLOSE equ 3
%%ERROR_CODE_GROUND equ 0xfffffffffffff000

%%start:
	mov eax, %%SYS_CLOSE
	mov rdi, %1
	syscall
	cmp rax, ERROR_CODE_GROUND
	cmova r10, rax
%endmacro

%endif