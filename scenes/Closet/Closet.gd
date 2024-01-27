@tool
extends Polygon2D

@export var sprite_open: Texture = preload("res://icon.svg")
@export var sprite_closed: Texture = preload("res://icon.svg")

@onready var InsideChecker = $InsideChecker
@onready var InsideCheckerPolygon = $InsideChecker/CollisionPolygon2D
@onready var EdgeChecker = $EdgeChecker/CollisionPolygon2D
@onready var SpriteOpen = $SpriteOpen
@onready var SpriteClosed = $SpriteClosed

var is_open = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		_make_poly()
		SpriteOpen.texture = sprite_open
		SpriteClosed.texture = sprite_closed

func _physics_process(delta):
	if not Engine.is_editor_hint():
		SpriteOpen.visible = is_open
		SpriteClosed.visible = not is_open
	
	if Engine.is_editor_hint():
		_make_poly()
		SpriteOpen.texture = sprite_open
		SpriteClosed.texture = sprite_closed

func _make_poly():
	EdgeChecker.polygon = self.polygon

	var slightly_smaller_poly = PackedVector2Array()
	# scale each vertex
	for i in self.polygon.size():
		slightly_smaller_poly.append(self.polygon[i] * 0.9)
	
	InsideCheckerPolygon.polygon = slightly_smaller_poly


func _on_inside_checker_body_entered(body):
	if body.name == "Player":
		if body.velocity.x < -50 and is_open:
			is_open = false
			(func(): InsideChecker.monitorable = false).call_deferred()
		if body.velocity.x > 50:
			is_open = true
			(func(): InsideChecker.monitorable = true).call_deferred()
		print(is_open)

