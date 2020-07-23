        DEVICE ZXSPECTRUM48
speed:                  EQU $00ff
start:                  EQU $8000
DISPLAY_FILE:           EQU $4000

        ORG start

        ld hl,DISPLAY_FILE      ; point to the beginning of DISPLAY_FILE (screen)
        ld (hl),$80            ; draw pixel on screen

move:
        ld a,(hl)               ; load current pixel into A
        scf                     ; set the carry flag (to do shift right with carry)
        rra                     ; rotate right pulling the carry bit in
        jr c,next_pixel         ; if we shifted a bit out, then we're done
	ld (hl),a               ; draw
        jr move

next_pixel:
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
