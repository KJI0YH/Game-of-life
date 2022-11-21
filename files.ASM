filter		db		 "Game of life files (*.gol)", 0,"*.gol", 0, 0
FLAGS		=		 OFN_EXPLORER + OFN_FILEMUSTEXIST + OFN_HIDEREADONLY
defExt		db		 "gol", 0
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

	stdcall ReadField, [hFile]

	invoke	CloseHandle, [hFile]
	mov	[bSuccess], 1

.EndProc:
	mov	eax, [bSuccess]
	ret

endp

; Read game field from the file
; IN:
;	hFile - handle to the file to read
proc ReadField uses ebx esi edi,\
     hFile

	locals
		row		dw	?
		col		dw	?
		bytesRead	dd	?
	endl

	; Destroy old field
	stdcall DestroyField

	; Read field size
	lea	esi, [hFieldCellCount]
	invoke	ReadFile, [hFile], esi, 2, 0, 0
	lea	esi, [wFieldCellCount]
	invoke	ReadFile, [hFile], esi, 2, 0, 0

	; Create new field
	stdcall CreateField, [hFieldCellCount], [wFieldCellCount]
	lea	edi, [bytesRead]

.Read:
	lea	esi, [row]
	invoke	ReadFile, [hFile], esi, 2, edi, 0
	cmp	[bytesRead], 0
	je	.EndProc
	lea	esi, [col]
	invoke	ReadFile, [hFile], esi, 2, edi, 0
	cmp	[bytesRead], 0
	je	.EndProc
	xor	eax, eax
	mov	ax, [row]
	xor	ebx, ebx
	mov	bx, [col]
	stdcall SetCell, eax, ebx, [hCells]
	jmp	.Read

.EndProc:
	ret

endp












