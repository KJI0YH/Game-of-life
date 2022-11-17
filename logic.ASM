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
	mov	ebx, 8		; one cell = one bit
	xor	edx, edx
	div	ebx
	cmp	edx, 0
	je     @F
	inc	eax
@@:
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
;	hCells - handle to cells memory
; OUT:
;	return zero if cell is 0
;	return not zero if cell is 1
proc GetCell uses ebx esi edi ecx edx,\
     row, col, hCells

	lea	esi, [row]
	stdcall NormalizeCoord, esi, [hFieldCellCount]
	lea	esi, [col]
	stdcall NormalizeCoord, esi, [wFieldCellCount]

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
; OUT:
;	hCells - handle to memory with new generation
proc NextGeneration uses ebx esi edi,\
    hCells, hBackCells

	; Set back memory to zero
	mov	ecx, [cellsBufferSize]
	xor	eax, eax
	cld
	mov	edi, [hBackCells]
	repnz stosb

	xor	esi, esi

.ByRows:

	xor	edi, edi

.ByCols:

	stdcall  IsAlive, esi, edi, [hCells]
	test	 eax, eax
	jz	 @F
	stdcall SetCell, esi, edi, [hBackCells]
@@:
	inc	edi
	cmp	edi, [wFieldCellCount]
	jl	.ByCols

	inc	esi
	cmp	esi, [hFieldCellCount]
	jl	.ByRows

	ret

endp

; Check game rules and determine cell state
; IN:
;	row - row of the cell
;	col - col of the cell
;	hCell - handle to memory with cells
; OUT:
;	return not zero if cell is alive, else return 0
proc IsAlive uses ebx esi edi ecx edx,\
     row, col, hCells

	mov	esi, [row]
	mov	edi, [col]
	dec	esi
	dec	edi
	mov	ebx, [col]
	inc	ebx

	xor	edx, edx
	mov	ecx, 3

.loop:
	stdcall GetCell, esi, edi, [hCells]
	test	eax, eax
	jz	@F
	inc	edx
@@:
	stdcall GetCell, esi, [col], [hCells]
	test	eax, eax
	jz	@F
	inc	edx
@@:
	stdcall GetCell, esi, ebx, [hCells]
	test	eax, eax
	jz	@F
	inc	edx
@@:
	inc	esi
	loop	.loop

	stdcall GetCell, [row], [col], [hCells]
	test	eax, eax
	jz	.IsDead

.IsAlive:
	cmp	edx, 4
	jg	.Zero
	cmp	edx, 3
	jl	.Zero
	jmp	.EndProc
.IsDead:
	cmp	edx, 3
	jne	.EndProc
	mov	eax, edx
	jmp	.EndProc
.Zero:
	xor	eax, eax
.EndProc:
	ret

endp




























