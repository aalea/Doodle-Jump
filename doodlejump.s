#####################################################################
#
# CSC258H1F Fall 2020 Assembly Final Project
# University of Toronto, St. George
#
# Student: Aalea Ally, 1004947748
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3/4/5 (choose the one the applies)
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Any additional information that the TA needs to know:
# - (write here, if any)
######################################################################

.data
	displayAddress:.word 0x10008000
	
	platformOneLocation: .word 4020
	platformTwoLocation: .word 2096
	platformThreeLocation: .word 256
	doodlerLocation: .word 3896
	
	platformColour: .word 0xe9dc9e
	doodlerColour: .word 0xafe99e
	
.text

main:
	jal setup
	
setup:
	jal drawPlatforms
	jal drawDoodler
	
drawPlatforms:
	lw $t0, displayAddress # $t0 stores the base address for display
	lw $t1, platformColour # $t1 stores the colour of the platforms
	sw $t1, 4020($t0) # paint the 1st pixel of the first platform
	sw $t1, 4024($t0) # paint the 2nd pixel of the first platform
	sw $t1, 4028($t0) # paint the 3rd pixel of the first platform
	sw $t1, 4032($t0) # paint the 4th pixel of the first platform
	sw $t1, 4036($t0) # paint the 5th pixel of the first platform
	sw $t1, 4040($t0) # paint the 6th pixel of the first platform
	sw $t1, 4044($t0) # paint the 7th pixel of the first platform
	
	lw $t2, platformTwoLocation # store the second platform's offset to base address
	add $t3, $t0, $t2 # create $t3 starting at leftmost pixel of platform, will be used as cursor
	
	add $t4, $zero, $zero # set init value to 0
	addi $t5, $zero, 7 # set loop stop val to 7 (loop repeats 7 times)
START_LOOP_DRAWING_PLATFORM_TWO:	beq $t4, $t5, EXIT_LOOP_DRAWING_PLATFORM_TWO # branch if counter is 7
					sw $t1, 0($t3) # paint the pixel at the cursor's address
					addi $t3, $t3, 4 # increment the cursor by 4 to target the next address in display
UPDATE_LOOP_DRAWING_PLATFORM_TWO: 	addi $t4, $t4, 1 # increment counter by 1
			 		j START_LOOP_DRAWING_PLATFORM_TWO
EXIT_LOOP_DRAWING_PLATFORM_TWO: 	
	lw $t2, platformThreeLocation # store the third platform's offset to base address
	add $t3, $t0, $t2 # create $t3 starting at leftmost pixel of platform, will be used as cursor
	
	add $t4, $zero, $zero # set init value to 0
	addi $t5, $zero, 7 # set loop stop val to 7 (loop repeats 7 times)
START_LOOP_DRAWING_PLATFORM_THREE:	beq $t4, $t5, EXIT_LOOP_DRAWING_PLATFORM_THREE # branch if counter is 7
					sw $t1, 0($t3) # paint the pixel at the cursor's address
					addi $t3, $t3, 4 # increment the cursor by 4 to target the next address in display
UPDATE_LOOP_DRAWING_PLATFORM_THREE: 	addi $t4, $t4, 1 # increment counter by 1
			 		j START_LOOP_DRAWING_PLATFORM_THREE
EXIT_LOOP_DRAWING_PLATFORM_THREE: 
	
	# now all three platforms have been drawn
	
drawDoodler:
	lw $t0, displayAddress
	lw $t1, doodlerColour
	lw $t2, doodlerLocation
	add $t3, $t0, $t2 # create $t3 starting at left-bottommost pixel of doodler, will be used as cursor
	
	add $t4, $zero, $zero # set outer init value to 0
	addi $t5, $zero, 5 # set outer loop stop val to 5 (outer loop repeats 5 times)
	add $t6, $zero, $zero # set inner init value to 0
	addi $t7, $zero, 5 # set inner loop stop val to 5 (inner loop repeats 5 times)
START_OUTER_LOOP_DRAWING_DOODLER:	beq $t4, $t5, EXIT_OUTER_LOOP_DRAWING_DOODLER # branch if counter is 5

START_INNER_LOOP_DRAWING_DOODLER:	beq $t6, $t7, EXIT_INNER_LOOP_DRAWING_DOODLER # branch if counter is 5
					sw $t1, 0($t3) # paint the pixel at the cursor's address
					addi $t3, $t3, 4 # increment the cursor by 4 to target the next address in display
UPDATE_INNER_LOOP_DRAWING_DOODLER: 	addi $t6, $t6, 1 # increment counter by 1
			 		j START_INNER_LOOP_DRAWING_DOODLER
EXIT_INNER_LOOP_DRAWING_DOODLER: 	subi $t3, $t3, 20 # set cursor to first
					subi $t3, $t3, 128 # pixel of next row
					add $t6, $zero, $zero # reset inner init value to 0
					
UPDATE_OUTER_LOOP_DRAWING_DOODLER: 	addi $t4, $t4, 1 # increment counter by 1
			 		j START_OUTER_LOOP_DRAWING_DOODLER
EXIT_OUTER_LOOP_DRAWING_DOODLER: 
	
	
	
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
