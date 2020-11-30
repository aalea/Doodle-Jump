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
# 1. Press 'q' to pause
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
	#platformOneLocation: .word 4020 
	#platformTwoLocation: .word 2096
	#platformThreeLocation: .word 256
	
	platformsArray: .word 0:5
	nextPlatformToRedraw: .word 0
	
	# offset of the left-bottommost pixel's location from the base address
	doodlerLocation: .word 3896 #1968 #3896
	
	platformColour: .word 0xe9dc9e
	doodlerColour: .word 0xafe99e
	backgroundColour: .word 0x4a2772
	
.text

main:
	jal setup
	jal waitForStart
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
	jal drawBackground
	jal drawPlatforms
	jal drawDoodler
	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	
sleep:	
	li $v0, 32
	li $a0, 100
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
	
generateNewPlatform: # generate a new platform and replace the one at index nextPlatformToDraw with it.
		     # then increment that index by 1
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	lw $t1, nextPlatformToRedraw # load the index to access the platformsArray with
	sll $t1, $t1, 2 # multiple index by 4 to correctly address a word in memory
	
	# t3 is the addr of platform at nextPlatformToDraw
	la $t2, platformsArray
	add $t3, $t2, $t1 # t3 is addr(platformsArray[nextPlatformToDraw])
		     
	# store lower bound on stack
	addi $t6, $zero, 0
	addi $sp, $sp, -4
	sw $t6, ($sp)
		
	# store upper bound on stack
	addi $t6, $zero, 192	
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
	
	# increment nextPlatformToDraw by 1 if under 3, if 3 set to 0
	bge $t1, 3, RESET_PLATFORM_INDEX
	addi $t1, $t1, 1
	j FINISHED_ADJUSTING_INDEX

RESET_PLATFORM_INDEX:	addi $t1, $zero, 0	

FINISHED_ADJUSTING_INDEX:
	sw $t1, nextPlatformToRedraw
	
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

drawBackground:
	lw $s0, displayAddress
	lw $s1, backgroundColour
	
	add $t0, $zero, $s0 # counter
	addi $t1, $s0, 4096 
		
START_LOOP_DRAWING_BACKGROUND:	bge $t0, $t1, EXIT_LOOP_DRAWING_BACKGROUND
				sw $s1, ($t0)

UPDATE_LOOP_DRAWING_BACKGROUND:	addi $t0, $t0, 4 # to access the next memory location
				j START_LOOP_DRAWING_BACKGROUND

EXIT_LOOP_DRAWING_BACKGROUND:	jr $ra # now the background has been drawn
	
	
drawPlatforms:
	lw $s0, displayAddress # $s0 stores the base address for display
	lw $s1, platformColour # $s1 stores the colour of the platforms
	
	la $t8, platformsArray
	addi $t0, $zero, 0 # will be used as counter
	addi $t1, $zero, 5 
	
START_OUTER_LOOP_DRAWING_PLATFORMS:	bge $t0, $t1, EXIT_OUTER_LOOP_DRAWING_PLATFORMS # iterates through index 0-4 of platforms
					sll $t2, $t0, 2
					add $t9, $t8, $t2
					
					# modify to target array elements	
					lw $s2, ($t9) # store the second platform's offset to base address
					add $t3, $s0, $s2 # create $t3 starting at leftmost pixel of platform, will be used as cursor
	
					add $t4, $zero, $zero # set init value to 0
					addi $t5, $zero, 7 # set loop stop val to 7 (loop repeats 7 times)
START_INNER_LOOP_DRAWING_PLATFORMS:	beq $t4, $t5, EXIT_INNER_LOOP_DRAWING_PLATFORMS # branch if counter is 7
					sw $s1, 0($t3) # paint the pixel at the cursor's address
					addi $t3, $t3, 4 # increment the cursor by 4 to target the next address in display
UPDATE_INNER_LOOP_DRAWING_PLATFORMS: 	addi $t4, $t4, 1 # increment counter by 1
			 		j START_INNER_LOOP_DRAWING_PLATFORMS
EXIT_INNER_LOOP_DRAWING_PLATFORMS: 
	
UPDATE_OUTER_LOOP_DRAWING_PLATFORMS:	addi $t0, $t0, 1
					j START_OUTER_LOOP_DRAWING_PLATFORMS

EXIT_OUTER_LOOP_DRAWING_PLATFORMS:	
	
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
	
waitForStart:	# NEED TO MERGE WITH pause
	addi $sp, $sp, -4
	sw $ra, ($sp)
	# enter loop that checks if input changed and if not, sleep for 1 sec and repeat
	lw $t1, 0xffff0000 # store if a key was pressed
	lw $t2, 0xffff0004 # store the ASCII value of the key that was pressed
	addi $t3, $zero, 1
	addi $t4, $zero, 115
	
START_WAIT_LOOP:	beq $t1, $t3, EXIT_WAIT_LOOP
			jal sleep
			
UPDATE_WAIT_LOOP:	lw $t1, 0xffff0000 # store if a key was pressed
			lw $t2, 0xffff0004 # store the ASCII value of the key that was pressed
			j START_WAIT_LOOP

EXIT_WAIT_LOOP:		bne $t2, $t4, START_WAIT_LOOP
			lw $ra, ($sp)
			addi $sp, $sp, 4
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
	addi $sp, $sp, -4
	sw $ra, ($sp)
	lw $t0, doodlerLocation
	lw $t1, 0xffff0000 # store if a key was pressed
	lw $t2, 0xffff0004 # store the ASCII value of the key that was pressed
			
	# check for a key press
	bne $t1, 1, KEY_NOT_PRESSED
	
	# check if the key press was 's'
	bne $t2, 115, NOT_A_S_KEY_PRESS
	# handle 's' key press
	jal resetDoodlerPosition
	j main

NOT_A_S_KEY_PRESS:		
	# check if the key press was 'j'
	bne $t2, 106, NOT_J_KEY_PRESS
	# handle j key press
	addi $t0, $t0, -4 # move to left by 1 pixel
	j KEY_NOT_PRESSED	
			
NOT_J_KEY_PRESS:	#check if the key press was 'k'
			bne $t2, 107, NOT_A_K_KEY_PRESS
			#handle k key press
			addi $t0, $t0, 4 # move to right by 1 pixel
			
NOT_A_K_KEY_PRESS:	#check if the key press was 'q'
			bne $t2, 113, KEY_NOT_PRESSED
			#handle q key press
			jal pause
KEY_NOT_PRESSED:	
			sw $t0, doodlerLocation
			
			lw $ra, ($sp)
			addi $sp, $sp, 4
			jr $ra
			
pause:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	# enter loop that checks if input changed and if not, sleep for 1 sec and repeat
	lw $t1, 0xffff0000 # store if a key was pressed
	lw $t2, 0xffff0004 # store the ASCII value of the key that was pressed
	addi $t3, $zero, 1
	addi $t4, $zero, 113
	
START_PAUSE_LOOP:	beq $t1, $t3, EXIT_PAUSE_LOOP
			jal sleep
			
UPDATE_PAUSE_LOOP:	lw $t1, 0xffff0000 # store if a key was pressed
			lw $t2, 0xffff0004 # store the ASCII value of the key that was pressed
			j START_PAUSE_LOOP

EXIT_PAUSE_LOOP:	bne $t2, $t4, START_PAUSE_LOOP
			lw $ra, ($sp)
			addi $sp, $sp, 4
			jr $ra
			
resetDoodlerPosition:
	addi $t0, $zero, 3896
	sw $t0, doodlerLocation
	jr $ra

jump:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	lw $t0, doodlerLocation
	
	add $t8, $zero, $zero # set init value to 0
	addi $t9, $zero, 13 # set loop stop val to 7 (loop repeats 13 times)
START_LOOP_JUMP_UP:	beq $t8, $t9, EXIT_LOOP_JUMP_UP # branch if counter is 13
			# 1. Update Doodler's position by 1 up
			jal recolourPixelsOverDoodler
			jal keyPressHandler
			
			lw $t0, doodlerLocation
			subi $t0, $t0, 128
			sw $t0, doodlerLocation
			
			jal handleScroll
	
			# 2. Redraw Doodler
			jal drawDoodler
			jal sleep
			
UPDATE_LOOP_JUMP_UP: 	addi $t8, $t8, 1 # increment counter by 1
			j START_LOOP_JUMP_UP
EXIT_LOOP_JUMP_UP: 	j fall

			lw $ra, ($sp)
			addi $sp, $sp, 4
			jr $ra
			
handleScroll:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	# if doodlerLocation < half of screen
	lw $t0, doodlerLocation
	addi $t1, $zero, 2044 # approx the middle point of the school
	
	bgt $t0, $t1, DONT_SCROLL # if the doodler is in the lower half of the screen, don't scroll
		# then add some constant times 128 to all objects
		jal scrollObjects
		# generate a new platform to replace the one at index nextPlatformToDraw and increment that index by 1
		jal generateNewPlatform
		jal generateNewPlatform
		jal generateNewPlatform
		# redraw all the platforms (jump function takes care of doodler)
		jal drawBackground
		jal drawPlatforms
DONT_SCROLL:
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	
scrollObjects: # add a constant times 128 to all objects
	addi $t2, $zero, 16 # the scroll constant
	addi $t3, $zero, 128
	mult $t2, $t3
	mflo $t2
	
	lw $t0, doodlerLocation
	
	# scroll doodler
	add $t0, $t0, $t2
	sw $t0, doodlerLocation
	
	la $t5, platformsArray

	# scroll platforms
	add $t3, $zero, $zero # set init value to 0
	addi $t4, $zero, 4 # set loop stop val to 4 (loop repeats 4 times)
START_LOOP_SCROLLING_PLATFORMS:		beq $t3, $t4, EXIT_LOOP_SCROLLING_PLATFORMS # branch if counter is 4
					sll $t6, $t3, 2
					add $t6, $t5, $t6 # t6 is the addr of the curr platform
					
					lw $t7, ($t6)
					add $t7, $t7, $t2
					sw $t7, ($t6)
					
UPDATE_LOOP_SCROLLING_PLATFORMS:	addi $t3, $t3, 1
					j START_LOOP_SCROLLING_PLATFORMS
EXIT_LOOP_SCROLLING_PLATFORMS:		jr $ra	

			
fall:
	#addi $sp, $sp, -4
	#sw $ra, ($sp)
	# 4. Check for platform collision
	# if platformLocation - 132 <= doodlerLocation <= platformLocation - 122
	#	platformLocation - 132 - doodlerLocation <= 0 <= platformLocation - 122 - doodlerLocation
	# checking platform 1
	lw $s0, doodlerLocation
	la $t8, platformsArray
	add $t0, $zero, $zero
	addi $t4, $zero, 5
	#checking platforms
START_LOOP_CHECKING_PLATFORMS:	bge $t0, $t4, END_LOOP_CHECKING_PLATFORMS
				sll $t5, $t0, 2
				add $t6, $t8, $t5
				lw $t1, ($t6)
	
				# adjust $t2 to use in less than or equal branch condition
				subi $t2, $t1, 144
				#adjust $t3 to use in greater than or equal branch condition 
				subi $t3, $t1, 100
			
				ble $s0, $t2, UPDATE_LOOP_CHECKING_PLATFORMS
		       		bgt $s0, $t3, UPDATE_LOOP_CHECKING_PLATFORMS #continue
		       		j HANDLE_COLLISION # handle colliding with platform 3
UPDATE_LOOP_CHECKING_PLATFORMS:	addi $t0, $t0, 1
				j START_LOOP_CHECKING_PLATFORMS
END_LOOP_CHECKING_PLATFORMS:
		       	
CHECKING_BOTTOM_OF_SCREEN:
			addi $t1, $zero, 4096 # last possible pixel
			ble $s0, $t1, NO_COLLISION	
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
			
			
