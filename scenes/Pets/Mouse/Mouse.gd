extends CharacterBody2D


@export var species: String
@export var nickname: String

@onready var sprite_limbs = $SpriteLimbs
@onready var sprite_no_limbs = $SpriteNoLimbs
@onready var collision_shape_2d = $CollisionShape2D
@onready var feet = $Feet


@export var g_top_speed		= 10
@export var g_decel 		=  100 #ground friction

@export var a_decel 		=  3 #air friction

@export var jump_strength 	= -400
@export var grav_normal		=  980 #normal gravity, like when move off a ledge

func _ready():
	self.add_to_group("pets")


func _physics_process(delta):
	if collision_shape_2d.disabled:
		return
	
	velocity.x = move_toward(velocity.x, 0, g_decel * delta)
	velocity.y = move_toward(velocity.y, 400, grav_normal * delta)
	
	move_and_slide()


func pick_up():
	(func(): collision_shape_2d.disabled = true).call_deferred()
	velocity = Vector2.ZERO


func dodge():
	velocity += Vector2(jump_strength, 0).rotated(randf_range(0.0, PI))


func drop():
	(func(): collision_shape_2d.disabled = false).call_deferred()
