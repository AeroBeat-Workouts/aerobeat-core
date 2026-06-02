extends "res://addons/gut/test.gd"

class FakeProvider:
	extends AeroInputProvider

	var provider_id_value: String
	var started_count := 0
	var stopped_count := 0

	func _init(provider_id: String = "") -> void:
		provider_id_value = provider_id

	func get_provider_id() -> String:
		return provider_id_value

	func start(_settings_json: String) -> bool:
		started_count += 1
		return true

	func stop() -> void:
		stopped_count += 1

	func is_tracking() -> bool:
		return false

	func has_capability(_capability: AeroInputProvider.Capability) -> bool:
		return false

	func get_head_position(_mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
		return Vector3.ZERO

	func get_left_hand_position(_mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
		return Vector3.ZERO

	func get_right_hand_position(_mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
		return Vector3.ZERO

	func get_left_foot_position(_mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
		return Vector3.ZERO

	func get_right_foot_position(_mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
		return Vector3.ZERO

	func get_head_velocity() -> Vector3:
		return Vector3.ZERO

	func get_left_hand_velocity() -> Vector3:
		return Vector3.ZERO

	func get_right_hand_velocity() -> Vector3:
		return Vector3.ZERO

	func get_left_foot_velocity() -> Vector3:
		return Vector3.ZERO

	func get_right_foot_velocity() -> Vector3:
		return Vector3.ZERO

	func get_head_rotation() -> Quaternion:
		return Quaternion.IDENTITY

	func get_left_hand_rotation() -> Quaternion:
		return Quaternion.IDENTITY

	func get_right_hand_rotation() -> Quaternion:
		return Quaternion.IDENTITY

	func get_left_foot_rotation() -> Quaternion:
		return Quaternion.IDENTITY

	func get_right_foot_rotation() -> Quaternion:
		return Quaternion.IDENTITY

	func get_tracking_confidence(_body_part: StringName) -> float:
		return 0.0

	func set_tracking_mode(_mode: TrackingMode) -> void:
		pass

	func set_body_track_flags(_flags: int) -> void:
		pass

	func trigger_haptic(_side: int, _intensity: float, _duration_ms: int) -> void:
		pass

func test_base_provider_id_defaults_to_global_name_snake_case() -> void:
	var provider: AeroInputProvider = autofree(AeroInputProvider.new())
	assert_eq(provider.get_provider_id(), "aero_input_provider")

func test_registers_provider_under_explicit_provider_id() -> void:
	var manager: InputManager = add_child_autoqfree(InputManager.new())
	manager.auto_switch_inputs = false
	var provider: FakeProvider = add_child_autoqfree(FakeProvider.new("camera_tracking"))

	assert_true(manager.register_provider(provider))
	assert_true(manager.get_registered_providers().has("camera_tracking"))
	assert_eq(manager.get_provider("camera_tracking"), provider)

func test_priority_selection_prefers_explicit_provider_id_over_class_name() -> void:
	var manager: InputManager = add_child_autoqfree(InputManager.new())
	manager.input_priority = ["camera_tracking", "keyboard"]

	var fallback_provider: FakeProvider = add_child_autoqfree(FakeProvider.new("keyboard"))
	var preferred_provider: FakeProvider = add_child_autoqfree(FakeProvider.new("camera_tracking"))

	assert_true(manager.register_provider(fallback_provider))
	assert_eq(manager.get_active_provider(), fallback_provider)

	assert_true(manager.register_provider(preferred_provider))
	assert_eq(manager.get_active_provider(), preferred_provider)

func test_registry_does_not_resolve_legacy_mediapipe_provider_lookup_after_clean_break() -> void:
	var provider: FakeProvider = add_child_autoqfree(FakeProvider.new("camera_tracking"))
	var publish := AeroProviderSessionRegistry.publish_session("camera_tracking_owner", provider, {"session_key": "camera_tracking/shared"})
	assert_true(bool(publish.get("ok", false)))
	var by_provider := AeroProviderSessionRegistry.request_session({"provider_id": "mediapipe_python"})
	assert_false(bool(by_provider.get("ok", false)))
	assert_eq(String(by_provider.get("status", "")), AeroProviderSessionRegistry.STATUS_MISSING)
	var by_session_key := AeroProviderSessionRegistry.request_session({"session_key": "mediapipe_python/shared"})
	assert_false(bool(by_session_key.get("ok", false)))
	assert_eq(String(by_session_key.get("status", "")), AeroProviderSessionRegistry.STATUS_MISSING)
