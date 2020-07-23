		device ZXSPECTRUMNEXT
BORDER:	equ 	$c350
Start: 		equ	$8000

		org 	Start
		jr      SetupISR
Update:
		ld      a,(BORDER)
		break
		inc     a
		ld      c,7
		and     c
		out     (254),a
		ld	(BORDER),a
		ret

SetupISR:

		; Setup the 128 entry vector table
		di

		ld	hl, IM2Table
		ld	de, IM2Table+1
		ld	bc, 256

		; Setup the I register (the high byte of the table)
		ld	a, h
		ld	i, a

		; Set the first entries in the table to $FC
		ld	a, $FC
		ld	(hl), a

		; Copy to all the remaining 256 bytes
		ldir

		; Setup IM2 mode
		im	2
		ei

		ret

		ORG	$FCFC

; ISR (Interrupt Service Routine)
ISR:
		push    af
		push    hl
		push    bc
		push    de
		push    ix
		push    iy
		exx
		ex      af, af'
		push    af
		push    hl
		push    bc
		push    de

		call    Update

		pop     de
		pop     bc
		pop     hl
		pop     af
		ex      af, af'
		exx
		pop     iy
		pop     ix
		pop     de
		pop     bc
		pop     hl
		pop     af
		ei
		rst	$18:DW $0038

	; Make sure this is on a 256 byte boundary
		ORG	$FE00
IM2Table:
		defs	257

		;SAVESNA         "i3.sna", Start
		SAVENEX OPEN "i3.nex", Start, $ff40
		SAVENEX CORE 3, 0, 0        ; core 3.0.0 required
		SAVENEX CFG 1               ; blue border (as debug)
		SAVENEX AUTO                ; dump all modified banks into NEX file