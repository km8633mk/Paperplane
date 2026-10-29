class_name Records
## Stores the best time on disk.

const SAVE_PATH := "user://papierflieger.cfg"

static func load_best_time() -> float:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return 0.0
	return config.get_value("records", "best_time", 0.0)

static func save_best_time(seconds: float) -> void:
	var config := ConfigFile.new()
	config.set_value("records", "best_time", seconds)
	config.save(SAVE_PATH)
