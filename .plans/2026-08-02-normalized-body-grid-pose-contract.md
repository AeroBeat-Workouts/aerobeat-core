# Normalized Body Grid Pose Contract

**Date:** 2026-08-02  
**Status:** In Progress  
**Last Updated:** 2026-08-02 18:54 EDT  
**Blocked Reason:** None  
**Agent:** pico

---

## Goal

Add a first-class input-core contract for calibrated nose, left-wrist, and right-wrist positions in normalized grid space so gameplay and debug overlays can consume continuous body anchor positions without depending on camera-provider internals.

---

## Overview

The current input-core `BodyCellInput` lane exposes calibrated cell-entry events for left wrist, right wrist, and nose, plus shared calibration session updates. That is enough for smoke tests and intent events, but the playable Flow/Boxing testbeds need continuous body anchor positions inside the calibrated grid so the runner can map the athlete's nose and wrists into first-person world space and render debug markers.

This slice should extend the shared body-cell lane rather than adding a runner-only camera-tracking dependency. Camera tracking remains the concrete provider of the data, but input-core owns the stable contract: normalized grid-space positions for the three gameplay anchors after calibration. The runner can then consume the same surface from `InputManager`, visualize the grid/nose/wrists after a separate calibration event, and fade that debug visualization after a public YAML-controlled duration.

The debug rendering behavior belongs to the playable testbed plan and runner-root YAML. The core contract only says what data is available, when it is valid, how coordinates are normalized, how each body-part event is emitted, and how calibration events are surfaced separately from pose updates.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Existing input-core body-cell and calibration contracts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/interfaces/body_cell_input.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/input_manager.gd` |
| `REF-02` | Input-core README lane ownership | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/README.md` |
| `REF-03` | Camera tracking calibration/grid implementation and proving scenes | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn` |
| `REF-04` | Camera tracking YAML documentation/comment style | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.gesture_detection.yaml`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-05` | Playable Flow/Boxing testbed plan that consumes this contract | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-02-playable-flow-boxing-testbeds.md` |
| `REF-06` | Camera tracking debug visual config shape | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.testbed_debug.yaml`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.testbed_debug.yaml` |

---

## Frozen Requirements

### Core Contract

- Extend `BodyCellInput` with continuous calibrated body-grid pose surfaces for exactly three first-pass anchors: `nose`, `left_wrist`, and `right_wrist`.
- The contract is first-class input-core API, not provider debug data and not a runner-local adapter contract.
- The surface should be available through the active provider and proxied by `InputManager`.
- Keep the existing cell-entry signals. The new continuous surface complements cell-entry events; it does not replace them.
- The surface becomes valid only after a successful calibration session. Before calibration, providers emit/query schema-shaped invalid body-part data rather than fake normalized positions or `{}`.
- The surface should include a validity flag per anchor so a consumer can keep the grid visible while one wrist temporarily loses tracking.
- Pose updates must not bundle calibration lifecycle information. Calibration status/success/failure/resume events are separate input-core signals and queries, and pose events may reference the current calibration/session identity only as metadata.

### Coordinate Semantics

- Grid origin is top-left, matching the input testbed and existing body-cell contracts.
- Coordinates are normalized within the calibrated base grid:
  - `x = 0.0` at the left edge, `x = 1.0` at the right edge.
  - `y = 0.0` at the top edge, `y = 1.0` at the bottom edge.
  - `cell = row * columns + column` with row-major top-left indexing.
- Default grid dimensions are `columns = 4`, `rows = 3` unless calibration metadata explicitly supplies another supported grid.
- The normalized position may also include `cell`, `row`, and `column` for convenience, but continuous `x/y` remains the authoritative data for camera/world mapping.
- Providers should clamp normalized coordinates to `[0.0, 1.0]` when reporting gameplay-ready positions, and may include raw/unclamped values separately if useful for debug.
- Required acceptance examples for 4x3:
  - `x < 0.25`, `y < 0.333...` maps to cell `0`, athlete upper-left.
  - `x >= 0.75`, `y < 0.333...` maps to cell `3`, athlete upper-right.
  - `x < 0.25`, `y >= 0.666...` maps to cell `8`, athlete lower-left.
  - `x >= 0.75`, `y >= 0.666...` maps to cell `11`, athlete lower-right.

### API Shape

- Add exactly one continuous signal per body part, not one combined pose-frame callback:

```gdscript
signal body_grid_nose_updated(anchor: Dictionary)
signal body_grid_left_wrist_updated(anchor: Dictionary)
signal body_grid_right_wrist_updated(anchor: Dictionary)
```

- Add separate calibration lifecycle signals. These are not bundled into body-part pose payloads:

```gdscript
signal body_grid_calibration_started(event: Dictionary)
signal body_grid_calibration_succeeded(event: Dictionary)
signal body_grid_calibration_failed(event: Dictionary)
signal body_grid_calibration_canceled(event: Dictionary)
```

- Body-part `anchor` dictionary shape:

```gdscript
{
	"schema": "aerobeat/body_grid_anchor",
	"version": 1,
	"anchor": "nose",
	"valid": true,
	"calibration_id": "stable-id-from-latest-successful-calibration",
	"timestamp_ms": 0,
	"grid": {
		"columns": 4,
		"rows": 3,
		"origin": "top_left",
		"indexing": "row_major"
	},
	"raw_x": 0.52,
	"raw_y": 0.34,
	"x": 0.52,
	"y": 0.34,
	"cell": 5,
	"row": 1,
	"column": 1
}
```

- Invalid body-part query/update dictionaries keep the same schema shape and set `valid: false`, `raw_x: null`, `raw_y: null`, `x: null`, `y: null`, `cell: null`, `row: null`, and `column: null`. Consumers must always check `valid` before using position fields.
- A body-part anchor is valid when calibration is currently valid, tracking is `tracking` or `reacquiring`, the landmark exists, and the landmark confidence is at or above the existing camera-tracking body-cell/flow threshold used for that anchor.

- Calibration event dictionary shape:

```gdscript
{
	"schema": "aerobeat/body_grid_calibration_event",
	"version": 1,
	"state": "succeeded",
	"calibration_id": "camera_tracking:1780000000000",
	"captured_at_ms": 1780000000000,
	"grid": {
		"columns": 4,
		"rows": 3,
		"origin": "top_left",
		"indexing": "row_major"
	}
}
```

- Add body-part queries to `BodyCellInput` and `InputManager`: `get_body_grid_nose() -> Dictionary`, `get_body_grid_left_wrist() -> Dictionary`, and `get_body_grid_right_wrist() -> Dictionary`.
- Add a calibration query to `BodyCellInput` and `InputManager`: `get_body_grid_calibration_state() -> Dictionary`.
- Do not introduce a new Godot Resource type unless review finds dictionary shape too weak for existing repo patterns.

### Provider Implementation Requirement

- `aerobeat-input-camera-tracking` should emit/update this surface from the same calibrated bounds used for cell-entry and T-pose calibration.
- The provider must document whether it uses mirrored preview coordinates or athlete-space coordinates. The accepted contract is athlete-space: cell `0` means the athlete's upper-left, and visual consumers must not accidentally mirror it to the athlete's right.
- The provider should update this pose whenever fresh calibrated landmark data is evaluated, not only when a cell changes.
- The provider emits schema-shaped invalid body-part updates immediately on tracking timeout, calibration start/cancel/fail, provider stop, or active provider switch.
- `calibration_id` is generated only after a successful calibration and remains stable until the next successful calibration. Failed, canceled, or in-progress calibration attempts do not increment it. The provider emits `calibration_id` and `captured_at_ms` through `body_grid_calibration_succeeded(event)`.
- Existing Flow and Boxing proving scenes should be able to show the normalized nose/wrist values as debug if the scene enables that overlay.
- The camera-tracking testbed debug visual options for body pose, nose, and wrists should be promoted or mirrored into a reusable debug config shape so the playable testbed can enable the same class of visuals without depending on provider internals.

### Runner Testbed Consumption Requirement

- The playable runner testbed should consume the per-body-part `InputManager` signals/queries for nose, left wrist, and right wrist instead of provider-specific landmark/debug APIs.
- The playable runner testbed should consume separate calibration events from `InputManager` to trigger grid/marker debug visibility and pause/recalibration/resume behavior.
- After calibration completes, the runner testbed should show the calibrated grid, nose marker, left-wrist marker, and right-wrist marker visually.
- Those debug markers should fade away after `debug.body_grid_pose_visible_after_calibration_ms`, default `2000`.
- This fade duration belongs in runner-root `assets/playable_testbed.yaml` using the exact documentation-comment shape from `REF-06`: every field has a short human comment directly above it, allowed options appear in the comment where relevant, and each runtime/debug field includes an ownership tag such as `runner testbed debug only`.
- A value of `0` means the debug visualization does not persist after calibration.
- The runner testbed should still allow debug toggles to keep the body pose, grid, nose, left-wrist, and right-wrist overlays visible for development.

---

## Frozen Build Decisions

1. V1 uses the exact per-body-part signals and queries listed above.
2. Calibration lifecycle is its own event/query surface and is never bundled into body-part payloads.
3. `x/y` are clamped `[0.0, 1.0]` gameplay-ready coordinates, and `raw_x/raw_y` are required for QA/debug of mirroring and out-of-grid behavior.
4. Invalid query behavior is schema-shaped invalid body-part dictionaries with nullable position fields.
5. Tracking loss emits invalid body-part updates immediately on timeout, calibration start/cancel/fail, provider stop, or active provider switch.
6. Runner overlay fade starts on separate calibration success event, `0 = no post-calibration persistence`, and always-visible behavior is controlled by separate debug toggles. Avoid `-1` in v1.
7. `calibration_id` is stable per successful calibration and changes only on the next successful calibration.

## Audit Findings To Apply

- The contract should remain input-core owned, with camera-tracking as the concrete provider and runner consuming only the `InputManager` surface.
- `InputManager` should proxy per-body-part body-grid updates only from the active provider, deep-duplicate emitted/query dictionaries, and clear cached body-part anchors to invalid when the active provider stops or switches.
- `InputManager` should proxy calibration lifecycle events separately from pose/body-part updates, using the active provider only.
- Camera-tracking should build/store body-grid anchors every evaluated `process_landmarks()` frame and emit per-body-part updates independently of cell transition events, including frames with no cell change.
- Public contract output must be athlete-space top-left normalized coordinates. Existing preview mirroring and gameplay-bottom-left internals must stay implementation/debug details and must not leak into emitted `x/y`.
- Cell derivation should be `cell = floor(y * rows) * columns + floor(x * columns)`, with `x = 1.0` and `y = 1.0` clamped into the last column/row.
- Per-anchor validity should reuse or explicitly name the camera-tracking confidence gate. Recommendation: an anchor is valid when calibrated, tracking is `tracking` or `reacquiring`, the landmark exists, and confidence is at or above the existing body-cell/flow threshold.

## Derrick Corrections To Apply

- Pose should be exposed as one callback/event per body part: nose, left wrist, and right wrist.
- Calibration events should be emitted separately and should not be bundled with pose/body-part information.
- Debug visuals from the input camera tracking testbed scene for body pose, wrists, and nose should be available as runner testbed options.
- Runner/testbed YAML must use the same comment shape as the camera-tracking testbed/debug YAMLs: a comment directly above each field, allowed options where relevant, and an ownership note in comments for debug/runtime-only values.

---

## Tasks

### Task 1: Contract Plan Review

**Bead ID:** `aerobeat-input-core-00d`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01` through `REF-05`  
**Prompt:** Claim bead `aerobeat-input-core-00d` on start. Review `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/2026-08-02-normalized-body-grid-pose-contract.md` and `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-02-playable-flow-boxing-testbeds.md` against the referenced input-core, input-camera-tracking, and runner repos. Do not implement code. Identify contradictions, repo-boundary mistakes, missing decisions, and exact contract details that must be frozen before implementation. Pay special attention to top-left athlete-space semantics, clamped vs raw normalized coordinates, per-frame dictionary signal shape, calibration validity/session identity, InputManager proxy responsibilities, provider mirroring risks, and runner YAML debug fade behavior with default `2000ms`. Return concrete plan edits/questions, then close bead `aerobeat-input-core-00d` only if the plan review is complete.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/2026-08-02-normalized-body-grid-pose-contract.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-02-playable-flow-boxing-testbeds.md`

**Status:** ✅ Complete

**Results:** Auditor review completed and bead `aerobeat-input-core-00d` was closed. No code changes, commits, or pushes were made by the auditor. The review found the plan direction sound but required tighter freeze decisions around coherent frame signal ownership, invalid query shape, active-provider proxy semantics, per-frame provider emission, top-left athlete-space output despite mixed internal coordinate systems, required raw-vs-clamped fields, calibration identity, per-anchor validity thresholds, and runner overlay fade semantics. Those findings are captured above.

---

### Task 2: Freeze Executable Contract Slices

**Bead ID:** `aerobeat-input-core-ij5`  
**SubAgent:** `primary` (for `research` / `auditor` workflow roles)  
**Role:** `research`  
**References:** `REF-01` through `REF-05`  
**Prompt:** After Task 1 review and Derrick's corrections, update the plan with frozen API decisions and create execution beads for input-core per-body-part contract changes, separate calibration lifecycle events, camera-tracking provider emission, runner testbed consumption/YAML debug controls, QA, and audit.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/2026-08-02-normalized-body-grid-pose-contract.md`

**Status:** ✅ Complete

**Results:** Derrick corrected the contract direction: per-body-part pose events instead of one bundled pose frame, separate calibration events, and reusable debug visual options for body pose, wrists, and nose. The follow-up readiness audit passed from the runner plan and approved implementation seams. Input-core is the first dependency.

---

### Task 3: Implement Input-Core Contract

**Bead ID:** `aerobeat-input-core-ij5`  
**SubAgent:** `primary` (for `coder` / `qa` / `auditor` workflow roles)  
**Role:** `coder`  
**References:** `REF-01` through `REF-06`  
**Prompt:** Implement the normalized body-grid per-body-part contract in input-core: exact nose/left-wrist/right-wrist signals and queries, separate calibration lifecycle signals/query, schema-shaped invalid anchor payloads, active-provider-only `InputManager` proxying, deep-copy semantics, and tests. This bead must complete before camera-tracking provider emission and runner consumption work.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/tests/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.testbed/tests/unit/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/interfaces/body_cell_input.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/input_manager.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.testbed/tests/unit/test_body_grid_contract.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.testbed/tests/unit/test_body_grid_contract.gd.uid`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.testbed/tests/unit/test_input_provider.gd`

**Status:** ✅ Coder Complete / QA Pending

**Results:** Coder implementation completed in commit `c191de4` (`Implement normalized body-grid contract`) and was pushed to `origin/main`. The implementation added the `BodyCellInput` and `InputManager` body-grid anchor signals/queries, separate calibration lifecycle signals/query, schema-shaped invalid anchor defaults, active-provider-only proxying, deep-copy semantics, provider stop/switch invalidation, README documentation, and focused GUT coverage. Validation passed: `godot --headless --path .testbed --import`; `godot --headless --path .testbed --script addons/aerobeat-vendor-godot-unit-test/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` with `41/41` tests and `442` assertions. Bead `aerobeat-input-core-ij5` remains open for QA/audit.

---

### Task 4: QA Input-Core Contract

**Bead ID:** `aerobeat-input-core-ij5`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01` through `REF-06`  
**Prompt:** Claim bead `aerobeat-input-core-ij5` on start. Perform QA for commit `c191de4` against this plan and the bead notes. Verify the new input-core body-grid contract API, separate calibration lifecycle API, invalid anchor shape, active-provider-only InputManager proxy behavior, deep-copy behavior, provider switch/stop invalidation, README docs, and tests. Run the relevant Godot import/unit validation. Do not close the bead unless this QA role owns closure in its prompt; return pass/fail evidence and any gaps for the auditor.

**Folders Created/Deleted/Modified:**
- None expected.

**Files Created/Deleted/Modified:**
- None expected.

**Status:** ⏳ Pending

**Results:** Pending QA.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Frozen contract plan. Implementation is ready to start as the first dependency seam.

**Reference Check:** Subagent review completed against referenced input-core, input-camera-tracking, and runner files.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Completed on Pending*
