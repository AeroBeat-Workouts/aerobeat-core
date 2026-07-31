class_name BodyCellInput
extends "input_provider.gd"
## Shared AeroBeat calibrated body-cell lane for wrist/nose-driven consumers.
##
## This contract is intentionally gameplay-family-agnostic so menus, parallax,
## Flow, Boxing overlays, and future camera-driven features can all depend on
## the same body-part cell-entry and calibration surface.

# ============================================================================
# SIGNALS: GENERIC CALIBRATED BODY-CELL EVENTS
# ============================================================================

## Emitted when the left wrist enters a new calibrated cell.
## @param cell: Direct calibrated cell index in BeatSaver row-major order (0..11)
## @param direction: Recent 8-way motion direction, or -1 when ambiguous / not yet valid
signal left_wrist_cell_entered(cell: int, direction: int)

## Emitted when the right wrist enters a new calibrated cell.
## @param cell: Direct calibrated cell index in BeatSaver row-major order (0..11)
## @param direction: Recent 8-way motion direction, or -1 when ambiguous / not yet valid
signal right_wrist_cell_entered(cell: int, direction: int)

## Emitted when the nose enters a new calibrated cell.
## @param cell: Direct calibrated cell index in BeatSaver row-major order (0..11)
## @param direction: Recent 8-way motion direction, or -1 when ambiguous / not yet valid
signal nose_cell_entered(cell: int, direction: int)

# ============================================================================
# SIGNALS: SHARED CALIBRATION UI SURFACE
# ============================================================================

## Emitted whenever the current shared calibration session changes.
## Consumers should use this as the live proving-scene / HUD update surface.
signal calibration_session_updated(session: Dictionary)

# ============================================================================
# CALIBRATION CONTROL
# ============================================================================

## Request a fresh shared calibration pass.
## Override in concrete providers that support runtime calibration.
func start_calibration() -> bool:
	return false

## Cancel the current shared calibration pass.
## Override in concrete providers that support runtime calibration.
func cancel_calibration() -> bool:
	return false

## Return the current shared calibration session document.
## Override in concrete providers that support runtime calibration.
func get_calibration_session() -> Dictionary:
	return {}

# ============================================================================
# CAPABILITY CHECK
# ============================================================================

## Override to report generic body-cell gesture support.
func has_capability(capability: Capability) -> bool:
	match capability:
		Capability.GESTURE_RECOGNITION:
			return true
		_:
			return false
