@tool
extends Area2D
class_name Hazard
## A moving obstacle (bird, balloon, kite) or a static one (chimney).
## Crashes the plane on contact.

enum Type { CHIMNEY, KITE, BIRD, BALLOON }

const TEXTURES := {
	Type.CHIMNEY: preload("res://sprites/obstacle_chimney.png"),
	Type.KITE: preload("res://sprites/obstacle_kite.png"),
	Type.BIRD: preload("res://sprites/obstacle_bird.png"),
	Type.BALLOON: preload("res://sprites/obstacle_balloon.png"),
}
# The hitbox covers the solid middle of the sprite, not its transparent edges.
const HITBOX_FACTOR := 0.5

@export var type := Type.BIRD:
	set(value):
		type = value
		_refresh()
@export var sprite_scale := 1.0:
	set(value):
		sprite_scale = value
		_refresh()
## How far it moves up and down (0 = static).
@export var bob_amplitude := 0.0
@export var bob_speed := 2.0

var _base_y := 0.0
var _time := randf() * TAU

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_refresh()
	_base_y = position.y
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _refresh() -> void:
	if not is_node_ready():
		return
	sprite.texture = TEXTURES[type]
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	# The bird sprite faces right; turn it so it flies towards the plane.
	sprite.flip_h = type == Type.BIRD
	var shape := RectangleShape2D.new()
	shape.size = Vector2(sprite.texture.get_size()) * sprite_scale * HITBOX_FACTOR
	collision.shape = shape

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or bob_amplitude <= 0.0:
		return
	_time += delta
	position.y = _base_y + sin(_time * bob_speed) * bob_amplitude

func _on_body_entered(body: Node2D) -> void:
	if body is PaperPlane:
		body.hit()
