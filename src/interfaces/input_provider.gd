class_name AeroInputProvider
extends Node
## Abstract base class for AeroBeat input providers.
##
## AeroBeat v1 gameplay is camera-first and intent-first.
##
## This package keeps two intentionally different lanes of data:
## - gameplay-facing intent contracts: stable, versionable signals like punches,
##   guard, slices, squats, leans, and sidesteps
## - optional provider observation data: richer body/spatial feeds that concrete
##   providers may expose for detector internals, debugging, or future features
##
## Raw pose / observation data is not the primary gameplay contract for v1.
## Implementers should only advertise capabilities they truly support. Callers
## should gate optional behavior through has_capability() instead of assuming the
## full surface is available on every provider.

# ============================================================================
# ENUMS & CONSTANTS
# ============================================================================

## Tracking coordinate modes.
## MODE_2D is the most common fit for camera-first gameplay normalization.
enum TrackingMode {
	MODE_2D,  ## Screen-space or normalized camera-relative coordinates
	MODE_3D   ## Optional richer provider-defined 3D coordinates when available
}

## Provider capability flags.
## Capabilities are optional and provider-dependent unless a caller explicitly
## requires them. Do not treat the full list as the universal v1 baseline.
enum Capability {
	SPATIAL_TRANSFORM = 1,      ## Optional richer transform stream / 6DOF-style data
	GESTURE_RECOGNITION = 2,    ## Optional gameplay gesture events (punch, slice, etc.)
	LOWER_BODY = 4,             ## Optional lower-body tracking for future gameplay/fitness use
	HAPTICS = 8,                ## Future-facing feedback path for providers that can drive it
	VELOCITY = 16               ## Optional velocity polling when a provider can estimate it
}

## Body part tracking flags (bitmask).
## Camera-first providers will commonly prioritize head and hands. Foot tracking
## remains available for optional/future-capability providers.
enum BodyTrackFlags {
	NONE = 0,
	HEAD = 1,
	LEFT_HAND = 2,
	RIGHT_HAND = 4,
	LEFT_FOOT = 8,
	RIGHT_FOOT = 16,
	ALL = 31
}

# ============================================================================
# SIGNALS: LIFECYCLE CALLBACKS
# ============================================================================

## Emitted when tracking successfully starts.
signal started

## Emitted when tracking stops (normal shutdown).
signal stopped

## Emitted on error with description.
signal failed(error: String)

# ============================================================================
# SIGNALS: OPTIONAL OBSERVATION / SPATIAL FEED
# ============================================================================

## Optional continuous observation feed.
## This is a provider-side richness channel, not the canonical gameplay-facing
## v1 input contract. Camera providers may only populate part of this surface,
## while richer providers may drive it more fully.
signal tracking_updated(
	head_transform: Transform3D,
	left_hand_transform: Transform3D,
	right_hand_transform: Transform3D,
	left_foot_transform: Transform3D,
	right_foot_transform: Transform3D
)

## Emitted when the provider refreshes its available camera-device list or selected camera identity.
signal camera_devices_changed(devices: Array, selected_device_id: String)

# ============================================================================
# COMMANDS (Call these to control the provider)
# ============================================================================

## Initializes and starts the tracking backend.
## @param settings_json: Configuration for the specific driver (for example camera
## selection, smoothing, or future provider-specific toggles).
## Returns: bool indicating success/failure.
func start(settings_json: String) -> bool:
	push_error("AeroInputProvider: start() must be overridden")
	return false

## Shuts down tracking and releases hardware resources.
func stop() -> void:
	push_error("AeroInputProvider: stop() must be overridden")

## Returns true if the hardware is currently initialized and sending data.
func is_tracking() -> bool:
	push_error("AeroInputProvider: is_tracking() must be overridden")
	return false

## Returns the stable provider identity used for registration and priority selection.
## Concrete providers should override this when their official runtime identity
## must stay stable regardless of wrapper script names or assembly mount aliases.
func get_provider_id() -> String:
	var script: Variant = get_script()
	if script != null and script is GDScript:
		var global_name: String = String(script.get_global_name()).strip_edges()
		if global_name != "":
			return global_name.to_snake_case()

	return String(get_class()).strip_edges().to_snake_case()

## Returns whether this specific provider supports an optional capability.
## @param capability: The Capability enum value to check.
func has_capability(capability: Capability) -> bool:
	push_error("AeroInputProvider: has_capability() must be overridden")
	return false

## Return the currently available camera devices for this provider.
## Each entry should expose a stable `id` plus any optional display metadata the provider can supply.
func get_available_camera_devices() -> Array:
	return []

## Return the currently selected camera-device identity for this provider.
## Providers should prefer a stable identifier over an implicit numeric default when possible.
func get_selected_camera_device_id() -> String:
	return ""

## Set the selected camera-device identity for this provider.
## Providers may defer the actual hardware swap until the next start if hot-swap is not supported.
func set_selected_camera_device_id(_device_id: String) -> bool:
	return false

## Trigger haptics for feedback when supported.
## This is a future-facing extension and should be capability-gated.
## @param side: 0=Left, 1=Right
## @param intensity: 0.0 to 1.0
## @param duration_ms: duration in milliseconds
func trigger_haptic(side: int, intensity: float, duration_ms: int) -> void:
	push_error("AeroInputProvider: trigger_haptic() must be overridden")

# ============================================================================
# STATE QUERIES: POSITION
# ============================================================================

## Get head position in normalized 2D or optional richer 3D coordinates.
func get_head_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	push_error("AeroInputProvider: get_head_position() must be overridden")
	return Vector3.ZERO

## Get left hand position in normalized 2D or optional richer 3D coordinates.
func get_left_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	push_error("AeroInputProvider: get_left_hand_position() must be overridden")
	return Vector3.ZERO

## Get right hand position in normalized 2D or optional richer 3D coordinates.
func get_right_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	push_error("AeroInputProvider: get_right_hand_position() must be overridden")
	return Vector3.ZERO

## Get left foot position when the provider supports optional lower-body tracking.
func get_left_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	push_error("AeroInputProvider: get_left_foot_position() must be overridden")
	return Vector3.ZERO

## Get right foot position when the provider supports optional lower-body tracking.
func get_right_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	push_error("AeroInputProvider: get_right_foot_position() must be overridden")
	return Vector3.ZERO

# ============================================================================
# STATE QUERIES: VELOCITY (Optional)
# ============================================================================

## Get head velocity vector when supported.
func get_head_velocity() -> Vector3:
	push_error("AeroInputProvider: get_head_velocity() must be overridden")
	return Vector3.ZERO

## Get left hand velocity vector when supported.
func get_left_hand_velocity() -> Vector3:
	push_error("AeroInputProvider: get_left_hand_velocity() must be overridden")
	return Vector3.ZERO

## Get right hand velocity vector when supported.
func get_right_hand_velocity() -> Vector3:
	push_error("AeroInputProvider: get_right_hand_velocity() must be overridden")
	return Vector3.ZERO

## Get left foot velocity vector when lower-body tracking is supported.
func get_left_foot_velocity() -> Vector3:
	push_error("AeroInputProvider: get_left_foot_velocity() must be overridden")
	return Vector3.ZERO

## Get right foot velocity vector when lower-body tracking is supported.
func get_right_foot_velocity() -> Vector3:
	push_error("AeroInputProvider: get_right_foot_velocity() must be overridden")
	return Vector3.ZERO

# ============================================================================
# STATE QUERIES: ROTATION (Optional Rich Spatial Data)
# ============================================================================

## Get head rotation as quaternion when the provider can estimate it.
func get_head_rotation() -> Quaternion:
	push_error("AeroInputProvider: get_head_rotation() must be overridden")
	return Quaternion.IDENTITY

## Get left hand rotation as quaternion when the provider can estimate it.
func get_left_hand_rotation() -> Quaternion:
	push_error("AeroInputProvider: get_left_hand_rotation() must be overridden")
	return Quaternion.IDENTITY

## Get right hand rotation as quaternion when the provider can estimate it.
func get_right_hand_rotation() -> Quaternion:
	push_error("AeroInputProvider: get_right_hand_rotation() must be overridden")
	return Quaternion.IDENTITY

## Get left foot rotation as quaternion when lower-body tracking is supported.
func get_left_foot_rotation() -> Quaternion:
	push_error("AeroInputProvider: get_left_foot_rotation() must be overridden")
	return Quaternion.IDENTITY

## Get right foot rotation as quaternion when lower-body tracking is supported.
func get_right_foot_rotation() -> Quaternion:
	push_error("AeroInputProvider: get_right_foot_rotation() must be overridden")
	return Quaternion.IDENTITY

# ============================================================================
# STATE QUERIES: CONFIDENCE
# ============================================================================

## Get tracking confidence for a specific body part.
## @param body_part: One of: "head", "left_hand", "right_hand", "left_foot", "right_foot"
## Returns: confidence value from 0.0 to 1.0.
func get_tracking_confidence(body_part: StringName) -> float:
	push_error("AeroInputProvider: get_tracking_confidence() must be overridden")
	return 0.0

# ============================================================================
# SETTERS / CONFIG
# ============================================================================

## Set the tracking mode (2D camera-first normalization or optional richer 3D output).
func set_tracking_mode(mode: TrackingMode) -> void:
	push_error("AeroInputProvider: set_tracking_mode() must be overridden")

## Set body tracking flags (bitmask of BodyTrackFlags) for optional body regions.
func set_body_track_flags(flags: int) -> void:
	push_error("AeroInputProvider: set_body_track_flags() must be overridden")
