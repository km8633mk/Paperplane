extends CanvasLayer
class_name HUD
## On-screen information: status line, mission progress, lives, flight mode,
## clock, centre messages and section banners.

const HEART := preload("res://sprites/heart.png")
const HEART_EMPTY := preload("res://sprites/heart_empty.png")
const TEXT_COLOR := Color("294d59")
const DONE_COLOR := Color("2f7d4f")

@onready var status_label: Label = $Status
@onready var mode_label: Label = $Mode
@onready var time_label: Label = $Time
@onready var message_label: Label = $Message
@onready var banner_label: Label = $Banner
@onready var hearts: Array[Node] = $Hearts.get_children()
@onready var item_labels := {
	Pickup.Kind.STAMP: $Items/StampCount,
	Pickup.Kind.COIN: $Items/CoinCount,
	Pickup.Kind.FEATHER: $Items/FeatherCount,
}

func set_status(text: String) -> void:
	status_label.text = text

func update_items(collected: Dictionary, required: Dictionary) -> void:
	for kind in item_labels:
		var label: Label = item_labels[kind]
		# Spare pickups may push the count past the goal; the display stops at the goal.
		label.text = "%d/%d" % [mini(collected[kind], required[kind]), required[kind]]
		label.add_theme_color_override("font_color", DONE_COLOR if collected[kind] >= required[kind] else TEXT_COLOR)

func update_lives(lives: int) -> void:
	for i in hearts.size():
		hearts[i].texture = HEART if i < lives else HEART_EMPTY

func update_mode(glider_mode: bool, boosting: bool, braking: bool, diving: bool) -> void:
	var text := "GLEITER" if glider_mode else "DÜSENFLIEGER"
	if braking:
		text += "   ·   BREMST"
	if diving:
		text += "   ·   SINKT"
	if boosting:
		text += "   ·   WIND-SCHUB!"
	mode_label.text = text

func update_time(run_time: float, best_time: float) -> void:
	time_label.text = "Zeit: %s\nBestzeit: %s" % [format_time(run_time), format_time(best_time) if best_time > 0.0 else "–"]

func show_message(text: String) -> void:
	message_label.text = text
	message_label.show()

func hide_message() -> void:
	message_label.hide()

func show_banner(text: String) -> void:
	banner_label.text = text
	var tween := create_tween()
	tween.tween_property(banner_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.4)
	tween.tween_property(banner_label, "modulate:a", 0.0, 0.5)

static func format_time(seconds: float) -> String:
	return "%d:%05.2f" % [int(seconds) / 60, fmod(seconds, 60.0)]
