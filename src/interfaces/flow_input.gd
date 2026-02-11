class_name FlowInput
extends AeroInputProvider
## Interface for flow/slice gameplay input providers
## Extends AeroInputProvider with slice detection signals
##
## Providers that support slice-based gameplay (like rhythm sword games)
## should extend this class and emit slice_detected when slicing motions
## are detected.

# ============================================================================
# SIGNALS: SLICE DETECTION
# ============================================================================

## Emitted when a slice gesture is detected
## @param direction: Slice direction - "left", "right", "up", or "down"
## @param angle: The Euler angle of the controller/hand during the slice (in degrees)
signal slice_detected(direction: StringName, angle: float)

# ============================================================================
# SIGNALS: STANCE & POSITION (Common with Boxing)
# ============================================================================

## Emitted when player assumes standard stance (left foot forward)
signal stance_orthodox

## Emitted when player assumes southpaw stance (right foot forward)
signal stance_southpaw

## Emitted when player location changes
## @param zone: "left", "center", or "right"
signal location_changed(zone: StringName)

## Emitted when player height changes
## @param type: "stand" or "squat"
signal height_changed(type: StringName)

# ============================================================================
# CAPABILITY CHECK
# ============================================================================

## Override to report flow/slice capabilities
func has_capability(capability: Capability) -> bool:
	match capability:
		Capability.GESTURE_RECOGNITION:
			return true
		_:
			return super.has_capability(capability)
