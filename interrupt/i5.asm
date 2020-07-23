
                DEVICE          ZXSPECTRUMNEXT
                CSPECTMAP       "i5.map"

                org     $8000

Start:
                ;break
                jr      Attach

wBorder         db      0

Update:
                ld      a,(wBorder)
                inc     a
                and     7
                out     (254),a
                ld      (wBorder),a
                ret

Attach:
                ; Setup the 128 entry vector table
                di

                ; Setup the I register (the high byte of the table)
                ld      a,high IM2Table
                ld      i,a
                im      2
                ei

                ;jr      $
		ret

                ORG     $FCFC

; ISR (Interrupt Service Routine)
IM2Routine:
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
                rst	$38

        ; Make sure this is on a 256 byte boundary
                ORG     $FE00

IM2Table:
                ds      257,high IM2Routine

                SAVENEX OPEN "i5.nex", Start, $ff40
                SAVENEX CORE 3, 0, 0        ; core 3.0.0 required
                SAVENEX CFG 1               ; blue border (as debug)
                SAVENEX AUTO                ; dump all modified banks into NEX file