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
	keyPressedListener: .word 0xffff0000 # 1 if a key has been pressed
	keyPressed: .word 0xffff0004 # the ASCII value of the key that was pressed
	
	# offset of the leftmost pixel's location from the base address
	platformOneLocation: .word 4020 
	platformTwoLocation: .word 2096
	platformThreeLocation: .word 256
	
	platformsArray: .word 0:5
	
	# offset of the left-bottommost pixel's location from the base address
	doodlerLocation: .word 3896 #1968 #3896
	
	platformColour: .word 0xe9dc9e
	doodlerColour: .word 0xafe99e
	backgroundColour: .word 0x000000
	
.text

main:
	jal setup
	jal sleep
	jal jump
	j Exit
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
	
setup:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	jal generatePlatforms
	jal drawPlatforms
	jal drawDoodler
	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	
sleep:	
	li $v0, 32
	li $a0, 250
	syscall
	jr $ra
	
generatePlatforms:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	la $t8, platformsArray
	addi $t0, $zero, 1 # will be used as counter, starts at 1 bc we are hardcoding the first platform
	addi $t1, $zero, 5 #the first platform is not random
	
	#hardcode first platform placement
	addi $t5, $zero, 4020
	sw $t5, 0($t8) # store 4020 at index 0 of the array of platforms
	
START_LOOP_GENERATE_PLATFORMS:	bge $t0, $t1, END_LOOP_GENERATE_PLATFORMS
				sll $t2, $t0, 2
				add $t3, $t8, $t2 # $t3 is addr(platformsArray[i])
				# do random stuff
				addi $t7, $zero, 192
				# generate lower bound
				subi $t6, $t0, 1 # we want 0 times 192, 1 times 192, 2 times 192, and 3 times 192
				mult $t6, $t7
				mflo $t6 # result should not be more than 32 bits
				# store lower bound on stack
				addi $sp, $sp, -4
				sw $t6, ($sp)
				# generate upper bound
				addi $t6, $zero, 192
				mult $t6, $t0 # we want 1 times 192, 2 times 192, 3 times 192, and 4 times 192	
				mflo $t6 # result should not be more than 32 bits			
				# store upper bound on stack
				addi $sp, $sp, -4
				sw $t6, ($sp)
				
				jal generateRandomNumber
				# retrieve random number on stack
				lw $t5, ($sp)
				addi $sp, $sp, 4
				# set curr platform position
				addi $t6, $zero, 4
				mult $t5, $t6
				mflo $t5 # result should not be more than 32 bits
				sw $t5, 0($t3)


UPDATE_LOOP_GENERATE_PLATFORMS:	addi $t0, $t0, 1 # increment counter by 1
				j START_LOOP_GENERATE_PLATFORMS

END_LOOP_GENERATE_PLATFORMS:	# now all positions for platforms have been set
	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	
generateRandomNumber: # requires params for upper and lower bounds
    	li $v0, 42  #generates the random number.
    	li $a0, 0
    	# retrieve upper bound on stack
	lw $a1, ($sp) #Here you set $a1 to the max bound.
	addi $sp, $sp, 4
    	syscall
    	# retrieve lower bound on stack
    	lw $t6, ($sp) 
    	addi $sp, $sp, 4
    	add $a0, $a0, $t6
	# store random number on stack (use t2 and t3)
	addi $sp, $sp, -4
	sw $a0, ($sp)
	jr $ra
	
	
drawPlatforms:
	lw $t0, displayAddress # $t0 stores the base address for display
	lw $t1, platformColour # $t1 stores the colour of the platforms
	
	lw $t2, platformOneLocation # store the second platform's offset to base address
	add $t3, $t0, $t2 # create $t3 starting at leftmost pixel of platform, will be used as cursor
	
	add $t4, $zero, $zero # set init value to 0
	addi $t5, $zero, 7 # set loop stop val to 7 (loop repeats 7 times)
START_LOOP_DRAWING_PLATFORM_ONE:	beq $t4, $t5, EXIT_LOOP_DRAWING_PLATFORM_ONE # branch if counter is 7
					sw $t1, 0($t3) # paint the pixel at the cursor's address
					addi $t3, $t3, 4 # increment the cursor by 4 to target the next address in display
UPDATE_LOOP_DRAWING_PLATFORM_ONE: 	addi $t4, $t4, 1 # increment counter by 1
			 		j START_LOOP_DRAWING_PLATFORM_ONE
EXIT_LOOP_DRAWING_PLATFORM_ONE: 
	
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
	
	jr $ra # now all three platforms have been drawn
	
	
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
	jr $ra
	
recolourPixelsUnderDoodler:
	lw $t0, displayAddress
	lw $t1, backgroundColour
	lw $t2, doodlerLocation
	add $t3, $t0, $t2 # create $t3 starting at left-bottommost pixel of doodler, will be used as cursor
	
	add $t4, $zero, $zero # set init value to 0
	addi $t5, $zero, 5 # set loop stop val to 5 (loop repeats 5 times)

START_LOOP_COLOUR_PIXELS_UNDER_DOODLER:		beq $t4, $t5, EXIT_LOOP_COLOUR_PIXELS_UNDER_DOODLER # branch if counter is 5
						sw $t1, 0($t3) # paint the pixel at the cursor's address
						addi $t3, $t3, 4 # increment the cursor by 4 to target the next address in display
UPDATE_LOOP_COLOUR_PIXELS_UNDER_DOODLER: 	addi $t4, $t4, 1 # increment counter by 1
			 			j START_LOOP_COLOUR_PIXELS_UNDER_DOODLER
EXIT_LOOP_COLOUR_PIXELS_UNDER_DOODLER: 		jr $ra

recolourPixelsOverDoodler:
	lw $t0, displayAddress
	lw $t1, backgroundColour
	lw $t2, doodlerLocation
	add $t3, $t0, $t2 # create $t3 starting at left-bottommost pixel of doodler, will be used as cursor
	
	add $t4, $zero, $zero # set outer init value to 0
	addi $t5, $zero, 5 # set outer loop stop val to 5 (outer loop repeats 5 times)
	add $t6, $zero, $zero # set inner init value to 0
	addi $t7, $zero, 5 # set inner loop stop val to 5 (inner loop repeats 5 times)
START_OUTER_LOOP_DRAWING_OVER_DOODLER:	beq $t4, $t5, EXIT_OUTER_LOOP_DRAWING_OVER_DOODLER # branch if counter is 5

START_INNER_LOOP_DRAWING_OVER_DOODLER:	beq $t6, $t7, EXIT_INNER_LOOP_DRAWING_OVER_DOODLER # branch if counter is 5
					sw $t1, 0($t3) # paint the pixel at the cursor's address
					addi $t3, $t3, 4 # increment the cursor by 4 to target the next address in display
UPDATE_INNER_LOOP_DRAWING_OVER_DOODLER: 	addi $t6, $t6, 1 # increment counter by 1
			 		j START_INNER_LOOP_DRAWING_OVER_DOODLER
EXIT_INNER_LOOP_DRAWING_OVER_DOODLER: 	subi $t3, $t3, 20 # set cursor to first
					subi $t3, $t3, 128 # pixel of next row
					add $t6, $zero, $zero # reset inner init value to 0
					
UPDATE_OUTER_LOOP_DRAWING_OVER_DOODLER: 	addi $t4, $t4, 1 # increment counter by 1
			 		j START_OUTER_LOOP_DRAWING_OVER_DOODLER
EXIT_OUTER_LOOP_DRAWING_OVER_DOODLER: 
	jr $ra

keyPressHandler:
	lw $t0, doodlerLocation
	lw $t1, 0xffff0000
	lw $t2, 0xffff0004 # store the ASCII value of the key that was pressed
			
	# check for a key press
	bne $t1, 1, KEY_NOT_PRESSED
			
	# check if the key press was 'j'
	bne $t2, 106, NOT_J_KEY_PRESS
	# handle j key press
	addi $t0, $t0, -4 # move to left by 1 pixel
	j KEY_NOT_PRESSED	
			
NOT_J_KEY_PRESS:	#check if the key press was 'k'
			bne $t2, 107, NOT_A_K_KEY_PRESS
			#handle k key press
			addi $t0, $t0, 4 # move to right by 1 pixel
			
NOT_A_K_KEY_PRESS:	#check if the key press was 's'
			bne $t2, 115, KEY_NOT_PRESSED
			#handle s key press
			# TODO
			
KEY_NOT_PRESSED:	
			sw $t0, doodlerLocation
			jr $ra

jump:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	lw $t0, doodlerLocation
	
	add $t8, $zero, $zero # set init value to 0
	addi $t9, $zero, 9 # set loop stop val to 7 (loop repeats 7 times)
START_LOOP_JUMP_UP:	beq $t8, $t9, EXIT_LOOP_JUMP_UP # branch if counter is 7
			# 1. Update Doodler's position by 1 up
			jal recolourPixelsOverDoodler
			jal keyPressHandler
			
			lw $t0, doodlerLocation
			subi $t0, $t0, 128
			sw $t0, doodlerLocation
	
			# 2. Redraw Doodler
			jal drawDoodler
			jal sleep
			
UPDATE_LOOP_JUMP_UP: 	addi $t8, $t8, 1 # increment counter by 1
			j START_LOOP_JUMP_UP
EXIT_LOOP_JUMP_UP: 	j fall

			lw $ra, ($sp)
			addi $sp, $sp, 4
			jr $ra
			
fall:
	#addi $sp, $sp, -4
	#sw $ra, ($sp)
	# 4. Check for platform collision
	# if platformLocation - 132 <= doodlerLocation <= platformLocation - 122
	#	platformLocation - 132 - doodlerLocation <= 0 <= platformLocation - 122 - doodlerLocation
	# checking platform 1
	lw $t0, doodlerLocation
	
CHECKING_PLATFORM_ONE: 	
			lw $t1, platformOneLocation
	
			# adjust $t2 to use in less than or equal branch condition
			subi $t2, $t1, 144
			#adjust $t3 to use in greater than or equal branch condition 
			subi $t3, $t1, 100
			
			ble $t0, $t2, CHECKING_PLATFORM_TWO
		       	bgt $t0, $t3, CHECKING_PLATFORM_TWO	
		       	j HANDLE_COLLISION # handle colliding with platform 1
	# checking platform 2
CHECKING_PLATFORM_TWO: 
			lw $t1, platformTwoLocation
	
			# adjust $t2 to use in less than or equal branch condition
			subi $t2, $t1, 144
			#adjust $t3 to use in greater than or equal branch condition 
			subi $t3, $t1, 100
			
			ble $t0, $t2, CHECKING_PLATFORM_THREE
		       	bgt $t0, $t3, CHECKING_PLATFORM_THREE	
		       	j HANDLE_COLLISION # handle colliding with platform 2
	#checking platform 3
CHECKING_PLATFORM_THREE:
			lw $t1, platformThreeLocation
	
			# adjust $t2 to use in less than or equal branch condition
			subi $t2, $t1, 144
			#adjust $t3 to use in greater than or equal branch condition 
			subi $t3, $t1, 100
			
			#ble $t0, $t2, NO_COLLISION
		       	#bgt $t0, $t3, NO_COLLISION	
		       	#j HANDLE_COLLISION # handle colliding with platform 3
			
			#CAUSES INFINITE JUMP FOR SOME REASON
			ble $t0, $t2, CHECKING_BOTTOM_OF_SCREEN
		       	bgt $t0, $t3, CHECKING_BOTTOM_OF_SCREEN	
		       	j HANDLE_COLLISION # handle colliding with platform 3
		       	
CHECKING_BOTTOM_OF_SCREEN:
			addi $t1, $zero, 4096 # last possible pixel
			ble $t0, $t1, NO_COLLISION	
		       	j Exit # handle colliding with bottom of screen
			
	# 4.1. If Doodler's position is on top of platform, restart jump from current position
HANDLE_COLLISION:	j jump

NO_COLLISION: 
	# 4.2. Otherwise, check keyboard input
	# 4.2.1. If 'j', update Doodler's position by 1 left, 1 down
	# 4.2.2. If 'k', update Doodler's position by 1 right, 1 down
	# 4.2.3. Otherwise, update Doodler's position by 1 down only
	# 5. If no collision, repeat until there is, or Doodler's position passes bottom of screen
	
	
START_LOOP_JUMP_DOWN:	#beq $t8, $t9, EXIT_LOOP_JUMP_DOWN # branch if counter is 7
			# 1. Update Doodler's position by 1 down
			jal recolourPixelsOverDoodler
			jal keyPressHandler
			
			lw $t0, doodlerLocation
			addi $t0, $t0, 128
			sw $t0, doodlerLocation
	
			# 2. Redraw Doodler
			jal drawDoodler
			jal sleep
			
UPDATE_LOOP_JUMP_DOWN: 	#addi $t8, $t8, 1 # increment counter by 1
			
EXIT_LOOP_JUMP_DOWN: 	j fall

	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
			
			
