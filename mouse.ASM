oldCursor	dd	?
dragCursor	dd	?

cClick		dd	?
rClick		dd	?

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

; Processing mouse move
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
	JumpIf	TOUCH_DRAG,	      .Drag
	JumpIf	MOUSE_DRAG,	      .Drag
	JumpIf	FILL,		      .FillClear
	JumpIf	CLEAR,		      .FillClear
	jmp	.EndProc

.Drag:
.XShift:
	stdcall MouseToField, [x], [colScreenBegin]
	mov	esi, eax

.YShift:
	stdcall MouseToField, [y], [rowScreenBegin]
	mov	edi, eax

	; Normalizing screen begin cells
	stdcall MouseDragMove, esi, edi
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
proc DragStart uses ebx esi edi,\
     wParam, lParam

	; X coordinate of the click
	stdcall GET_X_LPARAM, [lParam]
	stdcall MouseToField, eax, [colScreenBegin]
	mov	[cClick], eax

	; Y coordinate of the click
	stdcall GET_Y_LPARAM, [lParam]
	stdcall MouseToField, eax, [rowScreenBegin]
	mov	[rClick], eax

	invoke LoadCursor, 0, IDC_CROSS
	mov    [dragCursor], eax
	invoke SetCursor, eax
	mov    [oldCursor], eax
	mov    [DRAG], 1
	ret

endp

; Changing the cursor back when stop dragging
proc DragStop uses ebx esi edi,\
     wParam, lParam

	invoke	SetCursor, [oldCursor]
	mov	[DRAG], 0
	ret
endp

; Changing the cell state
proc LButtonDown uses ebx esi edi,\
     wParam, lParam

	cmp	[wParam], TOUCH_DRAG
	jne	@F
	stdcall DragStart, [wParam], [lParam]
	jmp	.EndProc

@@:
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

proc LButtonUp uses ebx esi edi,\
     wParam, lParam
	cmp	[DRAG], 1
	jne	.EndProc
	stdcall DragStop, [wParam], [lParam]
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

; Normalize screen begin cell after mouse drag
; IN:
;	col - mouse col
;	row - mouse row
proc MouseDragMove uses ebx esi edi,\
     col, row

.Cols:
	mov	esi, [col]
	sub	esi, [cClick]
	test	esi, esi
	jz	.Rows
	sub	[colScreenBegin], esi
	lea	eax, [colScreenBegin]
	stdcall NormalizeCoord, eax, [wFieldCellCount]

.Rows:
	mov	esi, [row]
	sub	esi, [rClick]
	test	esi, esi
	jz	.EndProc
	sub	[rowScreenBegin], esi
	lea	eax, [rowScreenBegin]
	stdcall NormalizeCoord, eax, [hFieldCellCount]

.EndProc:
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
