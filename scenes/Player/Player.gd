extends CharacterBody2D

#old variables
#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0
# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#jump and move vars [g]round [a]ir
enum MoveState { on_ground, jumping, falling, fast_fall, coyote_time}
var prev_player_state = null
var player_state = MoveState.on_ground

@export var g_top_speed		= 200
@export var g_forward_speed =  20 
@export var g_reverse_speed =  10
@export var g_decel 		=  10 #ground friction

@export var a_top_speed 	=  100
@export var a_forward_speed =  10
@export var a_reverse_speed =  10
@export var a_decel 		=  300 #air friction

@export var jump_strength 	= -400
@export var grav_normal		=  980 #normal gravity, like when move off a ledge
@export var grav_on_jump 	=  980 #project settings = 980
@export var grav_on_fall 	=  980*2 #increase grav on release jump button
@export var max_fall_speed  =  800


#PHYSICS STEP
func _physics_process(delta):
	#friction check
	
	var is_entering_new_state = player_state != prev_player_state
	if is_entering_new_state:
		prev_player_state = player_state
	
	#check state
	match player_state:
		MoveState.on_ground:
			on_ground(delta, is_entering_new_state)
		MoveState.jumping:
			jumping(delta, is_entering_new_state)
		MoveState.falling:
			falling(delta, is_entering_new_state)
	
	
	## Add the gravity.
	#if not is_on_floor():
		#velocity.y += grav_on_jump * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("jump"):
		##velocity.y = JUMP_VELOCITY
		#if is_on_floor() :
			#velocity.y = jump_strength
		##else :
		##	velocity.y += grav_on_jump
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction = Input.get_axis("move_left", "move_right")
#
	#if direction :
		#velocity.x = move_toward(velocity.x, direction*g_top_speed, g_forward_speed)
		#print(velocity.x)
#
	#else:
		#velocity.x = move_toward(velocity.x, 0, 10)
#
	#move_and_slide()

func on_ground(delta, isEntering: bool) -> void:
	if (isEntering):
		pass
	print("on ground")
	
	#jump
	if Input.is_action_just_pressed("jump"):
		print("jump")
		player_state = MoveState.jumping
		velocity.y = jump_strength
	
	#move left and right
	var direction = Input.get_axis("move_left", "move_right")
	if direction :
		print("moving")
		velocity.x = move_toward(velocity.x, direction*g_top_speed, g_forward_speed)
		print(velocity.x)
	else :
		velocity.x = move_toward(velocity.x, 0, 10)
	
	move_and_slide()

func jumping(delta, isEntering: bool) -> void:
	if (isEntering):
		pass
	
	velocity.y = move_toward(velocity.y, max_fall_speed, grav_on_jump*delta)
	
	if velocity.y <= 0:
		player_state = MoveState.falling
	
	move_and_slide()

func falling(delta, isEntering: bool) -> void:
	# Hello I am breaking your thing with a merge!!!!!!
	# Hello I am breaking your thing with a merge!!!!!!
	# Hello I am breaking your thing with a merge!!!!!!
	# Hello I am breaking your thing with a merge!!!!!!
	# Hello I am breaking your thing with a merge!!!!!!
	# Hello I am breaking your thing with a merge!!!!!!
	if (isEntering):
		pass
	
	print("falling")
	velocity.y = move_toward(velocity.y, max_fall_speed, grav_normal*delta)
	
	var did_hit_something = move_and_slide()
	
	if did_hit_something:
		player_state = MoveState.on_ground

