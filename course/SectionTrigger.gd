extends Area2D
class_name SectionTrigger
## Invisible vertical line that announces a new course section.

signal entered(title: String)

@export var title := "Abschnitt"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is PaperPlane:
		set_deferred("monitoring", false)
		entered.emit(title)
