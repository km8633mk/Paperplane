@tool
extends Area2D
class_name Wall
## A solid block of tiled wall. Crashes the plane on contact. Built by Gate.

const TEXTURE := preload("res://sprites/obstacle_wall.png")

var size := Vector2(96, 96)

func _init(new_size: Vector2 = Vector2(96, 96)) -> void:
	size = new_size

func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURE
	# Repeat the pixel texture at 1:1 instead of stretching it, so pixels stay square.
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, size)
	add_child(sprite)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is PaperPlane:
		body.hit()
