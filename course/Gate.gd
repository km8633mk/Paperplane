@tool
extends Node2D
class_name Gate
## Two walls with a gap. The node sits at the centre of the gap.
## Narrow gates only let the folded dart through and help it aim.

signal passed(respawn_point: Vector2)

const GROUND := 510.0
const NARROW_GAP := 64.0
const NARROW_WIDTH := 48.0
const WIDE_WIDTH := 96.0
const NARROW_TINT := Color(1.0, 0.78, 0.72)
# How hard the dart is pulled towards the gap, and from how far ahead.
const AIM_ASSIST := 70.0
const AIM_RANGE := 220.0

@export var narrow := false:
	set(value):
		narrow = value
		_rebuild()
## Gap height for wide gates. Narrow gates always use NARROW_GAP.
@export var gap_height := 160.0:
	set(value):
		gap_height = value
		_rebuild()

var _plane: PaperPlane
var _plane_in_gap := false
var _passed := false

func _ready() -> void:
	_rebuild()
	if Engine.is_editor_hint():
		# Walls depend on the height of the gate, so rebuild them when it is moved in the editor.
		set_notify_transform(true)
	else:
		_plane = get_tree().get_first_node_in_group("player")

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		_rebuild()

func _rebuild() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		child.queue_free()
	var gap := get_gap()
	var width := get_width()
	# Walls reach from the top of the screen and down to the ground (global y 0 and GROUND).
	var top_height := position.y - gap / 2.0
	var bottom_height := GROUND - position.y - gap / 2.0
	_add_wall(Vector2(0, -gap / 2.0 - top_height / 2.0), Vector2(width, top_height))
	_add_wall(Vector2(0, gap / 2.0 + bottom_height / 2.0), Vector2(width, bottom_height))
	if narrow:
		_add_gap_zone(Vector2(width, gap))

func _add_wall(at: Vector2, size: Vector2) -> void:
	var wall := Wall.new(size)
	wall.position = at
	if narrow:
		wall.modulate = NARROW_TINT
	add_child(wall)

func _add_gap_zone(size: Vector2) -> void:
	# Invisible area in the gap: a glider inside it crashes, the dart passes.
	var zone := Area2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	zone.add_child(collision)
	zone.body_entered.connect(_on_gap_entered)
	zone.body_exited.connect(_on_gap_exited)
	add_child(zone)

func _on_gap_entered(body: Node2D) -> void:
	if body is PaperPlane:
		_plane_in_gap = true

func _on_gap_exited(body: Node2D) -> void:
	if body is PaperPlane:
		_plane_in_gap = false

func get_gap() -> float:
	return NARROW_GAP if narrow else gap_height

func get_width() -> float:
	return NARROW_WIDTH if narrow else WIDE_WIDTH

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _plane == null:
		return
	var distance := global_position.x - _plane.global_position.x
	if narrow:
		# Checked every frame, so unfolding to the glider inside the gap also crashes.
		if _plane_in_gap and _plane.glider_mode:
			_plane.hit()
		if distance > -30.0 and distance < AIM_RANGE:
			_plane.steer_towards(global_position.y, AIM_ASSIST, delta)
	if not _passed and distance < -60.0 and _plane.is_active():
		_passed = true
		passed.emit(Vector2(global_position.x + 120.0, global_position.y))
