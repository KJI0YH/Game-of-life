
; Change cursor visibility
proc CursorVisible uses ebx esi edi

	xor	[CURSOR_VISIBLE], 1
	invoke	ShowCursor, [CURSOR_VISIBLE]
	ret
endp

; Change grid visibility
proc GridVisible

	xor	[GRID_VISIBLE], 1
	ret
endp

; Set / unset generation pause
proc GenerationPause uses ebx esi edi

	xor	[GEN_PAUSE], 1
	ret
endp