drawFreq	=	10
prevTime	dd	?

cellSize	dd	?
cellRect	RECT

screenRowCount	dd	defCellCount
screenColCount	dd	defCellCount
screenRowStart	dd	0
screenColStart	dd	0
screenRowPixel	dd	0
screenColPixel	dd	0

defCellCount	=	9

colorBack	=	00_FF_FF_FFh
colorAlive	=	00_00_00_00h
colorDead	=	00_FF_FF_FFh

hbrBack 	dd	?
hbrAlive	dd	?
hbrDead 	dd	?

GRID_VISIBLE	dd	1

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
	jne	@F
	stdcall DrawGrid, [hdcBack], clientRect.left, [cellSize]
@@:

	; Draw cell
	stdcall DrawCell, [hdcBack], 0, 0
	stdcall DrawCell, [hdcBack], 5, 5
	stdcall DrawCell, [hdcBack], 5, 16
	stdcall DrawCell, [hdcBack], 3, 0
	stdcall DrawCell, [hdcBack], 0, 3


.SkipDraw:
	lea	esi, [ps]
	invoke	BeginPaint, [hWnd], esi
	invoke	BitBlt, eax, 0, 0, [clientRect.right], [clientRect.bottom], [hdcBack], 0, 0, SRCCOPY
	invoke	EndPaint, [hWnd], esi

	invoke	InvalidateRect, [hWnd], 0, 0

.EndProc:
	ret

endp

; In: hdcBack - buffer for drawing
;     clientRect - client rectangle
;     cellSize - size of the cell
; Out: drawing a grid
proc DrawGrid uses ebx esi edi,\
     hdcBack, clientRect, cellSize

	; Draw grid rows
	mov	edi, [screenRowPixel]
.Rows:
	invoke	MoveToEx, [hdcBack], 0, edi, 0
	invoke	LineTo, [hdcBack], [clientRect.right], edi
	add	edi, [cellSize]
	cmp	edi, [clientRect.bottom]
	jl	.Rows

	; Draw grid cols
	mov    edi, [screenColPixel]
.Cols:
	invoke	MoveToEx, [hdcBack], edi, 0, 0
	invoke	LineTo, [hdcBack], edi, [clientRect.bottom]
	add	edi, [cellSize]
	cmp	edi, [clientRect.right]
	jl	.Cols

	ret
endp

; In: clientRect - client rectangle
;     cellCount - the number of cell in one row or col
; Out: size of the sell in pixels
proc SetCellSize uses ebx esi edi,\
     clientRect, cellCount

	; Compare height and width to determite smallest
	Min	clientRect.bottom, clientRect.right
	xor	edx, edx
	div	[cellCount]
	mov	[cellSize], eax
	ret
endp

; In:	cellSize - size of the cell in pixels
;	screenLen - screen height or width in pixels
; Out:	number of cell in one row or col
proc GetCellCount uses ebx esi edi,\
     screenLen, cellSize

	mov	eax, [screenLen]
	xor	edx, edx
	div	[cellSize]

@@:
	ret
endp

; In: clientRect - client rectangle
;     cellSize - size of the cell
; Out: update number of cells in rows and cols
proc ResizeField uses ebx esi edi,\
     clientRect, cellSize

	mov	esi, [cellSize]

	stdcall GetCellCount, [clientRect.bottom], esi
	mov	[screenRowCount], eax
	cmp	[screenRowPixel], esi
	je	@F
	inc	[screenRowCount]
@@:
	stdcall GetCellCount, [clientRect.right], esi
	mov	[screenColCount], eax
	cmp	[screenColPixel], esi
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


