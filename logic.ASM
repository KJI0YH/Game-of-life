hHeap		     dd      ?
hCells		     dd      ?
hFieldCellCount      dd      ?
wFieldCellCount      dd      ?

; Allocate memory for game field
; In:
;	hCellCount - number of cells in height
;	wCellCount - number of cells in wigth
proc CreateField uses ebx esi edi,\
     hCellCount, wCellCount

	invoke	GetProcessHeap
	mov	[hHeap], eax

	mov	eax, [hCellCount]
	mov	[hFieldCellCount], eax
	mov	ebx, [wCellCount]
	mov	[wFieldCellCount], ebx

	; Calculate amount of memory that we need
	mul	ebx
	mov	ebx, 8		; one cell = one bit
	xor	edx, edx
	div	ebx
	cmp	edx, 0
	je     @F
	inc	eax
@@:
	invoke HeapAlloc, [hHeap], HEAP_ZERO_MEMORY, eax
	mov    [hCells], eax
	ret
endp

; Change cell on the field
; IN:
;	row - cell row in field
;	col - cell col in field
proc SetCell uses ebx esi edi,\
     row, col

	mov	eax, [row]
	mul	[wFieldCellCount]
	add	eax, [col]
	mov	ebx, 8
	xor	edx, edx
	div	ebx		; now eax - number of full bytes
				;     edx - number of bit in byte
	mov	cl, dl
	mov	bl, 1000_0000b
	shr	bl, cl
	mov	esi, [hCells]
	add	esi, eax
	xor	byte [esi], bl
	ret
endp

; Get cell state (0 or 1)
; IN:
;	row - cell row in field
;	col - cell col in field
; OUT:
;	return zero if cell is 0
;	return not zero if cell is 1
proc GetCell uses ebx esi edi,\
     row, col

	mov	eax, [row]
	mul	[wFieldCellCount]
	add	eax, [col]
	mov	ebx, 8
	xor	edx, edx
	div	ebx
	mov	cl, dl
	mov	bl, 1000_0000b
	shr	bl, cl
	mov	esi, [hCells]
	add	esi, eax
	xor	eax, eax
	mov	al, byte [esi]
	and	al, bl

	ret
endp

; Normalize pixel shift
; IN:
;	pixelShift - shift in pixels to normalize
;	cellSize - size of the cell in pixels
; OUT:
;	normalized pixel shift
;	return shift by rows or cols
proc NormalizePixelShift uses ebx esi edi,\
     pixelShift, cellSize

	xor	eax, eax
	mov	esi, [pixelShift]

	mov	ebx, [esi]
	cmp	ebx, 0
	jle	.NegativeShift
	cmp	ebx, [cellSize]
	jle	.EndProc

.PositiveShift:
	dec	eax
	sub	ebx, [cellSize]
	cmp	ebx, [cellSize]
	jge	.PositiveShift
	jmp	.EndProc

.NegativeShift:
	inc	eax
	add	ebx, [cellSize]
	cmp	ebx, 0
	jl	.NegativeShift

.EndProc:
	mov	[esi], ebx
	ret

endp

; Normalize screen begin cell
; IN:
;	screenBegin - begin screen cell to normalize
;	fieldCellCount - max cell count
; OUT:
;	normalized screen begin cell
proc NormalizeScreenBegin uses ebx esi edi,\
     screenBegin, fieldCellCount

	mov	esi, [screenBegin]

	mov	edi, [esi]
	cmp	edi, 0
	jl	.Negative
	cmp	edi, [fieldCellCount]
	jl	.EndProc

.Positive:
	sub	edi, [fieldCellCount]
	cmp	edi, [fieldCellCount]
	jge	.Positive
	jmp	.EndProc

.Negative:
	add	edi, [fieldCellCount]
	cmp	edi, 0
	jl	.Negative

.EndProc:
	mov	[esi], edi
	ret

endp