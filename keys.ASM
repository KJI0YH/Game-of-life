
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

; Change frame visibility
proc FrameVisible uses ebx esi edi

	xor	[FRAME_VISIBLE], 1
	ret
endp

; Increase speed generation
proc IncSpeed uses ebx esi edi

	sub	[stepFreq], speedStep
	cmp	[stepFreq], drawFreq
	jge	.EndProc
	mov	[stepFreq], drawFreq
.EndProc:
	ret

endp

; Decrease speed generation
proc DecSpeed uses ebx esi edi

	add	[stepFreq], speedStep
	ret

endp