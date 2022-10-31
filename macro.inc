macro JumpIf	value, label
{
	cmp	eax, value
	je	label
}

macro	Min	A, B
{
	local	..min
	mov	eax, [A]
	cmp	eax, [B]
	jle	..min
	mov	eax, [B]
..min:

}