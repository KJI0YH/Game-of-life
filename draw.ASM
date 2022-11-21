drawFreq	=	10
prevTime	dd	?

stepFreq	=	50
prevStep	dd	?


rowScreenBegin	dd	0
colScreenBegin	dd	0
rowPixelShift	dd	0
colPixelShift	dd	0

hbrBack 	dd	?
hbrAlive	dd	?
hbrDead 	dd	?

proc Draw uses ebx esi edi,\
     hWnd, hdcBack, clientRect

	locals
		ps     PAINTSTRUCT
	endl

	xor	ebx, ebx

	invoke GetTickCount
	sub    eax, [prevTime]
	cmp    eax, drawFreq
	jb     .SkipDraw
	add    eax, [prevTime]
	mov    [prevTime], eax

	cmp	[GEN_PAUSE], 1
	je     .SkipGeneration
	stdcall NextGeneration, [hCells], [hBackCells]
	mov	esi, [hCells]
	xchg	esi, [hBackCells]
	xchg	esi, [hCells]

.SkipGeneration:
	invoke	GetUpdateRect, [hWnd], 0, 0
	test	eax, eax
	jz	.EndProc

	; Clear client rectangle
	invoke	FillRect, [hdcBack], clientRect.left, [hbrBack]

	; Draw grid
	cmp    [GRID_VISIBLE], 1
	jne    .DrawCells

.DrawGrid:
	stdcall DrawGrid, [hdcBack], clientRect.left, [cellSize]

.DrawCells:

	; Draw cell
	stdcall DrawCells, [hdcBack], [hCells]

.SkipDraw:
	lea	esi, [ps]
	invoke	BeginPaint, [hWnd], esi
	invoke	BitBlt, eax, 0, 0, [clientRect.right], [clientRect.bottom], [hdcBack], 0, 0, SRCCOPY
	invoke	EndPaint, [hWnd], esi

	invoke	InvalidateRect, [hWnd], 0, 0

.EndProc:
	ret

endp

; Draw field grid
; IN:
;	hdcBack - back buffer for drawing
proc DrawGrid uses ebx esi edi,\
     hdcBack

	; Draw grid rows
	mov	edi, [rowPixelShift]
.Rows:
	invoke	MoveToEx, [hdcBack], 0, edi, 0
	invoke	LineTo, [hdcBack], [clientRect.right], edi
	add	edi, [cellSize]
	cmp	edi, [clientRect.bottom]
	jl	.Rows

	; Draw grid cols
	mov    edi, [colPixelShift]
.Cols:
	invoke	MoveToEx, [hdcBack], edi, 0, 0
	invoke	LineTo, [hdcBack], edi, [clientRect.bottom]
	add	edi, [cellSize]
	cmp	edi, [clientRect.right]
	jl	.Cols

	ret
endp

; Sets the size of the cell so that the number of cells fits into the screen
; IN:
;	clientRect - client rectangle
;	cellCount - the number of cell in one row or col
; OUT:
;	size of the sell in pixels
proc SetCellSize uses ebx esi edi,\
     clientRect, cellCount

	; Compare height and width to determite smallest
	Min	clientRect.bottom, clientRect.right
	xor	edx, edx
	div	[cellCount]
	mov	[cellSize], eax
	ret
endp

; Gets the number of cells that will fit in this screen length
; IN:
;	screenLen - screen height or width in pixels
;	cellSize - size of the cell in pixels
; OUT:
;	number of cell in one row or col
proc GetCellCount uses ebx esi edi,\
     screenLen, cellSize

	mov	eax, [screenLen]
	xor	edx, edx
	div	[cellSize]
	ret
endp

; OUT:
;	create brushes for drawing
proc CreateBrushes uses ebx esi edi
	invoke	CreateSolidBrush, colorBack
	mov	[hbrBack], eax
	invoke	CreateSolidBrush, colorAlive
	mov	[hbrAlive], eax
	invoke	CreateSolidBrush, colorDead
	mov	[hbrDead], eax
	ret
endp

; OUT:
;	delete brushes for drawing
proc DeleteBrushes uses ebx esi edi

	invoke	DeleteObject, [hbrBack]
	invoke	DeleteObject, [hbrAlive]
	invoke	DeleteObject, [hbrDead]
	ret
endp

; Draw all cells on screen
; IN:
;	hdcBack - back buffer for drawing
;	hCells - handle to cells memory
proc DrawCells uses ebx esi edi,\
     hdcBack, hCells

	locals
		cellRect	RECT
	endl

	mov	[cellRect.top], 0
	mov	ebx, [rowPixelShift]
	cmp	ebx, 0
	jne	@F
	mov	ebx, [cellSize]

@@:
	mov	[cellRect.bottom], ebx
	mov	edi, [rowScreenBegin]

.ByRows:
	mov	esi, [colScreenBegin]

	; Set initial left and right cell rectangle
	mov	[cellRect.left], 0
	mov	ebx, [colPixelShift]
	cmp	ebx, 0
	jne	@F
	mov	ebx, [cellSize]
@@:
	mov	[cellRect.right], ebx

.ByCols:

	stdcall GetCell, edi, esi, [hCells]
	cmp	eax, 0
	je	.SkipDraw

	; Draw cell if is alive
	lea	ebx, [cellRect.left]
	invoke	FillRect, [hdcBack], ebx, [hbrAlive]

.SkipDraw:

	; Modify left and right cell borders
	mov	ebx, [cellRect.right]
	mov	[cellRect.left], ebx
	add	ebx, [cellSize]
	cmp	ebx, [clientRect.right]
	jle	@F
	mov	ebx, [clientRect.right]

@@:
	mov	[cellRect.right], ebx

	; Modify col count
	inc	esi
	cmp	esi, [wFieldCellCount]
	jl	@F
	mov	esi, 0
@@:
	; Check cols condition
	cmp	[cellRect.left], ebx
	jl	.ByCols

	; Modify top and bottom cell borders
	mov	ebx, [cellRect.bottom]
	mov	[cellRect.top], ebx
	add	ebx, [cellSize]
	cmp	ebx, [clientRect.bottom]
	jle	@F
	mov	ebx, [clientRect.bottom]
@@:
	mov	[cellRect.bottom], ebx

	inc	edi
	cmp	edi, [hFieldCellCount]
	jl	@F
	mov	edi, 0
@@:
	; Check rows condition
	cmp	[cellRect.top], ebx
	jl	.ByRows

	ret
endp



