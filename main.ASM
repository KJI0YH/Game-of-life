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
	stdcall CreateBrushes
	stdcall CreateField, [clientRect.bottom], [clientRect.right]

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
	JumpIf	WM_LBUTTONUP,	.LButtonUp
	JumpIf	WM_RBUTTONDOWN, .RButtonDown
	JumpIf	WM_RBUTTONUP,	.RButtonUp
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

.LButtonUp:
	stdcall LButtonUp, [wParam], [lParam]
	jmp	.ReturnZero

.RButtonDown:
	stdcall DragStart, [wParam], [lParam]
	jmp	.ReturnZero

.RButtonUp:
	stdcall DragStop, [wParam], [lParam]
	jmp	.ReturnZero

.SetCursor:
	stdcall SetCursorMove, [wParam], [lParam]
	jmp	.ReturnZero

.KeyDown:
	mov	eax, [wParam]
	JumpIf	VK_ESCAPE,	.Destroy
	JumpIf	0x43,		..ShowCursor	; C key
	JumpIf	0x47,		..ShowGrid	; G key
	JumpIf	0x4F,		..OpenFile	; O key
	JumpIf	0x53,		..SaveFile	; S key
	JumpIf	0x46,		..ShowFrame	; F key
	JumpIf	0x44,		..DeleteField	; D key
	JumpIf	0x49,		..InvertColors	; I key
	JumpIf	0x20,		..Pause 	; Space key
	JumpIf	VK_RETURN,	..NextGen	; Enter key
	JumpIf	0xBB,		..IncSpeed	; + key
	JumpIf	0xBD,		..DecSpeed	; - key
	JumpIf	VK_LEFT,	..Arrow 	; left key
	JumpIf	VK_UP,		..Arrow 	; up key
	JumpIf	VK_DOWN,	..Arrow 	; down key
	JumpIf	VK_RIGHT,	..Arrow 	; right key
	jmp	.Default

..ShowCursor:
	stdcall CursorVisible
	jmp    .ReturnZero

..ShowGrid:
	stdcall GridVisible
	jmp	.ReturnZero

..ShowFrame:
	stdcall FrameVisible
	jmp	.ReturnZero

..DeleteField:
	stdcall ClearField
	jmp	.ReturnZero

..InvertColors:
	stdcall InvertColors
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

..NextGen:
	cmp	[GEN_PAUSE], 1
	jne	.ReturnZero
	stdcall NextGeneration, [hCells], [hBackCells]
	mov	esi, [hCells]
	xchg	esi, [hBackCells]
	xchg	esi, [hCells]
	jmp	.ReturnZero

..IncSpeed:
	stdcall IncSpeed
	jmp	.ReturnZero

..DecSpeed:
	stdcall DecSpeed
	jmp	.ReturnZero

..Arrow:
	stdcall ArrowMove, [wParam]
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
