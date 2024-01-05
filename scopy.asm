global _start

section .rodata

; System call codes.
SYS_WRITE 	equ 1
SYS_OPEN 	equ 2
SYS_CLOSE 	equ 3
SYS_EXIT 	equ 60

; Flag for creating the write-only file and failing if it already exists.
O_WRONLY_CREAT_EXCL equ 0q1 | 0q100 | 0q200
PERMISSION_MASK 	equ 0b110100100

; All values above ERROR_CODE_GROUND are error codes (-4095, -1).
ERROR_CODE_GROUND 	equ 0xfffffffffffff000

; Optimised buffer sizes.
; 8192 = BUFSIZ constant in C (default output stream buffer size).
OUT_BUFFER_SIZE 	equ 8192
; There are at most 3 bytes in the output for every 2 bytes of input
; (s, not-s) -> (s, 2-byte number).
IN_BUFFER_SIZE 		equ OUT_BUFFER_SIZE / 3 * 2

; Argument offsets on the stack.
IN_FILE_OFFSET		equ 16
OUT_FILE_OFFSET		equ 24

section .bss

in_buffer: resb IN_BUFFER_SIZE
out_buffer: resb OUT_BUFFER_SIZE

section .text

; Handle syscall error (set error flag accordingly).
; Arguments:
; - rax (syscall return value),
; - r10 (error flag used in the program).
; If an error occured, the ABOVE condition will be set.
handle_error:
	test r10b, r10b
	jnz .return
	cmp rax, ERROR_CODE_GROUND
	seta r10b
.return:
	ret

; Open a file and check for errors (set error flag accordingly).
; Arguments:
; - rdi (file name),
; - esi (flags),
; - edx (mode).
; If an error occured, the ABOVE condition will be set.
open_file:
	mov eax, SYS_OPEN
	syscall
	call handle_error
	ret

; Close a file and check for errors (set error flag accordingly).
; Arguments:
; - rdi (file name).
close_file:
	mov eax, SYS_CLOSE
	syscall
	call handle_error
	ret

; Main function.
; Register purposes:
; - r10 (error flag),
; - r9 (in_file descriptor),
; - r8 (out_file descriptor),
; - r12 (out_buffer address - for memory optimisation).
_start:
	; Clear error code.
	xor r10, r10
	; Set out_buffer address.
	mov r12, out_buffer
	; Check the number of parameters.
	cmp qword [rsp], 3
	jne .exit

	; Open in_file.
	mov rdi, [rsp + IN_FILE_OFFSET]
	xor esi, esi ; O_RDONLY = 0
	; (edx - mode is ignored)
	call open_file
	ja .exit
	; Set file descriptor.
	mov r9, rax

	; Create out_file.
	mov rdi, [rsp + OUT_FILE_OFFSET]
	mov esi, O_WRONLY_CREAT_EXCL
	mov edx, PERMISSION_MASK
	call open_file
	ja .close_in_file
	; Set file descriptor.
	mov r8, rax

	; Read and write between in_file and out_file.
	xor bl, bl ; count flag: 1 if the previous character was non-s, 0 otherwise
	xor bp, bp ; 16-bit non-s counter

.read_write_loop:
	; Read a batch of characters from in_file into a buffer.
	xor eax, eax ; SYS_READ = 0
	mov rdi, r9
	mov rsi, in_buffer
	mov edx, IN_BUFFER_SIZE
	syscall
	; Handle errors.
	call handle_error
	ja .close_files

	; If no bytes have been read, the end of file has been reached.
	test eax, eax
	jz .end_read_write_loop

	; Otherwise, the number of bytes specified in eax
	; have been read to the buffer.
	mov rdi, r12 ; address in out_buffer
	mov ecx, eax ; number of bytes to be translated
	; (address of in_buffer is already in rsi)

.translate_loop:
	; Load the next byte to al.
	lodsb
	cmp al, 'S'
	je .translate_s
	cmp al, 's'
	je .translate_s

	; If the current character is not S/s, increment the counter
	; and set the count flag.
.translate_not_s:
	inc bp
	mov bl, 1
	jmp .end_translate_loop

	; If the current character is S/s ...
.translate_s:
	; ... check the counter flag, ...
	test bl, bl
	jz .write_s
	; ... if it is on, write the counter to out_buffer, ...
	xchg ax, bp
	stosw
	xchg ax, bp
	; ... clear the flag and counter, ...
	xor bl, bl
	xor bp, bp
.write_s:
	; ... and finally write the character to out_buffer.
	stosb

.end_translate_loop:
	loop .translate_loop

	; Now, the in_buffer has been translated and put into out_buffer.
	mov rsi, r12 ; buffer pointer
	; In edx we store the number of translated bytes.
	mov rdx, rdi
	sub rdx, rsi

.write_loop:
	; Write to out_file as long as there are any remaining bytes.
	mov rdi, r8 ; out_file descriptor
	mov eax, SYS_WRITE
	syscall
	; Check for errors.
	call handle_error
	ja .close_files
	; Check if all bytes were written.
	cmp eax, edx
	je .read_write_loop
	; If not, move the buffer pointer, ...
	add rsi, rax
	; ... calculate bytes left, ...
	sub rdx, rax
	; ... and repeat the syscall.
	jmp .write_loop

.end_read_write_loop:
	; Make sure there is no non-s counter left.
	test bl, bl
	jz .close_files
	; If there is, write the counter to out_buffer, ...
	mov rsi, r12
	mov [rsi], bp
	; ... clear the flag and counter, ...
	xor bl, bl
	xor bp, bp
	; ... and write the buffer to the out_file
	; (the next iteration will get back here with cleared counter).
	mov edx, 2 ; the number of bytes to be written
	
	jmp .write_loop

.close_files:
	; Close out_file.
	mov rdi, r8
	call close_file

.close_in_file:
	; Close in_file.
	mov rdi, r9
	call close_file

.exit:
	; Exit with the right code.
	xor edi, edi
	mov dil, r10b
	mov eax, SYS_EXIT
	syscall
