extends Node2D
## Game flow: mission briefing, playing, crash and respawn, finish or game over.
## Connects the plane, the course, the HUD and the sound effects through signals.

const MAX_LIVES := 3
# After a crash the plane comes back behind the last gate it passed.
const RESPAWN_DELAY := 1.0
# Short delay so a frantic tap right at the end does not skip the result.
const RESULT_INPUT_DELAY := 0.6
const START_STATUS := "PAPIERFLIEGER  ·  Erfülle deine Mission"

enum State { READY, PLAYING, CRASHED, WON, GAME_OVER }

var state := State.READY
var lives := MAX_LIVES
var collected := {Pickup.Kind.STAMP: 0, Pickup.Kind.COIN: 0, Pickup.Kind.FEATHER: 0}
var run_time := 0.0
var state_time := 0.0
var best_time := 0.0

@onready var plane: PaperPlane = $PaperPlane
@onready var course: Course = $Course
@onready var hud: HUD = $HUD
@onready var sfx: Sfx = $Sfx
@onready var checkpoint := plane.position

func _ready() -> void:
	best_time = Records.load_best_time()
	plane.crashed.connect(_on_plane_crashed)
	plane.flapped.connect(sfx.play.bind("flap"))
	plane.folded.connect(sfx.play.bind("fold"))
	plane.wind_entered.connect(func(_strength: float) -> void: sfx.play("gust"))
	course.item_collected.connect(_on_item_collected)
	course.checkpoint_reached.connect(func(point: Vector2) -> void: checkpoint = point)
	course.section_entered.connect(hud.show_banner)
	course.finished.connect(_on_finished)
	hud.set_status(START_STATUS)
	hud.update_lives(lives)
	hud.show_message("PAPIERFLIEGER\n\nDeine Mission:\nSammle %s\nund bring den Brief zum Briefkasten.\n\nDu hast %d Leben.\n\nLeertaste / W / ↑ zum Starten" % [_list_items(course.required), MAX_LIVES])

func _process(delta: float) -> void:
	state_time += delta
	match state:
		State.READY:
			if Input.is_action_just_pressed("flap"):
				_set_state(State.PLAYING)
				hud.hide_message()
				plane.launch()
				sfx.play("flap")
		State.PLAYING:
			run_time += delta
		State.CRASHED:
			if state_time >= RESPAWN_DELAY:
				_set_state(State.PLAYING)
				hud.hide_message()
				hud.set_status(START_STATUS)
				plane.respawn(checkpoint)
		State.WON, State.GAME_OVER:
			if state_time > RESULT_INPUT_DELAY and Input.is_action_just_pressed("flap"):
				get_tree().reload_current_scene()
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	hud.update_items(collected, course.required)
	hud.update_mode(plane.glider_mode, plane.boost_time_left > 0.0, plane.braking and plane.is_active(), plane.diving and plane.is_active())
	hud.update_time(run_time, best_time)

func _set_state(new_state: State) -> void:
	state = new_state
	state_time = 0.0

func _on_item_collected(kind: Pickup.Kind) -> void:
	collected[kind] += 1
	sfx.play("stamp")

func _on_plane_crashed() -> void:
	if state != State.PLAYING:
		return
	lives -= 1
	hud.update_lives(lives)
	sfx.play("crash")
	if lives <= 0:
		_game_over("Keine Leben mehr!")
		return
	_set_state(State.CRASHED)
	hud.set_status("Oh nein, der Flieger ist abgestürzt!")
	hud.show_message("Abgestürzt!\n\nNoch %d Leben. Weiter hinter dem letzten Tor …" % lives)

func _on_finished(mailbox_position: Vector2) -> void:
	if state != State.PLAYING:
		return
	plane.stop_at(mailbox_position)
	var missing := _missing_items()
	if not missing.is_empty():
		_game_over("Mission nicht erfüllt!\nEs fehlen noch: %s." % _list_items(missing))
		return
	_set_state(State.WON)
	sfx.play("win")
	var new_best := best_time <= 0.0 or run_time < best_time
	if new_best:
		best_time = run_time
		Records.save_best_time(best_time)
	hud.set_status("Mission erfüllt!")
	# One star for every life left.
	hud.show_message("Mission erfüllt – Brief zugestellt!\n\n%s\n\nZeit: %s%s   ·   Leben übrig: %d/%d\n\nR oder Leertaste: neue Runde" % [
		"★".repeat(lives) + "☆".repeat(MAX_LIVES - lives),
		HUD.format_time(run_time),
		"  (neue Bestzeit!)" if new_best else "",
		lives, MAX_LIVES])

func _game_over(reason: String) -> void:
	_set_state(State.GAME_OVER)
	hud.set_status("Game Over")
	hud.show_message("GAME OVER\n\n%s\n\nR oder Leertaste: neuer Versuch" % reason)

func _missing_items() -> Dictionary:
	var missing := {}
	for kind in course.required:
		var count: int = course.required[kind] - collected[kind]
		if count > 0:
			missing[kind] = count
	return missing

## "3 Briefmarken, 3 Münzen und 3 Federn"
func _list_items(counts: Dictionary) -> String:
	var parts: Array[String] = []
	for kind in counts:
		if counts[kind] > 0:
			parts.append(Pickup.name_for(kind, counts[kind]))
	if parts.size() <= 1:
		return "".join(parts)
	return ", ".join(parts.slice(0, -1)) + " und " + parts[-1]
