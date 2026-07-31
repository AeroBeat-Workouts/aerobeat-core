class_name FlowInput
extends "body_cell_input.gd"
## Interface for AeroBeat Flow gameplay input providers.
##
## Flow is a camera-first gameplay mode in v1. This contract defines the stable
## gameplay-facing intent surface detectors should emit into.
##
## Important v1 rules:
## - each BeatSaver note targets one exact calibrated 4x3 cell
## - timing attaches to wrist entry into that cell
## - direction matching uses recent wrist motion in 8-way space
## - authored stance semantics like orthodox / southpaw are not tracked input events
## - warn_* / reward_* remain authored Flow semantics, not separate provider gestures
## - run_in_place is a legitimate authored Flow beat, but not a tracked provider event in the first pass
## - stale authored-abstraction vocabulary like swing_* / trail_* is not part of the runtime Flow contract
##
## Raw pose / observation data remains provider-side and optional; it does not
## replace this gameplay intent contract.

# ============================================================================
# SIGNALS: MOVEMENT / STATE INTENTS
# ============================================================================

## Emitted when the player begins a squat.
signal squat_enabled

## Emitted when the player ends a squat.
signal squat_disabled
