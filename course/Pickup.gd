@tool
extends Area2D
class_name Pickup
## Something to collect for the mission: a stamp, a coin or a feather.
## Bobs gently and pops when the plane picks it up.

signal collected(kind: Kind)

enum Kind { STAMP, COIN, FEATHER }

const TEXTURES := {
	Kind.STAMP: preload("res://sprites/stamp.png"),
	Kind.COIN: preload("res://sprites/coin.png"),
	Kind.FEATHER: preload("res://sprites/feather.png"),
}
## Singular and plural names, used for the mission text.
const NAMES := {
	Kind.STAMP: ["Briefmarke", "Briefmarken"],
	Kind.COIN: ["Münze", "Münzen"],
	Kind.FEATHER: ["Feder", "Federn"],
}

@export var kind := Kind.STAMP:
	set(value):
		kind = value
		if is_node_ready():
			sprite.texture = TEXTURES[kind]

var _time := randf() * TAU

@onready var sprite: Sprite2D = $Sprite2D

static func name_for(pickup_kind: Kind, count: int) -> String:
	return "%d %s" % [count, NAMES[pickup_kind][0 if count == 1 else 1]]

func _ready() -> void:
	sprite.texture = TEXTURES[kind]
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_time += delta
	sprite.position.y = sin(_time * 3.0) * 3.0

func _on_body_entered(body: Node2D) -> void:
	if not body is PaperPlane:
		return
	collected.emit(kind)
	set_deferred("monitoring", false)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", sprite.scale * 2.0, 0.25)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)
