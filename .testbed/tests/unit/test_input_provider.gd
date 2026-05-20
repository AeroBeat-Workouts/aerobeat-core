extends "res://addons/gut/test.gd"

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
	var provider = autofree(FlowInput.new())

	assert_true(provider.has_capability(AeroInputProvider.Capability.GESTURE_RECOGNITION))
	assert_false(provider.has_capability(AeroInputProvider.Capability.LOWER_BODY))
	assert_false(provider.has_capability(AeroInputProvider.Capability.HAPTICS))

func test_boxing_input_reports_gesture_capability_without_claiming_lower_body_or_haptics_by_default():
	var provider = autofree(BoxingInput.new())

	assert_true(provider.has_capability(AeroInputProvider.Capability.GESTURE_RECOGNITION))
	assert_false(provider.has_capability(AeroInputProvider.Capability.LOWER_BODY))
	assert_false(provider.has_capability(AeroInputProvider.Capability.HAPTICS))

func test_boxing_input_exposes_v1_intent_signals_and_omits_retired_aliases():
	var provider = autofree(BoxingInput.new())

	for signal_name in [
		"punch_left",
		"punch_right",
		"uppercut_left",
		"uppercut_right",
		"hook_left",
		"hook_right",
		"guard_start",
		"guard_end",
		"squat_start",
		"squat_end",
		"lean_left_start",
		"lean_left_end",
		"lean_right_start",
		"lean_right_end",
		"sidestep_left_start",
		"sidestep_left_end",
		"sidestep_right_start",
		"sidestep_right_end",
		"knee_left",
		"knee_right",
		"leg_lift_left_start",
		"leg_lift_left_end",
		"leg_lift_right_start",
		"leg_lift_right_end"
	]:
		assert_true(provider.has_signal(signal_name), "Expected BoxingInput to expose '%s'" % signal_name)

	for signal_name in [
		"cross_left",
		"cross_right",
		"block_start",
		"block_end",
		"stance_orthodox",
		"stance_southpaw",
		"location_changed",
		"height_changed",
		"run_start",
		"run_end",
		"run_in_place",
		"slice_detected",
		"knee_strike_left",
		"knee_strike_right"
	]:
		assert_false(provider.has_signal(signal_name), "Expected BoxingInput to omit '%s'" % signal_name)

func test_flow_input_exposes_v1_motion_family_and_state_signals():
	var provider = autofree(FlowInput.new())

	for signal_name in [
		"swing_left",
		"swing_right",
		"trail_left",
		"trail_right",
		"squat_start",
		"squat_end",
		"lean_left_start",
		"lean_left_end",
		"lean_right_start",
		"lean_right_end",
		"sidestep_left_start",
		"sidestep_left_end",
		"sidestep_right_start",
		"sidestep_right_end"
	]:
		assert_true(provider.has_signal(signal_name), "Expected FlowInput to expose '%s'" % signal_name)

	for signal_name in [
		"stance_orthodox",
		"stance_southpaw",
		"location_changed",
		"height_changed",
		"run_in_place",
		"slice_detected"
	]:
		assert_false(provider.has_signal(signal_name), "Expected FlowInput to omit '%s'" % signal_name)

func test_flow_motion_family_signals_keep_placement_and_direction_as_distinct_args():
	var provider = autofree(FlowInput.new())

	for signal_name in ["swing_left", "swing_right", "trail_left", "trail_right"]:
		var signal_info = _get_signal_info(provider, signal_name)
		assert_eq(signal_info["args"].size(), 2, "Expected %s to keep two semantic args" % signal_name)
		assert_eq(signal_info["args"][0]["name"], &"placement")
		assert_eq(signal_info["args"][1]["name"], &"direction")

func test_input_manager_proxies_v1_intent_surface():
	var manager = autofree(InputManager.new())

	for signal_name in [
		"punch_left",
		"punch_right",
		"guard_start",
		"guard_end",
		"squat_start",
		"squat_end",
		"lean_left_start",
		"lean_left_end",
		"sidestep_left_start",
		"sidestep_left_end",
		"knee_left",
		"knee_right",
		"swing_left",
		"swing_right",
		"trail_left",
		"trail_right"
	]:
		assert_true(manager.has_signal(signal_name), "Expected InputManager to proxy '%s'" % signal_name)

	for signal_name in [
		"cross_left",
		"cross_right",
		"block_start",
		"block_end",
		"stance_orthodox",
		"stance_southpaw",
		"location_changed",
		"height_changed",
		"run_start",
		"run_end",
		"run_in_place",
		"slice_detected",
		"knee_strike_left",
		"knee_strike_right"
	]:
		assert_false(manager.has_signal(signal_name), "Expected InputManager to omit '%s'" % signal_name)

	for signal_name in ["swing_left", "swing_right", "trail_left", "trail_right"]:
		var signal_info = _get_signal_info(manager, signal_name)
		assert_eq(signal_info["args"][0]["name"], &"placement")
		assert_eq(signal_info["args"][1]["name"], &"direction")

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
