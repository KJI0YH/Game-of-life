oldCursor	dd	?
dragCursor	dd	?

mClickX 	dd	?
mClickY 	dd	?

lClickX 	dd	?
lClickY 	dd	?

; Zoom field with mouse wheel
proc MouseWheel uses ebx esi edi,\
     wParam, lParam

	mov	eax, [wParam]
	test	eax, 80000000h
	jz     .ZoomOut

.ZoomIn:
	cmp	 [cellSize], 1
	jle	 .EndProc

	dec	 [cellSize]

	jmp	.EndProc

.ZoomOut:
	inc	[cellSize]

.EndProc:

	ret
endp

proc MouseMove uses ebx esi edi,\
     wParam, lParam

	locals
		x	dd	?
		y	dd	?
	endl

	 ; X coordinate of the cursor
	stdcall GET_X_LPARAM, [lParam]
	mov	[x], eax

	 ; Y coordinate of the cursor
	stdcall GET_Y_LPARAM, [lParam]
	mov	[y], eax

	mov	eax, [wParam]
	JumpIf	FIELD_DRAG_BUTTON,    .Drag
	JumpIf	FILL,		      .FillClear
	JumpIf	CLEAR,		      .FillClear
	jmp	.EndProc

.Drag:
	; Dragging
	mov	ecx, [cellSize]

.XShift:
	mov	esi, [x]

	; Check X shift
	sub	esi, [mClickX]	      ; esi - mouse x delta

.YShift:
	mov	edi, [y]

	; Check Y shift
	sub	edi, [mClickY]	      ; edi - mouse y delta

	; Normalizing pixel shifts and screen begin cells
	stdcall NormalizeAfterMouse, esi, edi
	jmp	.EndProc

.FillClear:

	stdcall MouseToField, [y], [rowScreenBegin]
	mov	edi, eax
	stdcall MouseToField, [x], [colScreenBegin]

	mov	esi, eax
	stdcall GetCell, edi, esi, [hCells]

	cmp	[wParam], CLEAR
	je	.Clear

.Fill:
	test	eax, eax
	jnz	.EndProc
	jmp	.Set

.Clear:
	test	eax, eax
	jz	.EndProc

.Set:
	stdcall SetCell, edi, esi, [hCells]
.EndProc:
	ret
endp

; Changing the cursor when start dragging
proc MButtonDown uses ebx esi edi,\
     wParam, lParam

	; X coordinate of the click
	stdcall GET_X_LPARAM, [lParam]
	mov	[mClickX], eax

	; Y coordinate of the click
	stdcall GET_Y_LPARAM, [lParam]
	mov	[mClickY], eax

	invoke LoadCursor, 0, IDC_CROSS
	mov    [dragCursor], eax
	invoke SetCursor, eax
	mov    [oldCursor], eax
	mov    [DRAG], 1
	ret

endp

; Changing the cursor back when stop dragging
proc MButtonUp uses ebx esi edi,\
     wParam, lParam

	invoke	SetCursor, [oldCursor]
	mov	[DRAG], 0
	ret
endp

; Changing the cell state
proc LButtonDown uses ebx esi edi,\
     wParam, lParam

	mov	[GEN_PAUSE], 1

	stdcall GET_X_LPARAM, [lParam]
	mov	[lClickX], eax
	stdcall MouseToField, eax, [colScreenBegin]
	mov	esi, eax

	stdcall GET_Y_LPARAM, [lParam]
	mov	[lClickY], eax
	stdcall MouseToField, eax, [rowScreenBegin]
	mov	edi, eax

	stdcall GetCell, edi, esi, [hCells]
	cmp	[wParam], CLEAR
	je	.Clear

.Fill:
	test	eax, eax
	jnz	.EndProc
	jmp	.Set

.Clear:
	test	eax, eax
	jz	.EndProc

.Set:
	stdcall SetCell, edi, esi, [hCells]

.EndProc:
	ret

endp

; Save cursor icon when moving
proc SetCursorMove uses ebx esi edi,\
     wParam, lParam

	test	 [DRAG], 1
	jz	 @F
	invoke	SetCursor, [dragCursor]
	jmp	 .EndProc

@@:
	invoke	LoadCursor, 0, IDC_HAND
	invoke	SetCursor, eax

.EndProc:
	ret
endp

; Get X mouse coordinate from lParam
proc GET_X_LPARAM uses ebx esi edi,\
     lParam

	mov	eax, [lParam]
	and	eax, 0000FFFFh
	ret

endp

; Get Y mouse coordinate from lParam
proc GET_Y_LPARAM uses ebx esi edi,\
     lParam

	mov	eax, [lParam]
	and	eax, 0xFFFF0000
	shr	eax, 16
	ret

endp

; Normalize screen begin cell after mouse manipulations
; IN:
;	xDelta - mouse delta by x axe
;	yDelta - mouse delta by y axe
proc NormalizeAfterMouse uses ebx esi edi,\
     xDelta, yDelta

	; Normalizing col screen begin cell
	mov	      ebx, [xDelta]
	cmp	      ebx, 0
	jg	      .xGreater

.xLess:
	neg	ebx
	cmp	ebx, [cellSize]
	jl	.xNormalize

.xLessLoop:
	sub	ebx, [cellSize]
	inc	[colScreenBegin]
	cmp	ebx, 0
	jg	.xLessLoop
	jmp	.MClickX

.xGreater:
	cmp	ebx, [cellSize]
	jl	.xNormalize

.xGreaterLoop:
	sub	ebx, [cellSize]
	dec	[colScreenBegin]
	cmp	ebx, 0
	jg	.xGreaterLoop

.MClickX:
	mov	ebx, [xDelta]
	add	[mClickX], ebx
	jmp	.xNormalize

.xNormalize:
	lea	esi, [colScreenBegin]
	stdcall NormalizeCoord, esi, [wFieldCellCount]

	; Normalizing row screen begin cell
	mov	      ebx, [yDelta]
	cmp	      ebx, 0
	jg	      .yGreater

.yLess:
	neg	ebx
	cmp	ebx, [cellSize]
	jl	.yNormalize

.yLessLoop:
	sub	ebx, [cellSize]
	inc	[rowScreenBegin]
	cmp	ebx, 0
	jg	.yLessLoop
	jmp	.MClickY

.yGreater:
	cmp	ebx, [cellSize]
	jl	.yNormalize

.yGreaterLoop:
	sub	ebx, [cellSize]
	dec	[rowScreenBegin]
	cmp	ebx, 0
	jg	.yGreaterLoop

.MClickY:
	mov	ebx, [yDelta]
	add	[mClickY], ebx

.yNormalize:
	lea	esi, [rowScreenBegin]
	stdcall NormalizeCoord, esi, [hFieldCellCount]

	ret

endp

; Convert mouse position (x or y) to field position
; IN:
;	mousePos - mouse coordinate to convert
;	screenBegin - row or col that the screen begin with
;	pixelShift - shift in pixel from top left corner
; OUT:
;	not normalized field coordinate
proc MouseToField uses ebx esi edi,\
     mousePos, screenBegin

	mov	eax, [screenBegin]
	mov	esi, [mousePos]
	cmp	esi, [cellSize]
	jle	.EndProc

.loop:
	sub	esi, [cellSize]
	inc	eax
	cmp	esi, [cellSize]
	jg	.loop
.EndProc:
	ret

endp













