# Demo for painting
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
.data
	displayAddress:.word 0x10008000
.text
	lw $t0, displayAddress# $t0 stores the base address for display
	li $t1, 0xff0000# $t1 stores the red colour code
	li $t2, 0x00ff00# $t2 stores the green colour code
	li $t3, 0x0000ff# $t3 stores the blue colour code
	sw $t2, 0($t0) # paint the first (top-left) unit green.
	sw $t2, 4($t0) # paint the second unit on the first row green. Why$t0+4?
	sw $t2, 8($t0)
	sw $t2, 12($t0)
	sw $t2, 128($t0) # paint the first unit on the second row green. Why +128?
	sw $t2, 132($t0)
	sw $t2, 136($t0)
	sw $t2, 140($t0)
	sw $t2, 256($t0) # paint the first unit on the third row green
	sw $t2, 260($t0)
	sw $t2, 264($t0)
	sw $t2, 268($t0)
	sw $t2, 384($t0) # paint the first unit on the fourth row green
	sw $t2, 388($t0)
	sw $t2, 392($t0)
	sw $t2, 396($t0)
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
