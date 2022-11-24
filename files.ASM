filter		db		 "Game of life files (*.rle)", 0,"*.rle", 0, 0
FLAGS		=		 OFN_EXPLORER + OFN_FILEMUSTEXIST + OFN_HIDEREADONLY
defExt		db		 "rle", 0
fileName	db		 MAX_PATH dup 0, 0

; Call Save file dialog and save game field to file
; IN:
;	hWnd - handle to the window that owns the dialog box
proc FileSave uses ebx esi edi,\
     hWnd

	locals
		hFile		dd		 ?
		bSuccess	dd		 0
		ofn		OPENFILENAME	 sizeof.OPENFILENAME, 0, 0, filter, 0, 0, 0, fileName, MAX_PATH, 0, 0, 0, 0, FLAGS, 0, 0, defExt, 0, 0, 0
	endl

	mov	eax, [hWnd]
	mov	[ofn.hwndOwner], eax

	mov	[CURSOR_VISIBLE], 1
	invoke	ShowCursor, [CURSOR_VISIBLE]

	lea	esi, [ofn]
	invoke	GetSaveFileNameA, esi
	cmp	eax, 0
	je	.EndProc

	lea	esi, [fileName]
	invoke	CreateFileA, esi, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	mov	[hFile], eax
	cmp	eax, INVALID_HANDLE_VALUE
	je	.EndProc

	stdcall WriteField, [hFile]

	invoke	CloseHandle, [hFile]
	mov	[bSuccess], 1

.EndProc:
	mov	eax, [bSuccess]
	ret

endp

; Write game field to the file
; IN:
;	hFile - handle to the file to write
proc WriteField uses ebx esi edi,\
     hFile

	locals
		row	dw	?
		col	dw	?
	endl

	; write field size
	lea	esi, [hFieldCellCount]
	invoke	WriteFile, [hFile], esi, 2, 0, 0
	lea	esi, [wFieldCellCount]
	invoke	WriteFile, [hFile], esi, 2, 0, 0
	mov	esi, [hCells]

	mov	ebx, [hFieldCellCount]
	dec	ebx
	mov	[row], bx
	mov	ebx, [wFieldCellCount]
	dec	ebx
	mov	[col], bx
	mov	ecx, [cellsBufferSize]
.StartLoop:
	mov	al, byte [esi + ecx - 1]
	cmp	al, 0
	je	.EndLoop
	lea	edi, [row]
	push	ecx
	invoke	WriteFile, [hFile], edi, 2, 0, 0
	lea	edi, [col]
	invoke	WriteFile, [hFile], edi, 2, 0, 0
	pop	ecx

.EndLoop:
	dec	[col]
	cmp	[col], 0
	jge	@F
	dec	[row]
	mov	[col], bx
@@:
	loop	.StartLoop
	ret

endp

; Call Open file dialog and read game field from the file
; IN:
;	hWnd - handle to the window that owns the dialog box
proc FileOpen uses ebx esi edi,\
     hWnd

	locals
		hFile		dd		 ?
		bSuccess	dd		 0
		ofn		OPENFILENAME	 sizeof.OPENFILENAME, 0, 0, filter, 0, 0, 0, fileName, MAX_PATH, 0, 0, 0, 0, FLAGS, 0, 0, defExt, 0, 0, 0
	endl

	mov	eax, [hWnd]
	mov	[ofn.hwndOwner], eax

	mov	[CURSOR_VISIBLE], 1
	invoke	ShowCursor, [CURSOR_VISIBLE]

	lea	esi, [ofn]
	invoke	GetOpenFileNameA, esi
	cmp	eax, 0
	je	.EndProc

	lea	esi, [fileName]
	invoke	CreateFileA, esi, GENERIC_READ, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0

	mov	[hFile], eax
	cmp	eax, INVALID_HANDLE_VALUE
	je	.EndProc

	 stdcall ReadRLE, [hFile]

	invoke	CloseHandle, [hFile]
	mov	[bSuccess], 1

.EndProc:
	mov	eax, [bSuccess]
	ret

endp

; Read RLE game of life file
; IN:
;	hFile - handle to the file to read
proc ReadRLE uses ebx esi edi,\
     hFile

	locals
		bytesRead	dd	?
		char		db	?
		part		db	?
		row		dd	?
		col		dd	?
		number		dd	?
		e		dd	?
		x		dd	?
		y		dd	?
	endl

	lea	edi, [bytesRead]
	lea	esi, [char]
	xor	ebx, ebx		; ebx stores the number of duplication or 0
	mov	[row], ebx
	mov	[col], ebx
	jmp	.Read

.CreateField:
	mov	edx, [wFieldCellCount]
	cmp	edx, [x]
	jl	@F
	mov	[x], edx
@@:
	mov	edx, [hFieldCellCount]
	cmp	edx, [y]
	jl	@F
	mov	[y], edx
@@:
	stdcall DestroyField
	stdcall CreateField, [y], [x]
	xor	ebx, ebx

.Read:
	invoke	ReadFile, [hFile], esi, 1, edi, 0
	cmp	[bytesRead], 0
	je	.EndProc
	movzx	eax, [char]
.Compare:
	JumpIf	'#',	.Comment
	JumpIf	'x',	.HeaderX
	JumpIf	'y',	.HeaderY
	JumpIf	'o',	.Alive
	JumpIf	'b',	.Dead
	JumpIf	'$',	.LineFeed
	JumpIf	'!',	.EndRead
	cmp	eax, '0'
	jl	.Read
	cmp	eax, '9'
	jg	.Read
	jmp	.Digit

; Skip all comments started with '#'
.Comment:
	invoke	ReadFile, [hFile], esi, 1, edi, 0
	cmp	[bytesRead], 0
	je	.EndProc
	cmp	[char], 0x0A
	jne	.Comment
	xor	ebx, ebx
	jmp	.Read

; Read the header of the file
.HeaderX:
	mov	[part], RLE_HEADER_X
	jmp	..Skip

.HeaderY:
	mov	[part], RLE_HEADER_Y

..Skip:
	invoke	ReadFile, [hFile], esi, 1, edi, 0
	cmp	[bytesRead], 0
	je	.EndProc
	movzx	eax, [char]
	cmp	eax, '0'
	jl	..Skip
	cmp	eax, '9'
	jg	..Skip
	jmp	.Digit

	xor	ebx, ebx
	jmp	.Read

; Calculate readed number
.Digit:
	xor	ebx, ebx
..Push:
	inc	ebx
	sub	eax, '0'
	push	eax
	invoke	ReadFile, [hFile], esi, 1, edi, 0
	cmp	[bytesRead], 0
	je	.EndProc

	movzx	eax, [char]
	cmp	eax, '0'
	jl	..Calc
	cmp	eax, '9'
	jg	..Calc
	jmp	..Push

..Calc:
	mov	ecx, ebx
	xor	eax, eax
	mov	[number], eax
	mov	[e], 1
..Pop:
	mov	eax, [e]
	pop	ebx
	mul	ebx
	add	[number], eax
	mov	eax, [e]
	mov	edx, 10
	mul	edx
	mov	[e], eax
	loop	..Pop

	mov	ebx, [number]
	movzx	eax, [char]
	cmp	[part], RLE_HEADER_X
	jne	@F
	mov	[x], ebx
	inc	[x]
@@:
	cmp	[part], RLE_HEADER_Y
	jne	@F
	mov	[y], ebx
	inc	[y]
	mov	[part], RLE_BODY
	jmp	.CreateField
@@:
	jmp	.Compare

; Alive cell
.Alive:
	stdcall SetCell, [row], [col], [hCells]

	; Calculate next row and col
	inc	[col]
	mov	eax, [wFieldCellCount]
	cmp	[col], eax
	jl	@F
	mov	[col], 0
	inc	[row]
@@:
	dec	ebx
	cmp	ebx, 0
	jg	.Alive

	xor	ebx, ebx
	jmp	.Read

; Dead cell
.Dead:
	cmp	ebx, 0
	jne	@F
	inc	ebx
@@:
	mov	eax, ebx
	mov	ebx, [wFieldCellCount]
	xor	edx, edx
	div	ebx
	add	[row], eax
	add	[col], edx
	cmp	[col], ebx
	jl	@F
	mov	[col], 0
	inc	[row]
@@:
	xor	ebx, ebx
	jmp	.Read

; Feed lines
.LineFeed:
	inc	[row]
	dec	ebx
	cmp	ebx, 0
	jg	.LineFeed

	xor	ebx, ebx
	mov	[col], ebx
	jmp	.Read

; This is the end of the field
.EndRead:

.EndProc:
	ret

endp












