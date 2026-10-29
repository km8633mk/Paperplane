extends Node2D
class_name Course
## The level. Every round CourseGenerator builds new obstacles and PickupSpawner
## rolls a new mission; section markers and the mailbox are placed in Course.tscn.
## Collects the signals of all course objects and passes them on to the game.

signal item_collected(kind: Pickup.Kind)
signal checkpoint_reached(respawn_point: Vector2)
signal section_entered(title: String)
signal finished(mailbox_position: Vector2)

## The mission for this round: how many pickups of each kind must be collected.
var required := {}

@onready var generator: CourseGenerator = $CourseGenerator
@onready var spawner: PickupSpawner = $PickupSpawner

func _ready() -> void:
	generator.generate(self)
	required = spawner.spawn(self)
	# Gates build their walls at runtime, so search unowned nodes too.
	for node in find_children("*", "", true, false):
		if node is Pickup:
			node.collected.connect(item_collected.emit)
		elif node is Gate:
			node.passed.connect(checkpoint_reached.emit)
		elif node is SectionTrigger:
			node.entered.connect(section_entered.emit)
		elif node is Mailbox:
			node.reached.connect(finished.emit)
