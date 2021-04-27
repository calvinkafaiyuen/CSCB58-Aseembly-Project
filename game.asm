#####################################################################
#
# CSCB58 Winter 2021 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Ka Fai Yuen, 1006336225, yuenka8
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8 (update this as needed)
# - Unit height in pixels: 8 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1, 2, 3, and 4
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. the ability for the player to shoot enemy ships
# 2. pick-ups: a red item that restores the player's health, and a blue item that shields the player
# 3. increase in difficulty: the game speeds up as it progresses
# ... (add more if necessary)
#
# Link to video demonstration for final submission: https://play.library.utoronto.ca/play/da8b2d379365a429bbfe327fc6bc802d
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

.eqv BASE_ADDRESS 	0x10008000
.eqv WIDTH		32
.eqv HEIGHT		32
.eqv ROW_SHIFT		7
.eqv KEY_PRESSED	0xffff0000 

.eqv RED 		0xff0000
.eqv GREEN 		0x00ff33
.eqv BLUE		0x0000ff
.eqv LIGHT_BLUE		0x00ffff
.eqv GREY		0xbebebe
.eqv DARK_GREY		0x737373
.eqv BLACK		0x000000

.eqv W_KEY		119
.eqv A_KEY		97
.eqv S_KEY		115
.eqv D_KEY		100
.eqv P_KEY		112
.eqv SPACE_KEY 		32


.data 
player: .word 15, 1, 16, 1, 16, 2, 15, 3, 16, 3, 17, 3, 16, 4, 16, 5			# the rows and columns of all pixels of player
player_health: 6									# the column of the right most pixel of player health bar
player_colour: GREEN									# the colour of the player
shooting: .word -1, -1									# the row and column of the shooting pixel

health_item: .word -1, -1								# the row and column of the health item
shield_item: .word -1, -1								# the row and column of the shield item

enemy_one: .word -1, 28, 6, 29, 7, 29, 8, 29, 6, 30, 8, 30, 6, 31, 8, 31		# the rows and columns of all pixels of enemy one

enemy_two: .word 16, 28, 15, 29, 16, 29, 17, 29, 15, 30, 17, 30, 15, 31, 17, 31		# the rows and columns of all pixels of enemy two

enemy_three: .word -1, 28, 24, 29, 25, 29, 26, 29, 24, 30, 26, 30, 24, 31, 26, 31	# the rows and columns of all pixels of enemy three

default_enemy_col: .word 28, 29, 29, 29, 30, 30, 31, 31					# the default columns where the pixels of all enemies spawn

wait_time: 5000

.text  

 .globl main
 
main:			la $t0, player_colour			# get the player colour
			lw $a0, 0($t0)			
			jal drawPlayer				# draw the player
			li $a0, GREY				
			la $a1, enemy_two			# draw enemy two 
			jal drawEnemy				
			
fillPlayerHealth:	li $t0, 0
			li $t1, 5				
fillPlayerHealthLoop:	jal restorePlayerHealth			# fill up the health bar
			addi $t0, $t0, 1
			blt $t0, $t1, fillPlayerHealthLoop	# loop 5 times
			
update:			la $a0, GREY
			la $t2, enemy_two
			la $a1, enemy_one		
			li $t0, -1
			lw $t1, 0($a1)
			beq $t0, $t1, drawEnemyOne		# if enemy one has not yet been drawn	
			la $a1, enemy_three			
			lw $t1, 0($a1)
			beq $t0, $t1, drawEnemyTwo		# if enemy three has not yet been drawn
			j generate_items			# jump to generate_items
			
			
drawEnemyOne:		lw $t0, 4($t2)				
			li $t1, 21
			bge $t0, $t1, check_key			# if enemy two has travelled at least 10 pixels
			li $t1, 7
			sw $t1, 0($a1)	
			jal drawEnemy				# draw enemy_one
			j generate_items			# jump to generate_items
			
			
drawEnemyTwo:		lw $t0, 4($t2)				
			li $t1, 11
			bge $t0, $t1, check_key			# if enemy two has travelled at least 20 pixels
			li $t1, 25
			sw $t1, 0($a1)				
			jal drawEnemy				# draw enemy_three
			

generate_items:		li $v0, 42				# generate items based on a randomly generated number
			li $a0, 0
			li $a1, 60
			syscall			
			li $t0, 0
			beq $a0, $t0, generate_health		# if the randomly generated number is 20, generate health item
			li $t0, 30
			beq $a0, $t0, generate_shield		# if the randomly generated number is 40, generate shield item
			j check_key	 

	
generate_health:	la $t0, health_item
			li $t1, -1
			lw $t2, 0($t0)
			bne $t2, $t1, check_key			# if a health item already exists on the map, do not create a new one
			li $v0, 42
			li $a0, 0
			li $a1, 28				# get a random number for the row where the health item will spawn
			syscall
			addi $a0, $a0, 3			# add 3 to the random number to keep it within the range
			sw $a0, 0($t0)
			li $a1, 31
			sw $a1, 4($t0)				# update the position of the health item
			li $a2, RED
			jal drawPixel				# draw the health item
			j check_key
	
	
generate_shield:	la $t0, shield_item
			li $t1, -1
			lw $t2, 0($t0)
			bne $t2, $t1, check_key			# if a shield item already exists on the map, do not create a new one
			li $v0, 42
			li $a0, 0
			li $a1, 28				# get a random number for the row where the shield item will spawn
			syscall
			addi $a0, $a0, 3			# add 3 to the random number to keep it within the range
			sw $a0, 0($t0)
			li $a1, 31
			sw $a1, 4($t0)				# update the position of the shield item
			li $a2, BLUE
			jal drawPixel				# draw the shield item
			j check_key
			
							
check_key:	  	li $t9, KEY_PRESSED			# check if a key is pressed
			lw $t8, 0($t9)
			beq $t8, 1, key_pressed
 			j moveEnemies				# jump to moveEnemies if no key has been pressed	
 		
key_pressed:		la $t2, player				
			lw $t8, 4($t9) 				# check which key is pressed and perform corresponding actions
			beq $t8, W_KEY, playerMoveUp
			beq $t8, A_KEY, playerMoveLeft
			beq $t8, S_KEY, playerMoveDown
			beq $t8, D_KEY, playerMoveRight
			beq $t8, P_KEY, restartGame
			beq $t8, SPACE_KEY, shoot
			j moveEnemies				# jump to moveEnemies	



playerMoveUp:		lw $t0, 0($t2)				# if player has already reached the top border of the map, don't move player
			li $t1, 3
			ble $t0, $t1, end
			li $a0, BLACK				# erase the player
			jal drawPlayer
			li $t0, 0				# $t0 indicates the current pixel of player
			li $t1, 14				# $t1 indicates the last pixel of player
			la $t2, player		
moveUpPixel:		lw $t3, 0($t2)				# get the row of the current pixel of player
			addi $t3, $t3, -1			# subract the row by 1 to move up
			sw $t3, 0($t2)
			addi $t2, $t2, 8			# visit the next pixel of player
			addi $t0, $t0, 2				
			ble $t0, $t1, moveUpPixel
			la $t0, player_colour			# get player colour
			lw $a0, 0($t0)				# redraw the player
			jal drawPlayer			
			j moveEnemies				# jump to moveEnemies	



playerMoveLeft:		lw $t0, 4($t2)				# if player has already reached the left border of the map, don't move player
			blez $t0, end
			li $a0, BLACK				# erase the player
			jal drawPlayer
			li $t0, 0				# $t0 indicates the current pixel of player
			li $t1, 14				# $t1 indicates the last pixel of player
			la $t2, player		
moveLeftPixel:		lw $t3, 4($t2)				# get the column of the current pixel of player
			addi $t3, $t3, -1			# subract the column by 1 to move left
			sw $t3, 4($t2)
			addi $t2, $t2, 8			# visit the next pixel of player
			addi $t0, $t0, 2				
			ble $t0, $t1, moveLeftPixel
			la $t0, player_colour			# get player colour
			lw $a0, 0($t0)				# redraw the player
			jal drawPlayer				
			j moveEnemies				# jump to moveEnemies
			
			
			
playerMoveDown:		lw $t0, 40($t2)				# if player has already reached the left border of the map, don't move player
			li $t1, 31
			bge $t0, $t1, end
			li $a0, BLACK				# erase the player
			jal drawPlayer
			li $t0, 0				# $t0 indicates the current pixel of player
			li $t1, 14				# $t1 indicates the last pixel of player
			la $t2, player		
moveDownPixel:		lw $t3, 0($t2)				# get the row of the current pixel of player
			addi $t3, $t3, 1			# add 1 to the row to move down
			sw $t3, 0($t2)
			addi $t2, $t2, 8			# visit the next pixel of player
			addi $t0, $t0, 2				
			ble $t0, $t1, moveDownPixel
			la $t0, player_colour			# get player colour
			lw $a0, 0($t0)				# redraw the player
			jal drawPlayer			
			j moveEnemies				# jump to moveEnemies		


 
playerMoveRight:	lw $t0, 60($t2)				# if player has already reached the left border of the map, don't move player
			li $t1, 31
			bge $t0, $t1, end
			li $a0, BLACK				# erase the player
			jal drawPlayer
			li $t0, 0				# $t0 indicates the current pixel of player
			li $t1, 14				# $t1 indicates the last pixel of player
			la $t2, player		
moveRightPixel:		lw $t3, 4($t2)				# get the column of the current pixel of player
			addi $t3, $t3, 1			# add 1 to the column to move right
			sw $t3, 4($t2)
			addi $t2, $t2, 8			# visit the next pixel of player
			addi $t0, $t0, 2				
			ble $t0, $t1, moveRightPixel
			la $t0, player_colour			# get player colour
			lw $a0, 0($t0)				# redraw the player
			jal drawPlayer							
			j moveEnemies

		
shoot:			la $t0, shooting			# launch a shooting from the player
			lw $t1, 0($t0)
			li $t2, -1
			bne $t1, $t2, moveEnemies		# if a shooting already exists in the game, don't launch another shooting
			la $t1, player			
			lw $a0, 56($t1)			
			lw $a1, 60($t1)				# get the position of the player where the shooting will be launched from
			addi $a1, $a1, 1
			sw $a0, 0($t0)				# assign the position to the shooting 
			sw $a1, 4($t0)		
			li $a2, LIGHT_BLUE			# draw the shooting	
			jal drawPixel	
				
			
moveEnemies:		la $a1, enemy_two
			jal check_collison			# check if enemy two is colliding with player or getting shot	
			li $a0, BLACK			
			la $a1, enemy_two			# erase enemy two
			jal drawEnemy
			la $a1, enemy_two			# move enemy two
			li $a2, -1				# enemy two travels by 1 pixel per loop
			jal moveEnemy
			li $a0, GREY
			la $a1, enemy_two			# redraw enemy two
			jal drawEnemy
			la $a1, enemy_two

			la $a1, enemy_one			# skip if enemy one has not yet been drawn
			lw $t0, 0($a1)
			li $t1, -1
			beq $t0, $t1, end		
			jal check_collison			# check if enemy one is colliding with player or getting shot	
			li $a0, BLACK			
			la $a1, enemy_one			# erase enemy one
			jal drawEnemy
			la $a1, enemy_one			# move enemy one	
			li $a2, -1				# enemy one travels by 1 pixel per loop
			jal moveEnemy
			li $a0, GREY
			la $a1, enemy_one			# redraw the first enemy one 
			jal drawEnemy
					
			la $a1, enemy_three			# skip if enemy two has not yet been drawn 
			lw $t0, 0($a1)
			li $t1, -1
			beq $t0, $t1, end	
			jal check_collison			# check if enemy three is colliding with player or getting shot					
			li $a0, BLACK				# erase enemy three
			la $a1, enemy_three			
			jal drawEnemy
			la $a1, enemy_three			# move enemy three
			li $a2, -1				# enemy three travels by 1 pixel per loop
			jal moveEnemy
			li $a0, GREY
			la $a1, enemy_three			# redraw enemy three
			jal drawEnemy

			
move_health_item:	la $t0, health_item
			li $t1, -1
			lw $a0, 0($t0)				# get the row and column of the pixel of health item
			beq $a0, $t1, move_shield_item		# skip if a health item does not exist on the map
			
			lw $a1, 4($t0)
			li $a2, BLACK
			jal drawPixel				# erase the health item

			la $t1, player				# check if player is colliding with the health item
			li $t2, 0
			li $t3, 7
			lw $t4, 0($t0)				# get the row of the health item
			lw $t5, 4($t0)				# get the column of the health item
health_item_loop:	lw $t6, 0($t1)				# loop through each pixel of player
			lw $t7, 4($t1)
			bne $t4, $t6, healthItemNoCollision
			bne $t5, $t7, healthItemNoCollision
			jal restorePlayerHealth			# restore player health
			j remove_health_item			# jump to remove_health_item
			
healthItemNoCollision:	addi $t1, $t1, 8			# current pixel of health item is not colliding with player
			addi $t2, $t2, 1
			ble $t2, $t3, health_item_loop
			
			blez $a1, remove_health_item		# if the health item has reached the left border of the map, keep it removed
			addi $a1, $a1, -1			# move the health item 
			sw $a1, 4($t0)	
			li $a2, RED				
			jal drawPixel				# redraw the health item
			j move_shield_item			# jump to move_shield_item

remove_health_item:	li $t1, -1
			sw $t1, 0($t0)				# update the row and column of the health item to -1
			sw $t1, 4($t0)				



move_shield_item:	la $t0, shield_item
			li $t1, -1
			lw $a0, 0($t0)				# get the row and column of the pixel of shield item
			beq $a0, $t1, moveShooting		# skip if a shield item does not exist on the map
			
			lw $a1, 4($t0)
			li $a2, BLACK
			jal drawPixel				# erase the shield item

			la $t1, player				# check if player is colliding with the shield item
			li $t2, 0
			li $t3, 7
			lw $t4, 0($t0)				# get the row of the shield item
			lw $t5, 4($t0)				# get the column of the shield item
shield_item_loop:	lw $t6, 0($t1)				# loop through each pixel of player
			lw $t7, 4($t1)
			bne $t4, $t6, shieldItemNoCollision
			bne $t5, $t7, shieldItemNoCollision
			jal player_gain_shield			# gain player shield
			j remove_shield_item			# jump to remove_shield_item
			
shieldItemNoCollision:	addi $t1, $t1, 8			# current pixel of shield item is not colliding with player
			addi $t2, $t2, 1
			ble $t2, $t3, shield_item_loop
						
			blez $a1, remove_shield_item		# if the shield item has reached the left border of the map, keep it removed		
			addi $a1, $a1, -1			# move the shield item 
			sw $a1, 4($t0)	
			la $a2, BLUE				
			jal drawPixel				# redraw the shield item
			j moveShooting				# jump to moveShooting

remove_shield_item:	li $t1, -1
			sw $t1, 0($t0)
			sw $t1, 4($t0)	
			
			
			
moveShooting:		la $t0, shooting	
			lw $a0, 0($t0)		
			lw $a1, 4($t0)
			li $t1, -1
			beq $a0, $t1, end			# skip if a shooting does not exist
			li $a2, BLACK		
			jal drawPixel				# erase the pixel of shooting
			li $t1, 31
			bge $a1, $t1, removeShooting		# if the shooting is out of the map, do not redraw it	
			addi $a1, $a1, 1			# move the pixel to the right
			sw $a1, 4($t0)				# update the pixel of shooting
			li $a2, LIGHT_BLUE			# redraw the pixel of shooting
			jal drawPixel
			j end
			
			
removeShooting:		li $t1, -1				# update both row and column of the shooting pixel to -1
			sw $t1, 0($t0)				# to keep it out of the map
			sw $t1, 4($t0)											
																													
end:			la $t0, wait_time			# get the wait time 
			lw $t1, 0($t0)
			li $t2, 200
			div $t3, $t1, $t2
			li $t4, 5				# $t2 stores the minimum wait time
			ble $t3, $t4, wait			# do not reduce the wait time if minimum wait time has been reached
			addi $t1, $t1, -1			# reducea the wait time as the game progresses
			sw $t1, 0($t0)
wait:			li $v0, 32				# wait for some time before looping				
			move $a0, $t3
			syscall		
			j update				# loop



drawPlayer:		li $s0, 0				# $s0 indicates the current pixel of player
			li $s1, 14				# $s1 indicates the last pixel of player
			la $s2, player		
drawPlayerLoop:		lw $s3, 0($s2)				# get the row of the current pixel of player
			sll $s4, $s3, ROW_SHIFT
			lw $s5, 4($s2)				# get the column of the current pixel of player
			sll $s5, $s5, 2
			add $s6, $s4, BASE_ADDRESS		# get the address of the current pixel 
			add $s6, $s6, $s5
			sw $a0, 0($s6)				# fill the pixel with the colour stored in $a0
			
			addi $s2, $s2, 8			# visit the next pixel of player
			addi $s0, $s0, 2			
			ble $s0, $s1, drawPlayerLoop		
			jr $ra					# return to caller



moveEnemy:		lw $s2, 4($a1)				# if enemy has reached the left border of the map, respawn it at the right side of the map
			li $s0, 0				# $s0 indicates the current pixel of enemy
			li $s1, 7				# $s1 indicates the last pixel of enemy	
			blez $s2, respawnEnemy	
moveLeftEnemyPixel:	lw $s3, 4($a1)				# get the column of the current pixel of enemy
			add $s3, $s3, $a2			# subract the column by 1 to move left
			sw $s3, 4($a1)
			addi $a1, $a1, 8			# visit the next pixel of enemy
			addi $s0, $s0, 1				
			ble $s0, $s1, moveLeftEnemyPixel
			la $a2, player				
			jr $ra					# return to caller
				
respawnEnemy:		li $s0, 0				# $s0 indicates the current pixel of enemy
			li $s1, 7				# $s1 indicates the last pixel of enemy	
			move $s2, $a1				# $s2 stores the address of enemy temporarily
			li $v0, 42				# get a random number for the row where the enemy ship respawns			
			li $a0, 0				
			li $a1, 27
			syscall
			move $a1, $s2				# move the address of enemy back to $a1
			move $s2, $a0				# $s2 stores the random number between 4-30
			addi $s2, $s2, 4
			addi $s3, $s2, -1
			addi $s4, $s2, 1
			sw $s2, 0($a1)				# update the rows of all pixels of the enemy ship based on the random number
			sw $s3, 8($a1)
			sw $s2, 16($a1)
			sw $s4, 24($a1)
			sw $s3, 32($a1)
			sw $s4, 40($a1)
			sw $s3, 48($a1)
			sw $s4, 56($a1)
			la $s5, default_enemy_col		# $s5 indicates the default columns of where the enemy ship spawns
respawnEnemyPixel:	lw $s3, 0($s5)				# set the columns of all pixels of the enemy ship to the right side of the map
			sw $s3, 4($a1)
			addi $a1, $a1, 8			# visit the next pixel of enemy
			addi $s5, $s5, 4			# visit the next index of default_enemy_col
			addi $s0, $s0, 1				
			ble $s0, $s1, respawnEnemyPixel				
			jr $ra					# return to caller



check_collison:		li $s0, 0				# check if enemy is getting shot
			li $s1, 7		
			la $s2, shooting
			lw $s3, 0($s2)
			lw $s4, 4($s2)		
			move $s7, $a1				# $s7 stores the address of enemy	
shootingLoop:		li $s5, -1
			beq $s3, $s5, not_getting_shot		# skip if a shooting does nto exist
			lw $s5, 0($a1)				# get the row of the current pixel of enemy
			lw $s6, 4($a1)				# get the column of the current pixel of enemy
			bne $s3, $s5, not_getting_shot
			bne $s4, $s6, not_getting_shot		# jump to not_getting_shot if the shotting pixel does not overlap with current pixel of enemy	
			
			addi $sp, $sp, -4			# push $ra onto the stack before calling other functions
			sw $ra, 0($sp)	
			
			move $a0, $s3
			move $a1, $s4
			la $a2, BLACK				
			jal drawPixel 				# erase the pixel of shooting
			
			li $s0, -1			
			la $s2, shooting	
			sw $s0, 0($s2)				# update both row and column of the shooting pixel to -1
			sw $s0, 4($s2)				# to keep it out of the map
			
			move $a1, $s7				# move the address of enemy back to $a1
			la $a0, BLACK				# erase the enemy	
			jal drawEnemy		
			
			move $a1, $s7				# move the address of enemy back to $a1
			jal respawnEnemy			# respawn enemy
			
			la $a0, GREY				
			move $a1, $s7				# move the address of enemy back to $a1
			jal drawEnemy				# redraw enemy	
			
			lw $ra, 0($sp)				# pop saved $ra off the stack
			addi $sp, $sp, 4
			jr $ra					# return to caller								

not_getting_shot:	addi $a1, $a1, 8
			addi $s0, $s0, 1
			ble $s0, $s1, shootingLoop
			
			
			move $a1, $s7				# move the address of enemy back to $a1
			li $s0, 0				# enemy is not getting shot, check if enemy is colliding with player 
			li $s1, 7			
			move $a2, $a1				# $a2 stores the address of enemy	
collisonLoop:		lw $s2, 0($a1)				# get the row of the current pixel of enemy
			lw $s3, 4($a1)				# get the column of the current pixel of enemy
			li $s4, 0
			la $s5, player	
playerLoop:		lw $s6, 0($s5)				# get the row of the current pixel of player
			lw $s7, 4($s5)				# get the column of the current pixel of player		
			bne $s2, $s6, notColliding		
			bne $s3, $s7, notColliding		# jump to notColliding if current pixel of player does not overlap with current pixel of enemy
			
			addi $sp, $sp, -4			# push $ra onto the stack before calling other functions
			sw $ra, 0($sp)		
						
			la $a0, BLACK				
			move $a1, $a2				# move the address of enemy back to $a1
			jal drawEnemy				# erase the enemy	
								
			la $a0,	RED				# player flashes red to indicate a collison
			la $a1, player		
			jal drawPlayer				
			
			la $s0, player_health			# player takes damage if it is collding with an enemy
			jal damagePlayer	
			
			la $t0, player_colour			# player finishes flashing red
			lw $a0, 0($t0)				# get player colour
			la $a1, player		
			jal drawPlayer	
			
			move $a1, $a2				# respawn enemy
			jal respawnEnemy
			la $a0, GREY				# redraw enemy
			move $a1, $a2
			jal drawEnemy			
			
			lw $ra, 0($sp)				# pop saved $ra off the stack
			addi $sp, $sp, 4
			jr $ra					# return to caller						
								
notColliding:		addi $s5, $s5, 8
			addi $s4, $s4, 1
			ble $s4, $s1, playerLoop		# visit the next pixel of player
			
			addi $a1, $a1, 8			
			addi $s0, $s0, 1			
			ble $s0, $s1, collisonLoop		# visit the next pixel of enemy
			jr $ra					# return to caller	



drawEnemy:		li $s0, 0				# $s0 indicates the current pixel of enemy
			li $s1, 14				# $s1 indicates the last pixel of enemy	
drawEnemyLoop:		lw $s3, 0($a1)				# get the row of the current pixel of enemy
			sll $s4, $s3, ROW_SHIFT
			lw $s5, 4($a1)				# get the column of the current pixel of enemy
			sll $s5, $s5, 2
			add $s6, $s4, BASE_ADDRESS		# get the address of the current pixel 
			add $s6, $s6, $s5
			sw $a0, 0($s6)				# fill the pixel with the colour stored in $a0
			
			addi $a1, $a1, 8			# visit the next pixel of enemy
			addi $s0, $s0, 2			
			ble $s0, $s1, drawEnemyLoop	
			jr $ra					# return to caller
	


restorePlayerHealth:	la $s0, player_health 			
			li $s1, 0
			li $s2, 4
restoreLoop:		lw $s3, 0($s0)				# get the column of the right most pixel of player health bar
			li $s4, 26
			bge $s3, $s4, endOfRestore		# jump to endOfRestore if player already has maximum health
			li $s4, BASE_ADDRESS	
			sll $s5, $s3, 2	
			addi $s4, $s4, 128	
			add $s6, $s4, $s5			# get the address of the right most pixel of player health bar
			li $s7, RED
			sw $s7, 0($s6)				# fill the pixel red
			addi $s3, $s3, 1			# update the column of the right most pixel of player health bar
			sw $s3, 0($s0)
			addi $s1, $s1, 1
			blt $s1, $s2, restoreLoop		# visit the next pixel
endOfRestore:		jr $ra					# return to caller



damagePlayer:		la $s0, player_colour 			# get player colour
			lw $s1, 0($s0)
			li $s2, BLUE	
			beq $s1, $s2, remove_shield		# if player is shielded, remove the shield instead of giving damage
			la $s0, player_health 		
			li $s1, 0
			li $s2, 4
damageLoop:		lw $s3, 0($s0)
			addi $s3, $s3, -1			# move the column of the right most pixel of player health bar one to the left
			sw $s3, 0($s0)
			li $s4, BASE_ADDRESS	
			sll $s5, $s3, 2	
			addi $s4, $s4, 128	
			add $s6, $s4, $s5			# get the address of the right most pixel of player health bar
			li $s7, DARK_GREY
			sw $s7, 0($s6)				# fill the pixel dark grey
			addi $s1, $s1, 1
			blt $s1, $s2, damageLoop		# visit the next pixel
			li $s0, 6
			ble, $s3, $s0, GAMEOVER 		# if player has no more health, end the game and jump to the Game Over screen
			li $v0, 32				# freeze for 0.5 second
			li $a0, 500
			syscall	
			jr $ra					# return to caller	
				
		
player_gain_shield:	addi $sp, $sp, -4			# push $ra onto the stack before calling drawPlayer
			sw $ra, 0($sp)
			la $s0, player_colour			# change player colour to blue to indicate it is shielded
			li $a0, BLUE
			sw $a0, 0($s0)				# store the colour value in player_colour
			jal drawPlayer				# paint the player blue 
			lw $ra, 0($sp)				# pop saved $ra off the stack
			addi $sp, $sp, 4
			jr $ra					# return to caller


remove_shield:		addi $sp, $sp, -4			# push $ra onto the stack before calling drawPlayer
			sw $ra, 0($sp)
			li $a0, GREEN				# remove the shield for player
			sw $a0, 0($s0)				# change player colour back to green to indicate the shield broke
			jal drawPlayer				# colour the player green
			lw $ra, 0($sp)				
			addi $sp, $sp, 4			# pop saved $ra off the stack
			jr $ra 					# return to caller
			
					
																																																																	
GAMEOVER:		la $t0, player_health			# remove player health bar
			li $t1, 25
			li $t6, BLACK
removePlayerHealthLoop:	lw $t2, 0($t0)				# get the column of each pixel of player health bar
			li $t3, BASE_ADDRESS	
			sll $t4, $t2, 2	
			addi $t3, $t3, 128	
			add $t5, $t3, $t4			# get the address of the pixel
			sw $t6, 0($t5)
			addi $t2, $t2, 1			
			sw $t2, 0($t0)				# remove the pixel by filling it black
			ble $t2, $t1, removePlayerHealthLoop	# visit the next pixel of player health bar until the entire health bar is removed				
			li $a0, BLACK				# erase the player
			jal drawPlayer
			la $a1, enemy_one			# erase enemy one
			jal drawEnemy
			la $a1, enemy_two			# erase enemy two
			jal drawEnemy
			la $a1, enemy_three			# erase enemy three
			jal drawEnemy	
			
			la $t0, shooting			# erase the shooting pixel 
			lw $a0, 0($t0)
			lw $a1, 4($t0)
			li $a2, BLACK
			jal drawPixel
			
			la $t0, health_item			# erase the health item
			lw $a0, 0($t0)
			lw $a1, 4($t0)
			li $a2, BLACK
			jal drawPixel
			
			la $t0, shield_item			# erase the shield item
			lw $a0, 0($t0)
			lw $a1, 4($t0)
			li $a2, BLACK
			jal drawPixel			
															
			la $a2, GREEN				# draw the GAME OVER text
			jal drawGAMEOVERtext								
			
end_of_game:		li $t9, KEY_PRESSED			# wait until a key is pressed
			lw $t8, 0($t9)
			beq $t8, 1, end_key_pressed
 			j end_of_game
 			
end_key_pressed:	lw $t8, 4($t9) 				# check which key is pressed and perform corresponding actions
			bne $t8, P_KEY, end_of_game	
			la $a2, BLACK				# erase the GAME OVER text
			jal drawGAMEOVERtext			
			j restartGame				# restart the game
			

	
restartGame:		la $t0, wait_time			# reset the wait time
			li $t1, 5000
			sw $t1, 0($t0)
			la $t0, player_health			# reset player health 
			li $t1, 6
			sw $t1, 0($t0) 
			
			la $t0, player_colour			# reset player colour to green
			li $t1, GREEN
			sw $t1, 0($t0)				
			
			la $t0, health_item			# erase the health item
			lw $a0, 0($t0)
			lw $a1, 4($t0)
			li $a2, BLACK
			jal drawPixel
			li $t1, -1
			sw $t1, 0($t0)				# reset the position of the health item
			sw $t1, 4($t0)
			
			la $t0, shield_item			# erase the shield item
			lw $a0, 0($t0)
			lw $a1, 4($t0)
			li $a2, BLACK
			jal drawPixel			
			sw $t1, 0($t0)				# reset the position of the shield item
			sw $t1, 4($t0)
			
			la $t0, shooting			# erase the shooting pixel 
			lw $a0, 0($t0)
			lw $a1, 4($t0)
			li $a2, BLACK
			jal drawPixel
			li $t1, -1				# reset the position of the shooting pixel
			sw $t1, 0($t0)
			sw $t1, 4($t0)					
								
			li $a0, BLACK				# erase the player
			jal drawPlayer
			la $a1, enemy_one			# erase enemy one
			jal drawEnemy
			la $a1, enemy_two			# erase enemy two
			jal drawEnemy
			la $a1, enemy_three			# erase enemy three
			jal drawEnemy	
			
			la $a0, player				# reset the position of player
			li $t1, 15
			sw $t1, 0($a0)
			sw $t1, 24($a0)
			li $t1, 1
			sw $t1, 4($a0)
			sw $t1, 12($a0)
			li $t1, 16
			sw $t1, 8($a0)
			sw $t1, 16($a0)
			sw $t1, 32($a0)
			sw $t1, 48($a0)
			sw $t1, 56($a0)
			li $t1, 2
			sw $t1, 20($a0)
			li $t1, 3 
			sw $t1, 28($a0)
			sw $t1, 36($a0)
			sw $t1, 44($a0)
			li $t1, 4
			sw $t1, 52($a0)
			li $t1, 5
			sw $t1, 60($a0)
			li $t1, 17
			sw $t1, 40($a0)
					
			la $a0, enemy_one			# reset positions of all enemies
			la $a1, enemy_two
			la $a2, enemy_three		
			li $t1, -1
			sw $t1, 0($a0)
			sw $t1, 0($a2)		
			li $t1, 6  
			sw $t1, 8($a0)
			sw $t1, 32($a0)
			sw $t1, 48($a0)		
			li $t1, 7
			sw $t1, 16($a0)		
			li $t1, 8
			sw $t1, 24($a0)
			sw $t1, 40($a0)
			sw $t1, 56($a0)			
			li $t1, 15
			sw $t1, 8($a1)
			sw $t1, 32($a1)
			sw $t1, 48($a1)						
			li $t1, 16
			sw $t1, 0($a1)
			sw $t1, 16($a1)			
			li $t1, 17
			sw $t1, 24($a1)
			sw $t1, 40($a1)
			sw $t1, 56($a1)			
			li $t1, 24
			sw $t1, 8($a2)
			sw $t1, 32($a2)
			sw $t1, 48($a2)			
			li $t1, 25
			sw $t1, 16($a2)			
			li $t1, 26
			sw $t1, 24($a2)
			sw $t1, 40($a2)
			sw $t1, 56($a2)			
			li $t1, 28
			sw $t1, 4($a0)
			sw $t1, 4($a1)
			sw $t1, 4($a2)			
			li $t1, 29
			sw $t1, 12($a0)
			sw $t1, 20($a0)
			sw $t1, 28($a0)
			sw $t1, 12($a1)
			sw $t1, 20($a1)
			sw $t1, 28($a1)
			sw $t1, 12($a2)
			sw $t1, 20($a2)
			sw $t1, 28($a2)						
			li $t1, 30
			sw $t1, 36($a0)
			sw $t1, 44($a0)
			sw $t1, 36($a1)
			sw $t1, 44($a1)
			sw $t1, 36($a2)
			sw $t1, 44($a2)			
			li $t1, 31
			sw $t1, 52($a0)
			sw $t1, 60($a0)
			sw $t1, 52($a1)
			sw $t1, 60($a1)
			sw $t1, 52($a2)
			sw $t1, 60($a2)
			j main					# return to start of game
			
			

drawPixel:		sll $s0, $a0, ROW_SHIFT
			sll $s1, $a1, 2
			add $s2, $s0, BASE_ADDRESS
			add $s2, $s2, $s1			# get the address of the pixel 
			sw $a2, 0($s2)				# colour the pixel 
			jr $ra					# return to caller
			
					
									
drawGAMEOVERtext:	addi $sp, $sp, -4			# push $ra onto the stack before calling other functions
			sw $ra, 0($sp)
			li $a0,	8				# draw all the pixels on row 8
			li $a1, 3				
			jal drawPixel				
			li $a1, 4
			jal drawPixel
			li $a1, 5
			jal drawPixel
			li $a1, 6
			jal drawPixel
			li $a1, 7
			jal drawPixel
			li $a1, 11
			jal drawPixel
			li $a1, 12
			jal drawPixel
			li $a1, 13
			jal drawPixel
			li $a1, 17
			jal drawPixel
			li $a1, 21
			jal drawPixel
			li $a1, 24
			jal drawPixel
			li $a1, 25
			jal drawPixel
			li $a1, 26
			jal drawPixel
			li $a1, 27
			jal drawPixel
			li $a1, 28
			jal drawPixel
			
			li $a0, 9				# draw all the pixels on row 9
			li $a1, 3
			jal drawPixel
			li $a1, 10
			jal drawPixel
			li $a1, 14
			jal drawPixel
			li $a1, 17
			jal drawPixel
			li $a1, 18
			jal drawPixel
			li $a1, 20
			jal drawPixel
			li $a1, 21
			jal drawPixel
			li $a1, 24
			jal drawPixel
			
			li $a0, 10 				# draw all the pixels on row 10
			li $a1, 3
			jal drawPixel
			li $a1, 10
			jal drawPixel
			li $a1, 14
			jal drawPixel
			li $a1, 17
			jal drawPixel
			li $a1, 19
			jal drawPixel
			li $a1, 21
			jal drawPixel
			li $a1, 24
			jal drawPixel		
			
			li $a0, 11				# draw all the pixels on row 11
			li $a1, 3
			jal drawPixel
			li $a1, 5
			jal drawPixel
			li $a1, 6
			jal drawPixel
			li $a1, 7
			jal drawPixel
			li $a1, 10
			jal drawPixel
			li $a1, 11
			jal drawPixel
			li $a1, 12
			jal drawPixel
			li $a1, 13
			jal drawPixel
			li $a1, 14
			jal drawPixel
			li $a1, 17
			jal drawPixel	
			li $a1, 21
			jal drawPixel		
			li $a1, 24
			jal drawPixel
			li $a1, 25
			jal drawPixel
			li $a1, 26
			jal drawPixel
			li $a1, 27
			jal drawPixel
			
			li $a0, 12				# draw all the pixels on row 12
			li $a1, 3
			jal drawPixel
			li $a1, 7
			jal drawPixel
			li $a1, 10
			jal drawPixel
			li $a1, 14
			jal drawPixel
			li $a1, 17
			jal drawPixel
			li $a1, 21
			jal drawPixel
			li $a1, 24
			jal drawPixel
			
			li $a0, 13				# draw all the pixels on row 13
			li $a1, 3
			jal drawPixel
			li $a1, 7
			jal drawPixel
			li $a1, 10
			jal drawPixel
			li $a1, 14
			jal drawPixel
			li $a1, 17
			jal drawPixel
			li $a1, 21
			jal drawPixel
			li $a1, 24
			jal drawPixel
			
			li $a0, 14				# draw all the pixels on row 14
			li $a1, 3
			jal drawPixel
			li $a1, 4
			jal drawPixel
			li $a1, 5
			jal drawPixel
			li $a1, 6
			jal drawPixel
			li $a1, 7
			jal drawPixel
			li $a1, 10
			jal drawPixel
			li $a1, 14
			jal drawPixel
			li $a1, 17
			jal drawPixel
			li $a1, 21
			jal drawPixel
			li $a1, 24
			jal drawPixel
			li $a1, 25
			jal drawPixel
			li $a1, 26
			jal drawPixel
			li $a1, 27
			jal drawPixel
			li $a1, 28
			jal drawPixel
			
			li $a0, 17				# draw all the pixels on row 17
			li $a1, 4
			jal drawPixel
			li $a1, 5
			jal drawPixel
			li $a1, 6
			jal drawPixel
			li $a1, 10
			jal drawPixel
			li $a1, 14
			jal drawPixel
			li $a1, 17
			jal drawPixel
			li $a1, 18
			jal drawPixel
			li $a1, 19
			jal drawPixel
			li $a1, 20		
			jal drawPixel
			li $a1, 21
			jal drawPixel
			li $a1, 24
			jal drawPixel
			li $a1, 25
			jal drawPixel
			li $a1, 26
			jal drawPixel
			li $a1, 27
			jal drawPixel
			
			li $a0, 18				# draw all the pixels on rows 18, 19, 21, 22, since their pixels share the same columns
			li $t0, 22
			li $t1, 20
drawPixelLoop:		beq $a0, $t1, row_twenty		# if current row is 20, jump to row_twenty	
			li $a1, 3
			jal drawPixel
			li $a1, 7
			jal drawPixel
			li $a1, 10
			jal drawPixel
			li $a1, 14
			jal drawPixel
			li $a1, 17
			jal drawPixel
			li $a1, 24
			jal drawPixel
			li $a1, 28
			jal drawPixel
			addi $a0, $a0, 1
			ble $a0, $t0, drawPixelLoop
			
			li $a0, 23				# draw all pixels on row 23
			li $a1, 4
			jal drawPixel
			li $a1, 5
			jal drawPixel
			li $a1, 6
			jal drawPixel
			li $a1, 11
			jal drawPixel
			li $a1, 12
			jal drawPixel
			li $a1, 13
			jal drawPixel
			li $a1, 17
			jal drawPixel
			li $a1, 18
			jal drawPixel
			li $a1, 19
			jal drawPixel
			li $a1, 20
			jal drawPixel
			li $a1, 21
			jal drawPixel
			li $a1, 24
			jal drawPixel
			li $a1, 28
			jal drawPixel	
			lw $ra, 0($sp)				# pop saved ra off the stack
			addi $sp, $sp, -4
			jr $ra					# return to caller						
			
row_twenty:		li $a1, 3
			jal drawPixel
			li $a1, 7
			jal drawPixel
			li $a1, 10
			jal drawPixel
			li $a1, 14
			jal drawPixel
			li $a1, 17
			jal drawPixel
			li $a1, 18
			jal drawPixel
			li $a1, 19
			jal drawPixel
			li $a1, 20
			jal drawPixel
			li $a1, 24
			jal drawPixel
			li $a1, 25
			jal drawPixel
			li $a1, 26
			jal drawPixel
			li $a1, 27
			jal drawPixel
			addi $a0, $a0, 1
			j drawPixelLoop
