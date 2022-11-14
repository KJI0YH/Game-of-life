CURSOR_VISIBLE		dd	0
GRID_VISIBLE		dd	1
DRAG			dd	0

; Drawing
colorBack		=	00_FF_FF_FFh
colorAlive		=	00_00_00_00h
colorDead		=	00_FF_FF_FFh

defaultCellCount	=	9

cellSize		dd	?
cellRect		RECT


; Mouse
DRAG_BUTTON		=	MK_MBUTTON
