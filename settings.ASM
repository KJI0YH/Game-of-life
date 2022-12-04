CURSOR_VISIBLE		dd	0
GRID_VISIBLE		dd	1
DRAG			dd	0
GEN_PAUSE		dd	1
FRAME_VISIBLE		dd	0

; Drawing
colorAlive		=	00_00_00_00h
colorDead		=	00_FF_FF_FFh
colorFrame		=	00_00_00_FFh
colorGridSub		=	00_80_80_30h
widthGridMain		=	2
widthGridSub		=	1
widthFrame		=	5

drawFreq		=	10
stepFreq		dd	50
speedStep		=	20
defaultCellCount	=	9

cellSize		dd	?
cellRect		RECT


; Mouse
FIELD_DRAG_BUTTON	=	MK_MBUTTON
FILL			=	MK_LBUTTON
CLEAR			=	MK_LBUTTON + MK_SHIFT

; Files
RLE_BODY		=	0
RLE_HEADER_X		=	1
RLE_HEADER_Y		=	2

