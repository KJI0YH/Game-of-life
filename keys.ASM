CURSOR_VISIBLE	dd	0

proc CursorVisible uses ebx esi edi

	xor	[CURSOR_VISIBLE], 1
	invoke	ShowCursor, [CURSOR_VISIBLE]

	ret
endp

proc GridVisible

	xor	[GRID_VISIBLE], 1
	ret
endp