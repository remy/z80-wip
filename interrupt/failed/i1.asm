Stack_Top:      equ 0x0000              ; Stack at top of RAM
IM2_Table:      equ 0xFE00              ; 256 byte page (+ 1 byte) for IM2
IM2_JP:         equ 0xFDFD              ; 3 bytes for JP routine under IM2 table
Interrupt:      equ 0xFD00

Initialise_Interrupt:
        di
        ld de, IM2_Table                ; The IM2 vector table (on page boundary)
        ld hl, IM2_JP                   ; Pointer for 3-byte interrupt handler
        ld a, d                         ; Interrupt table page high address
        ld i, a                         ; Set the interrupt register to that page
        ld a, l                         ; Fill page with values
.loop:
        ld (de), a
        inc e
        jr nz, .loop
        inc d                           ; In case data bus bit 0 is not 0, we
        ld (de), a                      ; put an extra byte in here
        ld (hl), 0xC3                   ; Write out the interrupt handler, a JP instruction
        inc l
        ld (hl), low Interrupt          ; Store the address of the interrupt routine in
        inc l
        ld (hl), high Interrupt
        im 2                            ; Set the interrupt mode
        ei                              ; Enable interrupts
        ret
