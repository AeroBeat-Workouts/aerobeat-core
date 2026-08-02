class_name BoxingInput
extends "body_cell_input.gd"
## Interface for AeroBeat Boxing gameplay input providers.
##
## Boxing is an active camera-first gameplay mode in v1. This contract defines
## the gameplay-facing intent events detectors should emit into.
##
## Important v1 rules:
## - straight punches are the canonical straight_left / straight_right names
## - guard is the canonical defensive wording
## - authored chart semantics like orthodox / southpaw are not tracked input events
## - run_in_place is a legitimate authored/chart beat, but not a tracked provider event in the first implementation pass
## - movement prompts are guard, squat, and weave_* only in Boxing v1
## - stale detector-era sidestep / knee / leg-lift vocabulary is not part of the Boxing contract
##
## Raw pose, observation streams, and richer provider-specific body data remain
## optional and provider-side. They do not replace this gameplay intent surface.

# ============================================================================
# SIGNALS: OFFENSIVE INTENTS
# ============================================================================

## Emitted when a left straight punch intent becomes active.
signal straight_left

## Emitted when a right straight punch intent becomes active.
signal straight_right

## Emitted when a left uppercut intent becomes active.
signal uppercut_left

## Emitted when a right uppercut intent becomes active.
signal uppercut_right

## Emitted when a left hook intent becomes active.
signal hook_left

## Emitted when a right hook intent becomes active.
signal hook_right

# ============================================================================
# SIGNALS: DEFENSIVE / STATE INTENTS
# ============================================================================

## Emitted when the player enters guard.
signal guard_enabled

## Emitted when the player exits guard.
signal guard_disabled

## Emitted when the player begins a squat.
signal squat_enabled

## Emitted when the player ends a squat.
signal squat_disabled

## Emitted when the player begins weaving to the left.
signal weave_left_enabled

## Emitted when the player stops weaving to the left.
signal weave_left_disabled

## Emitted when the player begins weaving to the right.
signal weave_right_enabled

## Emitted when the player stops weaving to the right.
signal weave_right_disabled
