class_name InputManager
extends Node
## Central coordinator for AeroBeat input providers.
##
## This manager preserves a future-friendly provider abstraction layer while
## making the current product truth explicit: camera providers are the official
## AeroBeat v1 gameplay default path.
##
## Its gameplay-facing signals mirror the stable v1 intent contracts exposed by
## FlowInput and BoxingInput. Optional provider observation data can still flow
## through the base AeroInputProvider channel, but that observation layer is not
## the primary gameplay contract.

# ============================================================================
# CONFIGURATION
# ============================================================================

## If true, automatically switch to the highest-priority available provider.
## The default priority order is intentionally camera-first for v1 gameplay.
@export var auto_switch_inputs: bool = true

## Priority order for input providers (highest priority first).
## Camera providers are the official gameplay-default path for v1.
## Non-camera providers remain registered/future-friendly, but are deprioritized
## so the runtime policy does not imply broad current gameplay parity.
@export var input_priority: Array[String] = [
	"camera_tracking",      # Preferred v1 desktop camera gameplay path
	"mediapipe_native",     # Preferred v1 mobile/native camera gameplay path
	"xr_6dof",              # Future / experimental richer provider path
	"joycon_hid",           # Future / experimental non-camera gameplay path
	"gamepad",              # Future / experimental non-camera gameplay path
	"mouse",                # Supported for menu/navigation; not official v1 gameplay parity
	"keyboard"              # Future / fallback input path; not official v1 gameplay parity
]

# ============================================================================
# SIGNALS: PROVIDER MANAGEMENT
# ============================================================================

## Emitted when a new provider is successfully registered.
signal provider_registered(provider: AeroInputProvider)

## Emitted when a provider is unregistered.
signal provider_unregistered(provider_id: String)

## Emitted when the active provider changes.
signal active_provider_changed(provider: AeroInputProvider)

# ============================================================================
# SIGNALS: LIFECYCLE (Proxied from active provider)
# ============================================================================

signal started
signal stopped
signal failed(error: String)

# ============================================================================
# SIGNALS: OPTIONAL OBSERVATION / SPATIAL FEED
# ============================================================================

signal tracking_updated(
	head_transform: Transform3D,
	left_hand_transform: Transform3D,
	right_hand_transform: Transform3D,
	left_foot_transform: Transform3D,
	right_foot_transform: Transform3D
)

signal camera_devices_changed(devices: Array, selected_device_id: String)

# ============================================================================
# SIGNALS: BOXING GAMEPLAY INTENTS (Proxied from active provider)
# ============================================================================

signal straight_left
signal straight_right
signal uppercut_left
signal uppercut_right
signal hook_left
signal hook_right
signal guard_enabled
signal guard_disabled
signal squat_enabled
signal squat_disabled
signal weave_left_enabled
signal weave_left_disabled
signal weave_right_enabled
signal weave_right_disabled

# ============================================================================
# SIGNALS: SHARED CALIBRATED BODY-CELL / CALIBRATION LANE
# ============================================================================

signal left_wrist_cell_entered(cell: int, direction: int)
signal right_wrist_cell_entered(cell: int, direction: int)
signal nose_cell_entered(cell: int, direction: int)
signal calibration_session_updated(session: Dictionary)
signal body_grid_nose_updated(anchor: Dictionary)
signal body_grid_left_wrist_updated(anchor: Dictionary)
signal body_grid_right_wrist_updated(anchor: Dictionary)
signal body_grid_calibration_started(event: Dictionary)
signal body_grid_calibration_succeeded(event: Dictionary)
signal body_grid_calibration_failed(event: Dictionary)
signal body_grid_calibration_canceled(event: Dictionary)

# ============================================================================
# INTERNAL STATE
# ============================================================================

## Dictionary of registered providers: provider_id -> AeroInputProvider.
var _providers: Dictionary = {}

## Currently active provider.
var _active_provider: AeroInputProvider = null

## Provider settings cache: provider_id -> settings_dict.
var _provider_settings: Dictionary = {}

## Concrete signal connections made by this manager: provider_instance_id -> connection dictionaries.
var _provider_signal_connections: Dictionary = {}

var _body_grid_anchors: Dictionary = {
	"nose": BodyCellInput.make_invalid_body_grid_anchor("nose"),
	"left_wrist": BodyCellInput.make_invalid_body_grid_anchor("left_wrist"),
	"right_wrist": BodyCellInput.make_invalid_body_grid_anchor("right_wrist")
}

var _body_grid_calibration_state: Dictionary = BodyCellInput.make_body_grid_calibration_state("none")

# ============================================================================
# PUBLIC API: PROVIDER REGISTRATION
# ============================================================================

## Register a new input provider.
## @param provider: The input provider instance to register.
## @param settings: Optional dictionary of settings for this provider.
## @return: true if registration succeeded, false otherwise.
func register_provider(provider: AeroInputProvider, settings: Dictionary = {}) -> bool:
	if provider == null:
		push_error("InputManager: Cannot register null provider")
		return false
	
	var provider_id := _get_provider_id(provider)
	
	if _providers.has(provider_id):
		push_warning("InputManager: Provider '%s' already registered" % provider_id)
		return false
	
	# Probe the provider with a lightweight startup check before registration.
	if not provider.start(JSON.stringify({"test": true})):
		push_warning("InputManager: Provider '%s' failed startup test" % provider_id)
		return false
	
	provider.stop()
	
	_providers[provider_id] = provider
	_provider_settings[provider_id] = settings
	
	_connect_provider_signals(provider)
	provider_registered.emit(provider)
	
	if auto_switch_inputs:
		_evaluate_provider_priority()
	
	return true

## Unregister an input provider.
## @param provider_id: The ID of the provider to unregister.
func unregister_provider(provider_id: String) -> void:
	if not _providers.has(provider_id):
		push_warning("InputManager: Provider '%s' not found" % provider_id)
		return
	
	var provider: AeroInputProvider = _providers[provider_id]
	
	if _active_provider == provider:
		provider.stop()
		_active_provider = null
		_clear_body_grid_anchors(true)
	
	_disconnect_provider_signals(provider)
	
	_providers.erase(provider_id)
	_provider_settings.erase(provider_id)
	
	provider_unregistered.emit(provider_id)
	
	if auto_switch_inputs:
		_evaluate_provider_priority()

## Get a registered provider by ID.
## @param provider_id: The provider ID to look up.
## @return: The provider instance, or null if not found.
func get_provider(provider_id: String) -> AeroInputProvider:
	return _providers.get(provider_id, null)

## Get the currently active provider.
## @return: The active provider, or null if none active.
func get_active_provider() -> AeroInputProvider:
	return _active_provider

## Get list of all registered provider IDs.
## @return: Array of provider ID strings.
func get_registered_providers() -> Array[String]:
	var provider_ids: Array[String] = []
	for provider_id in _providers.keys():
		provider_ids.append(String(provider_id))
	return provider_ids

# ============================================================================
# PUBLIC API: PROVIDER CONTROL
# ============================================================================

## Set a specific provider as active.
## @param provider: The provider to activate.
## @return: true if activation succeeded.
func set_active_provider(provider: AeroInputProvider) -> bool:
	if provider == null:
		push_error("InputManager: Cannot activate null provider")
		return false
	
	var provider_id := _get_provider_id(provider)
	
	if not _providers.has(provider_id):
		push_error("InputManager: Provider '%s' not registered" % provider_id)
		return false
	
	if _active_provider != null and _active_provider != provider:
		_active_provider.stop()
		_clear_body_grid_anchors(true)
	
	var settings: Dictionary = _provider_settings.get(provider_id, {})
	var settings_json: String = JSON.stringify(settings)
	
	if not provider.start(settings_json):
		push_error("InputManager: Failed to start provider '%s'" % provider_id)
		return false
	
	_active_provider = provider
	active_provider_changed.emit(provider)
	
	return true

## Stop the active provider.
func stop_active_provider() -> void:
	if _active_provider != null:
		_active_provider.stop()
		_active_provider = null
		_clear_body_grid_anchors(true)

## Return the active provider's available camera devices.
func get_active_provider_camera_devices() -> Array:
	if _active_provider == null:
		return []
	return _active_provider.get_available_camera_devices()

## Return the active provider's selected camera-device identity.
func get_active_provider_selected_camera_device_id() -> String:
	if _active_provider == null:
		return ""
	return _active_provider.get_selected_camera_device_id()

## Update the cached camera selection for a registered provider.
func set_provider_selected_camera_device_id(provider_id: String, device_id: String) -> bool:
	if not _providers.has(provider_id):
		return false
	var provider: AeroInputProvider = _providers[provider_id]
	var settings: Dictionary = _provider_settings.get(provider_id, {}).duplicate(true)
	settings["selected_camera_device_id"] = device_id
	settings["camera_source"] = device_id
	_provider_settings[provider_id] = settings
	return provider.set_selected_camera_device_id(device_id)

## Request a fresh shared calibration pass from the active provider.
func start_calibration() -> bool:
	if _active_provider == null or not _active_provider.has_method("start_calibration"):
		return false
	return bool(_active_provider.start_calibration())

## Cancel the current shared calibration pass on the active provider.
func cancel_calibration() -> bool:
	if _active_provider == null or not _active_provider.has_method("cancel_calibration"):
		return false
	return bool(_active_provider.cancel_calibration())

## Return the active provider's shared calibration session document.
func get_calibration_session() -> Dictionary:
	if _active_provider == null or not _active_provider.has_method("get_calibration_session"):
		return {}
	return _active_provider.get_calibration_session()

func get_body_grid_nose() -> Dictionary:
	return _get_body_grid_anchor_from_active_provider("nose", "get_body_grid_nose")

func get_body_grid_left_wrist() -> Dictionary:
	return _get_body_grid_anchor_from_active_provider("left_wrist", "get_body_grid_left_wrist")

func get_body_grid_right_wrist() -> Dictionary:
	return _get_body_grid_anchor_from_active_provider("right_wrist", "get_body_grid_right_wrist")

func get_body_grid_calibration_state() -> Dictionary:
	if _active_provider != null and _active_provider.has_method("get_body_grid_calibration_state"):
		var provider_state: Variant = _active_provider.get_body_grid_calibration_state()
		if provider_state is Dictionary:
			_body_grid_calibration_state = provider_state.duplicate(true)
	return _body_grid_calibration_state.duplicate(true)

# ============================================================================
# PUBLIC API: CAPABILITY CHECKS
# ============================================================================

## Check if the active provider supports a specific optional capability.
## @param capability: The Capability enum value to check.
## @return: true if the active provider supports the capability.
func active_provider_has_capability(capability: AeroInputProvider.Capability) -> bool:
	if _active_provider == null:
		return false
	return _active_provider.has_capability(capability)

## Check if any registered provider supports a specific optional capability.
## @param capability: The Capability enum value to check.
## @return: true if any provider supports the capability.
func any_provider_has_capability(capability: AeroInputProvider.Capability) -> bool:
	for provider in _providers.values():
		if provider.has_capability(capability):
			return true
	return false

# ============================================================================
# PRIVATE: SIGNAL MANAGEMENT
# ============================================================================

func _connect_provider_signals(provider: AeroInputProvider) -> void:
	_connect_provider_signal(provider, "started", func(): started.emit())
	_connect_provider_signal(provider, "stopped", func():
		if provider == _active_provider:
			_clear_body_grid_anchors(true)
			_active_provider = null
		stopped.emit()
	)
	_connect_provider_signal(provider, "failed", func(err): failed.emit(err))
	
	_connect_provider_signal(provider, "tracking_updated", func(h, lh, rh, lf, rf):
		tracking_updated.emit(h, lh, rh, lf, rf)
	)
	_connect_provider_signal(provider, "camera_devices_changed", func(devices, selected_device_id):
		if provider == _active_provider:
			camera_devices_changed.emit(devices, selected_device_id)
	)
	
	if provider.has_signal("straight_left"):
		_connect_boxing_signals(provider)
	
	if provider.has_signal("left_wrist_cell_entered") \
	or provider.has_signal("right_wrist_cell_entered") \
	or provider.has_signal("nose_cell_entered") \
	or provider.has_signal("calibration_session_updated") \
	or provider.has_signal("body_grid_nose_updated") \
	or provider.has_signal("body_grid_left_wrist_updated") \
	or provider.has_signal("body_grid_right_wrist_updated") \
	or provider.has_signal("body_grid_calibration_started") \
	or provider.has_signal("body_grid_calibration_succeeded") \
	or provider.has_signal("body_grid_calibration_failed") \
	or provider.has_signal("body_grid_calibration_canceled"):
		_connect_body_cell_signals(provider)

func _connect_boxing_signals(provider: AeroInputProvider) -> void:
	if provider.has_signal("straight_left"):
		_connect_provider_signal(provider, "straight_left", func(_power := 1.0): straight_left.emit())
	if provider.has_signal("straight_right"):
		_connect_provider_signal(provider, "straight_right", func(_power := 1.0): straight_right.emit())
	if provider.has_signal("uppercut_left"):
		_connect_provider_signal(provider, "uppercut_left", func(_power := 1.0): uppercut_left.emit())
	if provider.has_signal("uppercut_right"):
		_connect_provider_signal(provider, "uppercut_right", func(_power := 1.0): uppercut_right.emit())
	if provider.has_signal("hook_left"):
		_connect_provider_signal(provider, "hook_left", func(_power := 1.0): hook_left.emit())
	if provider.has_signal("hook_right"):
		_connect_provider_signal(provider, "hook_right", func(_power := 1.0): hook_right.emit())
	
	if provider.has_signal("guard_enabled"):
		_connect_provider_signal(provider, "guard_enabled", func(): guard_enabled.emit())
	if provider.has_signal("guard_disabled"):
		_connect_provider_signal(provider, "guard_disabled", func(): guard_disabled.emit())
	if provider.has_signal("squat_enabled"):
		_connect_provider_signal(provider, "squat_enabled", func(): squat_enabled.emit())
	if provider.has_signal("squat_disabled"):
		_connect_provider_signal(provider, "squat_disabled", func(): squat_disabled.emit())
	if provider.has_signal("weave_left_enabled"):
		_connect_provider_signal(provider, "weave_left_enabled", func(): weave_left_enabled.emit())
	if provider.has_signal("weave_left_disabled"):
		_connect_provider_signal(provider, "weave_left_disabled", func(): weave_left_disabled.emit())
	if provider.has_signal("weave_right_enabled"):
		_connect_provider_signal(provider, "weave_right_enabled", func(): weave_right_enabled.emit())
	if provider.has_signal("weave_right_disabled"):
		_connect_provider_signal(provider, "weave_right_disabled", func(): weave_right_disabled.emit())

func _connect_body_cell_signals(provider: AeroInputProvider) -> void:
	if provider.has_signal("left_wrist_cell_entered"):
		_connect_provider_signal(provider, "left_wrist_cell_entered", func(cell, direction):
			if provider == _active_provider:
				left_wrist_cell_entered.emit(cell, direction)
		)
	if provider.has_signal("right_wrist_cell_entered"):
		_connect_provider_signal(provider, "right_wrist_cell_entered", func(cell, direction):
			if provider == _active_provider:
				right_wrist_cell_entered.emit(cell, direction)
		)
	if provider.has_signal("nose_cell_entered"):
		_connect_provider_signal(provider, "nose_cell_entered", func(cell, direction):
			if provider == _active_provider:
				nose_cell_entered.emit(cell, direction)
		)
	if provider.has_signal("calibration_session_updated"):
		_connect_provider_signal(provider, "calibration_session_updated", func(session):
			if provider == _active_provider:
				calibration_session_updated.emit(session.duplicate(true))
		)
	if provider.has_signal("body_grid_nose_updated"):
		_connect_provider_signal(provider, "body_grid_nose_updated", func(anchor):
			_handle_body_grid_anchor_updated(provider, "nose", anchor)
		)
	if provider.has_signal("body_grid_left_wrist_updated"):
		_connect_provider_signal(provider, "body_grid_left_wrist_updated", func(anchor):
			_handle_body_grid_anchor_updated(provider, "left_wrist", anchor)
		)
	if provider.has_signal("body_grid_right_wrist_updated"):
		_connect_provider_signal(provider, "body_grid_right_wrist_updated", func(anchor):
			_handle_body_grid_anchor_updated(provider, "right_wrist", anchor)
		)
	if provider.has_signal("body_grid_calibration_started"):
		_connect_provider_signal(provider, "body_grid_calibration_started", func(event):
			_handle_body_grid_calibration_event(provider, "started", event)
			_clear_body_grid_anchors(true, false)
		)
	if provider.has_signal("body_grid_calibration_succeeded"):
		_connect_provider_signal(provider, "body_grid_calibration_succeeded", func(event):
			_handle_body_grid_calibration_event(provider, "succeeded", event)
		)
	if provider.has_signal("body_grid_calibration_failed"):
		_connect_provider_signal(provider, "body_grid_calibration_failed", func(event):
			_handle_body_grid_calibration_event(provider, "failed", event)
			_clear_body_grid_anchors(true, false)
		)
	if provider.has_signal("body_grid_calibration_canceled"):
		_connect_provider_signal(provider, "body_grid_calibration_canceled", func(event):
			_handle_body_grid_calibration_event(provider, "canceled", event)
			_clear_body_grid_anchors(true, false)
		)

func _get_body_grid_anchor_from_active_provider(anchor_name: String, method_name: String) -> Dictionary:
	if _active_provider != null and _active_provider.has_method(method_name):
		var provider_anchor: Variant = _active_provider.call(method_name)
		if provider_anchor is Dictionary:
			_body_grid_anchors[anchor_name] = provider_anchor.duplicate(true)
	return _body_grid_anchors[anchor_name].duplicate(true)

func _handle_body_grid_anchor_updated(provider: AeroInputProvider, anchor_name: String, anchor: Dictionary) -> void:
	if provider != _active_provider:
		return
	var anchor_copy := anchor.duplicate(true)
	_body_grid_anchors[anchor_name] = anchor_copy
	match anchor_name:
		"nose":
			body_grid_nose_updated.emit(anchor_copy.duplicate(true))
		"left_wrist":
			body_grid_left_wrist_updated.emit(anchor_copy.duplicate(true))
		"right_wrist":
			body_grid_right_wrist_updated.emit(anchor_copy.duplicate(true))

func _handle_body_grid_calibration_event(provider: AeroInputProvider, state_name: String, event: Dictionary) -> void:
	if provider != _active_provider:
		return
	_body_grid_calibration_state = event.duplicate(true)
	match state_name:
		"started":
			body_grid_calibration_started.emit(_body_grid_calibration_state.duplicate(true))
		"succeeded":
			body_grid_calibration_succeeded.emit(_body_grid_calibration_state.duplicate(true))
		"failed":
			body_grid_calibration_failed.emit(_body_grid_calibration_state.duplicate(true))
		"canceled":
			body_grid_calibration_canceled.emit(_body_grid_calibration_state.duplicate(true))

func _clear_body_grid_anchors(emit_updates: bool, reset_calibration_state: bool = true) -> void:
	var invalid_nose := BodyCellInput.make_invalid_body_grid_anchor("nose")
	var invalid_left_wrist := BodyCellInput.make_invalid_body_grid_anchor("left_wrist")
	var invalid_right_wrist := BodyCellInput.make_invalid_body_grid_anchor("right_wrist")
	var should_emit: bool = emit_updates and (
		_body_grid_anchors["nose"] != invalid_nose
		or _body_grid_anchors["left_wrist"] != invalid_left_wrist
		or _body_grid_anchors["right_wrist"] != invalid_right_wrist
	)
	_body_grid_anchors["nose"] = invalid_nose
	_body_grid_anchors["left_wrist"] = invalid_left_wrist
	_body_grid_anchors["right_wrist"] = invalid_right_wrist
	if reset_calibration_state:
		_body_grid_calibration_state = BodyCellInput.make_body_grid_calibration_state("none")
	if not should_emit:
		return
	body_grid_nose_updated.emit(_body_grid_anchors["nose"].duplicate(true))
	body_grid_left_wrist_updated.emit(_body_grid_anchors["left_wrist"].duplicate(true))
	body_grid_right_wrist_updated.emit(_body_grid_anchors["right_wrist"].duplicate(true))

func _disconnect_provider_signals(provider: AeroInputProvider) -> void:
	# Godot will usually clean these up when the provider is freed, but we keep the
	# explicit disconnect pass for predictable manager lifecycle semantics.
	var provider_instance_id := provider.get_instance_id()
	var connections: Array = _provider_signal_connections.get(provider_instance_id, [])
	for connection in connections:
		var signal_name: StringName = connection.get("signal", &"")
		var callback: Callable = connection.get("callable", Callable())
		if not callback.is_valid():
			continue
		if provider.has_signal(signal_name) and provider.is_connected(signal_name, callback):
			provider.disconnect(signal_name, callback)
	_provider_signal_connections.erase(provider_instance_id)

func _connect_provider_signal(provider: AeroInputProvider, signal_name: StringName, callback: Callable) -> void:
	if not provider.has_signal(signal_name):
		return
	if provider.is_connected(signal_name, callback):
		return
	var error := provider.connect(signal_name, callback)
	if error != OK:
		push_warning("InputManager: Failed to connect provider signal '%s' (error %d)" % [signal_name, error])
		return
	var provider_instance_id := provider.get_instance_id()
	if not _provider_signal_connections.has(provider_instance_id):
		_provider_signal_connections[provider_instance_id] = []
	_provider_signal_connections[provider_instance_id].append({
		"signal": signal_name,
		"callable": callback
	})

# ============================================================================
# PRIVATE: PRIORITY MANAGEMENT
# ============================================================================

func _evaluate_provider_priority() -> void:
	if _providers.is_empty():
		return
	
	# Prefer the highest-ranked registered provider. The default list is ordered so
	# camera providers become the active gameplay path before future-facing peers.
	for provider_id in input_priority:
		if _providers.has(provider_id):
			var provider: AeroInputProvider = _providers[provider_id]
			if _active_provider != provider:
				set_active_provider(provider)
			return
	
	# If no configured priority entry matches, fall back to the first available
	# provider without implying product-level parity.
	if _active_provider == null:
		var first_provider: AeroInputProvider = _providers.values()[0]
		set_active_provider(first_provider)

func _get_provider_id(provider: AeroInputProvider) -> String:
	var provider_id: String = String(provider.get_provider_id()).strip_edges().to_snake_case()
	if provider_id != "":
		return provider_id

	var script: Variant = provider.get_script()
	if script != null and script is GDScript:
		var global_name: String = String(script.get_global_name()).strip_edges()
		if global_name != "":
			return global_name.to_snake_case()
	
	return String(provider.get_class()).strip_edges().to_snake_case()

# ============================================================================
# CLEANUP
# ============================================================================

func _exit_tree() -> void:
	stop_active_provider()
	
	for provider in _providers.values():
		provider.stop()
	
	_providers.clear()
	_provider_settings.clear()
