extends Camera2D

@export var focus: Node2D = null
@export var lerp_speed: float = 5.0

# Called when the node enters the scene tree for the first time.
func _ready():
	if is_instance_valid(focus):
		global_position = focus.global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var target = Vector2.ZERO
	if is_instance_valid(focus):
		target = focus.global_position
	global_position = global_position.lerp(target, lerp_speed * delta)
