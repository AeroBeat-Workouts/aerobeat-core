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
# SIGNALS: NORMALIZED BODY-GRID ANCHORS
# ============================================================================

signal body_grid_nose_updated(anchor: Dictionary)
signal body_grid_left_wrist_updated(anchor: Dictionary)
signal body_grid_right_wrist_updated(anchor: Dictionary)

# ============================================================================
# SIGNALS: NORMALIZED BODY-GRID CALIBRATION LIFECYCLE
# ============================================================================

signal body_grid_calibration_started(event: Dictionary)
signal body_grid_calibration_succeeded(event: Dictionary)
signal body_grid_calibration_failed(event: Dictionary)
signal body_grid_calibration_canceled(event: Dictionary)

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
# NORMALIZED BODY-GRID QUERIES
# ============================================================================

## Return the latest normalized nose anchor in athlete-space top-left grid coordinates.
func get_body_grid_nose() -> Dictionary:
	return make_invalid_body_grid_anchor("nose")

## Return the latest normalized left-wrist anchor in athlete-space top-left grid coordinates.
func get_body_grid_left_wrist() -> Dictionary:
	return make_invalid_body_grid_anchor("left_wrist")

## Return the latest normalized right-wrist anchor in athlete-space top-left grid coordinates.
func get_body_grid_right_wrist() -> Dictionary:
	return make_invalid_body_grid_anchor("right_wrist")

## Return the current body-grid calibration lifecycle state.
func get_body_grid_calibration_state() -> Dictionary:
	return make_body_grid_calibration_state("none")

static func make_body_grid() -> Dictionary:
	return {
		"columns": 4,
		"rows": 3,
		"origin": "top_left",
		"indexing": "row_major"
	}

static func make_invalid_body_grid_anchor(anchor_name: String) -> Dictionary:
	return {
		"schema": "aerobeat/body_grid_anchor",
		"version": 1,
		"anchor": anchor_name,
		"valid": false,
		"calibration_id": null,
		"timestamp_ms": 0,
		"grid": make_body_grid(),
		"raw_x": null,
		"raw_y": null,
		"x": null,
		"y": null,
		"cell": null,
		"row": null,
		"column": null
	}

static func make_body_grid_calibration_state(state_name: String) -> Dictionary:
	return {
		"schema": "aerobeat/body_grid_calibration_event",
		"version": 1,
		"state": state_name,
		"calibration_id": null,
		"captured_at_ms": null,
		"grid": make_body_grid()
	}

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
