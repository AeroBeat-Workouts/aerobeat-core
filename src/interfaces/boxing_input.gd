class_name BoxingInput
extends AeroInputProvider
## Interface for boxing-specific input providers
## Extends AeroInputProvider with boxing gameplay signals
##
## Providers that support boxing gestures should extend this class
## and emit the appropriate signals when gestures are detected.

# ============================================================================
# SIGNALS: STANCE & POSITION
# ============================================================================

## Emitted when player assumes standard boxing stance (left foot forward)
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
# SIGNALS: OFFENSIVE - PUNCHES
# ============================================================================

## Emitted when left punch (jab/straight) detected
## @param power: Punch power from 0.0 to 1.0
signal punch_left(power: float)

## Emitted when right punch (jab/straight) detected
## @param power: Punch power from 0.0 to 1.0
signal punch_right(power: float)

## Emitted when left uppercut detected
## @param power: Uppercut power from 0.0 to 1.0
signal uppercut_left(power: float)

## Emitted when right uppercut detected
## @param power: Uppercut power from 0.0 to 1.0
signal uppercut_right(power: float)

## Emitted when left cross detected (power punch from orthodox stance)
## @param power: Cross power from 0.0 to 1.0
signal cross_left(power: float)

## Emitted when right cross detected (power punch from orthodox stance)
## @param power: Cross power from 0.0 to 1.0
signal cross_right(power: float)

## Emitted when left hook detected
## @param power: Hook power from 0.0 to 1.0
signal hook_left(power: float)

## Emitted when right hook detected
## @param power: Hook power from 0.0 to 1.0
signal hook_right(power: float)

# ============================================================================
# SIGNALS: DEFENSIVE
# ============================================================================

## Emitted when player raises guard (block start)
signal block_start

## Emitted when player lowers guard (block end)
signal block_end

## Emitted when head weave to left detected
signal weave_left

## Emitted when head weave to right detected
signal weave_right

## Emitted when combined duck and weave to left detected
signal duck_weave_left

## Emitted when combined duck and weave to right detected
signal duck_weave_right

# ============================================================================
# SIGNALS: SPECIAL MOVES
# ============================================================================

## Emitted when left knee strike detected (Muay Thai/clinch)
## @param power: Strike power from 0.0 to 1.0
signal knee_strike_left(power: float)

## Emitted when right knee strike detected
## @param power: Strike power from 0.0 to 1.0
signal knee_strike_right(power: float)

## Emitted when left leg lift detected
signal leg_lift_left

## Emitted when right leg lift detected
signal leg_lift_right

## Emitted when player begins running in place
signal run_start

## Emitted when player stops running in place
signal run_end

# ============================================================================
# CAPABILITY CHECK
# ============================================================================

## Override to report boxing capabilities
func has_capability(capability: Capability) -> bool:
	match capability:
		Capability.GESTURE_RECOGNITION:
			return true
		Capability.LOWER_BODY:
			return true
		_:
			return super.has_capability(capability)
