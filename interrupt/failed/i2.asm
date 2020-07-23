	DEVICE ZXSPECTRUMNEXT
; from http://www.breakintoprogram.co.uk/computers/zx-spectrum/interrupts
Interrupt:
		di                      ; Disable interrupts
		push af			; Save all the registers on the stack
		push bc			; This is probably not necessary unless
		push de			; we're looking at returning cleanly
		push hl 		; back to BASIC at some point
		push ix
		exx
		ex af,af'
		push af
		push bc
		push de
		push hl
		push iy
		;

		; my code - rotate the border?
		ld a,(23624)
		ld c,a
		inc a
		and 7
		out (254),a
		ld b,a
		ld a,c
		and 0F8h
		or b
		ld (23624),a

		;
		pop iy                  ; Restore all the registers
		pop hl
		pop de
		pop bc
		pop af
		exx
		ex af,af'
		pop ix
		pop hl
		pop de
		pop bc
		pop af
		;rst 38h                 ;
		ei			; Enable interrupts
		ret 			; And return
