extends Node2D


@onready var sprite_open = $SpriteOpen
@onready var sprite_closed = $SpriteClosed

@onready var audio_open = $AudioOpen
@onready var audio_closed = $AudioClosed
@onready var contents = $Contents
@onready var inside_checker = $InsideChecker/CollisionShape2D

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
		contents.visible = true
		audio_open.play()


func _on_open_checker_body_exited(body):
	if body.name == "Player":
		is_open = false
		contents.visible = false
		(func(): inside_checker.disabled = true).call_deferred()
		audio_closed.play()
