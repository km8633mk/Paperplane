extends Node
class_name CourseGenerator
## Builds a new random course every round from tried building blocks
## (gust + gate, single gate, double gate, hazard), so every layout stays fair:
## gates after an updraft sit high, gates after a downdraft sit low, and a gate's
## height never jumps too far from the one before. Later sections get harder.

const GATE_SCENE := preload("res://course/Gate.tscn")
const GUST_SCENE := preload("res://course/Gust.tscn")
const HAZARD_SCENE := preload("res://course/Hazard.tscn")
const GROUND := 510.0

## Where the first building block starts and where the last one must end.
@export var start_x := 450.0
@export var end_x := 5950.0
## Right edges of the three sections (matching the SectionTrigger nodes).
@export var section_ends: Array[float] = [1900.0, 3800.0, 5950.0]

# Per section (index = difficulty): how likely each choice is.
const NARROW_CHANCE := [0.4, 0.55, 0.7]
const HAZARD_CHANCE := [0.15, 0.3, 0.4]
const DOUBLE_GATE_CHANCE := [0.0, 0.2, 0.25]
const DOWNDRAFT_CHANCE := [0.0, 0.35, 0.45]
const BOB_AMPLITUDE := [30.0, 55.0, 75.0]

const HIGH_GATE := Vector2(180, 260)
const LOW_GATE := Vector2(320, 380)
const GATE_RANGE := Vector2(170, 360)
const MAX_HEIGHT_STEP := 90.0
const MIDDLE := 265.0

var _course: Node2D
var _gate_y := 265.0

func generate(course: Node2D) -> void:
	_course = course
	var x := start_x
	# The first block is always an updraft and a gate, to learn the folds.
	x = _gust_and_gate(x, 0, false)
	for difficulty in section_ends.size():
		var section_end: float = minf(section_ends[difficulty], end_x)
		while x < section_end - 350.0:
			x = _random_block(x, difficulty)

func _random_block(x: float, difficulty: int) -> float:
	var roll := randf()
	if roll < HAZARD_CHANCE[difficulty]:
		return _hazard(x, difficulty)
	roll -= HAZARD_CHANCE[difficulty]
	if roll < DOUBLE_GATE_CHANCE[difficulty]:
		return _double_gate(x)
	if randf() < 0.7:
		return _gust_and_gate(x, difficulty, randf() < DOWNDRAFT_CHANCE[difficulty])
	return _single_gate(x, difficulty)

func _gust_and_gate(x: float, difficulty: int, downdraft: bool) -> float:
	var gust: Gust = GUST_SCENE.instantiate()
	if downdraft:
		gust.size = Vector2(192, 336)
		gust.strength = -220.0
		_add(gust, Vector2(x + 100.0, 230.0))
		_gate_y = randf_range(LOW_GATE.x, LOW_GATE.y)
	else:
		_add(gust, Vector2(x + 100.0, 285.0))
		_gate_y = randf_range(HIGH_GATE.x, HIGH_GATE.y)
	_gate(x + 460.0, randf() < NARROW_CHANCE[difficulty])
	return x + 650.0

func _single_gate(x: float, difficulty: int) -> float:
	_step_gate_height()
	_gate(x + 150.0, randf() < NARROW_CHANCE[difficulty])
	return x + 450.0

func _double_gate(x: float) -> float:
	# Dart through the first gate, unfold for the second one right behind it.
	_step_gate_height()
	_gate(x + 150.0, true)
	_step_gate_height()
	_gate(x + 400.0, false)
	return x + 650.0

func _hazard(x: float, difficulty: int) -> float:
	var hazard: Hazard = HAZARD_SCENE.instantiate()
	if difficulty >= 2 and randf() < 0.35:
		# A chimney on the ground with a kite above it: fly through the middle.
		hazard.type = Hazard.Type.CHIMNEY
		hazard.sprite_scale = 2.0
		_add(hazard, Vector2(x + 200.0, GROUND - 80.0))
		var kite: Hazard = HAZARD_SCENE.instantiate()
		kite.type = Hazard.Type.KITE
		kite.bob_amplitude = 35.0
		kite.bob_speed = 1.8
		_add(kite, Vector2(x + 200.0, 130.0))
		return x + 400.0
	var types := [Hazard.Type.BIRD, Hazard.Type.BALLOON, Hazard.Type.KITE]
	hazard.type = types.pick_random()
	hazard.bob_amplitude = randf_range(0.5, 1.0) * BOB_AMPLITUDE[difficulty]
	hazard.bob_speed = randf_range(1.2, 2.2)
	_add(hazard, Vector2(x + 200.0, randf_range(150.0, 380.0)))
	return x + 400.0

func _step_gate_height() -> void:
	# Drift back towards the middle a little, so gates do not pile up at the top or bottom.
	var drift := (MIDDLE - _gate_y) * 0.4
	_gate_y = clampf(_gate_y + drift + randf_range(-MAX_HEIGHT_STEP, MAX_HEIGHT_STEP), GATE_RANGE.x, GATE_RANGE.y)

func _gate(x: float, narrow: bool) -> void:
	var gate: Gate = GATE_SCENE.instantiate()
	gate.narrow = narrow
	_add(gate, Vector2(x, _gate_y))

func _add(node: Node2D, at: Vector2) -> void:
	# Position first: gates build their walls from their height when they enter the tree.
	node.position = at
	_course.add_child(node)
