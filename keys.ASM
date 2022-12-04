
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

; Clear game field
proc ClearField uses ebx esi edi

	mov	[GEN_PAUSE], 1
	mov	ecx, [cellsBufferSize]
	mov	edi, [hCells]
	cld
	xor	eax, eax
	repnz	stosb
	ret

endp

; Move field by arrows
; IN:
;	vKey - pressed virtual key
proc ArrowMove uses ebx esi edi,\
     vKey

	mov	ebx, 1
	cmp	[cellSize], 30
	jg	.Start
	mov	ebx, 4
	cmp	[cellSize], 10
	jg	.Start
	mov	ebx, 8
	cmp	[cellSize], 1
	jg	.Start
	mov	ebx, 16



.Start:
	mov	eax, [vKey]
	JumpIf	VK_UP,		.Up
	JumpIf	VK_RIGHT,	.Right
	JumpIf	VK_DOWN,	.Down
	JumpIf	VK_LEFT,	.Left

.Up:
	sub	[rowScreenBegin], ebx
	jmp	.EndProc

.Right:
	add	[colScreenBegin], ebx
	jmp	.EndProc

.Down:
	add	[rowScreenBegin], ebx
	jmp	.EndProc

.Left:
	sub	[colScreenBegin], ebx
	jmp	.EndProc

.EndProc:
	lea	eax, [rowScreenBegin]
	stdcall NormalizeCoord, eax, [hFieldCellCount]
	lea	eax, [colScreenBegin]
	stdcall NormalizeCoord, eax, [wFieldCellCount]
	ret
endp

; Invert drawing colors
proc InvertColors uses ebx esi edi

	mov	eax, [hbrDead]
	xchg	eax, [hbrAlive]
	xchg	eax, [hbrDead]

	mov	eax, [hpnGridAlive]
	xchg	eax, [hpnGridDead]
	xchg	eax, [hpnGridAlive]
	ret

endp















