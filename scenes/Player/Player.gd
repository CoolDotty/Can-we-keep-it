extends CharacterBody2D

#old variables
#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0
# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#Initiate Variables
#region
#states and animation - (no longer used for locomotion)
enum MoveState { idle, jogging, skidding, turbo, jumping, falling, fast_fall, coyote_time, stun}
var prev_player_state = null
var player_state = MoveState.falling

#actions
@export var throw_strength_x = 100
@export var throw_strength_y = -100
#jump and move vars [g]round [a]ir
@export var g_top_speed		= 90
@export var g_jog_speed		= 60
@export var g_turbo_multiplier = 6
@export var g_forward_speed =  5
@export var g_reverse_speed =  10
@export var g_decel 		=  10 #ground friction

@export var a_top_speed 	=  500
@export var a_forward_speed =  5
@export var a_reverse_speed =  5
@export var a_decel 		=  3 #air friction

@export var jump_strength 	= -250
@export var running_jump    = -50
@export var grav_normal		=  900 #normal gravity, like when move off a ledge
@export var grav_on_jump 	=  900/2 #project settings = 980
@export var grav_on_fall 	=  6000 #increase grav on release jump button
@export var max_fall_speed  =  300

@onready var jump_hold_timer = $JumpHoldTimer
@onready var turbo_timer = $TurboTimer
@onready var stun_timer = $StunTimer
@onready var player_sprite = $Player
@onready var hand = $Player/Hand
@onready var feet = $Feet
@onready var grabbox = $Grabbox
@onready var place_checker = $Player/Hand/PlaceChecker
@onready var place_checker_collision = $Player/Hand/PlaceChecker/CollisionPolygon2D
@onready var placement_tester = $PlacementTester
@onready var placement_tester_poly = $PlacementTester/CollisionPolygon2D
@onready var placement_tester_poly_visible = $PlacementTester/Polygon2D



#grabby droppy
var is_place_mode = false
var held = null

#switches
var grounded = true
var direction = -1
var is_jumping = false
var grab = false
var carry = false

var was_at = position

#endregion
@onready var stuck_check = $stuck_check
@onready var stuck_collision_shape_2d = $stuck_check/CollisionShape2D
@onready var player_collision_shape_2d = $CollisionShape2D

func _ready():
	#stuck check
	stuck_collision_shape_2d.shape = player_collision_shape_2d.shape.duplicate()
	stuck_collision_shape_2d.shape.size = stuck_collision_shape_2d.shape.size - Vector2(1, 1)

#animation
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
	#unstucl
	print(stuck_check.get_overlapping_bodies())
	#var walls = stuck_check.get_overlapping_bodies().filter(func(b): return not b.get_child(0).one_way_collision)
	var walls = stuck_check.get_overlapping_bodies().filter(func(b): 
		var collision_shape = b.get_child(0)
		if (is_instance_valid(collision_shape)):
			return not b.get_child(0).one_way_collision
		else :
			# inside tilemap. We are stuck :(
			return true
			)
	
	if walls.size() > 0:
		position = was_at
	else:
		was_at = position
	
	# every frame place mode - is this the phycokenetic thing?
	#region
	
	#phyco-kenetic-pickup and drop? removed beceuse of conflict with normal pick up ad drop
	if is_place_mode:
		#var axis = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
		#if Input.is_action_just_pressed("move_left"): hand.position.x -= 9
		#if Input.is_action_just_pressed("move_right"): hand.position.x += 9
		#if Input.is_action_just_pressed("move_up"): hand.position.y -= 9
		#if Input.is_action_just_pressed("move_down"): hand.position.y += 9
#
		#var edge = false
		#var inside = false
		#var occupied = false
		#var closet = null
		#for area in place_checker.get_overlapping_areas():
			#if area.name == "EdgeChecker":
				#edge = true
			#if area.name == "InsideChecker":
				#inside = true
				#closet = area.owner
			#if area.is_in_group("pets"):
				#pass # IDK LOL
		#
		#var can_put_in_closet = not occupied and inside and not edge
		#var can_drop = not inside and not edge
		#
		#if can_put_in_closet:
			#held.modulate = Color(1, 1, 1, 1.0)
		#elif can_drop:
			#held.modulate = Color(1, 1, 1, 0.5)
		#else:
			#held.modulate = Color(1, 0, 0, 0.9)
		#
		#if Input.is_action_just_pressed("place_mode") and is_place_mode:
			#is_place_mode = false
			#
			#if can_put_in_closet:
				#place_hand(closet)
				#
			## on exit placing mode
			#hand.position = Vector2(-13, 0) # HACK, default value
			#hand.top_level = false
			#place_checker.visible = false
		#return
		pass
	
		#is_place_mode = true
		## on enter place mode
		#if is_place_mode:
			#hand.top_level = true
			#hand.position = ((self.global_position / 9).floor() * 9) + Vector2(5, -4)
			#place_checker.visible = true
			#var pet_poly = held.find_child("CollisionPolygon2D").polygon
			#place_checker_collision.polygon = pet_poly
	#endregion
	
	#run animation - switch to accell or input flags later?
	if abs(velocity.x) > 0:
		player_sprite.play()
	else:
		player_sprite.stop()
	
	#START OF NEW STUFF (movement ver.2) ##########################################################
	
	#HORIZONTAL MOVEMENT
	#region
	#move left and right
	var towards = Input.get_axis("move_left","move_right")
	#change direction
	var grab_box = $Grabbox
	if towards>0 : 
		direction = 1
		grab_box.position = Vector2(7,0)
	elif towards<0 : 
		direction = -1
		grab_box.position = Vector2(-7,0)

	#apply fricton
	if towards == 0 :
		velocity.x = move_toward(velocity.x,0,g_decel)
		if is_on_floor(): player_state = MoveState.idle
	#accellerate
	else :
		var accel = 0
		if direction == towards: accel = g_forward_speed
		else : accel = g_reverse_speed 
		velocity.x = move_toward(velocity.x, g_top_speed*towards,accel)
		if is_on_floor(): player_state = MoveState.jogging
	#endregion
	
	#VERTICAL MOVEMENT - FALLING & JUMPING
	#region
	#apply gravity
	if not is_on_floor() :
		velocity.y = move_toward(velocity.y, max_fall_speed, grav_normal*delta)
	#jumping
	is_jumping = false
	var ups  = (abs(velocity.x)/g_top_speed)*running_jump + jump_strength
	if Input.is_action_just_pressed("jump"): 
		if is_on_floor() :
			if Input.is_action_pressed("move_down"):
				# Drop through one way collisions
				position.y += 1
				player_state = MoveState.falling
			else:
				#running start
				#var ups  = (abs(velocity.x)/g_top_speed)*running_jump + jump_strength
				is_jumping = true
				velocity.y = ups
				player_state = MoveState.jumping
	
	if Input.is_action_just_released("jump") and velocity.y<0:
		#calculate fall grav porportioinal to jump height/ jump strength velocity
		var fall_grav = abs(velocity.y)/abs(ups)
		#var fall_grav = (velocity.y*velocity.y) /abs(ups)
		velocity.y = move_toward(velocity.y, max_fall_speed, grav_on_fall*delta*fall_grav)
		is_jumping = false
		player_state = MoveState.falling
		
	
	
	
	#endregion
	
	#GRAB AND RELEASE
	#region
	var valid_depot = placemode2()
	
	if Input.is_action_just_pressed("place"):
		grab = true
		if direction == 1 :
			grab_box.position = Vector2(7,0)
		else :
			grab_box.position = Vector2(-7,0) 
	if Input.is_action_just_released("place"):
		drop_hand(valid_depot)
		carry = false
		grab = false
		
	if grab and !carry:
		var pets = grabbox.get_overlapping_bodies().filter(func(b): return b.is_in_group("pets"))
		var pet = pets.pop_back()
		if is_instance_valid(pet):
			pet.get_parent().remove_child(pet)
			pet.pick_up()
			pet.position = Vector2.ZERO
			(func(): hand.add_child(pet)).call_deferred()
			held = pet
			carry = true
				
	#endregion
	
	#apply physics!!
	move_and_slide()
	#print player state - debug
	$DEBUG.text = MoveState.keys()[player_state]
	
	#locomotive states, no longer used
	#Don't know what this means, (help) - kelvin
	#var is_entering_new_state = player_state != prev_player_state
	#check state
	#match player_state:
		#MoveState.idle:
			#on_idle(delta, is_entering_new_state)
		#MoveState.jogging:
			#on_jogging(delta, is_entering_new_state)
		#MoveState.turbo:
			#on_turbo(delta, is_entering_new_state)
		#MoveState.skidding:
			#on_skidding(delta, is_entering_new_state)
		#MoveState.jumping:
			#jumping(delta, is_entering_new_state)
		#MoveState.falling:
			#falling(delta, is_entering_new_state)
		#MoveState.stun:
			#on_stun(delta, is_entering_new_state)
	
	#closet stuff ( is [z] )
	#if Input.is_action_pressed("place"):
		#if hand_is_empty():
			#return
		
		#var areas = grabbox.get_overlapping_areas()
		#var closet = null
		#for a in areas:
			#if a.get("is_closet"):
				#closet = a
				#break;
		#
		#if is_instance_valid(closet):
			#pass
		#else:
			#drop_hand()
	
	#if is_entering_new_state:
		#prev_player_state = player_state
		##print(MoveState.keys()[player_state])

func placemode2():
	if not is_instance_valid(held):
		placement_tester_poly.polygon = []
		#held.rotation_degrees = 0
		placement_tester_poly_visible.color = Color.TRANSPARENT
		return null
	
	if Input.is_action_just_pressed("place_mode") and is_instance_valid(held):
		held.rotation_degrees += 90
	
	placement_tester_poly.polygon = held.collision_polygon_2d.polygon
	placement_tester_poly_visible.polygon = held.collision_polygon_2d.polygon
	placement_tester_poly_visible.color = Color(1, 0, 0, 0.5)
	placement_tester.rotation_degrees = held.rotation_degrees
	
	var depots = placement_tester.get_overlapping_areas()
	var pets = placement_tester.get_overlapping_bodies()
	var edgechecker = null
	for d in depots:
		if d.name == "EdgeChecker":
			edgechecker = d
			break
	var insidechecker = null
	for d in depots:
		if d.name == "InsideChecker":
			insidechecker = d
			break
	
	
	if is_instance_valid(edgechecker) and is_instance_valid(insidechecker) and edgechecker.owner != insidechecker.owner:
		# Sanity check we're looking at two parts of the same thing
		return null
	
	# No valid closet!
	if not is_instance_valid(insidechecker):
		return null
	
	# we HEAVILY assume these are rectangles
	var depot_top_left = insidechecker.global_position - (insidechecker.get_child(0).shape.size / 2)
	placement_tester.global_position.x = depot_top_left.x + snapped(hand.global_position.x - depot_top_left.x, 9)
	
	# If sprite width in tiles is odd !!!!
	if abs((int(round(held.sprite_limbs.texture.region.size.rotated(held.rotation).x / 9)))) % 2 == 1:
		placement_tester.global_position.x -= 4.5
	placement_tester.global_position.y = depot_top_left.y + snapped(hand.global_position.y - depot_top_left.y, 9)
	# If sprite height in tiles is odd !!!!
	if abs(int(round(held.sprite_limbs.texture.region.size.rotated(held.rotation).y / 9))) % 2 == 1:
		placement_tester.global_position.y -= 4.5
	
	if is_instance_valid(edgechecker):
		return null
	else:
		if pets.size() == 0:
			placement_tester_poly_visible.color = Color(0, 1, 0, 0.5)
		return insidechecker.owner.contents

#METHODS
#region
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
	#velocity.x = move_toward(velocity.x, 0, g_decel)
	
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
		#turbo_timer.start()
	
	if Input.is_action_just_pressed("jump"):
		player_state = MoveState.jumping
		return
	
	var is_wish_right = Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left")
	var is_wish_left = Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right")
	var is_going_right = velocity.x > 0
	var is_going_left = velocity.x < 0
	
	if is_wish_right:
		#if is_going_right:
			velocity.x = min(velocity.x + g_forward_speed, g_jog_speed)
			direction = 1
		#skidding  - removed
		#else:
			#player_state = MoveState.skidding
			#return
	elif is_wish_left:
		#if is_going_left:
			velocity.x = max(velocity.x + -1 * g_forward_speed, -1 * g_jog_speed)
			direction = -1
	else:
		velocity.x = move_toward(velocity.x, 0, g_decel)
		#skiddint - removed
		#else:
			#player_state = MoveState.skidding
			#return
	#else:
		#player_state = MoveState.skidding
		#return
	
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
	
	#if turbo_timer.is_stopped():
		#player_state = MoveState.turbo
		#return


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

func drop_hand(depot=null):
	if hand_is_empty():
		return
	if is_instance_valid(depot):
		place_hand2(depot)
		return
	var pet = held
	var gpos = pet.global_position
	pet.get_parent().remove_child(pet)
	pet.position = gpos
	
	var throw_mod_x = 100
	var throw_mod_y = -150
	if Input.is_action_pressed("move_down"):
		throw_mod_x = 25
		throw_mod_y = 0
	if Input.is_action_pressed("move_up"): 
		print("throw up!!")
		throw_mod_y = -300
		throw_mod_x = 0
	
	pet.velocity.x = (velocity.x +throw_mod_x*direction)*(1/pet.weight)
	pet.velocity.y = (velocity.y +throw_mod_y)*(1/pet.weight)
	pet.rotation = 0
	pet.drop()
	(func(): get_parent().add_child(pet)).call_deferred()
	held = null

func place_hand2(depot: Node2D):
	if hand_is_empty():
		return
	var gpos = placement_tester.global_position
	var grot = placement_tester.global_rotation
	held.get_parent().remove_child(held)
	held.position = gpos
	held.rotation = grot
	held.place()
	var r = held
	(func(): depot.add_child(r)).call_deferred()
	
	held = null

func place_hand(closet):
	if hand_is_empty():
		return
	var pet = held
	var gpos = pet.global_position
	pet.get_parent().remove_child(pet)
	pet.position = gpos
	pet.modulate = Color.WHITE
	pet.place()
	(func(): get_parent().add_child(pet)).call_deferred()
	held = null

func hand_is_empty() -> bool:
	return held == null

#func _on_grabbox_body_entered(body):
	#if body.is_in_group("pets") and grab:
		#if player_state == MoveState.stun:
			#return
		#var pet = body
		## Empty hand and player is higher than pet
		##if hand_is_empty() and feet.global_position.y < pet.feet.global_position.y:
		#if hand_is_empty() :
			#pet.get_parent().remove_child(pet)
			#pet.pick_up()
			#pet.position = Vector2.ZERO
			#(func(): hand.add_child(pet)).call_deferred()
			#held = pet
		#else:
			#pet.dodge();

#endregion
