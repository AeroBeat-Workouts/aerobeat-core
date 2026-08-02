extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const BodyCellInputScript = preload("res://addons/aerobeat-input-core/src/interfaces/body_cell_input.gd")
const InputManagerScript = preload("res://addons/aerobeat-input-core/src/input_manager.gd")

class BodyGridProvider:
	extends BodyCellInput

	var provider_id_value: String
	var anchors: Dictionary = {
		"nose": BodyCellInput.make_invalid_body_grid_anchor("nose"),
		"left_wrist": BodyCellInput.make_invalid_body_grid_anchor("left_wrist"),
		"right_wrist": BodyCellInput.make_invalid_body_grid_anchor("right_wrist")
	}
	var calibration_state: Dictionary = BodyCellInput.make_body_grid_calibration_state("none")
	var stop_should_emit := false

	func _init(provider_id: String = "camera_tracking") -> void:
		provider_id_value = provider_id

	func get_provider_id() -> String:
		return provider_id_value

	func start(_settings_json: String) -> bool:
		return true

	func stop() -> void:
		if stop_should_emit:
			stopped.emit()

	func is_tracking() -> bool:
		return true

	func get_body_grid_nose() -> Dictionary:
		return anchors["nose"]

	func get_body_grid_left_wrist() -> Dictionary:
		return anchors["left_wrist"]

	func get_body_grid_right_wrist() -> Dictionary:
		return anchors["right_wrist"]

	func get_body_grid_calibration_state() -> Dictionary:
		return calibration_state

	func publish_anchor(anchor_name: String, x: float, y: float) -> void:
		var anchor := _make_valid_anchor(anchor_name, x, y)
		anchors[anchor_name] = anchor
		match anchor_name:
			"nose":
				body_grid_nose_updated.emit(anchor)
			"left_wrist":
				body_grid_left_wrist_updated.emit(anchor)
			"right_wrist":
				body_grid_right_wrist_updated.emit(anchor)

	func publish_calibration_event(state_name: String) -> void:
		var event := {
			"schema": "aerobeat/body_grid_calibration_event",
			"version": 1,
			"state": state_name,
			"calibration_id": "camera_tracking:1780000000000",
			"captured_at_ms": 1780000000000,
			"grid": BodyCellInput.make_body_grid()
		}
		calibration_state = event
		if state_name in ["started", "failed", "canceled"]:
			_publish_invalid_anchors()
		match state_name:
			"started":
				body_grid_calibration_started.emit(event)
			"succeeded":
				body_grid_calibration_succeeded.emit(event)
			"failed":
				body_grid_calibration_failed.emit(event)
			"canceled":
				body_grid_calibration_canceled.emit(event)

	func _publish_invalid_anchors() -> void:
		anchors["nose"] = BodyCellInput.make_invalid_body_grid_anchor("nose")
		anchors["left_wrist"] = BodyCellInput.make_invalid_body_grid_anchor("left_wrist")
		anchors["right_wrist"] = BodyCellInput.make_invalid_body_grid_anchor("right_wrist")
		body_grid_nose_updated.emit(anchors["nose"])
		body_grid_left_wrist_updated.emit(anchors["left_wrist"])
		body_grid_right_wrist_updated.emit(anchors["right_wrist"])

	func _make_valid_anchor(anchor_name: String, x: float, y: float) -> Dictionary:
		var columns := 4
		var rows := 3
		var column: int = mini(int(floor(x * float(columns))), columns - 1)
		var row: int = mini(int(floor(y * float(rows))), rows - 1)
		return {
			"schema": "aerobeat/body_grid_anchor",
			"version": 1,
			"anchor": anchor_name,
			"valid": true,
			"calibration_id": "camera_tracking:1780000000000",
			"timestamp_ms": 1780000000001,
			"grid": BodyCellInput.make_body_grid(),
			"raw_x": x,
			"raw_y": y,
			"x": x,
			"y": y,
			"cell": row * columns + column,
			"row": row,
			"column": column
		}

func test_body_cell_input_exposes_exact_body_grid_signals_and_invalid_queries() -> void:
	var provider = autofree(BodyCellInputScript.new())

	for signal_name in [
		"body_grid_nose_updated",
		"body_grid_left_wrist_updated",
		"body_grid_right_wrist_updated",
		"body_grid_calibration_started",
		"body_grid_calibration_succeeded",
		"body_grid_calibration_failed",
		"body_grid_calibration_canceled"
	]:
		assert_true(provider.has_signal(signal_name), "Expected BodyCellInput signal '%s'" % signal_name)
		assert_eq(_get_signal_info(provider, signal_name)["args"].size(), 1)

	assert_invalid_anchor_shape(provider.get_body_grid_nose(), "nose")
	assert_invalid_anchor_shape(provider.get_body_grid_left_wrist(), "left_wrist")
	assert_invalid_anchor_shape(provider.get_body_grid_right_wrist(), "right_wrist")
	assert_eq(provider.get_body_grid_calibration_state()["schema"], "aerobeat/body_grid_calibration_event")

func test_input_manager_exposes_body_grid_contract_surface() -> void:
	var manager = autofree(InputManagerScript.new())

	for signal_name in [
		"body_grid_nose_updated",
		"body_grid_left_wrist_updated",
		"body_grid_right_wrist_updated",
		"body_grid_calibration_started",
		"body_grid_calibration_succeeded",
		"body_grid_calibration_failed",
		"body_grid_calibration_canceled"
	]:
		assert_true(manager.has_signal(signal_name), "Expected InputManager signal '%s'" % signal_name)

	assert_invalid_anchor_shape(manager.get_body_grid_nose(), "nose")
	assert_invalid_anchor_shape(manager.get_body_grid_left_wrist(), "left_wrist")
	assert_invalid_anchor_shape(manager.get_body_grid_right_wrist(), "right_wrist")

func test_input_manager_proxies_active_provider_body_grid_anchors_only() -> void:
	var manager: InputManager = add_child_autoqfree(InputManagerScript.new())
	manager.auto_switch_inputs = false
	var active_provider: BodyGridProvider = add_child_autoqfree(BodyGridProvider.new("camera_tracking"))
	var inactive_provider: BodyGridProvider = add_child_autoqfree(BodyGridProvider.new("keyboard"))
	var emitted: Array[Dictionary] = []
	manager.body_grid_nose_updated.connect(func(anchor): emitted.append(anchor))

	assert_true(manager.register_provider(active_provider))
	assert_true(manager.register_provider(inactive_provider))
	assert_true(manager.set_active_provider(active_provider))

	inactive_provider.publish_anchor("nose", 0.9, 0.1)
	assert_eq(emitted.size(), 0)
	assert_invalid_anchor_shape(manager.get_body_grid_nose(), "nose")

	active_provider.publish_anchor("nose", 0.1, 0.1)
	assert_eq(emitted.size(), 1)
	assert_eq(manager.get_body_grid_nose()["cell"], 0)

func test_input_manager_invalidates_cached_anchors_on_active_provider_switch_and_stop() -> void:
	var manager: InputManager = add_child_autoqfree(InputManagerScript.new())
	manager.auto_switch_inputs = false
	var first_provider: BodyGridProvider = add_child_autoqfree(BodyGridProvider.new("camera_tracking"))
	var second_provider: BodyGridProvider = add_child_autoqfree(BodyGridProvider.new("keyboard"))
	var emitted: Array[Dictionary] = []
	manager.body_grid_left_wrist_updated.connect(func(anchor): emitted.append(anchor))

	assert_true(manager.register_provider(first_provider))
	assert_true(manager.register_provider(second_provider))
	assert_true(manager.set_active_provider(first_provider))

	first_provider.publish_anchor("left_wrist", 0.9, 0.9)
	assert_eq(manager.get_body_grid_left_wrist()["cell"], 11)

	assert_true(manager.set_active_provider(second_provider))
	assert_false(emitted[-1]["valid"])
	assert_invalid_anchor_shape(manager.get_body_grid_left_wrist(), "left_wrist")

	second_provider.publish_anchor("left_wrist", 0.1, 0.8)
	assert_eq(manager.get_body_grid_left_wrist()["cell"], 8)

	manager.stop_active_provider()
	assert_false(emitted[-1]["valid"])
	assert_invalid_anchor_shape(manager.get_body_grid_left_wrist(), "left_wrist")

func test_input_manager_invalidates_cached_anchors_on_provider_stopped_signal() -> void:
	var manager: InputManager = add_child_autoqfree(InputManagerScript.new())
	var provider: BodyGridProvider = add_child_autoqfree(BodyGridProvider.new("camera_tracking"))
	provider.stop_should_emit = true

	assert_true(manager.register_provider(provider))
	provider.publish_anchor("right_wrist", 0.9, 0.1)
	assert_eq(manager.get_body_grid_right_wrist()["cell"], 3)

	provider.stopped.emit()
	assert_invalid_anchor_shape(manager.get_body_grid_right_wrist(), "right_wrist")

func test_input_manager_proxies_body_grid_calibration_lifecycle_separately() -> void:
	var manager: InputManager = add_child_autoqfree(InputManagerScript.new())
	manager.auto_switch_inputs = false
	var provider: BodyGridProvider = add_child_autoqfree(BodyGridProvider.new("camera_tracking"))
	var inactive_provider: BodyGridProvider = add_child_autoqfree(BodyGridProvider.new("keyboard"))
	var states: Array[String] = []
	manager.body_grid_calibration_started.connect(func(event): states.append(event["state"]))
	manager.body_grid_calibration_succeeded.connect(func(event): states.append(event["state"]))
	manager.body_grid_calibration_failed.connect(func(event): states.append(event["state"]))
	manager.body_grid_calibration_canceled.connect(func(event): states.append(event["state"]))

	assert_true(manager.register_provider(provider))
	assert_true(manager.register_provider(inactive_provider))
	assert_true(manager.set_active_provider(provider))

	inactive_provider.publish_calibration_event("started")
	assert_eq(states, [])

	provider.publish_anchor("nose", 0.6, 0.6)
	provider.publish_calibration_event("started")
	assert_eq(states[-1], "started")
	assert_eq(manager.get_body_grid_calibration_state()["state"], "started")
	assert_invalid_anchor_shape(manager.get_body_grid_nose(), "nose")

	provider.publish_calibration_event("succeeded")
	provider.publish_calibration_event("failed")
	provider.publish_calibration_event("canceled")
	assert_eq(states, ["started", "succeeded", "failed", "canceled"])
	assert_eq(manager.get_body_grid_calibration_state()["state"], "canceled")

func test_input_manager_deep_duplicates_emitted_and_queried_body_grid_dictionaries() -> void:
	var manager: InputManager = add_child_autoqfree(InputManagerScript.new())
	var provider: BodyGridProvider = add_child_autoqfree(BodyGridProvider.new("camera_tracking"))
	var emitted: Array[Dictionary] = []
	manager.body_grid_nose_updated.connect(func(anchor):
		emitted.append(anchor)
		anchor["grid"]["columns"] = 99
		anchor["x"] = 99.0
	)

	assert_true(manager.register_provider(provider))
	provider.publish_anchor("nose", 0.5, 0.5)

	var queried := manager.get_body_grid_nose()
	assert_eq(queried["grid"]["columns"], 4)
	assert_eq(queried["x"], 0.5)

	queried["grid"]["columns"] = 12
	queried["x"] = 12.0
	var requeried := manager.get_body_grid_nose()
	assert_eq(requeried["grid"]["columns"], 4)
	assert_eq(requeried["x"], 0.5)
	assert_eq(emitted.size(), 1)

func test_top_left_4x3_body_grid_cell_examples_are_preserved_through_manager() -> void:
	var manager: InputManager = add_child_autoqfree(InputManagerScript.new())
	var provider: BodyGridProvider = add_child_autoqfree(BodyGridProvider.new("camera_tracking"))

	assert_true(manager.register_provider(provider))

	provider.publish_anchor("nose", 0.1, 0.1)
	assert_eq(manager.get_body_grid_nose()["cell"], 0)
	provider.publish_anchor("nose", 0.8, 0.1)
	assert_eq(manager.get_body_grid_nose()["cell"], 3)
	provider.publish_anchor("nose", 0.1, 0.8)
	assert_eq(manager.get_body_grid_nose()["cell"], 8)
	provider.publish_anchor("nose", 1.0, 1.0)
	assert_eq(manager.get_body_grid_nose()["cell"], 11)

func assert_invalid_anchor_shape(anchor: Dictionary, anchor_name: String) -> void:
	assert_eq(anchor["schema"], "aerobeat/body_grid_anchor")
	assert_eq(anchor["version"], 1)
	assert_eq(anchor["anchor"], anchor_name)
	assert_false(anchor["valid"])
	assert_eq(anchor["grid"]["columns"], 4)
	assert_eq(anchor["grid"]["rows"], 3)
	assert_eq(anchor["grid"]["origin"], "top_left")
	assert_eq(anchor["grid"]["indexing"], "row_major")
	for key in ["raw_x", "raw_y", "x", "y", "cell", "row", "column"]:
		assert_eq(anchor[key], null, "Expected invalid %s to keep %s null" % [anchor_name, key])

func _get_signal_info(target: Object, signal_name: String) -> Dictionary:
	for signal_info in target.get_signal_list():
		if String(signal_info["name"]) == signal_name:
			return signal_info
	return {}
