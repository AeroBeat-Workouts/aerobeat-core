extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

class FakeProvider:
	extends AeroInputProvider

	var provider_id_value := "camera_tracking"
	var supported_capabilities: Array = []

	func _init(provider_id: String = "camera_tracking", capabilities: Array = []) -> void:
		provider_id_value = provider_id
		supported_capabilities = capabilities.duplicate(true)

	func start(_settings_json: String) -> bool:
		return true

	func stop() -> void:
		pass

	func is_tracking() -> bool:
		return true

	func get_provider_id() -> String:
		return provider_id_value

	func has_capability(capability: Capability) -> bool:
		return supported_capabilities.has(int(capability))

	func trigger_haptic(_side: int, _intensity: float, _duration_ms: int) -> void:
		pass

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
		return 1.0

	func set_tracking_mode(_mode: TrackingMode) -> void:
		pass

	func set_body_track_flags(_flags: int) -> void:
		pass

func before_each() -> void:
	AeroProviderSessionRegistry.clear_registry_for_testing()

func after_each() -> void:
	AeroProviderSessionRegistry.clear_registry_for_testing()

func test_publish_and_request_session_by_provider_and_capability() -> void:
	var provider: FakeProvider = add_child_autoqfree(
		FakeProvider.new("camera_tracking", [
			AeroInputProvider.Capability.GESTURE_RECOGNITION,
			AeroInputProvider.Capability.VELOCITY,
		])
	)

	var publish := AeroProviderSessionRegistry.publish_session(
		"aerobeat-input-mediapipe-python:testbed",
		provider,
		{
			"session_key": "camera_tracking/desktop_main",
			"metadata": {
				"lane": "desktop_main",
				"source": "camera0",
			},
		}
	)

	assert_true(bool(publish.get("ok", false)))
	assert_eq(String(publish.get("status", "")), AeroProviderSessionRegistry.STATUS_PUBLISHED)

	var request := AeroProviderSessionRegistry.request_session({
		"provider_id": "camera_tracking",
		"required_capabilities": [AeroInputProvider.Capability.GESTURE_RECOGNITION],
		"metadata_match": {
			"lane": "desktop_main",
		},
	})

	assert_true(bool(request.get("ok", false)))
	assert_eq(String(request.get("status", "")), AeroProviderSessionRegistry.STATUS_AVAILABLE)
	var session: Dictionary = request.get("session", {})
	assert_eq(String(session.get("session_key", "")), "camera_tracking/desktop_main")
	assert_eq(String(session.get("owner_id", "")), "aerobeat-input-mediapipe-python:testbed")
	assert_eq(session.get("provider", null), provider)
	assert_true(Array(session.get("capabilities", [])).has(AeroInputProvider.Capability.GESTURE_RECOGNITION))

func test_acquire_and_release_track_borrowers_without_transferring_ownership() -> void:
	var provider: FakeProvider = add_child_autoqfree(
		FakeProvider.new("camera_tracking", [AeroInputProvider.Capability.GESTURE_RECOGNITION])
	)
	AeroProviderSessionRegistry.publish_session(
		"assembly:testbed",
		provider,
		{"session_key": "camera_tracking/shared"}
	)

	var first_acquire := AeroProviderSessionRegistry.acquire_session(
		"camera_gesture:testbed",
		{"session_key": "camera_tracking/shared"}
	)
	assert_true(bool(first_acquire.get("ok", false)))
	assert_eq(int(first_acquire.get("session", {}).get("borrower_count", -1)), 1)
	assert_eq(int(first_acquire.get("session", {}).get("borrowers", {}).get("camera_gesture:testbed", 0)), 1)

	var second_acquire := AeroProviderSessionRegistry.acquire_session(
		"camera_gesture:testbed",
		{"session_key": "camera_tracking/shared"}
	)
	assert_true(bool(second_acquire.get("ok", false)))
	assert_eq(int(second_acquire.get("session", {}).get("borrower_count", -1)), 2)
	assert_eq(int(second_acquire.get("session", {}).get("borrowers", {}).get("camera_gesture:testbed", 0)), 2)

	var release := AeroProviderSessionRegistry.release_session("camera_gesture:testbed", "camera_tracking/shared")
	assert_true(bool(release.get("ok", false)))
	assert_eq(String(release.get("status", "")), AeroProviderSessionRegistry.STATUS_RELEASED)
	assert_eq(int(release.get("session", {}).get("borrower_count", -1)), 1)
	assert_eq(int(release.get("session", {}).get("borrowers", {}).get("camera_gesture:testbed", 0)), 1)
	assert_eq(String(release.get("session", {}).get("owner_id", "")), "assembly:testbed")

func test_unpublish_requires_same_owner_id() -> void:
	var provider: FakeProvider = add_child_autoqfree(FakeProvider.new("camera_tracking"))
	AeroProviderSessionRegistry.publish_session(
		"mediapipe_owner",
		provider,
		{"session_key": "camera_tracking/shared"}
	)

	var wrong_owner := AeroProviderSessionRegistry.unpublish_session("camera_gesture_consumer", "camera_tracking/shared")
	assert_false(bool(wrong_owner.get("ok", false)))
	assert_eq(String(wrong_owner.get("status", "")), AeroProviderSessionRegistry.STATUS_OWNER_MISMATCH)

	var request_after_failure := AeroProviderSessionRegistry.request_session({"session_key": "camera_tracking/shared"})
	assert_true(bool(request_after_failure.get("ok", false)))

	var correct_owner := AeroProviderSessionRegistry.unpublish_session("mediapipe_owner", "camera_tracking/shared")
	assert_true(bool(correct_owner.get("ok", false)))
	assert_eq(String(correct_owner.get("status", "")), AeroProviderSessionRegistry.STATUS_UNPUBLISHED)
	assert_false(bool(AeroProviderSessionRegistry.request_session({"session_key": "camera_tracking/shared"}).get("ok", false)))

func test_request_filters_by_exact_owner_and_metadata() -> void:
	var owner_a: FakeProvider = add_child_autoqfree(FakeProvider.new("camera_tracking"))
	var owner_b: FakeProvider = add_child_autoqfree(FakeProvider.new("camera_tracking"))
	AeroProviderSessionRegistry.publish_session(
		"owner_a",
		owner_a,
		{
			"session_key": "camera_tracking/owner_a",
			"metadata": {"lane": "a", "device": "cam0"},
		}
	)
	AeroProviderSessionRegistry.publish_session(
		"owner_b",
		owner_b,
		{
			"session_key": "camera_tracking/owner_b",
			"metadata": {"lane": "b", "device": "cam1"},
		}
	)

	var request: Dictionary = AeroProviderSessionRegistry.request_session({
		"provider_id": "camera_tracking",
		"owner_id": "owner_b",
		"metadata_match": {"device": "cam1"},
	})
	assert_true(bool(request.get("ok", false)))
	assert_eq(String(request.get("session", {}).get("session_key", "")), "camera_tracking/owner_b")
	assert_eq(request.get("session", {}).get("provider", null), owner_b)
