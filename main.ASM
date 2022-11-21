include 	"main.inc"

wndClass	WNDCLASS	0, WindowProc, 0, 0, 0, 0, 0, 0, 0, className
WINDOW_STYLE	=		 WS_VISIBLE + WS_MAXIMIZE + WS_POPUP
className	db		"Game of life", 0
clientRect	RECT
hdcBack 	dd		?
hbmBack 	dd		?

proc WinMain

	locals
		hMainWindow	dd	?
		msg		MSG
	endl

	xor	ebx, ebx

	invoke	GetTickCount
	mov	[prevTime], eax
	mov	[prevStep], eax

	invoke	LoadCursor, 0, IDC_HAND
	mov	[wndClass.hCursor], eax

	; Register window class and create window
	invoke RegisterClass, wndClass
	invoke CreateWindowEx, ebx, className, className, WINDOW_STYLE,\
			       ebx, ebx, ebx, ebx, ebx, ebx, ebx, ebx
	mov	[hMainWindow], eax

	; Hide cursor
	invoke	ShowCursor, [CURSOR_VISIBLE]

	; Get client rectangle and DC
	invoke	GetClientRect, [hMainWindow], clientRect
	invoke	GetDC, [hMainWindow]
	mov	esi, eax

	; Create back buffer with compatible DC
	invoke	 CreateCompatibleDC, esi
	mov	 [hdcBack], eax
	invoke	 CreateCompatibleBitmap, esi, [clientRect.right], [clientRect.bottom]
	mov	 [hbmBack], eax
	invoke	 SelectObject, [hdcBack], eax
	invoke	 ReleaseDC, ebx, esi

	; Init settings
	stdcall SetCellSize, clientRect.left, defaultCellCount
	mov	[rowPixelShift], eax
	mov	[colPixelShift], eax
	stdcall CreateBrushes
	stdcall CreateField, [clientRect.bottom], [clientRect.right]
;	 stdcall CreateField, 9, 16

	stdcall SetCell, 5, 5, [hCells]
	stdcall SetCell, 5, 6, [hCells]
	stdcall SetCell, 5, 7, [hCells]

	; Load effective address for the msg
	lea	esi, [msg]

; Message loop
MSGLoop:
	invoke	GetMessage, esi, ebx, ebx, ebx
	test	eax, eax
	jz	.EndLoop
	invoke	TranslateMessage, esi
	invoke	DispatchMessage, esi
	jmp	MSGLoop

.EndLoop:
	invoke	DeleteDC, [hdcBack]
	invoke	DeleteDC, [hbmBack]
	invoke	ExitProcess, [msg.wParam]

endp

proc WindowProc uses ebx,\
     hWnd, uMsg, wParam, lParam

	xor	ebx, ebx
	mov	eax, [uMsg]

	JumpIf	WM_PAINT,	.Paint
	JumpIf	WM_DESTROY,	.Destroy
	JumpIf	WM_KEYDOWN,	.KeyDown
	JumpIf	WM_MOUSEWHEEL,	.MouseWheel
	JumpIf	WM_MOUSEMOVE,	.MouseMove
	JumpIf	WM_LBUTTONDOWN, .LButtonDown
	JumpIf	WM_MBUTTONDOWN, .MButtonDown
	JumpIf	WM_MBUTTONUP,	.MButtonUp
	JumpIf	WM_SETCURSOR,	.SetCursor

.Default:
	invoke	DefWindowProc, [hWnd], [uMsg], [wParam], [lParam]
	jmp	.EndProc

.Paint:
	stdcall Draw, [hWnd], [hdcBack], [clientRect]
	jmp	.ReturnZero

.MouseWheel:
	stdcall MouseWheel, [wParam], [lParam]
	jmp    .ReturnZero

.MouseMove:
	stdcall MouseMove, [wParam], [lParam]
	jmp	.ReturnZero

.LButtonDown:
	stdcall LButtonDown, [wParam], [lParam]
	jmp	.ReturnZero

.MButtonDown:
	stdcall MButtonDown, [wParam], [lParam]
	jmp	.ReturnZero

.MButtonUp:
	stdcall MButtonUp, [wParam], [lParam]
	jmp	.ReturnZero

.SetCursor:
	stdcall SetCursorMove, [wParam], [lParam]
	jmp	.ReturnZero


.KeyDown:
	mov	eax, [wParam]
	JumpIf	VK_ESCAPE,	.Destroy
	JumpIf	0x43,		..ShowCursor  ; C key
	JumpIf	0x47,		..ShowGrid    ; G key
	JumpIf	0x4F,		..OpenFile    ; O key
	JumpIf	0x53,		..SaveFile    ; S key
	JumpIf	0x20,		..Pause       ; Space key
	jmp	.Default

..ShowCursor:
	stdcall CursorVisible
	jmp    .ReturnZero

..ShowGrid:
	stdcall GridVisible
	jmp	.ReturnZero

..OpenFile:
	stdcall FileOpen, [hWnd]
	jmp	.ReturnZero

..SaveFile:
	stdcall FileSave, [hWnd]
	jmp	.ReturnZero

..Pause:
	stdcall GenerationPause
	jmp	.ReturnZero

.Destroy:
	stdcall DeleteBrushes
	stdcall DestroyField
	invoke	ExitProcess, ebx

.ReturnZero:
	xor	eax, eax

.EndProc:
	ret

endp
