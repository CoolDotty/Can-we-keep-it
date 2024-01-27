extends CharacterBody2D


@export var species: String
@export var nickname: String

@onready var sprite_limbs = $SpriteLimbs
@onready var sprite_no_limbs = $SpriteNoLimbs
@onready var collision_polygon_2d = $CollisionPolygon2D

@onready var feet = $Feet
@onready var fidget_timer = $FidgetTimer


@export var g_top_speed		= 100
@export var g_accel 		= 150
@export var g_decel 		=  100 #ground friction

@export var a_decel 		=  3 #air friction

@export var jump_strength 	= -400
@export var grav_normal		=  980 #normal gravity, like when move off a ledge

var panic = 0
var fidget_dir: int = 0

var _disabled = false


func _ready():
	self.add_to_group("pets")


func _physics_process(delta):
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
	
	velocity.x = clamp(velocity.x + fidget_dir * g_accel, -g_top_speed, g_top_speed)
	
	velocity.x = move_toward(velocity.x, 0, g_decel * delta)
	velocity.y = move_toward(velocity.y, 400, grav_normal * delta)
	
	move_and_slide()
	
	if is_on_wall() and is_on_floor() and fidget_dir != 0:
		velocity.y += jump_strength


func pick_up():
	_disabled = true
	(func(): collision_polygon_2d.disabled = true).call_deferred()
	velocity = Vector2.ZERO


func dodge():
	velocity += Vector2(jump_strength, 0).rotated(randf_range(0.0, PI))


func drop():
	_disabled = false
	(func(): collision_polygon_2d.disabled = false).call_deferred()

func place():
	_disabled = true
	(func(): collision_polygon_2d.disabled = false).call_deferred()
