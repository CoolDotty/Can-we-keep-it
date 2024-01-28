extends CharacterBody2D
class_name Pet


@export var species: String
@export var nickname: String


@onready var sprite_limbs = $SpriteLimbs
@onready var sprite_no_limbs = $SpriteNoLimbs
@onready var collision_polygon_2d = $CollisionPolygon2D


var _disabled = false


func _ready():
	self.add_to_group("pets")


func pick_up():
	_disabled = true
	(func(): collision_polygon_2d.disabled = true).call_deferred()
	velocity = Vector2.ZERO


func drop():
	_disabled = false
	(func(): collision_polygon_2d.disabled = false).call_deferred()

func place():
	_disabled = true
	(func(): collision_polygon_2d.disabled = false).call_deferred()
