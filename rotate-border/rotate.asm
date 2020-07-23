	device ZXSPECTRUMNEXT
	CSPECTMAP "rotate.map"

	ORG $8000
start:
	ei
rotate:
	inc     a
	and     $07
	out     (254),a
	;halt
	ld 	b, $ff		; adjust this value to change the speed
loop:
	djnz 	loop

	jr      rotate

	SAVENEX OPEN "rotate.nex", start, $ff40
	SAVENEX CORE 3, 0, 0
	SAVENEX AUTO