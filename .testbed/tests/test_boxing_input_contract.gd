extends "res://addons/aerobeat-vendor-godot-unit-test/test.gd"

const PUNCH_SIGNALS: Array[String] = [
	"straight_left",
	"straight_right",
	"uppercut_left",
	"uppercut_right",
	"hook_left",
	"hook_right",
]

class BoxingProvider:
	extends BoxingInput
	
	func get_provider_id() -> String:
		return "camera_tracking"
	
	func start(_settings_json: String) -> bool:
		return true
	
	func stop() -> void:
		pass
	
	func is_tracking() -> bool:
		return true
	
	func has_capability(_capability: AeroInputProvider.Capability) -> bool:
		return true

func test_boxing_punch_signals_are_no_arg_active_events():
	var boxing_input := BoxingProvider.new()
	
	for signal_name in PUNCH_SIGNALS:
		assert_eq(
			_get_signal_arg_count(boxing_input, signal_name),
			0,
			"%s should not carry punch power, strength, scalar intensity, or active booleans" % signal_name
		)
	
	boxing_input.free()

func test_input_manager_punch_proxy_signals_are_no_arg_active_events():
	var input_manager := InputManager.new()
	
	for signal_name in PUNCH_SIGNALS:
		assert_eq(
			_get_signal_arg_count(input_manager, signal_name),
			0,
			"InputManager.%s should mirror the no-arg BoxingInput contract" % signal_name
		)
	
	input_manager.free()

func test_input_manager_forwards_no_arg_boxing_punch_events():
	var input_manager := InputManager.new()
	var provider := BoxingProvider.new()
	
	var emitted: Array[String] = []
	for signal_name in PUNCH_SIGNALS:
		input_manager.connect(signal_name, func(): emitted.append(signal_name))
	
	assert_true(input_manager.register_provider(provider), "Boxing provider should register")
	
	provider.straight_left.emit()
	provider.straight_right.emit()
	provider.uppercut_left.emit()
	provider.uppercut_right.emit()
	provider.hook_left.emit()
	provider.hook_right.emit()
	
	assert_eq(emitted, PUNCH_SIGNALS, "Manager should forward each punch event without payload")
	
	input_manager.free()
	provider.free()

func _get_signal_arg_count(target: Object, signal_name: String) -> int:
	for signal_info in target.get_signal_list():
		if signal_info["name"] == signal_name:
			return signal_info["args"].size()
	return -1
