prevTime	dd	?
prevStep	dd	?

rowScreenBegin	dd	0
colScreenBegin	dd	0

hbrBack 	dd	?
hbrAlive	dd	?
hbrDead 	dd	?
hbrFrame	dd	?

proc Draw uses ebx esi edi,\
     hWnd, hdcBack, clientRect

	locals
		ps     PAINTSTRUCT
	endl

	xor	ebx, ebx

	; Check draw frequency
	invoke GetTickCount
	sub    eax, [prevTime]
	cmp    eax, drawFreq
	jb     .SkipDraw
	add    eax, [prevTime]
	mov    [prevTime], eax

	; Check step frequency
	cmp	[GEN_PAUSE], 1
	je	.SkipGeneration
	invoke	GetTickCount
	sub	eax, [prevStep]
	cmp	eax, [stepFreq]
	jb	.SkipGeneration
	add	eax, [prevStep]
	mov	[prevStep], eax

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

.DrawCells:

	; Draw cell
	stdcall DrawCells, [hdcBack], [hCells]

	; Draw grid
	cmp    [GRID_VISIBLE], 1
	jne    .SkipDraw

.DrawGrid:
	stdcall DrawGrid, [hdcBack], clientRect.left, [cellSize]

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
	xor    edi, edi
.Rows:
	invoke	MoveToEx, [hdcBack], 0, edi, 0
	invoke	LineTo, [hdcBack], [clientRect.right], edi
	add	edi, [cellSize]
	cmp	edi, [clientRect.bottom]
	jl	.Rows

	; Draw grid cols
	xor    edi, edi
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
	invoke	CreateSolidBrush, colorFrame
	mov	[hbrFrame], eax
	ret
endp

; OUT:
;	delete brushes for drawing
proc DeleteBrushes uses ebx esi edi

	invoke	DeleteObject, [hbrBack]
	invoke	DeleteObject, [hbrAlive]
	invoke	DeleteObject, [hbrDead]
	invoke	DeleteObject, [hbrFrame]
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

	; Set initial cell rectangle
	mov	[cellRect.top], 0
	mov	eax, [cellSize]
	mov	[cellRect.bottom], eax

	mov	esi, [rowScreenBegin]
.ByRows:
	mov	edi, [colScreenBegin]

	xor	ebx, ebx
	mov	[cellRect.left], ebx
	mov	eax, [cellSize]
	mov	[cellRect.right], ebx

.ByCols:
	stdcall GetCell, esi, edi, [hCells]
	test	eax, eax
	jz	.DeadCell

	mov	eax, [cellSize]
	add	[cellRect.right], eax
	mov	ebx, 1
	jmp	.EndCols

.DeadCell:
	test	ebx, ebx
	jz	@F
	lea	eax, [cellRect.left]
	invoke	FillRect, [hdcBack], eax, [hbrAlive]
	xor	ebx, ebx
@@:
	mov	eax, [cellRect.right]
	add	eax, [cellSize]
	mov	[cellRect.left], eax
	mov	[cellRect.right], eax

.EndCols:
	inc	edi
	cmp	edi, [wFieldCellCount]
	jl	@F
	mov	edi, 0
@@:
	mov	eax, [clientRect.right]
	cmp	[cellRect.right], eax
	jl	.ByCols

	test	ebx, ebx
	jz	.EndRows
	lea	eax, [cellRect.left]
	invoke	FillRect, [hdcBack], eax, [hbrAlive]
.EndRows:
	mov	eax, [cellRect.bottom]
	mov	[cellRect.top], eax
	add	eax, [cellSize]
	mov	[cellRect.bottom], eax

	inc	esi
	cmp	esi, [hFieldCellCount]
	jl	@F
	mov	esi, 0
@@:

	mov	eax, [clientRect.bottom]
	cmp	[cellRect.bottom], eax
	jle	.ByRows

	ret
endp



