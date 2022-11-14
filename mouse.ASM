oldCursor	dd	?
dragCursor	dd	?

clickPosX	dd	?
clickPosY	dd	?

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
	dec	 [rowPixelShift]
	dec	 [colPixelShift]

	jmp	.EndProc

.ZoomOut:
	inc	[cellSize]
	inc	[rowPixelShift]
	inc	[colPixelShift]

.EndProc:

	stdcall NormalizePixelShift, [rowPixelShift], [cellSize]
	mov	[rowPixelShift], eax
	stdcall NormalizePixelShift, [colPixelShift], [cellSize]
	mov	[colPixelShift], eax

	stdcall ResizeField, clientRect.left, [cellSize]
	ret
endp

proc MouseMove uses ebx esi edi,\
     wParam, lParam

	cmp    [wParam], DRAG_BUTTON
	jne	.EndProc

	; Dragging
	mov	ecx, [cellSize]

.XShift:

	 ; X coordinate of the cursor
	stdcall GET_X_LPARAM, [lParam]
	mov	esi, eax

	; Check X shift
	sub	esi, [clickPosX]
	add	[clickPosX], esi
	cmp	esi, 0
	jl	.RightShift

.LeftShift:

	; Left shift
	add	[colPixelShift], esi
	jmp	.YShift

	; Right shift
.RightShift:
	add	[colPixelShift], esi

.YShift:

	 ; Y coordinate of the cursor
	stdcall GET_Y_LPARAM, [lParam]
	mov	edi, eax

	; Check Y shift
	mov	eax, [hFieldCellCount]
	sub	edi, [clickPosY]
	add	[clickPosY], edi
	cmp	edi, 0
	jl	.BottomShift

.TopShift:

	; Top shift
	add	[rowPixelShift], edi
	jmp	.EndProc

.BottomShift:

	; Bottom shift
	add	[rowPixelShift], edi

.EndProc:

	; Normalizing pixel shifts
	stdcall NormalizePixelShift, [colPixelShift], ecx
	mov	[colPixelShift], eax
	stdcall NormalizePixelShift, [rowPixelShift], ecx
	mov	[rowPixelShift], eax

	lea	esi, [screenRowStart]
	lea	edi, [screenColStart]
	stdcall NormalizeCoords, esi, edi

	ret
endp

; Changing the cursor when start dragging
proc MButtonDown uses ebx esi edi,\
     wParam, lParam

	; X coordinate of the click
	stdcall GET_X_LPARAM, [lParam]
	mov	[clickPosX], eax

	; Y coordinate of the click
	stdcall GET_Y_LPARAM, [lParam]
	mov	[clickPosY], eax

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













