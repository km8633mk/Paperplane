extends Area2D
class_name Mailbox
## The finish. Its trigger spans the whole sky so the plane cannot fly past it.

signal reached(mailbox_position: Vector2)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is PaperPlane and body.is_active():
		set_deferred("monitoring", false)
		reached.emit(global_position)
