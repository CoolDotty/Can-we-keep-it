extends Node2D


@onready var sprite_open = $SpriteOpen
@onready var sprite_closed = $SpriteClosed

@onready var shelf_1 = $Shelf1/CollisionShape2D
@onready var shelf_2 = $Shelf2/CollisionShape2D
@onready var shelf_3 = $Shelf3/CollisionShape2D
@onready var audio_open = $AudioOpen
@onready var audio_closed = $AudioClosed
@onready var contents = $Contents
@onready var inside_checker = $EdgeChecker/CollisionPolygon2D


var is_open = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _physics_process(delta):
	sprite_open.visible = is_open
	sprite_closed.visible = not is_open


func _on_open_checker_body_entered(body):
	if body.name == "Player":
		is_open = true
		(func(): inside_checker.disabled = false).call_deferred()
		(func(): shelf_1.disabled = false).call_deferred()
		(func(): shelf_2.disabled = false).call_deferred()
		(func(): shelf_3.disabled = false).call_deferred()
		contents.visible = true
		audio_open.play()


func _on_open_checker_body_exited(body):
	if body.name == "Player":
		is_open = false
		(func(): inside_checker.disabled = true).call_deferred()
		(func(): shelf_1.disabled = true).call_deferred()
		(func(): shelf_2.disabled = true).call_deferred()
		(func(): shelf_3.disabled = true).call_deferred()
		contents.visible = false
		audio_closed.play()
