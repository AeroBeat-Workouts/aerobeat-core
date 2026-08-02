# Normalized Body Grid Pose Contract

**Date:** 2026-08-02  
**Status:** In Progress  
**Last Updated:** 2026-08-02 14:48 EDT  
**Blocked Reason:** Pending Derrick freeze/approval before implementation  
**Agent:** pico

---

## Goal

Add a first-class input-core contract for calibrated nose, left-wrist, and right-wrist positions in normalized grid space so gameplay and debug overlays can consume continuous body anchor positions without depending on camera-provider internals.

---

## Overview

The current input-core `BodyCellInput` lane exposes calibrated cell-entry events for left wrist, right wrist, and nose, plus shared calibration session updates. That is enough for smoke tests and intent events, but the playable Flow/Boxing testbeds need continuous body anchor positions inside the calibrated grid so the runner can map the athlete's nose and wrists into first-person world space and render debug markers.

This slice should extend the shared body-cell lane rather than adding a runner-only camera-tracking dependency. Camera tracking remains the concrete provider of the data, but input-core owns the stable contract: normalized grid-space positions for the three gameplay anchors after calibration. The runner can then consume the same surface from `InputManager`, visualize the grid/nose/wrists after a calibration event, and fade that debug visualization after a public YAML-controlled duration.

The debug rendering behavior belongs to the playable testbed plan and runner-root YAML. The core contract only says what data is available, when it is valid, how coordinates are normalized, and how consumers can query or subscribe to it.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Existing input-core body-cell and calibration contracts | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/interfaces/body_cell_input.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/src/input_manager.gd` |
| `REF-02` | Input-core README lane ownership | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/README.md` |
| `REF-03` | Camera tracking calibration/grid implementation and proving scenes | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/src/detectors/pose_detector_substrate.gd`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/boxing_proving.tscn`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/.testbed/scenes/flow_proving.tscn` |
| `REF-04` | Camera tracking YAML documentation/comment style | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/flow.gesture_detection.yaml`, `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-camera-tracking/assets/boxing.gesture_detection.yaml` |
| `REF-05` | Playable Flow/Boxing testbed plan that consumes this contract | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-gameplay-runner/.plans/2026-08-02-playable-flow-boxing-testbeds.md` |

---

## Frozen Requirements Candidate

### Core Contract

- Extend `BodyCellInput` with a continuous calibrated body-grid pose surface for exactly three first-pass anchors: `nose`, `left_wrist`, and `right_wrist`.
- The contract is first-class input-core API, not provider debug data and not a runner-local adapter contract.
- The surface should be available through the active provider and proxied by `InputManager`.
- Keep the existing cell-entry signals. The new continuous surface complements cell-entry events; it does not replace them.
- The surface becomes valid only after a successful calibration session. Before calibration, providers should emit/query invalid or empty pose data rather than fake normalized positions.
- The surface should include a validity flag per anchor so a consumer can keep the grid visible while one wrist temporarily loses tracking.
- The surface should carry the calibration/session identity or timestamp needed to know which calibration produced the normalized coordinates.

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

### Candidate API Shape

- Add a signal such as:

```gdscript
signal body_grid_pose_updated(pose: Dictionary)
```

- Candidate `pose` dictionary shape:

```gdscript
{
	"schema": "aerobeat/body_grid_pose",
	"version": 1,
	"valid": true,
	"calibration_id": "optional-stable-id-or-empty",
	"timestamp_ms": 0,
	"grid": {
		"columns": 4,
		"rows": 3,
		"origin": "top_left",
		"indexing": "row_major"
	},
	"anchors": {
		"nose": {
			"valid": true,
			"x": 0.5,
			"y": 0.5,
			"cell": 5,
			"row": 1,
			"column": 1
		},
		"left_wrist": {
			"valid": true,
			"x": 0.25,
			"y": 0.5,
			"cell": 5,
			"row": 1,
			"column": 1
		},
		"right_wrist": {
			"valid": true,
			"x": 0.75,
			"y": 0.5,
			"cell": 6,
			"row": 1,
			"column": 2
		}
	}
}
```

- Add a query such as `get_body_grid_pose() -> Dictionary` to `BodyCellInput` and `InputManager`.
- Implementation review should decide whether small helper methods are worth adding, for example `get_body_anchor_grid_position(anchor_name: String) -> Dictionary`, or whether the single dictionary query is enough for v1.
- Do not introduce a new Godot Resource type unless review finds dictionary shape too weak for existing repo patterns.

### Provider Implementation Requirement

- `aerobeat-input-camera-tracking` should emit/update this surface from the same calibrated bounds used for cell-entry and T-pose calibration.
- The provider must document whether it uses mirrored preview coordinates or athlete-space coordinates. The accepted contract is athlete-space: cell `0` means the athlete's upper-left, and visual consumers must not accidentally mirror it to the athlete's right.
- The provider should update this pose whenever fresh calibrated landmark data is evaluated, not only when a cell changes.
- Existing Flow and Boxing proving scenes should be able to show the normalized nose/wrist values as debug if the scene enables that overlay.

### Runner Testbed Consumption Requirement

- The playable runner testbed should consume `InputManager.body_grid_pose_updated` and `InputManager.get_body_grid_pose()` instead of provider-specific landmark/debug APIs.
- After calibration completes, the runner testbed should show the calibrated grid, nose marker, left-wrist marker, and right-wrist marker visually.
- Those debug markers should fade away after `debug.body_grid_pose_visible_after_calibration_ms`, default `2000`.
- This fade duration belongs in runner-root `assets/playable_testbed.yaml` using the same documentation-comment style as `REF-04`.
- A value of `0` should mean the debug visualization does not persist after calibration; review should decide whether a negative value should mean "stay visible until disabled" or whether that should be a separate boolean.
- The runner testbed should still allow a debug toggle to keep the overlay visible for development.

---

## Open Questions To Freeze Before Build

1. Freeze v1 as one coherent `body_grid_pose_updated(pose: Dictionary)` frame signal, not per-anchor signals. Per-anchor helpers can be added later as convenience APIs.
2. Freeze `x/y` as clamped `[0.0, 1.0]` gameplay-ready coordinates and require `raw_x/raw_y` in v1 for QA/debug of mirroring and out-of-grid behavior.
3. Freeze invalid query behavior: `BodyCellInput.get_body_grid_pose()` and `InputManager.get_body_grid_pose()` should return a schema-shaped invalid dictionary rather than `{}`. Decide whether invalid anchors include `x/y: 0.0` or omit meaningful `x/y`; consumers must always check `valid`.
4. Freeze root `valid` semantics. Recommendation: root `valid` means calibration/session is valid and at least one anchor is valid; per-anchor `valid` carries partial tracking loss.
5. Freeze tracking-loss behavior. Recommendation: emit an invalid pose immediately on tracking timeout, calibration start/cancel, provider stop, or active provider switch.
6. Freeze runner overlay semantics: `debug.body_grid_pose_visible_after_calibration_ms: 2000` starts on `calibration_id` change / calibration success, `0 = no post-calibration persistence`, and always-visible behavior is controlled by a separate debug toggle. Avoid `-1` in v1.
7. Freeze `calibration_id`. Recommendation: camera-tracking provider generates a stable ID per successful calibration, such as `"camera_tracking:%d" % captured_at_ms`, and also emits `calibration_captured_at_ms`.

## Audit Findings To Apply

- The contract should remain input-core owned, with camera-tracking as the concrete provider and runner consuming only the `InputManager` surface.
- `InputManager` should proxy `body_grid_pose_updated(pose)` only from the active provider, deep-duplicate emitted/query dictionaries, and clear cached pose to invalid when the active provider stops or switches.
- Camera-tracking should build/store body-grid pose every evaluated `process_landmarks()` frame and emit it independently of cell transition events, including frames with no cell change.
- Public contract output must be athlete-space top-left normalized coordinates. Existing preview mirroring and gameplay-bottom-left internals must stay implementation/debug details and must not leak into emitted `x/y`.
- Cell derivation should be `cell = floor(y * rows) * columns + floor(x * columns)`, with `x = 1.0` and `y = 1.0` clamped into the last column/row.
- Per-anchor validity should reuse or explicitly name the camera-tracking confidence gate. Recommendation: an anchor is valid when calibrated, tracking is `tracking` or `reacquiring`, the landmark exists, and confidence is at or above the existing body-cell/flow threshold.

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

**Bead ID:** `Pending`  
**SubAgent:** `primary` (for `research` / `auditor` workflow roles)  
**Role:** `research`  
**References:** `REF-01` through `REF-05`  
**Prompt:** After Task 1 review, update the plan with frozen API decisions and create execution beads for input-core contract changes, camera-tracking provider emission, runner testbed consumption/YAML debug controls, QA, and audit. Do not begin implementation until Derrick confirms the plan is ready to execute.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/2026-08-02-normalized-body-grid-pose-contract.md`

**Status:** ⏳ Pending

**Results:** Pending Derrick approval/freeze of the decisions above.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Draft plan only. No implementation started.

**Reference Check:** Subagent review completed against referenced input-core, input-camera-tracking, and runner files.

**Commits:**
- Pending.

**Lessons Learned:** Pending.

---

*Completed on Pending*
