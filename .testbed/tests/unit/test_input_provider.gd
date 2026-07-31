extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const BodyCellInputScript = preload("res://addons/aerobeat-input-core/src/interfaces/body_cell_input.gd")
const FlowInputScript = preload("res://addons/aerobeat-input-core/src/interfaces/flow_input.gd")
const BoxingInputScript = preload("res://addons/aerobeat-input-core/src/interfaces/boxing_input.gd")
const InputManagerScript = preload("res://addons/aerobeat-input-core/src/input_manager.gd")

func test_aero_input_provider_default_left_hand_position_is_zero_vector():
	var provider = autofree(AeroInputProvider.new())

	var result = provider.get_left_hand_position()
	assert_push_error("AeroInputProvider: get_left_hand_position() must be overridden")
	assert_eq(result, Vector3.ZERO, "Default abstract implementation should return Vector3.ZERO")

func test_tracking_mode_enum_values():
	assert_eq(AeroInputProvider.TrackingMode.MODE_2D, 0)
	assert_eq(AeroInputProvider.TrackingMode.MODE_3D, 1)

func test_body_track_flags_bitfield():
	assert_eq(AeroInputProvider.BodyTrackFlags.NONE, 0)
	assert_eq(AeroInputProvider.BodyTrackFlags.HEAD, 1)
	assert_eq(AeroInputProvider.BodyTrackFlags.LEFT_HAND, 2)
	assert_eq(AeroInputProvider.BodyTrackFlags.RIGHT_HAND, 4)
	assert_eq(AeroInputProvider.BodyTrackFlags.LEFT_FOOT, 8)
	assert_eq(AeroInputProvider.BodyTrackFlags.RIGHT_FOOT, 16)

	var combined = AeroInputProvider.BodyTrackFlags.HEAD | AeroInputProvider.BodyTrackFlags.LEFT_HAND
	assert_eq(combined, 3, "Combined flags should work")

func test_optional_capability_enum_values_remain_stable():
	assert_eq(AeroInputProvider.Capability.SPATIAL_TRANSFORM, 1)
	assert_eq(AeroInputProvider.Capability.GESTURE_RECOGNITION, 2)
	assert_eq(AeroInputProvider.Capability.LOWER_BODY, 4)
	assert_eq(AeroInputProvider.Capability.HAPTICS, 8)
	assert_eq(AeroInputProvider.Capability.VELOCITY, 16)

func test_flow_input_reports_gesture_capability_without_claiming_other_optional_features():
	var provider = autofree(FlowInputScript.new())

	assert_true(provider.has_capability(AeroInputProvider.Capability.GESTURE_RECOGNITION))
	assert_false(provider.has_capability(AeroInputProvider.Capability.LOWER_BODY))
	assert_false(provider.has_capability(AeroInputProvider.Capability.HAPTICS))

func test_boxing_input_reports_gesture_capability_without_claiming_lower_body_or_haptics_by_default():
	var provider = autofree(BoxingInputScript.new())

	assert_true(provider.has_capability(AeroInputProvider.Capability.GESTURE_RECOGNITION))
	assert_false(provider.has_capability(AeroInputProvider.Capability.LOWER_BODY))
	assert_false(provider.has_capability(AeroInputProvider.Capability.HAPTICS))

func test_body_cell_input_exposes_shared_wrist_nose_and_calibration_contract() -> void:
	var provider = autofree(BodyCellInputScript.new())

	for signal_name in [
		"left_wrist_cell_entered",
		"right_wrist_cell_entered",
		"nose_cell_entered",
		"calibration_session_updated"
	]:
		assert_true(provider.has_signal(signal_name), "Expected BodyCellInput to expose '%s'" % signal_name)

	assert_false(provider.start_calibration())
	assert_false(provider.cancel_calibration())
	assert_eq(provider.get_calibration_session(), {})

func test_boxing_input_exposes_canonical_boxing_and_shared_body_cell_signals() -> void:
	var provider = autofree(BoxingInputScript.new())

	for signal_name in [
		"straight_left",
		"straight_right",
		"uppercut_left",
		"uppercut_right",
		"hook_left",
		"hook_right",
		"guard_enabled",
		"guard_disabled",
		"squat_enabled",
		"squat_disabled",
		"weave_left_enabled",
		"weave_left_disabled",
		"weave_right_enabled",
		"weave_right_disabled",
		"left_wrist_cell_entered",
		"right_wrist_cell_entered",
		"nose_cell_entered",
		"calibration_session_updated"
	]:
		assert_true(provider.has_signal(signal_name), "Expected BoxingInput to expose '%s'" % signal_name)

	for signal_name in [
		"cross_left",
		"cross_right",
		"block_start",
		"block_end",
		"lean_left_start",
		"lean_left_end",
		"sidestep_left_start",
		"sidestep_left_end",
		"knee_left",
		"knee_right"
	]:
		assert_false(provider.has_signal(signal_name), "Expected BoxingInput to omit retired '%s'" % signal_name)

func test_flow_input_exposes_shared_body_cell_lane_plus_squat_only() -> void:
	var provider = autofree(FlowInputScript.new())

	for signal_name in [
		"left_wrist_cell_entered",
		"right_wrist_cell_entered",
		"nose_cell_entered",
		"calibration_session_updated",
		"squat_enabled",
		"squat_disabled"
	]:
		assert_true(provider.has_signal(signal_name), "Expected FlowInput to expose '%s'" % signal_name)

	for signal_name in [
		"swing_left",
		"swing_right",
		"trail_left",
		"trail_right",
		"lean_left_start",
		"lean_left_end",
		"sidestep_left_start",
		"sidestep_left_end"
	]:
		assert_false(provider.has_signal(signal_name), "Expected FlowInput to omit retired '%s'" % signal_name)

	for signal_name in ["left_wrist_cell_entered", "right_wrist_cell_entered", "nose_cell_entered"]:
		var signal_info = _get_signal_info(provider, signal_name)
		assert_eq(signal_info["args"].size(), 2, "Expected %s to keep two semantic args" % signal_name)
		assert_eq(signal_info["args"][0]["name"], &"cell")
		assert_eq(signal_info["args"][1]["name"], &"direction")

func test_input_manager_proxies_canonical_boxing_shared_body_cell_and_calibration_surface() -> void:
	var manager = autofree(InputManagerScript.new())

	for signal_name in [
		"straight_left",
		"straight_right",
		"guard_enabled",
		"guard_disabled",
		"squat_enabled",
		"squat_disabled",
		"weave_left_enabled",
		"weave_left_disabled",
		"weave_right_enabled",
		"weave_right_disabled",
		"left_wrist_cell_entered",
		"right_wrist_cell_entered",
		"nose_cell_entered",
		"calibration_session_updated"
	]:
		assert_true(manager.has_signal(signal_name), "Expected InputManager to proxy '%s'" % signal_name)

	for signal_name in [
		"cross_left",
		"cross_right",
		"block_start",
		"block_end",
		"swing_left",
		"swing_right",
		"trail_left",
		"trail_right"
	]:
		assert_false(manager.has_signal(signal_name), "Expected InputManager to omit retired '%s'" % signal_name)

	for signal_name in ["left_wrist_cell_entered", "right_wrist_cell_entered", "nose_cell_entered"]:
		var signal_info = _get_signal_info(manager, signal_name)
		assert_eq(signal_info["args"][0]["name"], &"cell")
		assert_eq(signal_info["args"][1]["name"], &"direction")

	var calibration_signal_info := _get_signal_info(manager, "calibration_session_updated")
	assert_eq(calibration_signal_info["args"][0]["name"], &"session")

func _get_signal_info(target: Object, signal_name: String) -> Dictionary:
	for signal_info in target.get_signal_list():
		if String(signal_info["name"]) == signal_name:
			return signal_info
	return {}


func test_camera_device_contract_defaults() -> void:
	var provider := AeroInputProvider.new()
	assert_eq(provider.get_available_camera_devices(), [])
	assert_eq(provider.get_selected_camera_device_id(), "")
	assert_false(provider.set_selected_camera_device_id("/dev/video2"))
