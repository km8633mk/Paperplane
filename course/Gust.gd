@tool
extends Area2D
class_name Gust
## Wind zone. Positive strength is an updraft, negative a (purple) downdraft.
## The plane decides how strongly it reacts (see PaperPlane.enter_wind).

const DOWNDRAFT_TINT := Color(0.75, 0.55, 0.7, 0.9)
const UPDRAFT_TINT := Color(1, 1, 1, 0.9)
const TILE_HEIGHT := 96.0

@export var size := Vector2(192, 384):
	set(value):
		size = value
		_refresh()
@export var strength := 260.0:
	set(value):
		strength = value
		_refresh()

var _time := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_refresh()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)

func _refresh() -> void:
	if not is_node_ready():
		return
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	# Repeat the arrows instead of stretching them; flip them for downdrafts.
	sprite.region_rect = Rect2(Vector2.ZERO, size)
	sprite.flip_v = strength < 0.0
	sprite.modulate = DOWNDRAFT_TINT if strength < 0.0 else UPDRAFT_TINT

func _process(delta: float) -> void:
	# Scroll the arrows in the wind direction (flip_v turns this around for downdrafts).
	_time += delta
	sprite.region_rect.position.y = fposmod(_time * 60.0, TILE_HEIGHT)

func _on_body_entered(body: Node2D) -> void:
	if body is PaperPlane:
		body.enter_wind(strength)

func _on_body_exited(body: Node2D) -> void:
	if body is PaperPlane:
		body.exit_wind()
