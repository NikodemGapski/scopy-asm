%ifndef MACRO_DEBUG
%define MACRO_DEBUG

; Print text provided in %1
%macro print 1
	jmp %%start

%%SYS_WRITE equ 1
%%STDOUT	equ 1
%%INPUT_TEXT: db %1
%%INPUT_LEN	equ $ - %%INPUT_TEXT
%%ENDLINE_TEXT: db `\n`
%%ENDLINE_LEN equ $ - %%ENDLINE_TEXT

%%start:
	; Put all used registers on the stack
	; (including rcx and r11 used by syscall)
	pushf
	push rcx
	push r11
	push rax
	push rdi
	push rsi
	push rdx

	; Print the text
	mov eax, %%SYS_WRITE
	mov edi, %%STDOUT
	mov rsi, %%INPUT_TEXT
	mov edx, %%INPUT_LEN
	syscall
	; Print endline
	mov eax, %%SYS_WRITE
	mov edi, %%STDOUT
	mov rsi, %%ENDLINE_TEXT
	mov edx, %%ENDLINE_LEN
	syscall
	
	; Bring the saved registers back
	pop rdx
	pop rsi
	pop rdi
	pop rax
	pop r11
	pop rcx
	popf
%endmacro

; Print text provided in %1 and the content of
; the register %2 in hexadecimal
%macro print_hex 2
	jmp %%start

%%SYS_WRITE equ 1
%%STDOUT	equ 1
%%INPUT_TEXT: db %1
%%INPUT_LEN	equ $ - %%INPUT_TEXT
%%STACK_OFFSET equ 7 * 8

%%start:
	; First, put %2 on the stack
	push %2
	; and make space for the hexadecimal representation
	sub rsp, 16
	; Then, put all used registers on the stack
	; (including rcx and r11 used by syscall)
	pushf
	push rcx
	push r11
	push rax
	push rdi
	push rsi
	push rdx

	; Print the text
	mov eax, %%SYS_WRITE
	mov edi, %%STDOUT
	mov rsi, %%INPUT_TEXT
	mov edx, %%INPUT_LEN
	syscall
	
	; Translate %2 into text (hex)
	mov rdx, [rsp + %%STACK_OFFSET + 16] ; %2 value
	mov rcx, 16
%%loop_start:
	dec rcx
	mov al, dl
	and al, 0xf
	cmp al, 9
	jbe %%is_digit
	add al, 'a' - 10 - '0'
%%is_digit:
	add al, '0'
	; Now in al is the ASCII code of the last hex character
	mov [rsp + %%STACK_OFFSET + rcx], byte al
	shr rdx, 4

	and rcx, rcx
	jnz %%loop_start
	; Put `\n` at the end of the string
	mov [rsp + %%STACK_OFFSET + 16], byte `\n`

	; Print the value
	mov eax, %%SYS_WRITE
	mov edi, %%STDOUT
	lea rsi, [rsp + %%STACK_OFFSET]
	mov edx, 17
	syscall


	; Bring the saved registers back
	pop rdx
	pop rsi
	pop rdi
	pop rax
	pop r11
	pop rcx
	popf
	add rsp, 24
%endmacro


%macro print_dec 2
	jmp %%start

%%SYS_WRITE 		equ 1
%%STDOUT			equ 1
%%INPUT_TEXT: db %1
%%INPUT_LEN			equ $ - %%INPUT_TEXT
%%STACK_OFFSET 		equ 7 * 8
%%MAX_REGISTER_LEN 	equ 20

%%start:
	; First, put %2 on the stack
	push %2
	; and make space for the hexadecimal representation
	sub rsp, %%MAX_REGISTER_LEN
	; Then, put all used registers on the stack
	; (including rcx and r11 used by syscall)
	pushf
	push rcx
	push r11
	push rax
	push rdi
	push rsi
	push rdx

	; Print the text
	mov eax, %%SYS_WRITE
	mov edi, %%STDOUT
	mov rsi, %%INPUT_TEXT
	mov edx, %%INPUT_LEN
	syscall
	
	; Translate %2 into text (hex)
	mov rax, [rsp + %%STACK_OFFSET + %%MAX_REGISTER_LEN] ; %2 value
	mov rdi, 10
	mov rcx, %%MAX_REGISTER_LEN
%%loop_start:
	dec rcx

	xor rdx, rdx
	div rdi ; remainder in dl
	
	add dl, '0'
	; Now in dl is the ASCII code of the last hex character
	mov [rsp + %%STACK_OFFSET + rcx], byte dl

	; if the number is already 0, exit the loop
	and rax, rax
	jz %%end_loop
	
	and rcx, rcx
	jnz %%loop_start

%%end_loop:
	; Put `\n` at the end of the string
	mov [rsp + %%STACK_OFFSET + %%MAX_REGISTER_LEN], byte `\n`

	; Print the value
	mov eax, %%SYS_WRITE
	mov edi, %%STDOUT
	lea rsi, [rsp + %%STACK_OFFSET + rcx]
	xor rdx, rdx
	sub rdx, rcx ; rdx = -rcx
	lea edx, [%%MAX_REGISTER_LEN + rdx + 1]
	syscall


	; Bring the saved registers back
	pop rdx
	pop rsi
	pop rdi
	pop rax
	pop r11
	pop rcx
	popf
	add rsp, %%MAX_REGISTER_LEN + 8
%endmacro

%macro printa 1
	jna %%end
	print %1
%%end:
%endmacro

%endif