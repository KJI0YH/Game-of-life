hHeap		     dd      ?
hCells		     dd      ?
hBackCells	     dd      ?
hFieldCellCount      dd      ?
wFieldCellCount      dd      ?
cellsBufferSize      dd      ?

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

	mov	[cellsBufferSize], eax
	invoke HeapAlloc, [hHeap], HEAP_ZERO_MEMORY, eax
	mov    [hCells], eax
	invoke HeapAlloc, [hHeap], HEAP_ZERO_MEMORY, [cellsBufferSize]
	mov    [hBackCells], eax
	ret
endp

; Change cell on the field
; IN:
;	row - cell row in field
;	col - cell col in field
;	hCells - handle to cells memory
proc SetCell uses ebx esi edi ecx ebx,\
     row, col, hCells

	lea	esi, [row]
	stdcall NormalizeCoord, esi, [hFieldCellCount]
	lea	esi, [col]
	stdcall NormalizeCoord, esi, [wFieldCellCount]

	mov	eax, [row]
	mul	[wFieldCellCount]
	add	eax, [col]

	add	eax, [hCells]
	xor	byte [eax], 1

	ret
endp

; Get cell state (0 or 1)
; IN:
;	row - cell row in field
;	col - cell col in field
;	hCells - handle to cells memory
; OUT:
;	return zero if cell is 0
;	return not zero if cell is 1
proc GetCell uses ebx esi edi,\
     row, col, hCells

	lea	esi, [row]
	stdcall NormalizeCoord, esi, [hFieldCellCount]
	lea	esi, [col]
	stdcall NormalizeCoord, esi, [wFieldCellCount]

	mov	eax, [row]
	mul	[wFieldCellCount]
	add	eax, [col]

	add	eax, [hCells]
	mov	ebx, eax
	xor	eax, eax
	mov	al, byte [ebx]

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

; Normalize cell coordinate
; IN:
;	pCoord - pointer to cell coordinate (row or col) to normalize
;	fieldCellCount - max cell count
; OUT:
;	normalized cell coord
;	eax - normalized value
proc NormalizeCoord uses ebx esi edi,\
     pCoord, fieldCellCount

	mov	esi, [pCoord]

	mov	eax, [esi]
	cmp	eax, 0
	jl	.Negative
	cmp	eax, [fieldCellCount]
	jl	.EndProc

.Positive:
	sub	eax, [fieldCellCount]
	cmp	eax, [fieldCellCount]
	jge	.Positive
	jmp	.EndProc

.Negative:
	add	eax, [fieldCellCount]
	cmp	eax, 0
	jl	.Negative

.EndProc:
	mov	[esi], eax
	ret

endp

; Calculate the next generation of the game
; IN:
;	hCells - handle to memory with current generation
;	hBackCells - handle to memory with next generation
proc NextGeneration uses ebx esi edi,\
    hCells, hBackCells

	locals
		row	dd	0
		col	dd	0
		lShift	dd	?
		rShift	dd	?
		tShift	dd	?
		bShift	dd	?
		h	dd	?
		w	dd	?
		pos	dd	?
	endl
	mov	eax, [wFieldCellCount]
	dec	eax
	mov	[w], eax
	mov	eax, [hFieldCellCount]
	dec	eax
	mov	[h], eax

	xor	esi, esi
.ByRows:
	push	esi
	xor	edi, edi
	mov	[col], edi
.ByCols:
	push	edi
	mov	eax, [row]

	mul	[wFieldCellCount]
	add	eax, edi		; eax - normal cell shift

	mov	edi, [hBackCells]
	add	edi, eax		; edi - address of the cell in back buffer cells

	mov	esi, [hCells]
	add	esi, eax		; esi - address of the cell

	; Calculate bottom shift for cell neighbours
	mov	eax, [wFieldCellCount]
	mov	ebx, [h]
	cmp	[row], ebx
	jne	@F
	sub	eax, [cellsBufferSize]
@@:
	mov	[bShift], eax

	; Calculate top shift for cell neighbours
	mov	eax, [wFieldCellCount]
	neg	eax
	cmp	[row], 0
	jne	@F
	add	eax, [cellsBufferSize]
@@:
	mov	[tShift], eax

	; Calculate left shift for cell neighbours
	mov	eax, -1
	cmp	[col], 0
	jne	@F
	add	eax, [wFieldCellCount]
@@:
	mov	[lShift], eax

	; Calculate right shift for cell neighbours
	mov    eax, 1
	mov    ebx, [w]
	cmp    [col], ebx
	jne    @F
	sub    eax, [wFieldCellCount]
@@:
	mov	[rShift], eax

	xor	ebx, ebx

	; Top neighbours
	add	eax, [tShift]
	add	bl, byte [esi + eax]		; top-right
	mov	eax, [tShift]
	add	bl, byte [esi + eax]		; top
	add	eax, [lShift]
	add	bl, byte [esi + eax]		; top-left

	; Middle neighbours
	mov	eax, [lShift]
	add	bl, byte [esi + eax]		; left
	mov	eax, [rShift]
	add	bl, byte [esi + eax]		; right

	; Bottom neighbours
	add	eax, [bShift]			; bottom-right
	add	bl, byte [esi + eax]
	mov	eax, [bShift]
	add	bl, byte [esi + eax]		; bottom
	add	eax, [lShift]
	add	bl, byte [esi + eax]		; bottom-left

	mov	al, byte [esi]
	or	al, bl
	xor	bl, bl
	cmp	al, 3
	jne	.EndCycle
	mov	bl, 1

.EndCycle:
	mov	byte [edi], bl

	pop	edi
	inc	edi
	mov	[col], edi
	cmp	edi, [wFieldCellCount]
	jl	.ByCols

	pop	esi
	inc	esi
	mov	[row], esi
	cmp	esi, [hFieldCellCount]
	jl	.ByRows

	ret

endp




























