        DEVICE ZXSPECTRUM48

        ORG 65023

        push af
        push bc
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
        pop bc
        pop af
        rst 38h
        ei
        ret
