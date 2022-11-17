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
	dec	[hFieldCellCount]
	mov	ebx, [wCellCount]
	mov	[wFieldCellCount], ebx
	dec	[wFieldCellCount]

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
		vShift	dd	?
		hShift	dd	?
		pos	dd	?
	endl

	mov	esi, 1
.ByRows:
	push	esi
	mov	edi, 1
.ByCols:
	pop	esi
	mov	eax, esi
	push	esi
	push	edi
	mul	[wFieldCellCount]
	add	eax, edi		; eax - normal cell shift
;	 mov	 [pos], eax

	mov	edi, [hBackCells]
	add	edi, eax		; edi - address of the cell

	mov	esi, [hCells]
	add	esi, eax		; esi - address of the cell

	xor	ebx, ebx
	mov	eax, [wFieldCellCount]
	neg	eax

	; cmp if row == 0 then eax += H*W else
	; cmp if row == H then eax -= H*W
	; cmp if col == 0 then eax += W
	; cmp if col == W then eax -= W

.Top:
	; Top neighbours
	add	bl, byte [esi + eax - 1]
	add	bl, byte [esi + eax]
	add	bl, byte [esi + eax + 1]

	; Middle neighbours
	add	bl, byte [esi - 1]
	add	bl, byte [esi + 1]

	; Bottom neighbours
	neg	eax
	add	bl, byte [esi + eax - 1]
	add	bl, byte [esi + eax]
	add	bl, byte [esi + eax + 1]

	mov	al, byte [esi]
	test	al, al
	jz	.Dead

.Alive:
	cmp	ebx, 3
	jg	.Zero
	cmp	ebx, 2
	jl	.Zero
	mov	byte [edi], 1
	jmp	.EndCycle
.Dead:
	cmp	ebx, 3
	jne	 .Zero
	mov	byte [edi], 1
	jmp	.EndCycle
.Zero:
	mov	byte [edi], 0

.EndCycle:
	pop	edi
	inc	edi
	cmp	edi, [wFieldCellCount]
	jl	.ByCols

	pop	esi
	inc	esi
	cmp	esi, [hFieldCellCount]
	jl	.ByRows

	ret

endp




























