class_name AeroInputProvider
extends Node
## Abstract base class for all AeroBeat input providers
## All input drivers must extend this class and implement required methods
## 
## This contract defines the complete interface for input providers including:
## - Lifecycle management (start/stop)
## - Spatial tracking (positions, velocities, rotations)
## - Capabilities discovery
## - Haptic feedback

# ============================================================================
# ENUMS & CONSTANTS
# ============================================================================

## Tracking coordinate modes
enum TrackingMode {
	MODE_2D,  ## Screen-space coordinates (0.0 to 1.0)
	MODE_3D   ## World-space coordinates (meters)
}

## Provider capability flags
enum Capability {
	SPATIAL_TRANSFORM = 1,      ## Supports tracking_updated signal / 6DOF
	GESTURE_RECOGNITION = 2,    ## Supports gesture signals (punch, slice, etc.)
	LOWER_BODY = 4,             ## Supports foot tracking / knee strikes
	HAPTICS = 8,                ## Supports trigger_haptic feedback
	VELOCITY = 16               ## Supports velocity polling
}

## Body part tracking flags (bitmask)
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

## Emitted when tracking successfully starts
signal started

## Emitted when tracking stops (normal shutdown)
signal stopped

## Emitted on error with description
signal failed(error: String)

# ============================================================================
# SIGNALS: DATA (Continuous / 6DOF)
# ============================================================================

## Emitted every physics frame with the latest spatial data.
## Useful for collision-based gameplay (Supernatural VR & BeatSaber style).
signal tracking_updated(
	head_transform: Transform3D,
	left_hand_transform: Transform3D,
	right_hand_transform: Transform3D,
	left_foot_transform: Transform3D,
	right_foot_transform: Transform3D
)

# ============================================================================
# COMMANDS (Call these to control the provider)
# ============================================================================

## Initializes and starts the tracking backend.
## @param settings_json: Configuration for the specific driver (e.g. camera ID, XR passthrough toggles).
## Returns: bool indicating success/failure
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

## Returns whether this specific provider supports a feature.
## @param capability: The Capability enum value to check
func has_capability(capability: Capability) -> bool:
	push_error("AeroInputProvider: has_capability() must be overridden")
	return false

## Trigger haptics for feedback.
## @param side: 0=Left, 1=Right
## @param intensity: 0.0 to 1.0
## @param duration_ms: duration in milliseconds
func trigger_haptic(side: int, intensity: float, duration_ms: int) -> void:
	push_error("AeroInputProvider: trigger_haptic() must be overridden")

# ============================================================================
# STATE QUERIES: POSITION
# ============================================================================

## Get head position in 2D or 3D coordinates
func get_head_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	push_error("AeroInputProvider: get_head_position() must be overridden")
	return Vector3.ZERO

## Get left hand position in 2D or 3D coordinates
func get_left_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	push_error("AeroInputProvider: get_left_hand_position() must be overridden")
	return Vector3.ZERO

## Get right hand position in 2D or 3D coordinates
func get_right_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	push_error("AeroInputProvider: get_right_hand_position() must be overridden")
	return Vector3.ZERO

## Get left foot position in 2D or 3D coordinates
func get_left_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	push_error("AeroInputProvider: get_left_foot_position() must be overridden")
	return Vector3.ZERO

## Get right foot position in 2D or 3D coordinates
func get_right_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Vector3:
	push_error("AeroInputProvider: get_right_foot_position() must be overridden")
	return Vector3.ZERO

# ============================================================================
# STATE QUERIES: VELOCITY (Meters/Sec)
# ============================================================================

## Get head velocity vector (meters/second)
func get_head_velocity() -> Vector3:
	push_error("AeroInputProvider: get_head_velocity() must be overridden")
	return Vector3.ZERO

## Get left hand velocity vector (meters/second)
func get_left_hand_velocity() -> Vector3:
	push_error("AeroInputProvider: get_left_hand_velocity() must be overridden")
	return Vector3.ZERO

## Get right hand velocity vector (meters/second)
func get_right_hand_velocity() -> Vector3:
	push_error("AeroInputProvider: get_right_hand_velocity() must be overridden")
	return Vector3.ZERO

## Get left foot velocity vector (meters/second)
func get_left_foot_velocity() -> Vector3:
	push_error("AeroInputProvider: get_left_foot_velocity() must be overridden")
	return Vector3.ZERO

## Get right foot velocity vector (meters/second)
func get_right_foot_velocity() -> Vector3:
	push_error("AeroInputProvider: get_right_foot_velocity() must be overridden")
	return Vector3.ZERO

# ============================================================================
# STATE QUERIES: ROTATION (6DOF)
# ============================================================================

## Get head rotation as quaternion
func get_head_rotation() -> Quaternion:
	push_error("AeroInputProvider: get_head_rotation() must be overridden")
	return Quaternion.IDENTITY

## Get left hand rotation as quaternion
func get_left_hand_rotation() -> Quaternion:
	push_error("AeroInputProvider: get_left_hand_rotation() must be overridden")
	return Quaternion.IDENTITY

## Get right hand rotation as quaternion
func get_right_hand_rotation() -> Quaternion:
	push_error("AeroInputProvider: get_right_hand_rotation() must be overridden")
	return Quaternion.IDENTITY

## Get left foot rotation as quaternion
func get_left_foot_rotation() -> Quaternion:
	push_error("AeroInputProvider: get_left_foot_rotation() must be overridden")
	return Quaternion.IDENTITY

## Get right foot rotation as quaternion
func get_right_foot_rotation() -> Quaternion:
	push_error("AeroInputProvider: get_right_foot_rotation() must be overridden")
	return Quaternion.IDENTITY

# ============================================================================
# STATE QUERIES: CONFIDENCE
# ============================================================================

## Get tracking confidence for a specific body part
## @param body_part: One of: "head", "left_hand", "right_hand", "left_foot", "right_foot"
## Returns: confidence value from 0.0 to 1.0
func get_tracking_confidence(body_part: StringName) -> float:
	push_error("AeroInputProvider: get_tracking_confidence() must be overridden")
	return 0.0

# ============================================================================
# SETTERS / CONFIG
# ============================================================================

## Set the tracking mode (2D or 3D coordinates)
func set_tracking_mode(mode: TrackingMode) -> void:
	push_error("AeroInputProvider: set_tracking_mode() must be overridden")

## Set body tracking flags (bitmask of BodyTrackFlags)
func set_body_track_flags(flags: int) -> void:
	push_error("AeroInputProvider: set_body_track_flags() must be overridden")
