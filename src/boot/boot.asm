[BITS 16]

cli                      ; clear interrupt-enable flag (desable int)
xor		ax, ax
mov		ss, ax           ; stack segment
mov		sp, 0x7C00       ; stack pointer
mov		di, 0x2000       ; for writing to buff (0x20000-0x80000)


xor     bx, bx
xor     ch, ch           ; cylinder number
xor     dh, dh           ; head number
mov     cl, 0x1          ; starting sector number (from 2 to 18)


read_loop:

	;  384 * 1024 / 512 = 768 sectors
	;  768 / 36 = 21.33 cyls
	;  start = 0x20000
	;  end   = 0x80000

	mov		si, 0x03            ; error counter 
	
	read_num:
		cmp    	di, 0x8000          ; if end of buff
		je 		end_of_reading      ; then jump to end_of_read
		
		mov     es, di				; current value for stack segment
		mov	    ah, 0x02            ; BIOS read sector from drive
		mov     al, 0x01            ; amount of sectors
		int     0x13                

		jc		errmsglb            ; error check
		
		add    	di, 0x20            ; 512 bytes
		
		inc    	cl                  ; next sector
		cmp    	cl, 0x13            ; if 19th sector -> 
		je    	check_head          ; check head_num
		jmp    	read_loop           ; else read next sector
		

	check_head:
		mov    	cl, 0x1             ; sector num -> 1
		inc    	dh                  ; inc head num
		cmp    	dh, 0x2             ; if prev head num was 0x1
		je     	change_cyl          ; we've finished there -> go to next cyl
		jmp    	read_loop           ; if head num is 0x0 -> continue


	change_cyl:
		xor    	dh, dh              ; head num -> 0
		inc    	ch                  ; get next cyl
		jmp   	read_loop	   		; read from next cyl



end_of_reading: 
	mov ax, 0x2000                	    ; start from 0x20000
	mov es, ax                          ; es <- 0x2000
	xor dl, dl                          ; check sum
	xor bx, bx                          ; clear bx (for es)
		
	addition:

		add dl, BYTE[es:bx]         ; add the value from es:bx
		inc bx
		cmp bx, 0x10                ; if bx == 17
		je move_es                  ; -> we should inc es by 1 
		jmp addition                ; else - continue summation
		
		move_es:

			mov ax, es
			inc ax                  ; inc es
			mov es, ax  
			cmp ax, 0x8000          ; cmp if end of buff
			je  end_loop            ; if end -> end_loop
			xor bx, bx              ; bx -> 0 for next iteration
			jmp addition
	
errmsglb:
	dec    si             		    ; dec error counter
	cmp    si, 0x0      		    ; check if zero
	jne    read_num       		    ; if not zero - retry
					    ; else go to end_loop

end_loop:
;	jmp end_loop   - убит

times 510-($-$$) db 0
dw 0xAA55  

mov ah, 0xE
mov al, "A"
int 0x10

        

gdt_start:
  dq 0x0                           ; null descriptor
gdt_code:
  dq 0x92C200
  ;dw 0x92c2
  ;dw 0x0
gdt_data:
  dq 0xA63000
  ;dw 0xa630
  ;dw 0x0

gdt_end:                           ; ??

lgdt [gdt_descriptor]              ;

gdt_descriptor:
  dw gdt_end - gdt_start - 1       ; labels arithmetic
  dd gdt_start + 0x20000           ; GDT linear address in VBR copy

CODE_SEG equ gdt_code - gdt_start  ; def constants
DATA_SEG equ gdt_data - gdt_start


jmp CODE_SEG:protected_mode_tramplin + 0x7c00

[BITS 32]

protected_mode_tramplin:
  mov eax, DATA_SEG
  mov ds,  eax
  mov ss,  eax
  mov es,  eax
  mov fs,  eax
  mov gs,  eax
  mov esp, 0x20000

  jmp CODE_SEG:0x20200


                 ; define boot sector           



