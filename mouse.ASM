oldCursor	dd	?
dragCursor	dd	?

clickPosX	dd	?
clickPosY	dd	?

MBUTTON 	dd	0

; Scroll field with mouse wheel
proc MouseWheel uses ebx esi edi,\
     wParam, lParam

	mov	eax, [wParam]
	test	eax, 80000000h
	jz     .ScrollBack

	; Scroll forward
	cmp	 [cellSize], 1
	jle	 .EndProc
	dec	 [cellSize]
	dec	 [screenRowPixel]
	dec	 [screenColPixel]
	jmp    .EndProc

.ScrollBack:
	inc	[cellSize]
	inc	[screenRowPixel]
	inc	[screenColPixel]

.EndProc:
	stdcall ResizeField, clientRect.left, [cellSize]
	ret
endp

proc MouseMove uses ebx esi edi,\
     wParam, lParam

	cmp    [wParam], MK_MBUTTON
	jne	.EndProc

	; Dragging
	mov	ecx, [cellSize]

	; X coordinate of the cursor
	mov	ebx, [lParam]
	and	ebx, 0000FFFFh
	mov	esi, ebx

	; Y coordinate of the cursor
	mov	ebx, [lParam]
	and	ebx, 0xFFFF0000
	shr	ebx, 16
	mov	edi, ebx

	; Check X shift
	sub	esi, [clickPosX]
	add	[clickPosX], esi
	cmp	esi, 0
	jl	.RightShift

	; Left shift
	add	[screenColPixel], esi
	cmp	[screenColPixel], ecx
	jle	 @F
	sub	[screenColPixel], ecx
	dec	[screenColStart]
@@:
	jmp	.YShift

	; Right shift
.RightShift:
	add	[screenColPixel], esi
	cmp	[screenColPixel], 0
	jge	@F
	add	[screenColPixel], ecx
	inc	[screenColStart]

.YShift:
	; Check Y shift
	sub	edi, [clickPosY]
	add	[clickPosY], edi
	cmp	edi, 0
	jl	.BottomShift

	; Top shift
	add	[screenRowPixel], edi
	cmp	[screenRowPixel], ecx
	jle	@F
	sub	[screenRowPixel], ecx
	dec	[screenRowStart]

@@:
	jmp	.EndProc

.BottomShift:
	add	[screenRowPixel], edi
	cmp	[screenRowPixel], 0
	jge	@F
	add	[screenRowPixel], ecx
	inc	[screenRowStart]
@@:

.EndProc:
	ret
endp

; Changing the cursor when start dragging
proc MButtonDown uses ebx esi edi,\
     wParam, lParam

	; X coordinate of the click
	mov	ebx, [lParam]
	and	ebx, 0000FFFFh
	mov	[clickPosX], ebx

	; Y coordinate of the click
	mov	ebx, [lParam]
	and	ebx, 0xFFFF0000
	shr	ebx, 16
	mov	[clickPosY], ebx

	invoke LoadCursor, 0, IDC_CROSS
	mov    [dragCursor], eax
	invoke SetCursor, eax
	mov    [oldCursor], eax
	mov    [MBUTTON], 1
	ret

endp

; Changing the cursor back when stop dragging
proc MButtonUp uses ebx esi edi,\
     wParam, lParam

	invoke	SetCursor, [oldCursor]
	mov	[MBUTTON], 0
	ret
endp

; Save cursor icon when moving
proc SetCursorMove uses ebx esi edi,\
     wParam, lParam

	test	 [MBUTTON], 1
	jz	 @F
	invoke	SetCursor, [dragCursor]
	jmp	 .EndProc

@@:
	invoke	LoadCursor, 0, IDC_HAND
	invoke	SetCursor, eax

.EndProc:
	ret
endp













