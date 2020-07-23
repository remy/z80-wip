	DEVICE ZXSPECTRUMNEXT
	ORG $0000

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
	ld 	a,(value1)
	add	a,a
	jr	z,skip
reloc_2:
	call rotate
skip:
	ret

ayfx_api:
        djnz    bnot1                   ; On if B<>1

; B=1: set values.

	ld	a, e
reloc_3:
        ld      (value1),a
        and     a                       ; clear carry to indicate success
        ret

bnot1:
api_error:
        xor     a                       ; A=0, unsupported call id
        scf                             ; Fc=1, signals error
        ret

rotate:
reloc_4:
	ld	a, (value1)
	and     $07
	inc     a
reloc_5:
	ld	(value1),a
	out     (254),a
	ret


; **************************************************************
; Backup and restore whatever is in MMU6
;
; uses: a, bc
; **************************************************************
backup_bank:
	ld 	bc,$243b ; select NEXT register
	ld 	a, $56
	out 	(c),a
	inc 	b ; $253b to access (read or write) value
	in 	b,(c)
	push	bc
	ret

restore_bank:
	pop	bc
	ld	a, b
	nextreg $56, a
	ret


; **************************************************************
; * data
; **************************************************************

value1:
	defb	0

	IF $ > 512
		DISPLAY "Driver code exceeds 512 bytes"
		shellexec "exit", "1"	; couldn't work out how to error ¯\_(ツ)_/¯
	ELSE
		defs    512-$
	ENDIF

reloc_start:
        defw    reloc_1+2
        defw    reloc_2+2
        defw    reloc_3+2
        defw    reloc_4+2
        defw    reloc_5+2
reloc_end:
