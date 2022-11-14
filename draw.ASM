drawFreq	=	10
prevTime	dd	?

screenRowCount	dd	defaultCellCount
screenColCount	dd	defaultCellCount
screenRowStart	dd	0
screenColStart	dd	0
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
       ; stdcall DrawCells, [hdcBack]
       ; stdcall  DrawCell, [hdcBack], 8, 15


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

; IN:
;	clientRect - client rectangle
;	cellSize - size of the cell
; OUT:
;	update number of cells in rows and cols
proc ResizeField uses ebx esi edi,\
     clientRect, cellSize

	mov	esi, [cellSize]

	stdcall GetCellCount, [clientRect.bottom], esi
	mov	[screenRowCount], eax
	cmp	[rowPixelShift], esi
	je	@F
	inc	[screenRowCount]
@@:
	stdcall GetCellCount, [clientRect.right], esi
	mov	[screenColCount], eax
	cmp	[colPixelShift], esi
	je	@F
	inc	[screenColCount]
@@:
	ret
endp

; Out: create brushes for drawing
proc CreateBrushes uses ebx esi edi
	invoke	CreateSolidBrush, colorBack
	mov	[hbrBack], eax
	invoke	CreateSolidBrush, colorAlive
	mov	[hbrAlive], eax
	invoke	CreateSolidBrush, colorDead
	mov	[hbrDead], eax
	ret
endp

; Out: delete brushes for drawing
proc DeleteBrushes uses ebx esi edi

	invoke	DeleteObject, [hbrBack]
	invoke	DeleteObject, [hbrAlive]
	invoke	DeleteObject, [hbrDead]
	ret
endp

; In: row - row of the cell in matrix
;     col - col of the cell in matrix
; Out: cellRect - rectangle of the cell in screen coordinates
proc MatrixToScreen uses ebx esi edi,\
     row, col, cellRect

	mov	esi, [cellRect]
	mov	ebx, [cellSize]

	; Shift by X from top-left corner
	mov	ecx, [screenColPixel]

	; Calculate left and right coordinates
	mov	eax, ebx
	mov	edi, [col]
	sub	edi, [screenColStart]
	mul	edi
	add	eax, ecx
	mov	[esi + RECT.right], eax
	mov	[esi + RECT.left], eax
	sub	[esi + RECT.left], ebx

	; Check left border
	cmp	[esi + RECT.left], 0
	jge	@F
	mov	[esi + RECT.left], 0

@@:

	; Check right border
	mov	edi, [clientRect.right]
	cmp	[esi + RECT.right], edi
	jle	@F
	mov	[esi + RECT.right], edi

@@:
	mov	ecx, [screenRowPixel]

	; Calculate top and bottom coordinates
	mov	eax, ebx
	mov	edi, [row]
	sub	edi, [screenRowStart]
	mul	edi
	add	eax, ecx
	mov	[esi + RECT.bottom], eax
	mov	[esi + RECT.top], eax
	sub	[esi + RECT.top], ebx

	; Check top border
	cmp	[esi + RECT.top], 0
	jge	@F
	mov	[esi + RECT.top], 0

@@:

	; Check bottom border
	mov	edi, [clientRect.bottom]
	cmp	[esi + RECT.bottom], edi
	jle	@F
	mov	[esi + RECT.bottom], edi

@@:
	ret
endp

proc DrawCell uses ebx esi edi,\
     hdcBack, row, col

	locals
		cellRect	RECT
	endl

	; Check col
	mov	eax, [screenColStart]
	add	eax, [screenColCount]
	cmp	[col], eax
	jg	.EndProc

	; Check row
	mov	eax, [screenRowStart]
	add	eax, [screenRowCount]
	cmp	[row], eax
	jg	.EndProc

	lea	esi, [cellRect.left]
	stdcall MatrixToScreen, [row], [col], esi
	invoke	FillRect, [hdcBack], esi, [hbrAlive]

.EndProc:
	ret
endp

proc DrawCells uses ebx esi edi,\
     hdcBack


	mov	esi, [screenRowStart]
	add	esi, [screenRowCount]
;	 dec	 esi
.ByRows:
	push	esi
	mov	edi, esi
	mov	esi, [screenColStart]
	add	esi, [screenColCount]
;	 dec	 esi
.ByCols:
	stdcall NormalizeCoords, edi, esi
	stdcall GetCell, edi, esi
	cmp	 eax, 0
	je	@F
	stdcall  DrawCell, [hdcBack], edi, esi

@@:
	dec	esi
	cmp	esi, [screenColStart]
	jge	.ByCols

	pop	esi
	dec	esi
	cmp	esi, [screenRowStart]
	jge	.ByRows

	ret
endp

; Normalize pixel shift
; IN:
;	pixelShift - shift in pixels to normalize
;	cellSize - size of the cell in pixels
; OUT:
;	normalized pixel shift
proc NormalizePixelShift uses ebx esi edi,\
     pixelShift, cellSize

	mov	eax, [pixelShift]
	cmp	eax, 0
	jl	.NegativeShift
	cmp	eax, [cellSize]
	jl	.EndProc

.PositiveShift:
	sub	eax, [cellSize]
	cmp	eax, [cellSize]
	jge	.PositiveShift
	jmp	.EndProc

.NegativeShift:
	add	eax, [cellSize]
	cmp	eax, 0
	jl	.NegativeShift

.EndProc:
	ret

endp


