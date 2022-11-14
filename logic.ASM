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

proc NormalizeCoords uses ebx esi edi,\
     row, col

	mov	esi, [hFieldCellCount]
	mov	edi, [wFieldCellCount]

	; Normalize row
	cmp	[row], esi
	jle	@F
	sub	[row], esi
@@:
	cmp	[row], 0
	jge	@F
	add	[row], esi
@@:

	; Normalize col
	cmp    [col], edi
	jle    @F
	sub    [row], edi
@@:
	cmp	[col], 0
	jge	@F
	add	[col], edi
@@:
	ret
endp