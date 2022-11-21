format PE GUI 4.0
entry WinMain

	include 	"win32a.inc"
	include 	"api\user32.inc"
	include 	"api\kernel32.inc"
	include 	"api\gdi32.inc"
	include 	"api\comdlg32.inc"

data import

	library kernel32,	"KERNEL32.DLL",\
		user32, 	"USER32.DLL",\
		gdi32,		"GDI32.DLL",\
		comdlg32,	"COMDLG32.DLL"

end data

	include 	"macro.inc"
	include 	"draw.asm"
	include 	"mouse.asm"
	include 	"keys.asm"
	include 	"logic.asm"
	include 	"settings.asm"
	include 	"files.asm"

