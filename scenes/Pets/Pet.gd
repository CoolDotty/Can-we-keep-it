extends CharacterBody2D
class_name Pet


@export var species: String
@export var nickname: String

@export var idle_noise: AudioStream
@export var drop_noise: AudioStream
@export var grab_noise: AudioStream
@export var panic_noise: AudioStream


@onready var sprite_limbs = $SpriteLimbs
@onready var sprite_no_limbs = $SpriteNoLimbs
@onready var collision_polygon_2d = $CollisionPolygon2D

func _audio_register(name):
	var a = AudioStreamPlayer.new()
	a.name = name
	add_child(a)
	return a

@onready var idle_player = _audio_register("IdlePlayer")
@onready var drop_player = _audio_register("DropPlayer")
@onready var grab_player = _audio_register("GrabPlayer")
@onready var panic_player = _audio_register("PanicPlayer")

var _disabled = false

#INITIATE VARS
#region
#gravity
var grav_on = true
var grav_accel  	= 900
var max_fall_speed 	= 300
#horizontal deceleration
var friction = true
var g_decel 		=  800 #ground friction
#weight class - affects through distance
var weight = 1;

#endregion

func _ready():
	self.add_to_group("pets")
	var idle  = AudioStreamPlayer.new()
	name

#step
func _physics_process(delta):
	if _disabled:
		return
	#gravity
	if grav_on and not is_on_floor():
		velocity.y = move_toward(velocity.y, max_fall_speed, grav_accel*delta)
	#friction
	if friction and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, g_decel*delta)
		
	move_and_slide()

#methods
#region
func pick_up():
	_disabled = true
	(func(): collision_polygon_2d.disabled = true).call_deferred()
	velocity = Vector2.ZERO

func drop():
	_disabled = false
	(func(): collision_polygon_2d.disabled = false).call_deferred()

func place():
	_disabled = true
	# NOTE: This algorithm doesn't work for all shapes lmao
	# Set collision layer to new fridge only pets layer
	set_collision_layer_value(3, 0)
	set_collision_layer_value(5, 1)
	
	# how much to scale each vertex by
	var scaleAmount : float = 0.5
	# reference to the PoolVector2Array on the CollisionPolygon2D
	var polygon = collision_polygon_2d.polygon.duplicate()
	# scale each vertex
	for i in polygon.size():
		polygon[i] = polygon[i] * scaleAmount
	
	# assign the newly scaled vertices to the CollisionPolygon2D
	(func(): collision_polygon_2d.polygon = polygon).call_deferred()
	z_index = -1
	(func(): collision_polygon_2d.disabled = false).call_deferred()
#endregion
