extends Node
class_name PickupSpawner
## Rolls a new mission every round and scatters the pickups over the course.
## Pickups land either in a gate's gap or in open air, never inside walls or
## next to hazards, and close to a gate's height when a gate is near.

const PICKUP_SCENE := preload("res://course/Pickup.tscn")

## How many of each kind the mission asks for (random within this range).
@export var min_required := 2
@export var max_required := 4
## Extra pickups of each kind, so one miss does not ruin the mission.
@export var spare := 2
## Horizontal range of the course that may hold pickups.
@export var start_x := 400.0
@export var end_x := 5950.0
@export var min_y := 100.0
@export var max_y := 440.0
## Minimum distance between two pickups.
@export var spacing := 110.0
## Share of pickups placed in a gate's gap instead of open air.
@export_range(0.0, 1.0) var gate_share := 0.3

const GATE_CLEARANCE := 40.0
const HAZARD_CLEARANCE := 90.0
# Near a gate the plane has little room to change height, so pickups there
# stay within this distance of the gap.
const GATE_APPROACH := 300.0
const GATE_EXIT := 200.0
const NEAR_GATE_SPREAD := 60.0
const MAX_TRIES := 200

var _gates: Array[Gate] = []
var _hazards: Array[Hazard] = []
var _free_gates: Array[Gate] = []
var _placed: Array[Vector2] = []

## Creates the pickups as children of `course` and returns the mission:
## how many of each kind must be collected.
func spawn(course: Node2D) -> Dictionary:
	for node in course.get_children():
		if node is Gate:
			_gates.append(node)
		elif node is Hazard:
			_hazards.append(node)
	_free_gates = _gates.duplicate()
	var required := {}
	for kind in Pickup.Kind.values():
		required[kind] = randi_range(min_required, max_required)
		for i in required[kind] + spare:
			var spot := _find_spot()
			var pickup: Pickup = PICKUP_SCENE.instantiate()
			pickup.kind = kind
			pickup.position = spot
			course.add_child(pickup)
			_placed.append(spot)
	return required

func _find_spot() -> Vector2:
	if not _free_gates.is_empty() and randf() < gate_share:
		var gate: Gate = _free_gates.pop_at(randi() % _free_gates.size())
		return gate.position
	for i in MAX_TRIES:
		var spot := Vector2(randf_range(start_x, end_x), randf_range(min_y, max_y))
		spot.y = _limit_near_gates(spot)
		if _is_free(spot):
			return spot
	# Crowded course: fall back to any unused gate gap, or simply the last try.
	if not _free_gates.is_empty():
		return _free_gates.pop_back().position
	return Vector2(randf_range(start_x, end_x), randf_range(min_y, max_y))

func _limit_near_gates(spot: Vector2) -> float:
	for gate in _gates:
		var ahead := gate.position.x - spot.x
		if ahead > -GATE_EXIT and ahead < GATE_APPROACH:
			return clampf(spot.y, gate.position.y - NEAR_GATE_SPREAD, gate.position.y + NEAR_GATE_SPREAD)
	return spot.y

func _is_free(spot: Vector2) -> bool:
	for gate in _gates:
		if absf(gate.position.x - spot.x) < gate.get_width() / 2.0 + GATE_CLEARANCE:
			return false
	for hazard in _hazards:
		if absf(hazard.position.x - spot.x) < HAZARD_CLEARANCE:
			return false
	for other in _placed:
		if other.distance_to(spot) < spacing:
			return false
	return true
