# AeroBeat Input Core — UI Input Abstraction Contract

**Date:** 2026-05-15  
**Status:** Stale  
**Agent:** Byte 🐈‍⬛

---

## Goal

Define a composition-first UI interaction abstraction in `aerobeat-input-core` so other AeroBeat repos can consume one stable contract for 2D, 3D/hybrid, and future XR UI interaction without depending on raw Godot input semantics.

---

## Overview

The current `aerobeat-ui-kit-community` proof slice established that Godot gives us the primitives for world-space UI interaction, but not the automatic unified cross-device abstraction we want. That proof added 3D pick-surface routing, world-hit → UV → `SubViewport` coordinate mapping, and forwarded mouse/touch event classes into the rendered UI. It also proved we should separate the contract from any one rendering path. The next step belongs in `aerobeat-input-core`: define the stable interaction boundary once, then let downstream repos consume it without caring whether the underlying platform path is mouse, touch, or XR.

This contract should be composition-first, not inheritance-first. UI components in downstream repos should react to a normalized AeroBeat interaction surface instead of extending a giant base panel class. That means `input-core` should own the event model, source taxonomy, adapter semantics, and any shared singleton/bus or dispatch helpers. Platform- or surface-specific logic — such as raw Godot `InputEvent` conversion, world-panel raycast mapping, and later XR pointer translation — should live in adapter layers around that contract rather than leaking directly into each UI component.

We are intentionally allowing one truth gap for now: touch and XR support can be designed and implemented as first-class lanes in the contract while still being explicitly marked unverified. Other repos should not need to care whether a source path is verified yet; they should only target the stable abstraction. But the contract itself should carry enough metadata and docs to distinguish verified mouse semantics from currently unverified touch/XR semantics so we do not overclaim platform parity.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current input-core manager | `src/input_manager.gd` |
| `REF-02` | Current base provider abstraction | `src/interfaces/input_provider.gd` |
| `REF-03` | UI-kit hybrid input proof plan/results | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-ui-kit-community/.plans/2026-05-15-hybrid-3d-gui-input-detection.md` |
| `REF-04` | UI-kit hybrid input research note | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-ui-kit-community/.temp/aerobeat-ui-kit-community-4w8-input-path-research.md` |
| `REF-05` | UI-kit hybrid input proof implementation commit | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-ui-kit-community@1315276` |
| `REF-06` | Existing input-core downscope plan context | `.plans/2026-05-01-aerobeat-input-core-downscope-alignment.md` |

---

## Tasks

### Task 1: Design the v1 UI interaction contract and adapter boundary

**Bead ID:** `aerobeat-input-core-vko`  
**SubAgent:** `primary` (for `research` workflow role)  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core`, design the v1 UI interaction abstraction for AeroBeat. Produce a concrete contract proposal that defines normalized interaction event types, source taxonomy (`mouse`, `touch`, `xr` at minimum), lifecycle phases, verification-status semantics, and the intended separation between adapters/dispatch and UI component consumers. Be explicit that the design must use composition/adapters rather than requiring downstream panels to inherit a base input class.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `src/`
- optional `docs/` if needed

**Files Created/Deleted/Modified:**
- design notes and/or proposed source files as needed

**Status:** ✅ Complete

**Results:** Wrote the contract proposal to `docs/ui-interaction-contract-v1-proposal.md`. Derrick reviewed and approved the design with one refinement: the shared event payload should expose a single canonical `phase` field and should not also carry a separate canonical `action` field. The approved proposal defines a composition-first UI interaction abstraction centered on a normalized `AeroUiInteractionEvent`, explicit source taxonomy (`mouse`, `touch`, `xr` with variants), stable interaction phases (`hover_enter`, `press_begin`, `drag_move`, `press_end`, `cancel`, etc.), first-class `verification_status` semantics, a shared `AeroUiInteractionBus` dispatcher, and a strict adapter boundary that keeps raw Godot/surface-specific differences out of downstream consumers. It explicitly covers how `screen_2d`, `world_3d`, and `hybrid_3d_gui` surfaces plug into the same contract and how future XR should arrive as another adapter without downstream API changes. No production implementation was added in this task; this was design-only before approval.

---

### Task 2: Implement the input-core abstraction surface and minimal adapter scaffolding

**Approval Gate:** Do not execute until Derrick explicitly approves the contract produced by Task 1.


**Bead ID:** `aerobeat-input-core-3qm`  
**SubAgent:** `primary` (for `coder` workflow role)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core`, implement the approved v1 UI interaction contract. Add the abstraction surface, normalized event/data structures, verification-status handling for source paths, and minimal adapter/dispatch scaffolding needed so downstream repos can depend on the contract without touching raw Godot input directly. Keep the architecture composition-first and future-ready for world-space and XR adapters, but do not overclaim verified touch/XR behavior.

**Folders Created/Deleted/Modified:**
- `src/`
- optional `docs/`
- optional `.testbed/` if a tiny local proof is useful

**Files Created/Deleted/Modified:**
- new/updated input-core source and documentation files as needed

**Status:** ✅ Complete

**Results:** The approved v1 abstraction surface is implemented in `src/ui/` and was already landed on `main` in commit `94a2e42` (`Add v1 UI interaction contract scaffolding`). The implementation includes the normalized `AeroUiInteractionEvent`, stable source/surface/phase taxonomies, first-class verification truth labels, the shared `AeroUiInteractionBus`, and composition-first adapters/helpers for screen, hybrid, and XR-facing UI paths. The core event payload keeps `phase` as the only canonical lifecycle field and intentionally rejects a shared `action` field. Touch and XR are present in the contract with explicit `unverified` defaults. Repo-local validation was run with headless Godot/GUT (`res://tests/unit/ui` and all `res://tests/unit`), and `git diff --check` passed.

---

### Task 3: QA the abstraction surface for downstream-consumer clarity and truthfulness

**Bead ID:** `aerobeat-input-core-7tu`  
**SubAgent:** `primary` (for `qa` workflow role)  
**Role:** `qa`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-05`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core`, verify that the new abstraction is understandable and safe for downstream repos. Confirm the contract clearly hides raw Godot specifics, exposes composition-first consumer hooks, and truthfully marks mouse vs unverified touch/XR semantics. Validate any repo-local tests or smoke paths available.

**Folders Created/Deleted/Modified:**
- repo QA artifact paths only if needed

**Files Created/Deleted/Modified:**
- QA evidence artifacts if produced

**Status:** ⏳ Pending

**Results:** Awaiting QA.

---

### Task 4: Audit whether the contract is ready for ui-kit-community adoption

**Bead ID:** `aerobeat-input-core-ada`  
**SubAgent:** `primary` (for `auditor` workflow role)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core`, audit the new UI interaction abstraction independently. Decide whether it is ready for adoption by `aerobeat-ui-kit-community` through GodotEnv, whether the composition/adapters boundary is clean enough, and whether the contract is honest about verified vs unverified source paths. If it is not ready, identify the minimum missing pieces.

**Folders Created/Deleted/Modified:**
- `.plans/` (notes/results only if needed)

**Files Created/Deleted/Modified:**
- optional audit notes if produced

**Status:** ⏳ Pending

**Results:** Awaiting audit.

---

## Final Results

**Status:** ⏳ Pending

**What We Built:** Pending execution.

**Reference Check:** Pending execution.

**Commits:**
- Pending

**Lessons Learned:** Pending execution.

---

*Drafted on 2026-05-15*