extends Pet

#Initiate Variables
#region

@onready var fidget_timer = $FidgetTimer


@export var g_top_speed		= 100
@export var g_accel 		= 150
@export var g_decel 		= 100 #ground friction

@export var a_decel 		=  3 #air friction

@export var jump_strength 	= -400
@export var grav_normal		=  980 #normal gravity, like when move off a ledge

var fidget_dir: int = 0


func _physics_process(delta):
	#stop if disabled
	if _disabled:
		return
	
	
	if velocity.x > 0:
		sprite_limbs.scale.x = -1
		sprite_no_limbs.scale.x = -1
	if velocity.x < 0:
		sprite_no_limbs.scale.x = 1
		sprite_no_limbs.scale.x = 1
	
	$Label.text = "%s" % fidget_dir
	if fidget_timer.is_stopped():
		fidget_dir = randi_range(-1, 1)
		fidget_timer.start(randf_range(5, 15))
	#friction
	if _disabled: 
		velocity.x = move_toward(velocity.x, 0, g_decel*delta)
		velocity.y = move_toward(velocity.y, 0, grav_normal * delta)
	else: 
		velocity.x = clamp(velocity.x + fidget_dir * g_accel, -g_top_speed, g_top_speed)
		velocity.x = move_toward(velocity.x, 0, g_decel * delta)
		velocity.y = move_toward(velocity.y, 400, grav_normal * delta)
	
	move_and_slide()
	
	if is_on_wall() and is_on_floor() and fidget_dir != 0:
		velocity.y += jump_strength


func drop():
	super()
	fidget_dir = 0
	fidget_timer.start(60)


func dodge():
	velocity += Vector2(jump_strength, 0).rotated(randf_range(0.0, PI))
