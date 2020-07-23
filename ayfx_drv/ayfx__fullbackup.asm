	DEVICE ZXSPECTRUMNEXT
	ORG $0000

MMU6_C000_NR_56		equ $56
; **************************************************************
; * API
; - 0: set bank id
; - 1: set effect
; **************************************************************

api_entry:
	jr      ayfx_api
	nop

; At $0003 is the entry point for the interrupt handler. This will only be
; called if bit 7 of the driver id byte has been set in your .DRV file, so
; need not be implemented otherwise.
im1_entry:
reloc_1:
	call	backup_bank
reloc_2:
	call 	AFXFRAME
reloc_3:
	call	restore_bank

	ret

; ***************************************************************************
; * AYFX driver API                                                      *
; ***************************************************************************
; On entry, use B=call id with HL,DE other parameters.
; (NOTE: HL will contain the value that was either provided in HL (when called
;        from dot commands) or IX (when called from a standard program).
;
; When called from the DRIVER command, DE is the first input and HL is the second.
;
; When returning values, the DRIVER command will place the contents of BC into
; the first return variable, then DE and then HL.

ayfx_api:
	break
        bit     7,b                     ; check if B>=$80
        jr      nz,standard_api         ; on for standard API functions if so

	djnz	bnot1			; On if B<>1

; B=1: set bank to the value in DE
callId1_load_bank:
reloc_5:
	call	backup_bank
	ld	a,e			; user bank is in DE and set in A and as
	add	a,e			; NextBASIC banks are in 16k: double it
reloc_4:
	ld	(ayfx_bank),a		; store it for future use
	nextreg MMU6_C000_NR_56, a 	; load the user's bank in
	ld 	hl,$C000		; user data sits at the start of the bank
reloc_6:
	call 	AFXINIT
reloc_7:
	call	restore_bank
	and     a                       ; clear carry to indicate success
	ret

bnot1:
	djnz    bnot2                   ; On if B<>2

; B=2: start effect value DE
callId2_set_effect:
	ld	a,e			; E = effect id
reloc_8:
	call 	backup_bank
reloc_9:
	call 	AFXPLAY
reloc_10:
	call	restore_bank
	and     a                       ; clear carry to indicate success
	ret

; Unsupported values of B.

bnot2:
api_error:
	xor	a			; A=0, unsupported call id
	scf				; Fc=1, signals error
	ret


; FIXME unsure if I need to even handle the standard_api
standard_api:
	and	a 			; both install and uninstall are fine
	ret

ayfx_bank:
        defb	0

ayfx_index:
        defb	0

bank_backup:
	defb	0


; **************************************************************
; Backup and restore whatever is in MMU6
;
; uses: a, bc
; **************************************************************
backup_bank:
	ld 	bc,$243b ; select NEXT register
	ld 	a, MMU6_C000_NR_56
	out 	(c),a
	inc 	b ; $253b to access (read or write) value
	in 	b,(c)
	push	bc
	ret

restore_bank:
	pop	bc
	ld	a, b
	nextreg MMU6_C000_NR_56, a
	ret

;-Minimal ayFX player v0.15 06.05.06---------------------------;
;                                                              ;
; The simplest player for effects. Plays effects on one AY,    ;
; without music in the background. Channel selection priority: ;
; if available; free channels, one of them is selected. If free;
; no channels, the longest sounding one is selected. Procedure ;
; playback uses registers AF, BC, DE, HL, IX.                  ;
;                                                              ;
; Initialization:                                              ;
;   ld hl, effect bank address                                 ;
;   call AFXINIT                                               ;
;                                                              ;
; Effects playback:                                            ;
;   ld a, effect number (0..255)                               ;
;   call AFXPLAY                                               ;
;                                                              ;
; In the interrupt handler:                                    ;
;   call AFXFRAME                                              ;
;                                                              ;
;--------------------------------------------------------------;


; channel descriptors, 4 bytes per channel:
; +0 (2) current address (channel is free if high byte = # 00)
; +2 (2) effect sounding time
; ...

afxChDesc	DS 3*4			; will be populated with 0x0000 0xffff (x 3 via B register)

; ------------------------------------------------- -------------;
; Effects player initialization.                                 ;
; Turns off all channels, sets variables.                        ;
; Input: HL = Effects bank address                               ;
; ------------------------------------------------- -------------;

AFXINIT
	inc hl
reloc_11:
	ld (afxBnkAdr+1),hl	        ; save the address of the offset table
reloc_12:
	ld hl,afxChDesc		        ; mark all channels as empty
	ld de,#00ff
	ld bc,#03fd
afxInit0
	ld (hl),d
	inc hl
	ld (hl),d
	inc hl
	ld (hl),e
	inc hl
	ld (hl),e
	inc hl
	djnz afxInit0

	ld hl,#ffbf			; initialise AY
	ld e,#15
afxInit1 ; runs 15 times (from E register)
	dec e
	ld b,h
	out (c),e
	ld b,l
	out (c),d
	jr nz,afxInit1
reloc_13:
	ld (afxNseMix+1),de             ; reset the player variables
	ret



; --------------------------------------------------------------;
; Play the current frame.                                       ;
; Has no parameters.                                            ;
; --------------------------------------------------------------;

AFXFRAME
	ld bc,#03fd
reloc_14:
	ld ix,afxChDesc

afxFrame0
	push bc

	ld a,11
	ld h,(ix+1)			; high byte of address by <11
	cp h
	jr nc,afxFrame7		        ; channel is not playing, skip
	ld l,(ix+0)

	ld e,(hl)			; take the value of the byte
	inc hl

	sub b				; select the volume register:
	ld d,b				; (11-3=8, 11-2=9, 11-1=10)

	ld b,#ff			;load volume value
	out (c),a
	ld b,#bf
	ld a,e
	and #0f
	out (c),a

	bit 5,e				; will ther be a tone change?
	jr z,afxFrame1		        ; tone didn't change

	ld a,3				; select the tone registers:
	sub d				; 3-3=0, 3-2=1, 3-1=2
	add a,a				; 0*2=0, 1*2=2, 2*2=4

	ld b,#ff			; load the tone value
	out (c),a
	ld b,#bf
	ld d,(hl)
	inc hl
	out (c),d
	ld b,#ff
	inc a
	out (c),a
	ld b,#bf
	ld d,(hl)
	inc hl
	out (c),d

afxFrame1
	bit 6,e				; will there be a noise change?
	jr z,afxFrame3		        ; noise didn't change

	ld a,(hl)			; read noise word
	sub #20
	jr c,afxFrame2		        ; less than # 20, play on
	ld h,a				; otherwise end of the effect
	ld b,#ff
	ld b,c				; in BC we enter the longest time
	jr afxFrame6

afxFrame2
	inc hl
reloc_15:
	ld (afxNseMix+1),a	        ; store the noise value

afxFrame3
	pop bc				; restore the loop value to B
	push bc
	inc b				; number of offsets for TN flags

	ld a,%01101111		        ; mask for TN flags
afxFrame4
	rrc e				; move flags and mask
	rrca
	djnz afxFrame4
	ld d,a
reloc_16:
	ld bc,afxNseMix+2	        ; save flag values
	ld a,(bc)
	xor e
	and d
	xor e				;E is masked with D
	ld (bc),a

afxFrame5
	ld c,(ix+2)			; increase the time counter
	ld b,(ix+3)
	inc bc

afxFrame6
	ld (ix+2),c
	ld (ix+3),b

	ld (ix+0),l			; save changed address
	ld (ix+1),h

afxFrame7
	ld bc,4				; go to next channel
	add ix,bc
	pop bc
	djnz afxFrame0

	ld hl,#ffbf			; load noise and mixer values
afxNseMix
	ld de,0				;+1(E)=noise, +2(D)=mixer
	ld a,6
	ld b,h
	out (c),a
	ld b,l
	out (c),e
	inc a
	ld b,h
	out (c),a
	ld b,l
	out (c),d

	ret



; ------------------------------------------------- -------------;
; Triggers the effect on a free channel. Without the most recent ;
; sounding channel is selected.
; Input: A = effect number 0..255;
; ------------------------------------------------- -------------;

AFXPLAY
	ld de,0				; in DE, the longest search time
	ld h,e
	ld l,a
	add hl,hl
afxBnkAdr
	ld bc,0				; this address is set during AFXINIT and points to our sound effects
	add hl,bc
	ld c,(hl)
	inc hl
	ld b,(hl)
	add hl,bc			; effect address is held in HL
	push hl				; save the address of the effect on the stack
reloc_17:
	ld hl,afxChDesc		        ; find empty channel
	ld b,3
afxPlay0
	inc hl
	inc hl
	ld a,(hl)			; compare the channel time with the longest
	inc hl
	cp e
	jr c,afxPlay1
	ld c,a
	ld a,(hl)
	cp d
	jr c,afxPlay1
	ld e,c				; save the longest time
	ld d,a
	push hl				; save the channel address+3 in IX
	pop ix
afxPlay1
	inc hl
	djnz afxPlay0

	pop de				; pop the effect address from the stack
	ld (ix-3),e			; put into the channel descriptor
	ld (ix-2),d
	ld (ix-1),b			; zero out the seconds
	ld (ix-0),b

	ret

	IF $ > 512
		DISPLAY "Driver code exceeds 512 bytes"
		shellexec "exit", "1"	; couldn't work out how to error ¯\_(ツ)_/¯
	ELSE
		defs    512-$
	ENDIF

reloc_start:
        defw    reloc_1+2
        defw    reloc_2+2
        defw    reloc_3+3
        defw    reloc_4+2
        defw    reloc_5+2
        defw    reloc_6+3
        defw    reloc_7+2
        defw    reloc_8+2
        defw    reloc_9+2
        defw    reloc_10+2
        defw    reloc_11+2
        defw    reloc_12+2
        defw    reloc_13+2
        defw    reloc_14+2
        defw    reloc_15+2
        defw    reloc_16+2
        defw    reloc_17+2
reloc_end:
