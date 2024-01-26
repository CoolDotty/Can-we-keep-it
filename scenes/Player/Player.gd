extends CharacterBody2D

#old variables
#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0
# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum MoveState { idle, jogging, skidding, turbo, jumping, falling, fast_fall, coyote_time, stun}
var prev_player_state = null
var player_state = MoveState.falling

#jump and move vars [g]round [a]ir
@export var g_top_speed		= 500
@export var g_jog_speed		= 60
@export var g_turbo_multiplier = 6
@export var g_forward_speed =  1
@export var g_reverse_speed =  10
@export var g_decel 		=  5 #ground friction

@export var a_top_speed 	=  100
@export var a_forward_speed =  5
@export var a_reverse_speed =  5
@export var a_decel 		=  3 #air friction

@export var jump_strength 	= -400
@export var grav_normal		=  980 #normal gravity, like when move off a ledge
@export var grav_on_jump 	=  980 #project settings = 980
@export var grav_on_fall 	=  980 * 2 #increase grav on release jump button
@export var max_fall_speed  =  800

@onready var jump_hold_timer = $JumpHoldTimer
@onready var turbo_timer = $TurboTimer
@onready var stun_timer = $StunTimer
@onready var player_sprite = $FollowParent2D/Player
@onready var hand = $FollowParent2D/Player/Hand
@onready var feet = $Feet


var direction = 1

func _process(delta):
	match player_state:
		MoveState.idle:
			player_sprite.rotation_degrees = 0
			player_sprite.speed_scale = -1
			player_sprite.frame = 1
		MoveState.jogging:
			player_sprite.rotation_degrees = 0
			player_sprite.speed_scale = sign(velocity.x) * clampf(abs(velocity.x * 0.01), 0.1, 2.0)
			if direction == 1:
				# Point in opposite direction if stunned
				if player_state == MoveState.stun:
					player_sprite.scale.x = 1
				else:
					player_sprite.scale.x = -1
			else:
				# Point in opposite direction if stunned
				if player_state == MoveState.stun:
					player_sprite.scale.x = -1
				else:
					player_sprite.scale.x = 1
		MoveState.turbo:
			player_sprite.rotation_degrees = 0
			player_sprite.speed_scale = sign(velocity.x) * clampf(abs(velocity.x * 0.01), 0.1, 2.0)
			if direction == 1:
				# Point in opposite direction if stunned
				if player_state == MoveState.stun:
					player_sprite.scale.x = 1
				else:
					player_sprite.scale.x = -1
			else:
				# Point in opposite direction if stunned
				if player_state == MoveState.stun:
					player_sprite.scale.x = -1
				else:
					player_sprite.scale.x = 1
		MoveState.skidding:
			player_sprite.speed_scale = -1
			player_sprite.frame = 1
			player_sprite.rotation_degrees = 0
		MoveState.jumping:
			player_sprite.speed_scale = -1
			player_sprite.frame = 0
			player_sprite.rotation_degrees = 0
		MoveState.falling:
			player_sprite.speed_scale = -1
			player_sprite.frame = 3
			player_sprite.rotation_degrees = 0
		MoveState.stun:
			player_sprite.speed_scale = -1
			player_sprite.frame = 1
			player_sprite.rotation_degrees = 90
	

#PHYSICS STEP
func _physics_process(delta):
	#friction check
	
	if velocity.x < 0:
		direction = -1
	if velocity.x > 0:
		direction = 1
	if abs(velocity.x) > 0:
		player_sprite.play()
	else:
		player_sprite.stop()
	
	$DEBUG.text = MoveState.keys()[player_state]
	
	var is_entering_new_state = player_state != prev_player_state
	
	#check state
	match player_state:
		MoveState.idle:
			on_idle(delta, is_entering_new_state)
		MoveState.jogging:
			on_jogging(delta, is_entering_new_state)
		MoveState.turbo:
			on_turbo(delta, is_entering_new_state)
		MoveState.skidding:
			on_skidding(delta, is_entering_new_state)
		MoveState.jumping:
			jumping(delta, is_entering_new_state)
		MoveState.falling:
			falling(delta, is_entering_new_state)
		MoveState.stun:
			on_stun(delta, is_entering_new_state)
	
	if is_entering_new_state:
		prev_player_state = player_state
		print(MoveState.keys()[player_state])


func on_ground(delta, isEntering: bool) -> void:
	if (isEntering):
		pass
	
	#jump
	if Input.is_action_just_pressed("jump"):
		player_state = MoveState.jumping
		return
	
	#move left and right
	var wish_dir = Input.get_axis("move_left", "move_right")
	var is_wish_right = wish_dir > 0
	var is_wish_left = wish_dir < 0
	var is_going_right = velocity.x > 0
	var is_going_left = velocity.x < 0
	var standing_still = velocity == Vector2.ZERO
	
	var skid_stopping = (is_wish_right and is_going_left) or (is_wish_left and is_going_right)
	var moving_with_velocity = (is_wish_right and is_going_right) or (is_wish_left and is_going_left)
	var turbo = (abs(velocity.x) > g_jog_speed - 5) and moving_with_velocity
	var jogging = not turbo and (moving_with_velocity or standing_still)
	
	if skid_stopping:
		velocity.x = move_toward(velocity.x, 0.0, g_reverse_speed)
	elif turbo:
		velocity.x = move_toward(velocity.x, wish_dir * g_top_speed, g_forward_speed * g_turbo_multiplier)
	elif jogging:
		velocity.x = move_toward(velocity.x, wish_dir * g_jog_speed, g_forward_speed)
	else: # Drifting to a stop
		velocity.x = move_toward(velocity.x, 0, g_decel)
	
	var pre_pos = position
	move_and_slide()
	
	# hit a wall
	if pre_pos == position:
		player_state = MoveState.idle
		return
	
	if not is_on_floor():
		player_state = MoveState.falling
		return
	

func on_idle(delta, isEntering: bool) -> void:
	if (isEntering):
		pass
	
	if Input.is_action_just_pressed("jump"):
		player_state = MoveState.jumping
		return
	
	var wish_dir = Input.get_axis("move_left", "move_right")
	var is_wish_right = wish_dir > 0
	var is_wish_left = wish_dir < 0
	
	if is_wish_right:
		player_state = MoveState.jogging
		velocity.x = 1
		# intentionally fall through (no return), to check if we're hitting a wall
	if is_wish_left:
		player_state = MoveState.jogging
		velocity.x = -1
		# intentionally fall through (no return), to check if we're hitting a wall
	
	var pre_pos = position
	move_and_slide()
	
	# hit a wall
	if pre_pos == position:
		player_state = MoveState.idle
		return
	
	if not is_on_floor():
		player_state = MoveState.falling
		return


func on_jogging(delta, isEntering: bool) -> void:
	if (isEntering):
		const minimum_starting_velocity = 1
		var d = sign(velocity.x)
		velocity.x = d * max(abs(velocity.x), minimum_starting_velocity)
		
		turbo_timer.start()
	
	if Input.is_action_just_pressed("jump"):
		player_state = MoveState.jumping
		return
	
	var is_wish_right = Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left")
	var is_wish_left = Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right")
	var is_going_right = velocity.x > 0
	var is_going_left = velocity.x < 0
	
	if is_wish_right:
		if is_going_right:
			velocity.x = min(velocity.x + g_forward_speed, g_jog_speed)
		else:
			player_state = MoveState.skidding
			return
	elif is_wish_left:
		if is_going_left:
			velocity.x = max(velocity.x + -1 * g_forward_speed, -1 * g_jog_speed)
		else:
			player_state = MoveState.skidding
			return
	else:
		player_state = MoveState.skidding
		return
	
	move_and_slide()
	
	var pre_pos = position
	move_and_slide()
	
	# hit a wall
	if pre_pos == position:
		player_state = MoveState.idle
		return
	
	if not is_on_floor():
		player_state = MoveState.falling
		return
	
	if turbo_timer.is_stopped():
		player_state = MoveState.turbo
		return


func on_turbo(delta, isEntering: bool) -> void:
	if (isEntering):
		pass
	
	if Input.is_action_just_pressed("jump"):
		player_state = MoveState.jumping
		return
	
	var is_wish_right = Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left")
	var is_wish_left = Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right")
	var is_going_right = velocity.x > 0
	var is_going_left = velocity.x < 0
	
	var pre_pos = position
	move_and_slide()
	
	# hit a wall
	if pre_pos == position:
		player_state = MoveState.stun
		return
	
	if is_wish_right:
		if is_going_right:
			velocity.x = min(velocity.x + g_forward_speed * g_turbo_multiplier, g_top_speed)
		else:
			player_state = MoveState.skidding
			return
	elif is_wish_left:
		if is_going_left:
			velocity.x = max(velocity.x + -1 * g_forward_speed * g_turbo_multiplier, -1 * g_top_speed)
		else:
			player_state = MoveState.skidding
			return
	else:
		player_state = MoveState.skidding
		return
	
	if not is_on_floor():
		player_state = MoveState.falling
		return


var can_skip_jogging: bool = false
func on_skidding(delta, isEntering: bool) -> void:
	if (isEntering):
		can_skip_jogging = abs(velocity.x) > g_jog_speed 
		pass
	
	if Input.is_action_just_pressed("jump"):
		player_state = MoveState.jumping
		return
	
	var wish_dir = Input.get_axis("move_left", "move_right")
	
	if abs(velocity.x) < 0.1:
		if wish_dir != 0:
			velocity.x = wish_dir
			if can_skip_jogging:
				player_state = MoveState.turbo
			else:
				player_state = MoveState.jogging
		else:
			velocity.x = 0
			player_state = MoveState.idle
		return
	
	var is_wish_right = wish_dir > 0
	var is_wish_left = wish_dir < 0
	var is_going_right = velocity.x > 0
	var is_going_left = velocity.x < 0
	
	if is_wish_right:
		if is_going_left:
			velocity.x = move_toward(velocity.x, 0, g_reverse_speed)
	elif is_wish_left:
		if is_going_right:
			velocity.x = move_toward(velocity.x, 0, g_reverse_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, g_decel)
	
	move_and_slide()
	
	if not is_on_floor():
		player_state = MoveState.falling
		return


#var current_jump: float = 0.0 
func jumping(delta, isEntering: bool) -> void:
	if (isEntering):
		velocity.y = jump_strength
		jump_hold_timer.start()
	
	
	velocity.y = move_toward(velocity.y, 0.0, grav_on_jump * delta)
	
	
	if Input.is_action_just_released("jump") or jump_hold_timer.is_stopped():
		player_state = MoveState.falling
		return
	
	var pre_pos = position
	move_and_slide()
	
	if pre_pos.x == position.x:
		player_state = MoveState.stun
		return
	


func falling(delta, isEntering: bool) -> void:
	if (isEntering):
		pass
	
	velocity.y = move_toward(velocity.y, max_fall_speed, grav_on_fall * delta)
	
	var did_hit_something = move_and_slide()
	
	if is_on_floor():
		if abs(velocity.x) > g_jog_speed:
			player_state = MoveState.turbo
		elif Input.get_axis("move_left", "move_right") != 0:
			player_state = MoveState.jogging
		elif abs(velocity.x) > 1:
			player_state = MoveState.skidding
		else:
			player_state = MoveState.idle
		return


func on_stun(delta, isEntering: bool) -> void:
	if (isEntering):
		stun_timer.start()
		velocity.y = -300
		velocity.x = 300
		drop_hand()
	
	velocity.x = move_toward(velocity.x, 0, g_decel)
	velocity.y = move_toward(velocity.y, max_fall_speed, grav_on_fall * delta)
	
	var pre_pos = position
	var pre_vel = velocity
	move_and_slide()
	
	#hit a wall
	if is_on_wall():
		velocity.x = pre_vel.x * -1
	
	if stun_timer.is_stopped():
		if Input.get_axis("move_left", "move_right"):
			player_state = MoveState.jogging
		else:
			player_state = MoveState.skidding
		return

func drop_hand():
	if hand_is_empty():
		return
	var pet = hand.get_child(0)
	var gpos = pet.global_position
	pet.get_parent().remove_child(pet)
	pet.position = gpos
	pet.velocity = velocity
	pet.drop()
	(func(): get_parent().add_child(pet)).call_deferred()
	

func hand_is_empty() -> bool:
	return hand.get_child_count() == 0

func _on_grabbox_body_entered(body):
	if body.is_in_group("pets"):
		if player_state == MoveState.stun:
			return
		var pet = body
		# Empty hand and player is higher than pet
		print(feet.global_position.y, '<', pet.feet.global_position.y)
		if hand_is_empty() and feet.global_position.y < pet.feet.global_position.y:
			pet.get_parent().remove_child(pet)
			pet.pick_up()
			pet.position = Vector2.ZERO
			(func(): hand.add_child(pet)).call_deferred()
		else:
			pet.dodge();
