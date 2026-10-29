extends CharacterBody2D
class_name PaperPlane
## The paper plane. Reads its own flight input and exposes a small interface
## (hit, enter_wind, exit_wind, steer_towards) that course objects call.

signal crashed
signal flapped
signal folded
signal wind_entered(strength: float)

const GLIDER_GRAVITY := 110.0
const DART_GRAVITY := 200.0
const DART_SPEED := 340.0
const GLIDER_SPEED := 245.0
const FLAP_IMPULSE := 150.0
const WIND_BOOST_SPEED := 105.0
const WIND_BOOST_DURATION := 1.25
# Holding brake slows the plane to this share of its speed; speed changes smoothly.
const BRAKE_FACTOR := 0.5
const SPEED_CHANGE := 500.0
# Holding dive pushes the plane down on top of gravity.
const DIVE_FORCE := 320.0
const RESPAWN_GRACE := 1.5
const WORLD_TOP := 45.0
const WORLD_BOTTOM := 510.0
const CAMERA_Y := 270.0
const CAMERA_LEAD := 360.0
# Hitboxes are a little smaller than the sprites so near misses feel fair.
# Narrow gates check the fold themselves (see Gate), so the glider box can stay small.
const GLIDER_HITBOX := Vector2(36.0, 16.0)
const DART_HITBOX := Vector2(32.0, 8.0)

var glider_mode := true
var alive := true
var flying := false
var boost_time_left := 0.0
var braking := false
var diving := false
var shake_strength := 0.0
# Short grace period after a respawn so the plane cannot crash again straight away.
var invulnerable_time := 0.0
var _gusts_inside := 0
var _gust_strength := 0.0
var _crash_spin := 0.0
# Ignores the start tap so it does not also count as a lift impulse.
var _flap_cooldown := 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D
@onready var visuals: Node2D = $Visuals
@onready var glider_sprite: Sprite2D = $Visuals/GliderSprite
@onready var dart_sprite: Sprite2D = $Visuals/DartSprite
@onready var wind_trail: Sprite2D = $Visuals/WindTrail

func _ready() -> void:
	# The camera only follows horizontally, so the fixed-height course never wobbles.
	camera.top_level = true
	_snap_camera()
	_update_shape()

func _physics_process(delta: float) -> void:
	_update_camera(delta)
	if not alive:
		_tumble(delta)
		return
	if not flying:
		# Waiting on the start screen: hover gently in place.
		visuals.position.y = sin(Time.get_ticks_msec() / 300.0) * 3.0
		return
	visuals.position.y = 0.0
	_handle_input(delta)
	_apply_forces(delta)
	move_and_slide()
	_keep_in_world()
	_animate(delta)

func _handle_input(delta: float) -> void:
	_flap_cooldown = maxf(0.0, _flap_cooldown - delta)
	if Input.is_action_just_pressed("flap") and _flap_cooldown <= 0.0:
		# A tap gives one controlled lift impulse; holding the key cannot launch
		# the plane off-screen.
		velocity.y = maxf(velocity.y - FLAP_IMPULSE, -220.0)
		flapped.emit()
	if Input.is_action_just_pressed("fold"):
		toggle_fold()
	braking = Input.is_action_pressed("brake")
	diving = Input.is_action_pressed("dive")

func _apply_forces(delta: float) -> void:
	velocity.y += (GLIDER_GRAVITY if glider_mode else DART_GRAVITY) * delta
	if diving:
		velocity.y += DIVE_FORCE * delta
	if _gusts_inside > 0:
		# Wind pulls the vertical speed towards a target instead of accelerating forever,
		# so the plane leaves a gust controllable. Positive strength lifts, negative pushes down.
		# The narrow dart only feels a weaker push and keeps falling through an updraft.
		if glider_mode:
			var target_vy := -_gust_strength * 0.35
			if (_gust_strength > 0.0 and velocity.y > target_vy) or (_gust_strength < 0.0 and velocity.y < target_vy):
				velocity.y = move_toward(velocity.y, target_vy, 600.0 * delta)
		else:
			velocity.y -= _gust_strength * 0.3 * delta
	boost_time_left = maxf(0.0, boost_time_left - delta)
	velocity.y = clampf(velocity.y, -280.0, 360.0)
	var base_speed := GLIDER_SPEED if glider_mode else DART_SPEED
	var target_speed := base_speed + (WIND_BOOST_SPEED if boost_time_left > 0.0 else 0.0)
	if braking:
		target_speed *= BRAKE_FACTOR
	velocity.x = move_toward(velocity.x, target_speed, SPEED_CHANGE * delta)

func _keep_in_world() -> void:
	if position.y < WORLD_TOP:
		# The ceiling limits climbing without ending the run.
		position.y = WORLD_TOP
		velocity.y = maxf(velocity.y, 0.0)
	if position.y > WORLD_BOTTOM:
		# Touching the ground bounces the plane back up instead of ending the run.
		position.y = WORLD_BOTTOM
		velocity.y = -170.0
		shake_strength = 3.0

func _animate(delta: float) -> void:
	invulnerable_time = maxf(0.0, invulnerable_time - delta)
	visuals.modulate.a = 0.4 if invulnerable_time > 0.0 and fmod(invulnerable_time, 0.2) < 0.1 else 1.0
	wind_trail.visible = boost_time_left > 0.0
	# Tilt the nose with the vertical speed and settle any fold squash.
	var target_tilt := clampf(velocity.y / 360.0, -1.0, 1.0) * 0.45
	if braking:
		# Nose up while braking, like flaring before a landing.
		target_tilt -= 0.25
	visuals.rotation = lerpf(visuals.rotation, target_tilt, minf(1.0, 10.0 * delta))
	visuals.scale = visuals.scale.lerp(Vector2.ONE, minf(1.0, 12.0 * delta))

func _update_camera(delta: float) -> void:
	shake_strength = maxf(0.0, shake_strength - 30.0 * delta)
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength
	if alive:
		camera.global_position = Vector2(global_position.x + CAMERA_LEAD, CAMERA_Y)

func _snap_camera() -> void:
	camera.global_position = Vector2(global_position.x + CAMERA_LEAD, CAMERA_Y)
	camera.reset_smoothing()

func _tumble(delta: float) -> void:
	# Crumpled plane spins and drops out of the picture.
	velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
	velocity.y = minf(velocity.y + 700.0 * delta, 600.0)
	position += velocity * delta
	visuals.rotation += _crash_spin * delta
	visuals.scale = visuals.scale.lerp(Vector2(0.6, 0.6), minf(1.0, 4.0 * delta))

func _update_shape() -> void:
	var shape := RectangleShape2D.new()
	shape.size = GLIDER_HITBOX if glider_mode else DART_HITBOX
	collision_shape.shape = shape
	glider_sprite.visible = glider_mode
	dart_sprite.visible = not glider_mode

# --- Interface used by the game and the course objects. ---

func is_active() -> bool:
	return alive and flying

func launch() -> void:
	flying = true
	velocity = Vector2(GLIDER_SPEED, -60.0)
	_flap_cooldown = 0.1

func respawn(at: Vector2) -> void:
	alive = true
	flying = true
	position = at
	velocity = Vector2(GLIDER_SPEED, -40.0)
	braking = false
	diving = false
	glider_mode = true
	_gusts_inside = 0
	boost_time_left = 0.0
	invulnerable_time = RESPAWN_GRACE
	_update_shape()
	collision_shape.set_deferred("disabled", false)
	visuals.rotation = 0.0
	visuals.scale = Vector2.ONE
	_snap_camera()

func toggle_fold() -> void:
	if not is_active():
		return
	glider_mode = not glider_mode
	_update_shape()
	# Short squash so the fold is readable.
	visuals.scale = Vector2(1.35, 0.6) if glider_mode else Vector2(0.7, 1.4)
	folded.emit()

## Called by obstacles. Ignored during the respawn grace period.
func hit() -> void:
	if not is_active() or invulnerable_time > 0.0:
		return
	alive = false
	collision_shape.set_deferred("disabled", true)
	wind_trail.visible = false
	velocity = Vector2(velocity.x * 0.4, -180.0)
	_crash_spin = randf_range(9.0, 13.0) * (1.0 if randf() > 0.5 else -1.0)
	shake_strength = 9.0
	crashed.emit()

## Called by gusts. Positive strength is an updraft, negative a downdraft.
func enter_wind(strength: float) -> void:
	_gusts_inside += 1
	_gust_strength = strength
	if strength > 0.0:
		boost_time_left = WIND_BOOST_DURATION
	wind_entered.emit(strength)

func exit_wind() -> void:
	_gusts_inside = maxi(0, _gusts_inside - 1)

## Aim assist used by narrow gates: nudges the dart towards a height.
func steer_towards(target_y: float, rate: float, delta: float) -> void:
	if is_active() and not glider_mode:
		position.y = move_toward(position.y, target_y, rate * delta)

## Used at the finish: slide the plane into the mailbox and stop.
func stop_at(target: Vector2) -> void:
	alive = false
	flying = false
	set_physics_process(false)
	wind_trail.visible = false
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visuals, "rotation", 0.0, 0.3)
	tween.tween_property(visuals, "scale", Vector2(0.2, 0.2), 0.4).set_delay(0.15)
