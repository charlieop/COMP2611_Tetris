.data
# player instruction
input_key:	.word 0 # input key from the player

#game setting
game_status:	.word 0 #the status of the game
game_pause: 	.word 0 #the state of game pause
auto_down_count:	.word 0 #the index to indicate whether auto down
add 
#Block properties
current_block_id: 	.word 0 #the id of current block
block_x_loc:		.word 0 #the current x_loc of current block‘s typical location 
block_y_loc:		.word 0 #the current y_loc of current block’s typical location 
block_mode:		.word 0 #the current mode of current block
inital_x_loc: 		.word 4 5 4 4 5 5 6 #the intial x_loc of all 7 types of block
inital_y_loc: 		.word 1:7 #the intial y_loc of all 7 types of block
mode_x_loc: 		.byte  #the x_loc of all 4 modes for all 7 types of block
-1 0 1 2 0 0 0 0 -1 0 1 2 0 0 0 0
-1 -1 0 1 -1 0 0 0 -1 0 1 1 0 0 0 1
-1 0 1 1 -1 0 0 0 -1 -1 0 1 0 0 0 1
0 0 1 1 0 0 1 1 0 0 1 1 0 0 1 1
-1 0 0 1 -1 -1 0 0 -1 0 0 1 -1 -1 0 0
-1 0 0 1 -1 0 0 0 -1 0 1 0 0 0 0 1
-1 0 0 1 1 1 0 0 -1 0 0 1 1 1 0 0
mode_y_loc: .byte  #the y_loc of all 4 modes for all 7 types of block
0 0 0 0 1 0 -1 -2 0 0 0 0 1 0 -1 -2
-1 0 0 0 0 0 -1 -2 -1 -1 -1 0 -2 -1 0 -2
0 0 0 -1 -2 -2 -1 0 -1 0 -1 -1 -2 -1 0 0
-1 0 -1 0 -1 0 -1 0 -1 0 -1 0 -1 0 -1 0
0 0 -1 -1 -2 -1 -1 0 0 0 -1 -1 -2 -1 -1 0
0 -1 0 0 -1 -2 -1 0 -1 -1 -1 0 -2 -1 0 -1
-1 -1 0 0 -2 -1 -1 0 -1 -1 0 0 -2 -1 -1 0

#Basic matrix
matrix_size:		.word 10 23 # width and height of the matrix
basic_matrix_bitmap: .byte 0:220
		     .byte 1:10


.text

main:
# Initialize the game
init_game:
	li $v0, 100 #syscall 100: create the game
	syscall
	
	la $s0,current_block_id #load the address of current_block_id
	sw $v0,0($s0) #load the id of the current block
	
	sll $v0,$v0,2
	la $t0,inital_x_loc # load the x_loc of current block
	add $t0,$t0,$v0
	lw $t1,0($t0) 
	la $s1,block_x_loc #load the address of x_loc of current block
	sw $t1,0($s1)
	
	la $t0,inital_y_loc # load the y_loc of current block
	add $t0,$t0,$v0
	lw $t1,0($t0)
	la $s2,block_y_loc #load the address of y_loc of current block
	sw $t1,0($s2)
	
	la $s3,block_mode #load the address of block_mode
	la $s4,basic_matrix_bitmap #load the address of basic_matrix_bitmap
	
	#syscall 102: turn on the background music
	li $a0, 0 
	li $a1, 1
	li $v0, 102
	syscall

game_loop:
	jal get_time 
	add $s6, $v0, $zero # $s6: starting time of the game

check_game_status:
	la $t0,game_status
	lw $t0,0($t0)
	bne $t0,$zero,game_over	#whether game over
	
game_player_instruction:
	jal get_keyboard_input
	jal process_player_input
	
auto_down:
	jal check_auto_down 

	
game_refresh: #refresh game	
	li $v0, 101 # Refresh the screen
	syscall
	add $a0, $s6, $zero
	addi $a1, $zero, 50 # iteration gap: 100 milliseconds
	jal have_a_nap
	j game_loop


game_over:
	# Update the game status
	li $v0,106
	syscall
	# Refresh the screen
	li $v0, 101
	syscall
	#syscall 102: play the sound of lose
	li $a0, 3 
	li $a1, 0
	li $v0, 102
	syscall	
	#syscall 102: turn off the background music
	li $a0, 0 
	li $a1, 2
	li $v0, 102
	syscall	
	# Terminate the program
	li $v0, 10
	syscall

#--------------------------------------------------------------------
# procedure: get_time
# Get the current time
# $v0 = current time
#--------------------------------------------------------------------
get_time:	li $v0, 30
		syscall # this syscall also changes the value of $a1
		andi $v0, $a0, 0x3FFFFFFF # truncated to milliseconds from some years ago
		jr $ra

#--------------------------------------------------------------------
# procedure: have_a_nap(last_iteration_time, nap_time)
#--------------------------------------------------------------------
have_a_nap:
	addi $sp, $sp, -8
	sw $ra, 4($sp)
	sw $s0, 0($sp)

	add $s0, $a0, $a1
	jal get_time
	sub $a0, $s0, $v0
	slt $t0, $zero, $a0 
	bne $t0, $zero, han_p
	li $a0, 1 # sleep for at least 1ms
	
han_p:	li $v0, 32 # syscall: let mars java thread sleep $a0 milliseconds
	syscall

	lw $ra, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	jr $ra

#--------------------------------------------------------------------
# procedure: get_keyboard_input
# If an input is available, save its ASCII value in the array input_key,
# otherwise save the value 0 in input_key.
#--------------------------------------------------------------------
get_keyboard_input:
	add $t2, $zero, $zero
	lui $t0, 0xFFFF
	lw $t1, 0($t0)
	andi $t1, $t1, 1
	beq $t1, $zero, gki_exit
	lw $t2, 4($t0)

gki_exit:	
	la $t0, input_key 
	sw $t2, 0($t0) # save input key
	jr $ra
	
#--------------------------------------------------------------------
# procedure: process_player_input
# Check the the data store in the address of "input_key",
# If there is any latest movement input key, check it whether a valid player input.
# If so, perform the action of the new keyboard input input_key.
# Otherwise, do nothing.
# If an input is processed but it cannot actually move the block 
# due to some restrictions (e.g. wall), no more movements will be made in later
# iterations for this input. 
#--------------------------------------------------------------------
process_player_input:
	addi $sp, $sp, -4
	sw $ra, 0($sp)	
	
	la $t0, input_key
	lw $t1, 0($t0) # new input key

	li $t0, 119 # corresponds to key 'w'
	beq $t1, $t0, ppi_move_up  
	li $t0, 115 # corresponds to key 's'
	beq $t1, $t0, ppi_move_down
	li $t0, 97 # corresponds to key 'a'
	beq $t1, $t0, ppi_move_left
	li $t0, 100 # corresponds to key 'd'
	beq $t1, $t0, ppi_move_right
	li $t0, 112 # corresponds to key 'p'
	beq $t1, $t0, ppi_pause
	j ppi_exit

ppi_move_left:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall
	jal block_move_left
	j ppi_exit

ppi_move_right:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall
	jal block_move_right
	j ppi_exit
	
ppi_move_up: 
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall
	jal block_rotate
	j ppi_exit

ppi_move_down:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall
	jal block_move_down
	j ppi_exit

ppi_pause:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall	
	jal set_game_pause
	j ppi_exit				

ppi_exit: 
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
#--------------------------------------------------------------------
# procedure: block_move_left
# Move the block leftward by one step.
# Move the object only when the object will not overlap with a wall or already fixed blocks.
# This function has no return value
#--------------------------------------------------------------------	
block_move_left:

	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)

	lw $t0,0($s1) #load the x_loc of the current block
	addi $a0,$t0,-1 #assume block moving left is valid
	
	lw $a1,0($s2) #load the y_loc of the current block
	lw $a2,0($s3) #load the mode of the current block
	lw $a3,0($s0) #load the id of the current block
	
	jal check_movement_valid
	
	beq $v0,$zero,bml_exit
	
bml_after_move:
	sw $a0,0($s1) #update the x_loc of the current block
	
	lw $a0,0($s1) #load the x_loc of the current block
	lw $a1,0($s2) #load the y_loc of the current block
	lw $a2,0($s3) #load the mode of the current block
	li $v0,104
	syscall
	
bml_exit:
	li $v0,101 #refresh the screen
	syscall
			
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	jr $ra	
	
#--------------------------------------------------------------------
# procedure: block_move_right
# Move the block rightward by one step.
# Move the object only when the object will not overlap with a wall or already fixed blocks.
# This function has no return value
#--------------------------------------------------------------------	
block_move_right:

# *****Task1: you need to complete this procedure block_move_right to perform its operations as described in comments above. 
# Hints:
# Procedure procedure check_movement_valid (Task3) is one of the callees. Read its description before you start coding here.
# Firstly, preserve values $ra, $s0, $s1, $s2, $s3 with stack
# Then, use the registers as described below:
# 		The address of id of the current block is in $s0
#		The address of x_loc of the current block is in $s1	
# 		The address of y_loc of the current block is in $s2
# 		The address of the mode of current block is in $s3
# Calculate new x_loc of the block.
# Check whether this movement is valid (using procedure check_movement_valid),
#		If it is invalid, don't update the value.
#		If it is valid, then save the new x_loc for the current block and update this movement to the GUI in java code.
# Lastly, pop and restore values in $ra, $s0, $s1, $s2, $s3  and return
# Hint: you can refer to block_move_left to get some clues and pause "p" is very useful to debug.
# *****Your codes start here
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)

	lw $t0,0($s1) #load the x_loc of the current block
	addi $a0,$t0,1 #assume block moving left is valid
	
	lw $a1,0($s2) #load the y_loc of the current block
	lw $a2,0($s3) #load the mode of the current block
	lw $a3,0($s0) #load the id of the current block
	
	jal check_movement_valid
	
	beq $v0,$zero,bmr_exit
	
bmr_after_move:
	sw $a0,0($s1) #update the x_loc of the current block
	
	lw $a0,0($s1) #load the x_loc of the current block
	lw $a1,0($s2) #load the y_loc of the current block
	lw $a2,0($s3) #load the mode of the current block
	li $v0,104
	syscall
	
bmr_exit:
	li $v0,101 #refresh the screen
	syscall
			
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	jr $ra
		
# *****Your codes end here	


#--------------------------------------------------------------------
# procedure: block_rotate
# Rotate the block by 90 degrees counterclockwise
# Rotate the object only when the object will not overlap with a wall or already fixed blocks.
# This function has no return value
#--------------------------------------------------------------------	
block_rotate:
# *****Task2: you need to complete this procedure block_rotate to perform its operations as described in comments above. 
# Hints:
# Procedure procedure check_movement_valid (Task3) is one of the callees. Read its description before you start coding here.
# Firstly, preserve values $ra, $s0, $s1, $s2, $s3 with stack
# Then, use the registers as described below:
# 		The address of id of the current block is in $s0
#		The address of x_loc of the current block is in $s1	
# 		The address of y_loc of the current block is in $s2
# 		The address of the mode of current block is in $s3
# Calculate new mode of the current block.
# Check whether this rotation is valid (using procedure check_movement_valid),
#		If it is invalid, don't update new mode of the current block.
#		If it is valid, then save the new mode for the current block and update this movement to the GUI in java code.
# Lastly, pop and restore values in $ra, $s0, $s1, $s2, $s3  and return
# Hint: you can refer to block_move_left to get some clues and pause "p" is very useful to debug.
# *****Your codes start here
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)

	# start of the code

	# test if the movement is valid
	lw $t0, 0($s3) #load the mode of the current block

	addi $t0, $t0, 1 # rotate by 90 degree
	slti $t1, $t0, 4 # check if the mode is in [0, 3]
	bne $t1, $zero, skip_reset_mode # skip the reset part if the mode is valid
	li $t0, 0 # reset the mode to 0
skip_reset_mode:
	
	lw $a0,0($s1) #load the x_loc of the current block
	lw $a1,0($s2) #load the y_loc of the current block
	move $a2, $t0 # assume the rotation is valid
	lw $a3,0($s0) #load the id of the current block
	
	jal check_movement_valid
	
	beq $v0,$zero,rotate_exit
	
after_rotate:
	sw $t0,0($s3) #update the mode of the current block
	
	lw $a0,0($s1) #load the x_loc of the current block
	lw $a1,0($s2) #load the y_loc of the current block
	lw $a2,0($s3) #load the mode of the current block
	li $v0,104
	syscall
	
rotate_exit:
	li $v0,101 #refresh the screen
	syscall
			
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	jr $ra		
		
# *****Your codes end here	
		

			
#--------------------------------------------------------------------
# procedure: block_move_down
# Move the block downward by one step.
# Move the object only when the object will not overlap with a wall or already fixed blocks.
# If this downward movement is invalid, it indicates the block gets the bottom of game space.
# If so, this block becomes fixed and update the basic matrix. 
# Then, check whether the game is over.
# Next, check whether this block leads to a new full row.
# At Last, use syscall 103 to create a new block.
# This function has no return value
#--------------------------------------------------------------------	
block_move_down:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)

	lw $a0,0($s1) #load the x_loc of the current block
	
	lw $t0,0($s2) #load the y_loc of the current block
	addi $a1,$t0,1 #assume block moving down is valid
	
	lw $a2,0($s3) #load the mode of the current block
	lw $a3,0($s0) #load the id of the current block
	
	jal check_movement_valid
	bne $v0,$zero,bmd_after_move

bmd_get_bottom:
	addi $a1,$a1,-1 #block moving down is invalid
	lw $a0,0($s1) #load the x_loc of the current block
	lw $a1,0($s2) #load the y_loc of the current block
	lw $a2,0($s3) #load the mode of the current block
	lw $a3,0($s0) #load the id of the current block
	jal update_basic_matrix
	
	# check_game_over
	addi $a0,$zero,2 
	la $t0,matrix_size
	lw $a1,0($t0)
	jal check_game_over
	bne $v0,$zero,bmd_update_status
	
	#check_full_row
	la $t0,matrix_size
	lw $a0,4($t0) #the height of basic_matrix
	lw $a1,0($t0) #the width of basic_matrix
	jal check_full_row
	

bmd_create_new_block:
	li $v0,103 # create new block
	syscall
	
	sw $v0,0($s0) #load the id of the current block
	
	sll $v0,$v0,2
	la $t0,inital_x_loc # load the x_loc of current block
	add $t0,$t0,$v0
	lw $t1,0($t0) 
	sw $t1,0($s1) #update the current x_loc of new block
	
	la $t0,inital_y_loc # load the y_loc of current block
	add $t0,$t0,$v0
	lw $t1,0($t0)
	sw $t1,0($s2) #update the current y_loc of new block	

	sw $zero,0($s3) #reset the block_mode of new block
	j bmd_exit

bmd_update_status:
	la $t0,game_status
	sw $v0,0($t0)
	j bmd_exit

bmd_after_move:
	sw $a1,0($s2) #update the y_loc of the current block
		
bmd_exit:
	lw $a0,0($s1) #load the x_loc of the current block
	lw $a1,0($s2) #load the y_loc of the current block
	lw $a2,0($s3) #load the mode of the current block
	li $v0,104
	syscall	
	li $v0,101 #refresh the screen
	syscall	
		
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	jr $ra			
	
#--------------------------------------------------------------------
# Procedure: check_movement_valid
# Check whether the potential movement is valid. 
# This function is used to check the validity of all types of actions.
# Input parameter: $a0: potential x_loc 
#		   $a1: potential y_loc
#		   $a2: potential block_mode
#		   $a3: current block id
# Output: $v0,1 means the movement is valid, 0 means the movement is invalid
#--------------------------------------------------------------------
check_movement_valid:
#*****Task3: you need to complete this procedure check_movement_valid to perform its operations as described in comments above. 
# Hints: 
# Firstly, preserve values $ra, $s4 with stack
# Then, use the registers as described below:
# 		The base address of basic_matrix_bitmap is in $s4
# Secondly, use the these four input parameters, mode_x_loc and mode_y_loc to calculate the absolute corrdinate of every 4 squares in a block.
# Thirdly, check whether the corrdinate of all four squares is valid with loop.
# Note that this procedure is used to check the validity of all types of actions, so it have to consider all situations.
# All situations includes crossing horizontal_boundary, crossing vertical_boundary and overlapping with fixed squares.
# At last, set the value of $v0 based on the check result ,and pop and restore values in $ra, $s4  and return.
#*****Your codes start here
	addi $sp, $sp, -36
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $t0, 20($sp)
	sw $t1, 24($sp)
	sw $t2, 28($sp)
	sw $t3, 32($sp)

	# start of the code
	move $s0, $a3	# get block id
	move $s1, $a0	# get x
	move $s2, $a1	# get y
	move $s3, $a2	# get mode
	
	la $t7, matrix_size
	lw $t8, 0($t7)	# width of matrix
	lw $t9, 4($t7)	# height of matrix

	
# ========== check the first block ==========
	# get positions
	sll $t0, $s0, 4	# get the row of the matrix
	sll $t3, $s3, 2	# get the column the matrix
	add $t0, $t0, $t3 # get the first position
	addi $t0, $t0, 0	# the n-th block

	la $t1, mode_x_loc	# load the x matrix
	add $t1, $t1, $t0	# position of adjustment
	lb $t1, 0($t1)	# get the adjustment required
	add $t1, $t1, $s1 # get the true x pos

	la $t2, mode_y_loc	# load the y matrix
	add $t2, $t2, $t0	# position of adjustment
	lb $t2, 0($t2)	# get the adjustment required
	add $t2, $t2, $s2 # get the true y pos

	jal check_validity # check for the block

# ========== check the second block ==========
	# get positions
	sll $t0, $s0, 4	# get the row of the matrix
	sll $t3, $s3, 2	# get the column the matrix
	add $t0, $t0, $t3 # get the first position
	addi $t0, $t0, 1	# the n-th block

	la $t1, mode_x_loc	# load the x matrix
	add $t1, $t1, $t0	# position of adjustment
	lb $t1, 0($t1)	# get the adjustment required
	add $t1, $t1, $s1 # get the true x pos

	la $t2, mode_y_loc	# load the y matrix
	add $t2, $t2, $t0	# position of adjustment
	lb $t2, 0($t2)	# get the adjustment required
	add $t2, $t2, $s2 # get the true y pos

	jal check_validity # check for the block

# ========== check the third block ==========
	# get positions
	sll $t0, $s0, 4	# get the row of the matrix
	sll $t3, $s3, 2	# get the column the matrix
	add $t0, $t0, $t3 # get the first position
	addi $t0, $t0, 2	# the n-th block

	la $t1, mode_x_loc	# load the x matrix
	add $t1, $t1, $t0	# position of adjustment
	lb $t1, 0($t1)	# get the adjustment required
	add $t1, $t1, $s1 # get the true x pos

	la $t2, mode_y_loc	# load the y matrix
	add $t2, $t2, $t0	# position of adjustment
	lb $t2, 0($t2)	# get the adjustment required
	add $t2, $t2, $s2 # get the true y pos

	jal check_validity # check for the block

# ========== check the fourth block ==========
	# get positions
	sll $t0, $s0, 4	# get the row of the matrix
	sll $t3, $s3, 2	# get the column the matrix
	add $t0, $t0, $t3 # get the first position
	addi $t0, $t0, 3	# the n-th block

	la $t1, mode_x_loc	# load the x matrix
	add $t1, $t1, $t0	# position of adjustment
	lb $t1, 0($t1)	# get the adjustment required
	add $t1, $t1, $s1 # get the true x pos

	la $t2, mode_y_loc	# load the y matrix
	add $t2, $t2, $t0	# position of adjustment
	lb $t2, 0($t2)	# get the adjustment required
	add $t2, $t2, $s2 # get the true y pos

	jal check_validity # check for the block

# ========== all block is valid ==========
	j valid


check_validity:
	# out of bounds?
	slti $t0, $t1, 0	# x < 0?
	bne $t0, $zero, not_valid
	slt $t0, $t1, $t8	# x > width?
	beq $t0, $zero, not_valid
	slti $t0, $t2, 0	# y < 0?
	bne $t0, $zero, not_valid
	slt $t0, $t2, $t9	# y > height?
	beq $t0, $zero, not_valid

	# position already exist?
	mult $t2, $t8	# pos = y * width
	mflo $t0
	add $t0, $t0, $t1	# pos += x
	add $t0, $s4, $t0	# get the address of corrsponding pos
	lb $t0, 0($t0)
	bne $t0, $zero, not_valid	# is space is occupied

	# if all valid
	jr $ra

not_valid:
	li $v0, 0
	j end_checking

valid:
	li $v0, 1

end_checking:
	# put back value
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $t0, 20($sp)
	lw $t1, 24($sp)
	lw $t2, 28($sp)
	lw $t3, 32($sp)
	addi $sp, $sp, 36
	jr $ra		
		
# *****Your codes end here	
				
	
#--------------------------------------------------------------------
# Procedure: update_basic_matrix
# Update data of the basic matrix when a block is going to be fixed
# Input parameter: $a0: x_loc of block to be fixed 
#		   $a1: y_loc of block to be fixed  
#		   $a2: mode of block to be fixed 
#		   $a3: id of block to be fixed
# This function has no return value.
#--------------------------------------------------------------------
update_basic_matrix:
#*****Task4: you need to complete this procedure update_basic_matrix to perform its operations as described in comments above. 
# Hints: 
# Firstly, preserve values $ra, $s4 with stack
# Then, use the registers as described below:
# 		The base address of basic_matrix_bitmap is in $s4
# Secondly, use the these four input parameters, mode_x_loc and mode_y_loc to calculate the absolute corrdinate of every 4 squares in a block.
# Thirdly, set the corresponding corrdinate in basic_matrix_bitmap to 1.
# At last, pop and restore values in $ra, $s4  and return.
#*****Your codes start here
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
		
	# start of the code
	move $s0, $a3	# get block id
	move $s1, $a0	# get x
	move $s2, $a1	# get y
	move $s3, $a2	# get mode

	la $t7, matrix_size
	lw $t8, 0($t7)	# width of matrix
	lw $t9, 4($t7)	# height of matrix

	li $v0, 105
	syscall
	
# ========== first block ==========
	# get positions
	sll $t0, $s0, 4	# get the row of the matrix
	sll $t3, $s3, 2	# get the column the matrix
	add $t0, $t0, $t3 # get the first position
	addi $t0, $t0, 0	# the n-th block

	la $t1, mode_x_loc	# load the x matrix
	add $t1, $t1, $t0	# position of adjustment
	lb $t1, 0($t1)	# get the adjustment required
	add $t1, $t1, $s1 # get the true x pos

	la $t2, mode_y_loc	# load the y matrix
	add $t2, $t2, $t0	# position of adjustment
	lb $t2, 0($t2)	# get the adjustment required
	add $t2, $t2, $s2 # get the true y pos

	jal add_one # set the position to one

# ========== first block ==========
	# get positions
	sll $t0, $s0, 4	# get the row of the matrix
	sll $t3, $s3, 2	# get the column the matrix
	add $t0, $t0, $t3 # get the first position
	addi $t0, $t0, 0	# the n-th block

	la $t1, mode_x_loc	# load the x matrix
	add $t1, $t1, $t0	# position of adjustment
	lb $t1, 0($t1)	# get the adjustment required
	add $t1, $t1, $s1 # get the true x pos

	la $t2, mode_y_loc	# load the y matrix
	add $t2, $t2, $t0	# position of adjustment
	lb $t2, 0($t2)	# get the adjustment required
	add $t2, $t2, $s2 # get the true y pos

	jal add_one # set the position to one

# ========== second block ==========
	# get positions
	sll $t0, $s0, 4	# get the row of the matrix
	sll $t3, $s3, 2	# get the column the matrix
	add $t0, $t0, $t3 # get the first position
	addi $t0, $t0, 1	# the n-th block

	la $t1, mode_x_loc	# load the x matrix
	add $t1, $t1, $t0	# position of adjustment
	lb $t1, 0($t1)	# get the adjustment required
	add $t1, $t1, $s1 # get the true x pos

	la $t2, mode_y_loc	# load the y matrix
	add $t2, $t2, $t0	# position of adjustment
	lb $t2, 0($t2)	# get the adjustment required
	add $t2, $t2, $s2 # get the true y pos

	jal add_one # set the position to one

# ========== third block ==========
	# get positions
	sll $t0, $s0, 4	# get the row of the matrix
	sll $t3, $s3, 2	# get the column the matrix
	add $t0, $t0, $t3 # get the first position
	addi $t0, $t0, 2	# the n-th block

	la $t1, mode_x_loc	# load the x matrix
	add $t1, $t1, $t0	# position of adjustment
	lb $t1, 0($t1)	# get the adjustment required
	add $t1, $t1, $s1 # get the true x pos

	la $t2, mode_y_loc	# load the y matrix
	add $t2, $t2, $t0	# position of adjustment
	lb $t2, 0($t2)	# get the adjustment required
	add $t2, $t2, $s2 # get the true y pos

	jal add_one # set the position to one

# ========== fourth block ==========
	# get positions
	sll $t0, $s0, 4	# get the row of the matrix
	sll $t3, $s3, 2	# get the column the matrix
	add $t0, $t0, $t3 # get the first position
	addi $t0, $t0, 3	# the n-th block

	la $t1, mode_x_loc	# load the x matrix
	add $t1, $t1, $t0	# position of adjustment
	lb $t1, 0($t1)	# get the adjustment required
	add $t1, $t1, $s1 # get the true x pos

	la $t2, mode_y_loc	# load the y matrix
	add $t2, $t2, $t0	# position of adjustment
	lb $t2, 0($t2)	# get the adjustment required
	add $t2, $t2, $s2 # get the true y pos

	jal add_one # set the position to one

	j update_end

add_one:
	mult $t2, $t8	# pos = y * width
	mflo $t0
	add $t0, $t0, $t1	# pos += x
	add $t0, $s4, $t0	# get the address of corrsponding pos
	addi $t1, $t1, 1
	sb $t1, 0($t0)	# set the pos to 1
	jr $ra

update_end:
	# put back value
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	jr $ra		
		
# *****Your codes end here


	
#--------------------------------------------------------------------
# Procedure: check_game_over
# Check whether the fixed blocks prevent the arrival of a new block
# The logic is that If a value in the first two row of basic matrix is larger than 1,
# then game over.
# Input parameter: $a0: 2, $a1: the width of matrix
# Output: $v0,0 means the game is still going, 1 means game over
#--------------------------------------------------------------------
check_game_over:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s4, 4($sp)
	
	move $v0,$zero
	
	addi $t0,$zero,0 #$t0 = 0, iterator i
	addi $t1,$zero,0 #$t1 = 0, iterator j
	
cgo_loop1:	
	slt $t2,$t0,$a0
	beq $t2,$zero,cgo_exit
	addi $t1,$zero,0
	
	mul $t3,$t0,$a1 #$t3 = i times the width of matrix
cgo_loop2:
	slt $t2,$t1,$a1
	beq $t2,$zero,cgo_loop2_exit
	
	add $t4,$t3,$t1 #$t4 = i times the width of matrix + j
	add $t4,$t4,$s4 #$t4 = i times the width of matrix + j + base address of of basic matrix
	
	lb $t5,0($t4)
	addi $t6,$zero,1
	slt $t7,$t6,$t5 # if basicmatrix[i][j] > 1
	bne $t7,$zero,cgo_game_over
	
	
	addi $t1,$t1,1	
	j cgo_loop2
	
cgo_loop2_exit:
	addi $t0,$t0,1
	j cgo_loop1

cgo_game_over:
	addi $v0,$v0,1	
	
cgo_exit:	
	lw $ra, 0($sp)
	lw $s4, 4($sp)
	addi $sp, $sp, 8
	jr $ra	

#--------------------------------------------------------------------
# Procedure: check_full_row
# Check whether there is full row in current basic matrix.
# If so, for each full row, let it disappear and the blocks placed above fall one rank.
# input parameter: $a0: the height of matrix, $a1: the width of matrix
# This function has no return value.
#--------------------------------------------------------------------
check_full_row:
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s4, 4($sp)

	addi $t0,$zero,0 #$t0 = 0, iterator i
	addi $t1,$zero,0 #$t1 = 0, iterator j 
	
	addi $a0,$a0,-1 #the height of matrix - 1
	
cfr_loop1:
	slt $t3,$t0,$a0
	beq $t3,$zero,cfr_exit
	
	addi $t1,$zero,0 #reset iterator j 
	addi $t2,$zero,1 #boolean(true) indicates whether there is a full row	
	
	mul $t4,$t0,$a1 #$t4 = i times the width of matrix
cfr_loop2:
	slt $t3,$t1,$a1
	beq $t3,$zero,cfr_loop2_exit
	
	add $t5,$t4,$t1 #$t5 = i times the width of matrix + j
	add $t5,$t5,$s4 #$t5 = i times the width of matrix + j + base address of of basic matrix
	
	lb $t5,0($t5)
	beq $t5,$zero,cfr_not_full_row # this row can't be a full row
	
	
	addi $t1,$t1,1	
	j cfr_loop2
	
cfr_not_full_row:
	move $t2,$zero # boolean = false

cfr_loop2_exit:
	bne $t2,$zero,cfr_process_full_row
	
	addi $t0,$t0,1 # i = i + 1
	j cfr_loop1
	
cfr_process_full_row:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $a1, 8($sp)
	sw $t0, 12($sp)
	sw $t1, 16($sp)

	move $a0,$t0
	la $t2,matrix_size
	lw $a1,0($t2)
	jal process_full_row
	
	lw $ra, 0($sp)
	lw $a0, 4($sp)
	lw $a1, 8($sp)
	lw $t0, 12($sp)
	lw $t1, 16($sp)
	addi $sp, $sp, 20
	
	j cfr_loop1
	
cfr_exit:	
	lw $ra, 0($sp)
	lw $s4, 4($sp)
	addi $sp, $sp, 8
	jr $ra
	

#--------------------------------------------------------------------
# Procedure: process_full_row
# Remove the specific row and let the blocks placed above fall one rank.
# Use syscall 107 to inform java program and score ++
# Use syscall 102 to play the sound effect of removing the full row
# input parameter: $a0: the full row number
#		   $a1: the width of matrix
# This function has no return value.
#--------------------------------------------------------------------
process_full_row:
#*****Task5: you need to complete this procedure process_full_row to perform its operations as described in comments above. 
# Hints: 
# Firstly, preserve values $ra, $s4 with stack
# Then, use the registers as described below:
# 		The base address of basic_matrix_bitmap is in $s4
# Secondly, delete row $a0 and use loop to move all rows above $a0 downside by one row.
# 	Logic for reference:  for all k (rows above row $a0 and row $a0), for all l (elements in this row), let basicMatrix[k][l][0] = basicMatrix[k - 1][l][0];
# Thirdly, let the first row of basic matrix equal to zero.
# At last, use syscall 107 and 102, then pop and restore values in $ra, $s4  and return.
#*****Your codes start here
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s4, 4($sp)
	la $s4, basic_matrix_bitmap
	# start of the code

	beq $a0, $zero, set_first_row_empty	# if the row is the first row

move_one_row_down:
	move $t0, $a0		# t0: current destination row
	addi $t1, $t0, -1	# t1: the origin row
	li $t2, 0			# t2: the index woriking on

	move_down_row_for_loop:	# do until t0 is the row 0

		li $t2, 0	# reset

		# calculate the addr of row t0 and t1
		mult $t0, $a1
		mflo $t3	# the addr of first element of t0
		add $t3, $t3, $s4
		sub $t4, $t3, $a1	# the addr of first element of t1

		move_down_col_for_loop:	# move each element one position

			add $t5, $t4, $t2	# the addr of origin element
			lb $t6, 0($t5)	# the value of origin element
			add $t5, $t3, $t2	# the addr of destination
			sb $t6, 0($t5)	# write

			addi $t2, $t2, 1	# increment by 1
			beq $t2, $a1, move_down_col_for_loop_end	# end if reached the end of row
			j move_down_col_for_loop

		move_down_col_for_loop_end:

	move $t0, $t1	# move up one row
	addi $t1, $t0, -1

	beq $t0, $zero, move_down_row_for_loop_end	# if $t0 is the row 0, then stop the loop
	j move_down_row_for_loop	# loop

	move_down_row_for_loop_end:

set_first_row_empty:	
	# write row 0 all 0
	li $t0, 0	# the index of col
	write_zero_for_loop:

		add $t1, $s4, $t0	# the addr of current element
		sb $zero, 0($t1)	# write 0

		addi $t0, $t0, 1	# increment
		beq $t0, $a1, write_zero_for_loop_end	# end if reached the end of row
		j write_zero_for_loop

	write_zero_for_loop_end:

		# update matrix
		li $v0, 107
		syscall

		# play sound
		li $v0, 102
		li $a0, 2
		li $a1, 0
		syscall

	lw $s4, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	jr $ra
		
# *****Your codes end here


#--------------------------------------------------------------------
# Procedure: check_auto_down
# Check whether the game pauses, If not,then 
# Check whether the block needs to go downside by one step automatically in this game iteration.
# If so, the block go down one step.
# This function has no input parameters and return value.
#--------------------------------------------------------------------
check_auto_down:
	addi $sp, $sp, -4
	sw $ra, 0($sp)	
	
cad_check_pause:
	la $t0,game_pause
	lw $t1,0($t0)
	bne $t1,$zero,cad_exit	

cad_check_autodown_count:	
	la $t0,auto_down_count
	lw $t1,0($t0)
	addi $t1,$t1,1
	sw $t1,0($t0)
	addi $t2,$zero,20
	
	slt $t3,$t1,$t2
	bne $t3,$zero,cad_exit

cad_auto_down:

	jal block_move_down
	la $t0,auto_down_count
	sw $zero,0($t0)

cad_exit:
	#sw $t1,0($t0) 
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#--------------------------------------------------------------------
# Procedure: set_game_pause
# Switch the state of game_pause.
# This function has no input parameters and return value.
#--------------------------------------------------------------------
set_game_pause:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0,game_pause
	lw $t1,0($t0)
	addi $t1,$t1,1
	
	addi $t2,$zero,2
	slt $t3,$t1,$t2
	bne $t3,$zero,sgp_exit
	
spg_mod2:
	move $t1,$zero
	
sgp_exit:
	sw $t1,0($t0)
    
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
