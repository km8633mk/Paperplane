extends Node
## Autoload: global settings that apply once for the whole session.

## Overall game tempo: 1.0 is full speed, lower values give more time to react.
## The clock runs in game time, so the par time stays fair at any tempo.
const GAME_SPEED := 0.7
const BASE_SIZE := Vector2(960, 540)

func _ready() -> void:
	Engine.time_scale = GAME_SPEED
	_fit_window()

func _fit_window() -> void:
	# 960x540 is tiny on high-resolution screens: scale the window up by the largest
	# whole factor that fits, so the pixel art stays crisp.
	if Engine.is_embedded_in_editor() or DisplayServer.get_name() == "headless":
		return
	var screen := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var factor := maxi(1, floori(minf(usable.size.x * 0.9 / BASE_SIZE.x, usable.size.y * 0.9 / BASE_SIZE.y)))
	var window_size := Vector2i(BASE_SIZE * factor)
	DisplayServer.window_set_size(window_size)
	DisplayServer.window_set_position(usable.position + (usable.size - window_size) / 2)
