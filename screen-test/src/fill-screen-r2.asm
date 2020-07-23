	DEVICE ZXSPECTRUM48
speed:			EQU $00ff
start:			EQU $8000
DISPLAY_FILE:		EQU $4000

	ORG start

	ld bc,0
	jr load_pixel
	ld hl,DISPLAY_FILE	; point to the beginning of DISPLAY_FILE (screen)
	ld (hl),$80		; draw pixel on screen

paint:
	ld a,(hl)		; load current pixel into A
	scf			; set the carry flag (to do shift right with carry)
	rra			; rotate right pulling the carry bit in
	jr c,next		; if we shifted a bit out, then we're done
	ld (hl),a		; draw
	jr paint

next:
	inc bc

load_pixel:
	; convert bc into address
	ld hl,bc

next:
	inc l
	ld a, $20
	and l
	jr z, .skip
	ld l,0
	inc h
.skip:
	ld (hl),$80
	jr move

wait:
	ld bc, speed
.loop:
	dec bc
	ld a,b
	or c
	jr nz, .loop
	jr move

fin:
	jr $ ; loop forever

	SAVESNA "fill-screen.sna", start
