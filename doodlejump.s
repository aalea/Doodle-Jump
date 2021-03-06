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
# - Milestone 5
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. Press 'q' to pause
# 2. Game Over screen and restart with 's'
# 3. Score that updates on screen during gameplay
# 4. Graphics (background gradient with moon, platforms are clouds, Doodler is more detailed and eyes move up and down)
# 5. Powerups (Spring and Rocket)
# 6. On-screen notifications ("Cool!" appears after every 10 points, "Wow!" appears after every 100 points, "Pog!" appears after every 1000 points)
#
# Any additional information that the TA needs to know:
# - The score also appears on the console everytime it updates
######################################################################

.data
	displayAddress: .word 0x10008000
	displayBufferAddress: .word 0
	#keyPressedListener: .word 0xffff0000 # 1 if a key has been pressed
	#keyPressed: .word 0xffff0004 # the ASCII value of the key that was pressed
	
	# offset of the leftmost pixel's location from the base address
	bottomPlatformLocation: .word 4020 # initially starts at 4020, will be stored during scrolling
	#platformTwoLocation: .word 2096
	#platformThreeLocation: .word 256
	
	platformsArray: .word 0:4
	nextPlatformToRedraw: .word 3
	
	# offset of the left-bottommost pixel's location from the base address
	doodlerLocation: .word 3896 #1968 #3896
	doodlerState: .word 0 # 0 if falling, 1 if jumping
	doodlerHeadColour: .word 0xfc94dd
	doodlerBodyColour: .word 0xfce0f4
	doodlerShoeColour: .word 0xfc1648
	
	platformColour: .word 0xdefcfb
	doodlerColour: .word 0xafe99e
	backgroundColour: .word 0x0713fc
	
	rocketPowerupLocation: .word -1 # -1 if not on screen
	springPowerupLocation: .word -1 # -1 if not on screen
	
	jumpLoopCounter: .word 0
	jumpLoopStopVal: .word 0
	jumpSpeed: .word 1
	sleepyTime: .word 75
	scrollCounter: .word 0
	
	score: .word 0:8
	
	spaceChar: .asciiz " "
	
	extraSpaceForBufferErrors: .word 0:4096
	
	displayBuffer: .word 0:4096	
	
.text

main:
	jal resetDoodlerPosition
	jal resetJumpSpeed
	jal setDisplayBufferAddress
	jal setup
	jal waitForStart
	jal sleep
	jal jump
	j Exit
	
Exit:
	li $v0, 10 # terminate the program gracefully
	syscall
	
setDisplayBufferAddress:	
	la $t0, displayBuffer
	sw $t0, displayBufferAddress
	jr $ra
	
loadBufferToScreen:
	# load displayAddress
	lw $s7, displayAddress
	# load displayBufferAddress
	lw $s6, displayBufferAddress
	
	# set a counter that starts at 0 (offset of displayAddress and displayBufferAddress)
	addi $s5, $zero, 0
	
	# start a loop that iterates through each pixel in the buffer and paints the appropriate pixel on the actual screen
START_LOOP_LOADING_BUFFER:	beq $s5, 4096, EXIT_LOOP_LOADING_BUFFER # branch if counter is equal to 4096	
				add $s3, $s6, $s5 # calculate sum of displayBufferAddress + counter, which is an address
				lw $s3, ($s3) # load value at address
				add $s4, $s7, $s5 # calculate sum of displayAddress + counter, which is an address
				sw $s3, ($s4) # store value into this address

UPDATE_LOOP_LOADING_BUFFER:	addi $s5, $s5, 4 # add 4 to counter
				j START_LOOP_LOADING_BUFFER # jump to loop start

EXIT_LOOP_LOADING_BUFFER:	jr $ra
	
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
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	jal loadBufferToScreen
	
	li $v0, 32
	lw $a0, sleepyTime
	#lw $a0, jumpSpeed
	syscall
	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	
generatePlatforms:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	la $t8, platformsArray
	addi $t0, $zero, 0 # will be used as counter
	addi $t1, $zero, 3 #the first platform is not random, hardcoding last platform
	
	#hardcode last platform placement
	lw $t5, bottomPlatformLocation
	sw $t5, 12($t8) # store 4020 at index 3 of the array of platforms
	
START_LOOP_GENERATE_PLATFORMS:	bge $t0, $t1, END_LOOP_GENERATE_PLATFORMS
				sll $t2, $t0, 2
				add $t3, $t8, $t2 # $t3 is addr(platformsArray[i])
				# do random stuff
				addi $t7, $zero, 256
				# generate lower bound (64 + 256*(counter-1))
				add $t6, $t0, $zero # we want 0 times 256, 1 times 256, 2 times 256
				mult $t6, $t7
				mflo $t6 # result should not be more than 32 bits
				addi $t6, $t6, 64
				# store lower bound on stack
				addi $sp, $sp, -4
				sw $t6, ($sp)
				# generate upper bound (249 + 256*(counter-1))
				add $t6, $t0, $zero # we want 0 times 256, 1 times 256, 2 times 256
				mult $t6, $t7
				mflo $t6 # result should not be more than 32 bits
				addi $t6, $t6, 249			
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
	addi $t6, $zero, 185
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
	# retrieve lower bound on stack
    	lw $t6, ($sp) 
    	addi $sp, $sp, 4
    	sub $a1, $a1, $t6 # adjust range to be 0 to (max-min)
    	syscall
    	
	# store random number on stack (use t2 and t3)
	add $a0, $a0, $t6 # adjust rand num to be in range min to max
	addi $sp, $sp, -4
	sw $a0, ($sp)
	jr $ra

drawBackground:
	lw $s0, displayBufferAddress # $s0 is x
	lw $s1, backgroundColour
	addi $s1, $s1, 10
	add $t0, $zero, 0

START_LOOP_COLOUR_GRADIENT:		bge $t0, 32, EXIT_LOOP_COLOUR_GRADIENT
								sw $s1, ($s0)
								sw $s1, 4($s0)
								sw $s1, 8($s0)
								sw $s1, 12($s0)
								sw $s1, 16($s0)
								sw $s1, 20($s0)
								sw $s1, 24($s0)
								sw $s1, 28($s0)
								sw $s1, 32($s0)
								sw $s1, 36($s0)
								sw $s1, 40($s0)
								sw $s1, 44($s0)
								sw $s1, 48($s0)
								sw $s1, 52($s0)
								sw $s1, 56($s0)
								sw $s1, 60($s0)
								sw $s1, 64($s0)
								sw $s1, 68($s0)
								sw $s1, 72($s0)
								sw $s1, 76($s0)
								sw $s1, 80($s0)
								sw $s1, 84($s0)
								sw $s1, 88($s0)
								sw $s1, 92($s0)
								sw $s1, 96($s0)
								sw $s1, 100($s0)
								sw $s1, 104($s0)
								sw $s1, 108($s0)
								sw $s1, 112($s0)
								sw $s1, 116($s0)
								sw $s1, 120($s0)
								sw $s1, 124($s0)
UPDATE_LOOP_COLOUR_GRADIENT:	addi $s1, $s1, 8
				addi $t0, $t0, 1
				addi $s0, $s0, 128
				j START_LOOP_COLOUR_GRADIENT
EXIT_LOOP_COLOUR_GRADIENT:	# draw moon
				li $s1, 0xf9f975
				lw $s0, displayBufferAddress
				sw $s1, 4($s0)
				sw $s1, 8($s0)
				sw $s1, 12($s0)
				sw $s1, 16($s0)
				sw $s1, 20($s0)
				sw $s1, 128($s0)
				sw $s1, 132($s0)
				sw $s1, 136($s0)
				sw $s1, 152($s0)
				sw $s1, 256($s0)
				sw $s1, 260($s0)
				sw $s1, 384($s0)
				sw $s1, 388($s0)
				sw $s1, 512($s0)
				sw $s1, 516($s0)
				sw $s1, 640($s0)
				sw $s1, 644($s0)
				sw $s1, 648($s0)
				sw $s1, 664($s0)
				sw $s1, 772($s0)
				sw $s1, 776($s0)
				sw $s1, 780($s0)
				sw $s1, 784($s0)
				sw $s1, 788($s0)
				
				jr $ra # now the background has been drawn
	
	
drawPlatforms:
	lw $s0, displayBufferAddress # $s0 stores the base address for display
	lw $s1, platformColour # $s1 stores the colour of the platforms
	
	la $t8, platformsArray
	addi $t0, $zero, 0 # will be used as counter
	addi $t1, $zero, 4 
	
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
					# drawing rest of cloud
					subi $s4, $s1, 40
					add $t3, $s0, $s2
					subi $t3, $t3, 128 # move cursor up by 1 row from leftmost pixel
					addi $t3, $t3, 4
					sw $s4, 0($t3) # paint the pixel at the cursor's address
					sw $s4, 4($t3) 
					sw $s4, 8($t3) 
					sw $s4, 12($t3) 
					sw $s4, 16($t3) 
					addi $s4, $zero, 0xffffff
					subi $t3, $t3, 128 # move cursor up by 1 row 
					addi $t3, $t3, 4
					sw $s1, 0($t3) # paint the pixel at the cursor's address
					sw $s1, 4($t3) 
					sw $s1, 8($t3)
					
					
	
UPDATE_OUTER_LOOP_DRAWING_PLATFORMS:	addi $t0, $t0, 1
					j START_OUTER_LOOP_DRAWING_PLATFORMS

EXIT_OUTER_LOOP_DRAWING_PLATFORMS:	
	
	jr $ra # now all three platforms have been drawn
	
	
drawDoodler:
	#lw $t0, displayAddress
	#lw $t1, doodlerColour
	#lw $t2, doodlerLocation
	#add $t3, $t0, $t2 # create $t3 starting at left-bottommost pixel of doodler, will be used as cursor
	
	#add $t4, $zero, $zero # set outer init value to 0
	#addi $t5, $zero, 5 # set outer loop stop val to 5 (outer loop repeats 5 times)
	#add $t6, $zero, $zero # set inner init value to 0
	#addi $t7, $zero, 5 # set inner loop stop val to 5 (inner loop repeats 5 times)
#START_OUTER_LOOP_DRAWING_DOODLER:	beq $t4, $t5, EXIT_OUTER_LOOP_DRAWING_DOODLER # branch if counter is 5
#
#START_INNER_LOOP_DRAWING_DOODLER:	beq $t6, $t7, EXIT_INNER_LOOP_DRAWING_DOODLER # branch if counter is 5
#					sw $t1, 0($t3) # paint the pixel at the cursor's address
#					addi $t3, $t3, 4 # increment the cursor by 4 to target the next address in display
#UPDATE_INNER_LOOP_DRAWING_DOODLER: 	addi $t6, $t6, 1 # increment counter by 1
#			 		j START_INNER_LOOP_DRAWING_DOODLER
#EXIT_INNER_LOOP_DRAWING_DOODLER: 	subi $t3, $t3, 20 # set cursor to first
#					subi $t3, $t3, 128 # pixel of next row
#					add $t6, $zero, $zero # reset inner init value to 0
#					
#UPDATE_OUTER_LOOP_DRAWING_DOODLER: 	addi $t4, $t4, 1 # increment counter by 1
#			 		j START_OUTER_LOOP_DRAWING_DOODLER
#EXIT_OUTER_LOOP_DRAWING_DOODLER: 
	lw $t0, displayBufferAddress # $s0 is x
	lw $t2, doodlerLocation
	add $t0, $t0, $t2 # bottom left pixel of doodler
	subi $t0, $t0, 512 # top right pixel
	
	lw $t1, doodlerHeadColour
	lw $t3, doodlerBodyColour
	lw $t4, doodlerShoeColour
	lw $t5, doodlerState
	li $t6, 0xffffff # white
	li $t7, 0x000000 # black

	beq $t5, 3, DRAW_ROCKET

	# draw head
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 128($t0)
	sw $t1, 136($t0)
	sw $t1, 144($t0)
	sw $t1, 256($t0)
	sw $t1, 264($t0)
	sw $t1, 272($t0)

	# draw body
	sw $t3, 388($t0)
	sw $t3, 392($t0)
	sw $t3, 396($t0)

	# draw shoes
	sw $t4, 512($t0)
	sw $t4, 516($t0)
	sw $t4, 524($t0)
	sw $t4, 528($t0)

	# draw eyes
DRAW_LOOKING_DOWN:	bne $t5, 0, DRAW_LOOKING_UP
					sw $t7, 132($t0)
					sw $t7, 140($t0)
					sw $t6, 260($t0)
					sw $t6, 268($t0)
					j FINISHED_DRAWING_DOODLER

DRAW_LOOKING_UP:	bne $t5, 1, DRAW_SPRING
					sw $t6, 132($t0)
					sw $t6, 140($t0)
					sw $t7, 260($t0)
					sw $t7, 268($t0)
					j FINISHED_DRAWING_DOODLER

DRAW_SPRING:		bne $t5, 2, DRAW_ROCKET
					sw $t6, 132($t0)
					sw $t6, 140($t0)
					sw $t7, 260($t0)
					sw $t7, 268($t0)
					#drawing the actual spring
					li $t6, 0xcecece # light gray
					li $t7, 0x999999 # dark gray
					sw $t6, 636($t0)
					sw $t6, 640($t0)
					sw $t6, 644($t0)
					sw $t6, 648($t0)
					sw $t6, 652($t0)
					sw $t6, 656($t0)
					sw $t6, 660($t0)
					sw $t7, 768($t0)
					sw $t7, 772($t0)
					sw $t7, 776($t0)
					sw $t7, 780($t0)
					sw $t7, 784($t0)
					sw $t6, 892($t0)
					sw $t6, 896($t0)
					sw $t6, 900($t0)
					sw $t6, 904($t0)
					sw $t6, 908($t0)
					sw $t6, 912($t0)
					sw $t6, 916($t0)
					j FINISHED_DRAWING_DOODLER

DRAW_ROCKET:		subi $t0, $t0, 128 # move cursor up by 1 row
					subi $t0, $t0, 4 # move cursor left by 1 col
					# drawing head
					sw $t1, 12($t0)
					sw $t1, 136($t0)
					sw $t1, 140($t0)
					sw $t1, 144($t0)
					# drawing body
					sw $t3, 268($t0)
					sw $t3, 396($t0)
					sw $t3, 520($t0)
					sw $t3, 524($t0)
					sw $t3, 528($t0)
					# drawing shoes(arms)
					sw $t4, 388($t0)
					sw $t4, 404($t0)
					sw $t4, 512($t0)
					sw $t4, 516($t0)
					sw $t4, 532($t0)
					sw $t4, 536($t0)
					# drawing eyes
					sw $t6, 392($t0)
					sw $t6, 400($t0)
					sw $t7, 264($t0)
					sw $t7, 272($t0)
					# drawing fire
					li $t6, 0xfc6602
					li $t7, 0xfce302
					sw $t6, 648($t0)
					sw $t7, 652($t0)
					sw $t6, 656($t0)
					sw $t6, 772($t0)
					sw $t6, 780($t0)
					sw $t6, 788($t0)


FINISHED_DRAWING_DOODLER:	jr $ra

drawPowerups:	
	lw $t0, scrollCounter
	la $t1, platformsArray
	li $t2, 0xffffff # white for testing
	lw $t3, displayBufferAddress
	lw $t1, 8($t1) # targets address of 3rd platform and loads value
CHECK_FOR_ROCKET_POWERUP:	bne $t0, 4, CHECK_FOR_SPRING_POWERUP
				# set the rocket's location to be on top of 3rd platform
				subi $t1, $t1, 128
				sw $t1, rocketPowerupLocation
				# draw the rocket
				add $t1, $t1, $t3 # target address in buffer of left bottom pixel of rocket
				#sw $t2, ($t1) # make that pixel white	
					subi $t1, $t1, 512 # top left pixel
					subi $t1, $t1, 128 # move cursor up by 1 row

					li $t7, 0xff0000 # red for head and arms
					li $t3, 0xffffff # white for body

					# drawing head
					sw $t7, 12($t1)
					sw $t7, 136($t1)
					sw $t7, 140($t1)
					sw $t7, 144($t1)
					# drawing body
					sw $t3, 268($t1)
					sw $t3, 396($t1)
					sw $t3, 520($t1)
					sw $t3, 524($t1)
					sw $t3, 528($t1)
					# drawing shoes(arms)
					sw $t7, 388($t1)
					sw $t7, 404($t1)
					sw $t7, 512($t1)
					sw $t7, 516($t1)
					sw $t7, 532($t1)
					sw $t7, 536($t1)
					# drawing eyes (more body)
					sw $t3, 392($t1)
					sw $t3, 400($t1)
					sw $t3, 264($t1)
					sw $t3, 272($t1)
					# drawing fire
					li $t6, 0xfc6602
					li $t7, 0xfce302
					sw $t6, 648($t1)
					sw $t7, 652($t1)
					sw $t6, 656($t1)
					sw $t6, 772($t1)
					sw $t6, 780($t1)
					sw $t6, 788($t1)
				j FINISHED_DRAWING_POWERUPS
				
CHECK_FOR_SPRING_POWERUP:	bne $t0, 2, FINISHED_DRAWING_POWERUPS
				# set the spring's location to be on top of 3rd platform
				subi $t1, $t1, 128
				sw $t1, springPowerupLocation
				# draw the spring
				add $t1, $t1, $t3 # target address in buffer of left bottom pixel of spring
				#li $t2, 0xff0000
				#sw $t2, ($t1) # make that pixel red
				li $t6, 0xcecece # light gray
					li $t7, 0x999999 # dark gray
					subi $t1, $t1, 512 # top left pixel
					subi $t1, $t1, 508

					sw $t6, 636($t1)
					sw $t6, 640($t1)
					sw $t6, 644($t1)
					sw $t6, 648($t1)
					sw $t6, 652($t1)
					sw $t6, 656($t1)
					sw $t6, 660($t1)
					sw $t7, 768($t1)
					sw $t7, 772($t1)
					sw $t7, 776($t1)
					sw $t7, 780($t1)
					sw $t7, 784($t1)
					sw $t6, 892($t1)
					sw $t6, 896($t1)
					sw $t6, 900($t1)
					sw $t6, 904($t1)
					sw $t6, 908($t1)
					sw $t6, 912($t1)
					sw $t6, 916($t1)

FINISHED_DRAWING_POWERUPS:	jr $ra
	
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
	lw $t0, displayBufferAddress
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
	lw $t0, displayBufferAddress
	lw $t1, backgroundColour
	lw $t2, doodlerLocation
	
	subi $t2, $t2, 4 # recolour a 7x7 square instead of a 5x5 one
	addi $t2, $t2, 384
	
	addi $t1, $t1, 10
	addi $t4, $zero, 128
	addi $t5, $zero, 8
	div $t2, $t4
	mflo $t4
	mult $t4, $t5
	mflo $t4 # this is the amount you need to add to the colour of the bg
	add $t1, $t1, $t4 # this is the appropriate colour for the row
	
	add $t3, $t0, $t2 # create $t3 starting at left-bottommost pixel of doodler, will be used as cursor
	
	add $t4, $zero, $zero # set outer init value to 0
	#addi $t5, $zero, 5 # set outer loop stop val to 5 (outer loop repeats 5 times)
	addi $t5, $zero, 8
	add $t6, $zero, $zero # set inner init value to 0
	#addi $t7, $zero, 5 # set inner loop stop val to 5 (inner loop repeats 5 times)
	addi $t7, $zero, 7
START_OUTER_LOOP_DRAWING_OVER_DOODLER:	beq $t4, $t5, EXIT_OUTER_LOOP_DRAWING_OVER_DOODLER # branch if counter is 5

START_INNER_LOOP_DRAWING_OVER_DOODLER:	beq $t6, $t7, EXIT_INNER_LOOP_DRAWING_OVER_DOODLER # branch if counter is 5
					sw $t1, 0($t3) # paint the pixel at the cursor's address
					addi $t3, $t3, 4 # increment the cursor by 4 to target the next address in display
UPDATE_INNER_LOOP_DRAWING_OVER_DOODLER: 	addi $t6, $t6, 1 # increment counter by 1
			 		j START_INNER_LOOP_DRAWING_OVER_DOODLER
EXIT_INNER_LOOP_DRAWING_OVER_DOODLER: 	#subi $t3, $t3, 20 # set cursor to first
					subi $t3, $t3, 28
					subi $t3, $t3, 128 # pixel of next row
					add $t6, $zero, $zero # reset inner init value to 0
					
UPDATE_OUTER_LOOP_DRAWING_OVER_DOODLER: 	addi $t4, $t4, 1 # increment counter by 1
						subi $t1, $t1, 8
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
	
resetJumpSpeed:
	addi $t0, $zero, 1
	sw $t0, jumpSpeed
	jr $ra

jump:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	addi $t0, $zero, 0
	sw $t0, doodlerState # set doodler state to 1 (jumping)
	
	lw $t0, doodlerLocation
	
	add $t8, $zero, $zero # set init value to 0
	addi $t9, $zero, 13 # set loop stop val to 13 (loop repeats 13 times)
START_LOOP_JUMP_UP:	beq $t8, $t9, EXIT_LOOP_JUMP_UP # branch if counter is 13

			sw $t8, jumpLoopCounter
			sw $t9, jumpLoopStopVal
			
			# 1. Update Doodler's position by 1 up
			jal recolourPixelsOverDoodler
			jal keyPressHandler
			
			# adjust jump speed for realistic physics
			lw $t0, doodlerLocation
			#lw $t8, jumpSpeed
			#addi $t9, $zero, 128
			#mult $t8, $t9
			#mflo $t8
			
			subi $t0, $t0, 128
			sw $t0, doodlerLocation
			
			#lw $t8, jumpSpeed
			#addi $t8, $t8, 1
			#sw $t8, jumpSpeed
			
			jal handleScroll
			
			
			jal drawPlatforms
			jal drawPowerups
	
			# 2. Redraw Doodler
			jal drawDoodler
			jal sleep
			
			# adjustment for changing physics with the sleep function
			#lw $t8, jumpSpeed
			#addi $t9, $zero, 2
			#mult $t8, $t9
			#mflo $t8
			#addi $t8, $t8, 5
			#sw $t8, jumpSpeed
			
			lw $t8, jumpLoopCounter
			lw $t9, jumpLoopStopVal
			
UPDATE_LOOP_JUMP_UP: 	addi $t8, $t8, 1 # increment counter by 1
			j START_LOOP_JUMP_UP
EXIT_LOOP_JUMP_UP: 	j fall

			lw $ra, ($sp)
			addi $sp, $sp, 4
			jr $ra

springJump:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	addi $t0, $zero, 2
	sw $t0, doodlerState # set doodler state to 2 (spring)
	
	lw $t0, doodlerLocation
	
	add $t8, $zero, $zero # set init value to 0
	addi $t9, $zero, 26 # set loop stop val to 26 (loop repeats 26 times)
START_LOOP_SPRING_JUMP_UP:	beq $t8, $t9, EXIT_LOOP_SPRING_JUMP_UP # branch if counter is 13

			sw $t8, jumpLoopCounter
			sw $t9, jumpLoopStopVal
			
			# 1. Update Doodler's position by 1 up
			jal recolourPixelsOverDoodler
			jal keyPressHandler
			
			# adjust jump speed for realistic physics
			lw $t0, doodlerLocation
			#lw $t8, jumpSpeed
			#addi $t9, $zero, 128
			#mult $t8, $t9
			#mflo $t8
			
			subi $t0, $t0, 128
			sw $t0, doodlerLocation
			
			#lw $t8, jumpSpeed
			#addi $t8, $t8, 1
			#sw $t8, jumpSpeed
			
			jal handleScroll
			
			
			jal drawPlatforms
			jal drawPowerups
	
			# 2. Redraw Doodler
			jal drawDoodler
			jal sleep
			
			# adjustment for changing physics with the sleep function
			#lw $t8, jumpSpeed
			#addi $t9, $zero, 2
			#mult $t8, $t9
			#mflo $t8
			#addi $t8, $t8, 5
			#sw $t8, jumpSpeed
			
			lw $t8, jumpLoopCounter
			lw $t9, jumpLoopStopVal
			
UPDATE_LOOP_SPRING_JUMP_UP: 	addi $t8, $t8, 1 # increment counter by 1
				j START_LOOP_SPRING_JUMP_UP
EXIT_LOOP_SPRING_JUMP_UP: 	addi $t0, $zero, 0
				sw $t0, doodlerState # set doodler state to 0 (falling)
				j fall

			lw $ra, ($sp)
			addi $sp, $sp, 4
			jr $ra
	
rocketJump:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	addi $t0, $zero, 3
	sw $t0, doodlerState # set doodler state to 3 (rocket)
	
	lw $t0, doodlerLocation
	
	add $t8, $zero, $zero # set init value to 0
	addi $t9, $zero, 100 # set loop stop val to 100 (loop repeats 26 times)
START_LOOP_ROCKET_JUMP_UP:	beq $t8, $t9, EXIT_LOOP_ROCKET_JUMP_UP # branch if counter is 13

			sw $t8, jumpLoopCounter
			sw $t9, jumpLoopStopVal
			
			# 1. Update Doodler's position by 1 up
			jal recolourPixelsOverDoodler
			jal keyPressHandler
			
			# adjust jump speed for realistic physics
			lw $t0, doodlerLocation
			#lw $t8, jumpSpeed
			#addi $t9, $zero, 128
			#mult $t8, $t9
			#mflo $t8
			
			subi $t0, $t0, 128
			sw $t0, doodlerLocation
			
			#lw $t8, jumpSpeed
			#addi $t8, $t8, 1
			#sw $t8, jumpSpeed
			
			jal handleScroll
			
			
			jal drawPlatforms
			jal drawPowerups
	
			# 2. Redraw Doodler
			jal drawDoodler
			jal sleep
			
			# adjustment for changing physics with the sleep function
			#lw $t8, jumpSpeed
			#addi $t9, $zero, 2
			#mult $t8, $t9
			#mflo $t8
			#addi $t8, $t8, 5
			#sw $t8, jumpSpeed
			
			lw $t8, jumpLoopCounter
			lw $t9, jumpLoopStopVal
			
UPDATE_LOOP_ROCKET_JUMP_UP: 	addi $t8, $t8, 1 # increment counter by 1
				j START_LOOP_ROCKET_JUMP_UP
EXIT_LOOP_ROCKET_JUMP_UP: 	addi $t0, $zero, 0
				sw $t0, doodlerState # set doodler state to 0 (falling)
				j fall
	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
			
handleScroll:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	# if doodlerLocation < yellow stripe
	lw $t0, doodlerLocation
	addi $t1, $zero, 256 # the starting pixel of the yellow stripe
	
	bgt $t0, $t1, DONT_SCROLL # if the doodler is in the lower half of the screen, don't scroll
		# increment scrollCounter by 1
		lw $t2, scrollCounter
		addi $t2, $t2, 1
		sw $t2, scrollCounter
		# then add some constant times 128 to all objects
		jal scrollObjects
		# generate a new platform to replace the one at index nextPlatformToDraw and increment that index by 1
		jal generatePlatforms
		# redraw all the platforms (jump function takes care of doodler)
		jal drawBackground
		jal drawPlatforms
		# generate powerups
		jal drawPowerups
DONT_SCROLL:
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	
scrollObjects: # add a constant times 128 to all objects
	addi $t2, $zero, 25 # the scroll constant (moves yellow stripe to green stripe)
	addi $t3, $zero, 128
	mult $t2, $t3
	mflo $t2
	
	lw $t0, doodlerLocation
	
	# scroll doodler
	add $t0, $t0, $t2
	sw $t0, doodlerLocation
	
	la $t5, platformsArray
	lw $t5, 0($t5) # load platform in the yellow stripe
	add $t5, $t5, $t2 # scroll that top platform in the yellow stripe 25 units down
	sw $t5, bottomPlatformLocation
	

	# scroll platforms
#	add $t3, $zero, $zero # set init value to 0
#	addi $t4, $zero, 4 # set loop stop val to 4 (loop repeats 4 times)
#START_LOOP_SCROLLING_PLATFORMS:		beq $t3, $t4, EXIT_LOOP_SCROLLING_PLATFORMS # branch if counter is 4
#					sll $t6, $t3, 2
#					add $t6, $t5, $t6 # t6 is the addr of the curr platform
#					
#					lw $t7, ($t6)
#					add $t7, $t7, $t2
#					sw $t7, ($t6)
#					
#UPDATE_LOOP_SCROLLING_PLATFORMS:	addi $t3, $t3, 1
#					j START_LOOP_SCROLLING_PLATFORMS
#EXIT_LOOP_SCROLLING_PLATFORMS:		
	jr $ra	

			
fall:
	#addi $sp, $sp, -4
	#sw $ra, ($sp)
	# 4. Check for platform collision
	# if platformLocation - 132 <= doodlerLocation <= platformLocation - 122
	#	platformLocation - 132 - doodlerLocation <= 0 <= platformLocation - 122 - doodlerLocation
	# checking platform 1
	
	addi $s0, $zero, 1
	sw $s0, doodlerState # set doodler state to 0 (falling)
	
	lw $s0, doodlerLocation
	la $t8, platformsArray
	add $t0, $zero, $zero
	addi $t4, $zero, 4
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
		       		add $a0, $t1, $zero # store the platform location value that was collided with
		       		j HANDLE_COLLISION # handle colliding with platform 3
UPDATE_LOOP_CHECKING_PLATFORMS:	addi $t0, $t0, 1
				j START_LOOP_CHECKING_PLATFORMS
END_LOOP_CHECKING_PLATFORMS:
		       	
CHECKING_BOTTOM_OF_SCREEN:
			addi $t1, $zero, 4092 # last possible pixel
			ble $s0, $t1, NO_COLLISION	
		       	j gameOver # handle colliding with bottom of screen
			
	# 4.1. If Doodler's position is on top of platform, restart jump from current position
HANDLE_COLLISION:	jal checkCollisionWithPowerups
			jal updateScore
			jal resetJumpSpeed
			
			# if the doodler state is now 2, initiate spring
			lw $t0, doodlerState
			bne $t0, 2, CHECK_FOR_ROCKET_INITIATION
			addi $t0, $zero, -1
			sw $t0, springPowerupLocation
			j springJump
			
CHECK_FOR_ROCKET_INITIATION:	bne $t0, 3, NO_POWERUP # if the doodler state is now 3, initiate rocket
				addi $t0, $zero, -1
				sw $t0, rocketPowerupLocation
				j rocketJump
				
NO_POWERUP:			j jump

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
			
			# adjust fall speed for realistic physics
			lw $t0, doodlerLocation
			#lw $t8, jumpSpeed
			#subi $t8, $t8, 1
			#sw $t8, jumpSpeed
			#addi $t9, $zero, 128
			#mult $t8, $t9
			#mflo $t8
			
			addi $t0, $t0, 128
			sw $t0, doodlerLocation
			
			jal drawPlatforms
			jal drawPowerups
			
			# adjustment for changing physics with the sleep function
			#lw $t8, jumpSpeed
			#addi $t9, $zero, 2
			#div $t8, $t9
			#mflo $t8
			#subi $t8, $t8, 5
			#sw $t8, jumpSpeed
	
			# 2. Redraw Doodler
			jal drawDoodler
			jal sleep
			
UPDATE_LOOP_JUMP_DOWN: 	#addi $t8, $t8, 1 # increment counter by 1
			
EXIT_LOOP_JUMP_DOWN: 	j fall

	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	
checkCollisionWithPowerups:	# $a0 is the location of the platform the doodler jumped on
	lw $t0, doodlerLocation
	lw $t1, rocketPowerupLocation
	subi $t2, $a0, 128 # location of where the powerup should be
CHECK_ROCKET_LOCATION:		bne $t1, $t2, CHECK_SPRING_LOCATION
				addi $t0, $zero, 3
				sw $t0, doodlerState
				j DONE_CHECKING_LOCATION
				
CHECK_SPRING_LOCATION:		lw $t1, springPowerupLocation
				bne $t1, $t2, DONE_CHECKING_LOCATION
				addi $t0, $zero, 2
				sw $t0, doodlerState
DONE_CHECKING_LOCATION:		jr $ra
	
updateScore:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	addi $a0, $zero, 1 # initialize function return val
	addi $s0, $zero, 7 # initialize loop counter (will count in reverse)
START_LOOP_UPDATE_SCORE:	beq $a0, $zero, EXIT_LOOP_UPDATE_SCORE # branch if $a0 is 0 to EXIT_LOOP_UPDATE_SCORE
				beq $s0, -1, gameOver # branch if loop counter is -1 to gameOver
				addi $sp, $sp, -4
				sw $s0, ($sp) # put curr digit on stack
				jal checkScoreDigit # check score at the current digit (loop counter will tell you the current digit) (this will update $a0)
UPDATE_LOOP_UPDATE_SCORE:	subi $s0, $s0, 1 # subtract counter by 1
				j START_LOOP_UPDATE_SCORE # jump
EXIT_LOOP_UPDATE_SCORE:		jal printScore # call printScore
				# print space
				li $v0, 4
    				la $a0, spaceChar
    				syscall
    				# print digits
    				li $v0, 1
    				la $t0, score
    				lw $a0, ($t0)
    				syscall
    				lw $a0, 4($t0)
    				syscall
    				lw $a0, 8($t0)
    				syscall
    				lw $a0, 12($t0)
    				syscall
    				lw $a0, 16($t0)
    				syscall
    				lw $a0, 20($t0)
    				syscall
    				lw $a0, 24($t0)
    				syscall
    				lw $a0, 28($t0)
    				syscall
    				
				
    				
	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	
printScore:	
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal clearScore # clear score
	lw $t9, displayBufferAddress # load displayBufferAddress
	la $t6, score # load the address of the score array
	addi $t8, $zero, 0 # set loop counter to 0
	addi $t7, $zero, 0 # boolean value to say if you wanna start printing numbers
START_LOOP_PRINTING_SCORE:	bge $t8, 8, EXIT_LOOP_PRINTING_SCORE # branch if the loop counter is greater than or equal to 8 to EXIT
				# obtain the address in the array to the current score digit (is $t6)
				sll $t5, $t8, 2 
				add $t5, $t6, $t5 # this is the addr(score[curr digit])
				lw $t5, ($t5) # save the current score digit
				# calculate 4 + (16*loop counter)
				addi $t4, $zero, 16
				mult $t4, $t8
				mflo $t4
				addi $t4, $t4, 4
				# sum above and displayBufferAddress
				add $t4, $t4, $t9
				
	CHECK_ZERO:	bne $t5, 0, CHECK_ONE # branch if not zero to CHECK_ONE
			beq $t7, 0, UPDATE_LOOP_PRINTING_SCORE # branch if boolean is 0 to UPDATE
			# put sum ($t4) on stack
			addi $sp, $sp, -4
			sw $t4, ($sp)
			jal drawZero # drawZero
			j UPDATE_LOOP_PRINTING_SCORE # jump to UPDATE
			
	CHECK_ONE:	bne $t5, 1, CHECK_TWO # branch if not one to CHECK_TWO
			addi $t7, $zero, 1 # set boolean value to 1
			# put sum on stack
			addi $sp, $sp, -4
			sw $t4, ($sp)
			jal drawOne # drawOne
			j UPDATE_LOOP_PRINTING_SCORE # jump to UPDATE

	CHECK_TWO:	bne $t5, 2, CHECK_THREE # branch if not one to CHECK_THREE
			addi $t7, $zero, 1 # set boolean value to 1
			# put sum on stack
			addi $sp, $sp, -4
			sw $t4, ($sp)
			jal drawTwo # drawTwo
			j UPDATE_LOOP_PRINTING_SCORE # jump to UPDATE

	CHECK_THREE:	bne $t5, 3, CHECK_FOUR # branch if not one to CHECK_FOUR
			addi $t7, $zero, 1 # set boolean value to 1
			# put sum on stack
			addi $sp, $sp, -4
			sw $t4, ($sp)
			jal drawThree # drawThree
			j UPDATE_LOOP_PRINTING_SCORE # jump to UPDATE

	CHECK_FOUR:	bne $t5, 4, CHECK_FIVE # branch if not one to CHECK_FIVE
			addi $t7, $zero, 1 # set boolean value to 1
			# put sum on stack
			addi $sp, $sp, -4
			sw $t4, ($sp)
			jal drawFour # drawFour
			j UPDATE_LOOP_PRINTING_SCORE # jump to UPDATE

	CHECK_FIVE:	bne $t5, 5, CHECK_SIX # branch if not one to CHECK_SIX
			addi $t7, $zero, 1 # set boolean value to 1
			# put sum on stack
			addi $sp, $sp, -4
			sw $t4, ($sp)
			jal drawFive # drawFive
			j UPDATE_LOOP_PRINTING_SCORE # jump to UPDATE

	CHECK_SIX:	bne $t5, 6, CHECK_SEVEN # branch if not one to CHECK_SEVEN
			addi $t7, $zero, 1 # set boolean value to 1
			# put sum on stack
			addi $sp, $sp, -4
			sw $t4, ($sp)
			jal drawSix # drawSix
			j UPDATE_LOOP_PRINTING_SCORE # jump to UPDATE

	CHECK_SEVEN:	bne $t5, 7, CHECK_EIGHT # branch if not one to CHECK_EIGHT
			addi $t7, $zero, 1 # set boolean value to 1
			# put sum on stack
			addi $sp, $sp, -4
			sw $t4, ($sp)
			jal drawSeven # drawSeven
			j UPDATE_LOOP_PRINTING_SCORE # jump to UPDATE

	CHECK_EIGHT:	bne $t5, 8, CHECK_NINE # branch if not one to CHECK_NINE
			addi $t7, $zero, 1 # set boolean value to 1
			# put sum on stack
			addi $sp, $sp, -4
			sw $t4, ($sp)
			jal drawEight # drawEight
			j UPDATE_LOOP_PRINTING_SCORE # jump to UPDATE

	CHECK_NINE:	addi $t7, $zero, 1 # set boolean value to 1
			# put sum on stack
			addi $sp, $sp, -4
			sw $t4, ($sp)
			jal drawNine # drawNine
	

UPDATE_LOOP_PRINTING_SCORE:	addi $t8, $t8, 1 # increment the loop counter by 1
				j START_LOOP_PRINTING_SCORE # jump to START	

EXIT_LOOP_PRINTING_SCORE:		
	lw $ra, ($sp)
	addi $sp, $sp, 4
	jr $ra
	
	
checkScoreDigit: # retrieve current digit number on stack
	lw $t9, ($sp) 
	addi $sp, $sp, 4
	# put $ra on stack
	addi $sp, $sp, -4
	sw $ra, ($sp)
	# get address of current digit
	sll $t1, $t9, 2 # multiply current digit by 4
	la $t0, score
	add $t0, $t0, $t1 # correctly target the address of the current digit
	# load current digit
	lw $t1, ($t0)
	
	bge $t1, 9, RESET_CURRENT_DIGIT # branch if current digit == 9
	# if score digit is 6, sum doodlerLocation and 256, put that in $a0, and call drawCool
CHECK_FOR_COOL_NOTIF:	bne $t9, 6, CHECK_FOR_WOW_NOTIF
			lw $t9, doodlerLocation
			addi $a0, $t9, 228
			jal drawCool
			j FINISHED_CHECKING_FOR_NOTIFS
	# if score digit is 5, sum doodlerLocation and 256, put that in $a0, and call drawWow
CHECK_FOR_WOW_NOTIF:	bne $t9, 5, CHECK_FOR_POG_NOTIF
			lw $t9, doodlerLocation
			addi $a0, $t9, 232
			jal drawWow
			j FINISHED_CHECKING_FOR_NOTIFS
	# if score digit is 4, sum doodlerLocation and 256, put that in $a0, and call drawPog
CHECK_FOR_POG_NOTIF:	bne $t9, 4, FINISHED_CHECKING_FOR_NOTIFS
			lw $t9, doodlerLocation
			addi $a0, $t9, 244
			jal drawPog
	
	
FINISHED_CHECKING_FOR_NOTIFS:	addi $t1, $t1, 1 # then increment current digit by 1 
				sw $t1, ($t0) # store score digit in memory
	
				addi $a0, $zero, 0
				lw $ra, ($sp)
				addi $sp, $sp, 4
				jr $ra # and return 0 by setting $a0
	
RESET_CURRENT_DIGIT:	# else if current digit == 9, 
			sw $zero, ($t0) # then set current digit to 0 
			addi $a0, $zero, 1 
			lw $ra, ($sp)
			addi $sp, $sp, 4
			jr $ra # and return 1
			
clearScore:
	lw $t1, backgroundColour
	lw $t0, displayBufferAddress	
	addi $t0, $t0, 4 # address of the current number
	addi $t2, $zero, 0 # loop counter
	addi $t3, $zero, 16 # constant 16
	
	addi $t1, $t1, 10
	
	
START_LOOP_CLEARING_SCREEN:	bge $t2, 8, EXIT_LOOP_CLEARING_SCREEN # branch if loop counter is greater than or equal to 8
	
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	
	addi $t1, $t1, 8
	
	sw $t1, 128($t0)
	sw $t1, 136($t0)
		
	addi $t1, $t1, 8
	
	sw $t1, 256($t0)
	sw $t1, 260($t0)
	sw $t1, 264($t0)
	
	addi $t1, $t1, 8
	
	sw $t1, 384($t0)
	sw $t1, 392($t0)
	
	addi $t1, $t1, 8
	
	sw $t1, 512($t0)
	sw $t1, 516($t0)
	sw $t1, 520($t0)
	
	
UPDATE_LOOP_CLEARING_SCREEN:	addi $t2, $t2, 1
				addi $t0, $t0, 16
				subi $t1, $t1, 32
				j START_LOOP_CLEARING_SCREEN

EXIT_LOOP_CLEARING_SCREEN:	# draw moon
				li $t1, 0xf9f975
				lw $t0, displayBufferAddress
				sw $t1, 4($t0)
				sw $t1, 8($t0)
				sw $t1, 12($t0)
				sw $t1, 16($t0)
				sw $t1, 20($t0)
				sw $t1, 128($t0)
				sw $t1, 132($t0)
				sw $t1, 136($t0)
				sw $t1, 152($t0)
				sw $t1, 256($t0)
				sw $t1, 260($t0)
				sw $t1, 384($t0)
				sw $t1, 388($t0)
				sw $t1, 512($t0)
				sw $t1, 516($t0)
				sw $t1, 640($t0)
				sw $t1, 644($t0)
				sw $t1, 648($t0)
				sw $t1, 664($t0)
				sw $t1, 772($t0)
				sw $t1, 776($t0)
				sw $t1, 780($t0)
				sw $t1, 784($t0)
				sw $t1, 788($t0)
				jr $ra

drawCool:	# offset of upper left pixel of text is in $a0
	lw $s0, displayAddress 
	add $t2, $s0, $a0
	li $t3, 0xff0000
	
	# drawing cool!
	sw $t3, ($t2)
	sw $t3, 4($t2)
	sw $t3, 8($t2)
	sw $t3, 12($t2)
	sw $t3, 20($t2)
	sw $t3, 24($t2)
	sw $t3, 28($t2)
	sw $t3, 32($t2)
	sw $t3, 40($t2)
	sw $t3, 44($t2)
	sw $t3, 48($t2)
	sw $t3, 52($t2)
	sw $t3, 60($t2)
	sw $t3, 76($t2)
	# next row
	sw $t3, 128($t2)
	sw $t3, 148($t2)
	sw $t3, 160($t2)
	sw $t3, 168($t2)
	sw $t3, 180($t2)
	sw $t3, 188($t2)
	sw $t3, 204($t2)
	# next row
	sw $t3, 256($t2)
	sw $t3, 276($t2)
	sw $t3, 288($t2)
	sw $t3, 296($t2)
	sw $t3, 308($t2)
	sw $t3, 316($t2)
	# next row
	sw $t3, 384($t2)
	sw $t3, 388($t2)
	sw $t3, 392($t2)
	sw $t3, 396($t2)
	sw $t3, 404($t2)
	sw $t3, 408($t2)
	sw $t3, 412($t2)
	sw $t3, 416($t2)
	sw $t3, 424($t2)
	sw $t3, 428($t2)
	sw $t3, 432($t2)
	sw $t3, 436($t2)
	sw $t3, 444($t2)
	sw $t3, 448($t2)
	sw $t3, 452($t2)
	sw $t3, 460($t2)
	jr $ra
	
drawWow:	# offset of upper left pixel of text is in $a0
	lw $s0, displayAddress 
	add $t2, $s0, $a0
	li $t3, 0xff0000
	sw $t3, ($t2)
	sw $t3, 8($t2)
	sw $t3, 16($t2)
	sw $t3, 24($t2)
	sw $t3, 28($t2)
	sw $t3, 32($t2)
	sw $t3, 36($t2)
	sw $t3, 44($t2)
	sw $t3, 52($t2)
	sw $t3, 60($t2)
	sw $t3, 68($t2)
	# next row
	sw $t3, 128($t2)
	sw $t3, 136($t2)
	sw $t3, 144($t2)
	sw $t3, 152($t2)
	sw $t3, 164($t2)
	sw $t3, 172($t2)
	sw $t3, 180($t2)
	sw $t3, 188($t2)
	sw $t3, 196($t2)
	# next row
	sw $t3, 256($t2)
	sw $t3, 264($t2)
	sw $t3, 272($t2)
	sw $t3, 280($t2)
	sw $t3, 292($t2)
	sw $t3, 300($t2)
	sw $t3, 308($t2)
	sw $t3, 316($t2)
	# next row
	sw $t3, 384($t2)
	sw $t3, 388($t2)
	sw $t3, 392($t2)
	sw $t3, 396($t2)
	sw $t3, 400($t2)
	sw $t3, 408($t2)
	sw $t3, 412($t2)
	sw $t3, 416($t2)
	sw $t3, 420($t2)
	sw $t3, 428($t2)
	sw $t3, 432($t2)
	sw $t3, 436($t2)
	sw $t3, 440($t2)
	sw $t3, 444($t2)
	sw $t3, 452($t2)
	jr $ra
	
drawPog:	# offset of upper left pixel of text is in $a0
	lw $s0, displayAddress 
	add $t2, $s0, $a0
	li $t3, 0xff0000
	sw $t3, 48($t2)
	# next row
	sw $t3, 128($t2)
	sw $t3, 132($t2)
	sw $t3, 136($t2)
	sw $t3, 144($t2)
	sw $t3, 148($t2)
	sw $t3, 152($t2)
	sw $t3, 160($t2)
	sw $t3, 164($t2)
	sw $t3, 168($t2)
	sw $t3, 176($t2)
	# next row
	sw $t3, 256($t2)
	sw $t3, 264($t2)
	sw $t3, 272($t2)
	sw $t3, 280($t2)
	sw $t3, 288($t2)
	sw $t3, 296($t2)
	# next row
	sw $t3, 384($t2)
	sw $t3, 388($t2)
	sw $t3, 392($t2)
	sw $t3, 400($t2)
	sw $t3, 404($t2)
	sw $t3, 408($t2)
	sw $t3, 416($t2)
	sw $t3, 420($t2)
	sw $t3, 424($t2)
	sw $t3, 432($t2)
	# next row
	sw $t3, 512($t2)
	sw $t3, 552($t2)
	# next row
	sw $t3, 640($t2)
	sw $t3, 672($t2)
	sw $t3, 676($t2)
	sw $t3, 680($t2)
	jr $ra
	
	
gameOver:	
	# write Game Over on screen
	jal writeGameOver
	
	# reset score
	la $t0, score
	sw $zero, 0($t0)
	sw $zero, 4($t0)
	sw $zero, 8($t0)
	sw $zero, 12($t0)
	sw $zero, 16($t0)
	sw $zero, 20($t0)
	sw $zero, 24($t0)
	sw $zero, 28($t0)
	
	# reset initial platform
	addi $t0, $zero, 4020
	sw $t0, bottomPlatformLocation
	
	jal waitForStart
	j main
	
writeGameOver:
	lw $t0, displayBufferAddress # $t0 stores the base address for display
	li $t2, 0x00ff00 # $t2 stores the green colour code
	# write G
	sw $t2, 520($t0) # paint the first (top-left) unit green.
	sw $t2, 524($t0) # paint the second unit on the first row green. Why$t0+4?
	sw $t2, 528($t0)
	sw $t2, 532($t0)
	sw $t2, 644($t0) # paint the first unit on the second row green. Why +128?
	sw $t2, 648($t0)
	sw $t2, 652($t0)
	sw $t2, 656($t0)
	sw $t2, 660($t0) # paint the first unit on the third row green
	sw $t2, 664($t0)
	sw $t2, 772($t0)
	sw $t2, 776($t0)
	sw $t2, 788($t0) # paint the first unit on the fourth row green
	sw $t2, 792($t0)
	sw $t2, 900($t0)
	sw $t2, 920($t0)
	sw $t2, 1028($t0)
	sw $t2, 1156($t0)
	sw $t2, 1168($t0) # paint the first unit on the third row green
	sw $t2, 1172($t0)
	sw $t2, 1176($t0)
	sw $t2, 1284($t0)
	sw $t2, 1300($t0) # paint the first unit on the fourth row green
	sw $t2, 1304($t0)
	sw $t2, 1412($t0)
	sw $t2, 1416($t0)
	sw $t2, 1428($t0)
	sw $t2, 1432($t0) # paint the first unit on the third row green
	sw $t2, 1540($t0)
	sw $t2, 1544($t0)
	sw $t2, 1548($t0)
	sw $t2, 1552($t0) # paint the first unit on the fourth row green
	sw $t2, 1556($t0)
	sw $t2, 1560($t0)
	sw $t2, 1672($t0)
	sw $t2, 1676($t0)
	sw $t2, 1680($t0) # paint the first unit on the third row green
	sw $t2, 1684($t0)
	# write a
	sw $t2, 676($t0) # paint the first (top-left) unit green.
	sw $t2, 680($t0) # paint the second unit on the first row green. Why$t0+4?
	sw $t2, 684($t0)
	sw $t2, 688($t0)
	sw $t2, 800($t0) # paint the first unit on the second row green. Why +128?
	sw $t2, 804($t0)
	sw $t2, 808($t0)
	sw $t2, 812($t0)
	sw $t2, 816($t0) # paint the first unit on the third row green
	sw $t2, 820($t0)
	sw $t2, 928($t0)
	sw $t2, 932($t0)
	sw $t2, 944($t0) # paint the first unit on the fourth row green
	sw $t2, 948($t0)
	sw $t2, 1056($t0)
	sw $t2, 1076($t0)
	sw $t2, 1188($t0)
	sw $t2, 1192($t0)
	sw $t2, 1196($t0) # paint the first unit on the third row green
	sw $t2, 1204($t0)
	sw $t2, 1312($t0)
	sw $t2, 1316($t0)
	sw $t2, 1320($t0) # paint the first unit on the fourth row green
	sw $t2, 1324($t0)
	sw $t2, 1328($t0)
	sw $t2, 1332($t0)
	sw $t2, 1440($t0)
	sw $t2, 1456($t0) # paint the first unit on the third row green
	sw $t2, 1460($t0)
	sw $t2, 1568($t0)
	sw $t2, 1572($t0)
	sw $t2, 1576($t0) # paint the first unit on the fourth row green
	sw $t2, 1580($t0)
	sw $t2, 1584($t0)
	sw $t2, 1588($t0)
	sw $t2, 1700($t0)
	sw $t2, 1704($t0) # paint the first unit on the third row green
	sw $t2, 1708($t0)
	sw $t2, 1712($t0)
	# write m
	sw $t2, 828($t0) # paint the first (top-left) unit green.
	sw $t2, 832($t0) # paint the second unit on the first row green. Why$t0+4?
	sw $t2, 836($t0)
	sw $t2, 840($t0)
	sw $t2, 848($t0) # paint the first unit on the second row green. Why +128?
	sw $t2, 852($t0)
	sw $t2, 856($t0)
	sw $t2, 956($t0)
	sw $t2, 960($t0) # paint the first unit on the third row green
	sw $t2, 964($t0)
	sw $t2, 968($t0)
	sw $t2, 972($t0)
	sw $t2, 976($t0) # paint the first unit on the fourth row green
	sw $t2, 980($t0)
	sw $t2, 984($t0)
	sw $t2, 988($t0)
	sw $t2, 1084($t0)
	sw $t2, 1088($t0)
	sw $t2, 1096($t0) # paint the first unit on the third row green
	sw $t2, 1100($t0)
	sw $t2, 1104($t0)
	sw $t2, 1112($t0)
	sw $t2, 1116($t0) # paint the first unit on the fourth row green
	sw $t2, 1212($t0)
	sw $t2, 1228($t0)
	sw $t2, 1244($t0)
	sw $t2, 1340($t0)
	sw $t2, 1356($t0) # paint the first unit on the third row green
	sw $t2, 1372($t0)
	sw $t2, 1468($t0)
	sw $t2, 1484($t0)
	sw $t2, 1500($t0) # paint the first unit on the fourth row green
	sw $t2, 1596($t0)
	sw $t2, 1612($t0)
	sw $t2, 1628($t0)
	sw $t2, 1724($t0)
	sw $t2, 1740($t0) # paint the first unit on the third row green
	sw $t2, 1756($t0)
	# write e
	sw $t2, 744($t0) # paint the first (top-left) unit green.
	sw $t2, 748($t0) # paint the second unit on the first row green. Why$t0+4?
	sw $t2, 752($t0)
	sw $t2, 756($t0)
	sw $t2, 868($t0) # paint the first unit on the second row green. Why +128?
	sw $t2, 872($t0)
	sw $t2, 876($t0)
	sw $t2, 880($t0)
	sw $t2, 884($t0) # paint the first unit on the third row green
	sw $t2, 888($t0)
	sw $t2, 996($t0)
	sw $t2, 1000($t0)
	sw $t2, 1012($t0) # paint the first unit on the fourth row green
	sw $t2, 1016($t0)
	sw $t2, 1124($t0)
	sw $t2, 1144($t0)
	sw $t2, 1252($t0)
	sw $t2, 1256($t0)
	sw $t2, 1260($t0) # paint the first unit on the third row green
	sw $t2, 1264($t0)
	sw $t2, 1268($t0)
	sw $t2, 1272($t0)
	sw $t2, 1380($t0) # paint the first unit on the fourth row green
	sw $t2, 1508($t0)
	sw $t2, 1512($t0)
	sw $t2, 1524($t0)
	sw $t2, 1528($t0)
	sw $t2, 1636($t0) # paint the first unit on the third row green
	sw $t2, 1640($t0)
	sw $t2, 1644($t0)
	sw $t2, 1648($t0)
	sw $t2, 1652($t0) # paint the first unit on the fourth row green
	sw $t2, 1656($t0)
	sw $t2, 1768($t0)
	sw $t2, 1772($t0)
	sw $t2, 1776($t0)
	sw $t2, 1780($t0)
	# write O
	sw $t2, 2312($t0) # paint the first (top-left) unit green.
	sw $t2, 2316($t0) # paint the second unit on the first row green. Why$t0+4?
	sw $t2, 2320($t0)
	sw $t2, 2324($t0)
	sw $t2, 2328($t0)
	sw $t2, 2436($t0) # paint the first unit on the second row green. Why +128?
	sw $t2, 2440($t0)
	sw $t2, 2444($t0)
	sw $t2, 2448($t0)
	sw $t2, 2452($t0) # paint the first unit on the third row green
	sw $t2, 2456($t0)
	sw $t2, 2460($t0)
	sw $t2, 2564($t0)
	sw $t2, 2568($t0) # paint the first unit on the fourth row green
	sw $t2, 2584($t0)
	sw $t2, 2588($t0)
	sw $t2, 2692($t0)
	sw $t2, 2716($t0)
	sw $t2, 2820($t0)
	sw $t2, 2844($t0) # paint the first unit on the third row green
	sw $t2, 2948($t0)
	sw $t2, 2972($t0)
	sw $t2, 3076($t0)
	sw $t2, 3100($t0) # paint the first unit on the fourth row green
	sw $t2, 3204($t0)
	sw $t2, 3208($t0)
	sw $t2, 3224($t0)
	sw $t2, 3228($t0)
	sw $t2, 3332($t0) # paint the first unit on the third row green
	sw $t2, 3336($t0)
	sw $t2, 3340($t0)
	sw $t2, 3344($t0)
	sw $t2, 3348($t0) # paint the first unit on the fourth row green
	sw $t2, 3352($t0)
	sw $t2, 3356($t0)
	sw $t2, 3464($t0)
	sw $t2, 3468($t0)
	sw $t2, 3472($t0)
	sw $t2, 3476($t0)
	sw $t2, 3480($t0)
	# write v
	sw $t2, 2596($t0) # paint the first (top-left) unit green.
	sw $t2, 2620($t0) # paint the second unit on the first row green. Why$t0+4?
	sw $t2, 2724($t0)
	sw $t2, 2748($t0)
	sw $t2, 2852($t0)
	sw $t2, 2856($t0) # paint the first unit on the second row green. Why +128?
	sw $t2, 2872($t0)
	sw $t2, 2876($t0)
	sw $t2, 2980($t0)
	sw $t2, 2984($t0) # paint the first unit on the third row green
	sw $t2, 3000($t0)
	sw $t2, 3004($t0)
	sw $t2, 3112($t0)
	sw $t2, 3116($t0) # paint the first unit on the fourth row green
	sw $t2, 3124($t0)
	sw $t2, 3128($t0)
	sw $t2, 3240($t0)
	sw $t2, 3244($t0)
	sw $t2, 3248($t0)
	sw $t2, 3252($t0) # paint the first unit on the third row green
	sw $t2, 3256($t0)
	sw $t2, 3372($t0)
	sw $t2, 3376($t0)
	sw $t2, 3380($t0) # paint the first unit on the fourth row green
	sw $t2, 3504($t0)
	# write e
	sw $t2, 2632($t0) # paint the first (top-left) unit green.
	sw $t2, 2636($t0) # paint the second unit on the first row green. Why$t0+4?
	sw $t2, 2640($t0)
	sw $t2, 2644($t0)
	sw $t2, 2756($t0)
	sw $t2, 2760($t0) # paint the first unit on the second row green. Why +128?
	sw $t2, 2764($t0)
	sw $t2, 2768($t0)
	sw $t2, 2772($t0)
	sw $t2, 2776($t0) # paint the first unit on the third row green
	sw $t2, 2884($t0)
	sw $t2, 2888($t0)
	sw $t2, 2900($t0)
	sw $t2, 2904($t0) # paint the first unit on the fourth row green
	sw $t2, 3012($t0)
	sw $t2, 3032($t0)
	sw $t2, 3140($t0)
	sw $t2, 3144($t0)
	sw $t2, 3148($t0)
	sw $t2, 3152($t0) # paint the first unit on the third row green
	sw $t2, 3156($t0)
	sw $t2, 3160($t0)
	sw $t2, 3268($t0)
	sw $t2, 3396($t0) # paint the first unit on the fourth row green
	sw $t2, 3400($t0)
	sw $t2, 3412($t0)
	sw $t2, 3416($t0)
	sw $t2, 3524($t0)
	sw $t2, 3528($t0) # paint the first unit on the third row green
	sw $t2, 3532($t0)
	sw $t2, 3536($t0)
	sw $t2, 3540($t0)
	sw $t2, 3544($t0) # paint the first unit on the fourth row green
	sw $t2, 3656($t0)
	sw $t2, 3660($t0)
	sw $t2, 3664($t0)
	sw $t2, 3668($t0)
	# write r
	sw $t2, 2528($t0) # paint the first (top-left) unit green.
	sw $t2, 2536($t0) # paint the second unit on the first row green. Why$t0+4?
	sw $t2, 2540($t0)
	sw $t2, 2544($t0)
	sw $t2, 2656($t0)
	sw $t2, 2660($t0) # paint the first unit on the second row green. Why +128?
	sw $t2, 2664($t0)
	sw $t2, 2668($t0)
	sw $t2, 2672($t0)
	sw $t2, 2676($t0) # paint the first unit on the third row green
	sw $t2, 2784($t0)
	sw $t2, 2788($t0)
	sw $t2, 2792($t0)
	sw $t2, 2796($t0) # paint the first unit on the fourth row green
	sw $t2, 2800($t0)
	sw $t2, 2804($t0)
	sw $t2, 2808($t0)
	sw $t2, 2912($t0) # paint the first (top-left) unit green.
	sw $t2, 2916($t0) # paint the second unit on the first row green. Why$t0+4?
	sw $t2, 2936($t0)
	sw $t2, 3040($t0)
	sw $t2, 3168($t0)
	sw $t2, 3296($t0) # paint the first unit on the second row green. Why +128?
	sw $t2, 3424($t0)
	sw $t2, 3552($t0)
	
	jr $ra		
	
drawZero: # requires x (top left corner of number to be drawn) on the stack
	# retrieve x on stack
	lw $t0, ($sp) #Here you set $t0 to x
	addi $sp, $sp, 4
	li $t1, 0xff0000 # $t1 stores the red colour code
	
	# 0
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 136($t0)
	sw $t1, 264($t0)
	sw $t1, 392($t0)
	sw $t1, 520($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 512($t0)
	sw $t1, 516($t0)
	
	jr $ra

drawOne: # requires x (top left corner of number to be drawn) on the stack
	# retrieve x on stack
	lw $t0, ($sp) #Here you set $t0 to x
	addi $sp, $sp, 4
	li $t1, 0xff0000 # $t1 stores the red colour code
	
	# 1
	sw $t1, 8($t0)
	sw $t1, 136($t0)
	sw $t1, 264($t0)
	sw $t1, 392($t0)
	sw $t1, 520($t0)
	
	jr $ra

drawTwo: # requires x (top left corner of number to be drawn) on the stack
	# retrieve x on stack
	lw $t0, ($sp) #Here you set $t0 to x
	addi $sp, $sp, 4
	li $t1, 0xff0000 # $t1 stores the red colour code
	
	# 2
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 136($t0)
	sw $t1, 264($t0)
	sw $t1, 520($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 512($t0)
	sw $t1, 516($t0)
	sw $t1, 260($t0)
	
	jr $ra

drawThree: # requires x (top left corner of number to be drawn) on the stack
	# retrieve x on stack
	lw $t0, ($sp) #Here you set $t0 to x
	addi $sp, $sp, 4
	li $t1, 0xff0000 # $t1 stores the red colour code
	
	# 3
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 136($t0)
	sw $t1, 264($t0)
	sw $t1, 392($t0)
	sw $t1, 520($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	sw $t1, 516($t0)
	sw $t1, 260($t0)
	
	jr $ra

drawFour: # requires x (top left corner of number to be drawn) on the stack
	# retrieve x on stack
	lw $t0, ($sp) #Here you set $t0 to x
	addi $sp, $sp, 4
	li $t1, 0xff0000 # $t1 stores the red colour code
	
	# 4
	sw $t1, ($t0)
	sw $t1, 8($t0)
	sw $t1, 136($t0)
	sw $t1, 264($t0)
	sw $t1, 392($t0)
	sw $t1, 520($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 260($t0)
	
	jr $ra

drawFive: # requires x (top left corner of number to be drawn) on the stack
	# retrieve x on stack
	lw $t0, ($sp) #Here you set $t0 to x
	addi $sp, $sp, 4
	li $t1, 0xff0000 # $t1 stores the red colour code
	
	# 5
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 264($t0)
	sw $t1, 392($t0)
	sw $t1, 520($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	sw $t1, 516($t0)
	sw $t1, 260($t0)
	
	jr $ra

drawSix: # requires x (top left corner of number to be drawn) on the stack
	# retrieve x on stack
	lw $t0, ($sp) #Here you set $t0 to x
	addi $sp, $sp, 4
	li $t1, 0xff0000 # $t1 stores the red colour code
	
	# 6
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 264($t0)
	sw $t1, 392($t0)
	sw $t1, 520($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 512($t0)
	sw $t1, 516($t0)
	sw $t1, 260($t0)
	
	jr $ra

drawSeven: # requires x (top left corner of number to be drawn) on the stack
	# retrieve x on stack
	lw $t0, ($sp) #Here you set $t0 to x
	addi $sp, $sp, 4
	li $t1, 0xff0000 # $t1 stores the red colour code
	
	# 7
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 136($t0)
	sw $t1, 264($t0)
	sw $t1, 392($t0)
	sw $t1, 520($t0)
	
	jr $ra

drawEight: # requires x (top left corner of number to be drawn) on the stack
	# retrieve x on stack
	lw $t0, ($sp) #Here you set $t0 to x
	addi $sp, $sp, 4
	li $t1, 0xff0000 # $t1 stores the red colour code
	
	# 8
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 136($t0)
	sw $t1, 264($t0)
	sw $t1, 392($t0)
	sw $t1, 520($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 384($t0)
	sw $t1, 512($t0)
	sw $t1, 516($t0)
	sw $t1, 260($t0)
	
	jr $ra

drawNine: # requires x (top left corner of number to be drawn) on the stack
	# retrieve x on stack
	lw $t0, ($sp) #Here you set $t0 to x
	addi $sp, $sp, 4
	li $t1, 0xff0000 # $t1 stores the red colour code
	
	# 9
	sw $t1, ($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 136($t0)
	sw $t1, 264($t0)
	sw $t1, 392($t0)
	sw $t1, 520($t0)
	sw $t1, 128($t0)
	sw $t1, 256($t0)
	sw $t1, 512($t0)
	sw $t1, 516($t0)
	sw $t1, 260($t0)
	
	jr $ra
			
