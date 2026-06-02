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
	"mediapipe_python",     # Temporary compatibility fallback during de-MediaPipe migration
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

signal punch_left(power: float)
signal punch_right(power: float)
signal uppercut_left(power: float)
signal uppercut_right(power: float)
signal hook_left(power: float)
signal hook_right(power: float)
signal guard_start
signal guard_end
signal squat_start
signal squat_end
signal lean_left_start
signal lean_left_end
signal lean_right_start
signal lean_right_end
signal sidestep_left_start
signal sidestep_left_end
signal sidestep_right_start
signal sidestep_right_end
signal knee_left(power: float)
signal knee_right(power: float)
signal leg_lift_left_start
signal leg_lift_left_end
signal leg_lift_right_start
signal leg_lift_right_end

# ============================================================================
# SIGNALS: FLOW GAMEPLAY INTENTS (Proxied from active provider)
# ============================================================================

signal swing_left(placement: StringName, direction: StringName)
signal swing_right(placement: StringName, direction: StringName)
signal trail_left(placement: StringName, direction: StringName)
signal trail_right(placement: StringName, direction: StringName)

# ============================================================================
# INTERNAL STATE
# ============================================================================

## Dictionary of registered providers: provider_id -> AeroInputProvider.
var _providers: Dictionary = {}

## Currently active provider.
var _active_provider: AeroInputProvider = null

## Provider settings cache: provider_id -> settings_dict.
var _provider_settings: Dictionary = {}

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
	provider.started.connect(func(): started.emit())
	provider.stopped.connect(func(): stopped.emit())
	provider.failed.connect(func(err): failed.emit(err))
	
	provider.tracking_updated.connect(
		func(h, lh, rh, lf, rf): tracking_updated.emit(h, lh, rh, lf, rf)
	)
	provider.camera_devices_changed.connect(func(devices, selected_device_id):
		if provider == _active_provider:
			camera_devices_changed.emit(devices, selected_device_id)
	)
	
	if provider.has_signal("punch_left"):
		_connect_boxing_signals(provider)
	
	if provider.has_signal("swing_left") \
	or provider.has_signal("swing_right") \
	or provider.has_signal("trail_left") \
	or provider.has_signal("trail_right"):
		_connect_flow_signals(provider)

func _connect_boxing_signals(provider: AeroInputProvider) -> void:
	if provider.has_signal("punch_left"):
		provider.punch_left.connect(func(p): punch_left.emit(p))
	if provider.has_signal("punch_right"):
		provider.punch_right.connect(func(p): punch_right.emit(p))
	if provider.has_signal("uppercut_left"):
		provider.uppercut_left.connect(func(p): uppercut_left.emit(p))
	if provider.has_signal("uppercut_right"):
		provider.uppercut_right.connect(func(p): uppercut_right.emit(p))
	if provider.has_signal("hook_left"):
		provider.hook_left.connect(func(p): hook_left.emit(p))
	if provider.has_signal("hook_right"):
		provider.hook_right.connect(func(p): hook_right.emit(p))
	
	if provider.has_signal("guard_start"):
		provider.guard_start.connect(func(): guard_start.emit())
	if provider.has_signal("guard_end"):
		provider.guard_end.connect(func(): guard_end.emit())
	if provider.has_signal("squat_start"):
		provider.squat_start.connect(func(): squat_start.emit())
	if provider.has_signal("squat_end"):
		provider.squat_end.connect(func(): squat_end.emit())
	if provider.has_signal("lean_left_start"):
		provider.lean_left_start.connect(func(): lean_left_start.emit())
	if provider.has_signal("lean_left_end"):
		provider.lean_left_end.connect(func(): lean_left_end.emit())
	if provider.has_signal("lean_right_start"):
		provider.lean_right_start.connect(func(): lean_right_start.emit())
	if provider.has_signal("lean_right_end"):
		provider.lean_right_end.connect(func(): lean_right_end.emit())
	if provider.has_signal("sidestep_left_start"):
		provider.sidestep_left_start.connect(func(): sidestep_left_start.emit())
	if provider.has_signal("sidestep_left_end"):
		provider.sidestep_left_end.connect(func(): sidestep_left_end.emit())
	if provider.has_signal("sidestep_right_start"):
		provider.sidestep_right_start.connect(func(): sidestep_right_start.emit())
	if provider.has_signal("sidestep_right_end"):
		provider.sidestep_right_end.connect(func(): sidestep_right_end.emit())
	
	if provider.has_signal("knee_left"):
		provider.knee_left.connect(func(p): knee_left.emit(p))
	if provider.has_signal("knee_right"):
		provider.knee_right.connect(func(p): knee_right.emit(p))
	if provider.has_signal("leg_lift_left_start"):
		provider.leg_lift_left_start.connect(func(): leg_lift_left_start.emit())
	if provider.has_signal("leg_lift_left_end"):
		provider.leg_lift_left_end.connect(func(): leg_lift_left_end.emit())
	if provider.has_signal("leg_lift_right_start"):
		provider.leg_lift_right_start.connect(func(): leg_lift_right_start.emit())
	if provider.has_signal("leg_lift_right_end"):
		provider.leg_lift_right_end.connect(func(): leg_lift_right_end.emit())

func _connect_flow_signals(provider: AeroInputProvider) -> void:
	if provider.has_signal("swing_left"):
		provider.swing_left.connect(func(p, d): swing_left.emit(p, d))
	if provider.has_signal("swing_right"):
		provider.swing_right.connect(func(p, d): swing_right.emit(p, d))
	if provider.has_signal("trail_left"):
		provider.trail_left.connect(func(p, d): trail_left.emit(p, d))
	if provider.has_signal("trail_right"):
		provider.trail_right.connect(func(p, d): trail_right.emit(p, d))
	if provider.has_signal("squat_start"):
		provider.squat_start.connect(func(): squat_start.emit())
	if provider.has_signal("squat_end"):
		provider.squat_end.connect(func(): squat_end.emit())
	if provider.has_signal("lean_left_start"):
		provider.lean_left_start.connect(func(): lean_left_start.emit())
	if provider.has_signal("lean_left_end"):
		provider.lean_left_end.connect(func(): lean_left_end.emit())
	if provider.has_signal("lean_right_start"):
		provider.lean_right_start.connect(func(): lean_right_start.emit())
	if provider.has_signal("lean_right_end"):
		provider.lean_right_end.connect(func(): lean_right_end.emit())
	if provider.has_signal("sidestep_left_start"):
		provider.sidestep_left_start.connect(func(): sidestep_left_start.emit())
	if provider.has_signal("sidestep_left_end"):
		provider.sidestep_left_end.connect(func(): sidestep_left_end.emit())
	if provider.has_signal("sidestep_right_start"):
		provider.sidestep_right_start.connect(func(): sidestep_right_start.emit())
	if provider.has_signal("sidestep_right_end"):
		provider.sidestep_right_end.connect(func(): sidestep_right_end.emit())

func _disconnect_provider_signals(provider: AeroInputProvider) -> void:
	# Godot will usually clean these up when the provider is freed, but we keep the
	# explicit disconnect pass for predictable manager lifecycle semantics.
	var signals := provider.get_signal_list()
	for sig in signals:
		provider.disconnect(sig["name"], Callable())

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

