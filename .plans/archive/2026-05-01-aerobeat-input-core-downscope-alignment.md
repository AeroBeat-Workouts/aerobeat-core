# AeroBeat Input Core Downscope Alignment

**Date:** 2026-05-01  
**Status:** Stale  
**Agent:** Chip 🐱‍💻

---

## Goal

Align `aerobeat-input-core` with the downscoped AeroBeat v1 input truth so the repo clearly distinguishes the official camera-first gameplay path from future/deprioritized non-camera input abstractions.

---

## Overview

With the docs, authoring tool, content core, and feature core now aligned, `aerobeat-input-core` is the next shared abstraction layer likely to blur product truth if left stale. The approved v1 direction is clear: official gameplay input is camera-only, while mouse/touch remain valid for UI/menu navigation and other input providers may still exist as future, experimental, or deprioritized paths.

This repo should preserve the architectural flexibility for future providers without presenting them as equal-status official v1 gameplay support. The audit should identify any shared enums, docs, examples, tests, or abstraction language that still implies broad current input parity. Then the coder pass can tighten only the surfaces that spread stale truth.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Active plan for this repo-local cleanup slice | `.plans/2026-05-01-aerobeat-input-core-downscope-alignment.md` |
| `REF-02` | Updated AeroBeat docs source of truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-docs` |
| `REF-03` | Parent coordination plan and matrix | `/home/derrick/.openclaw/workspace/projects/openclaw-chip/.plans/2026-05-01-aerobeat-polyrepo-downscope-audit.md` |
| `REF-04` | Recently aligned feature/content/tool contract surfaces | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-feature-core` |

---

## Tasks

### Task 1: Audit `aerobeat-input-core` for stale downscope assumptions

**Bead ID:** `aerobeat-input-core-bqv`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Audit this repo against the updated docs and aligned contract surfaces. Identify stale input-core assumptions such as broad current gameplay-input parity, active non-camera peer truth, or docs/examples/tests/abstractions that fail to distinguish official camera-only v1 gameplay input from future/deprioritized providers. Do not edit yet; produce an execution-ready list.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `docs/`
- `src/`
- `tests/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-01-aerobeat-input-core-downscope-alignment.md`
- `docs/**`
- `src/**`
- `tests/**`

**Status:** ✅ Complete

**Results:** Completed the stale input-scope audit. Main findings: `src/input_manager.gd` still encodes broad active provider parity; `src/interfaces/input_provider.gd` still treats full-body/6DOF/haptics-style capabilities as the default shared baseline; `src/interfaces/flow_input.gd` still leans controller/sword-first in its wording; `src/interfaces/boxing_input.gd` still presents lower-body capability too generically; and README/testbed/metadata surfaces still imply the broader pre-downscope input matrix. Derrick approved the repo-level direction for the coder pass: keep the broader future-facing input abstractions in core (Option A), but explicitly mark advanced capabilities and non-camera providers as optional/future; keep lower-body/XR/haptics in core only with future phrasing; and keep mouse/touch supported for menu navigation but future/deprioritized for gameplay parity. Note: `bd info` reported a Dolt auto-push warning (`no common ancestor`) that does not block the local cleanup slice but may matter later for repo-level Beads sync hygiene.

---

### Task 2: Apply the repo cleanup and scope alignment

**Bead ID:** `aerobeat-input-core-ol9`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** After the audit/action list is approved, update this repo so its shared input-core contracts, docs, examples, and tests match the downscoped AeroBeat v1 input truth. Commit and push by default.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `docs/`
- `src/`
- `tests/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-01-aerobeat-input-core-downscope-alignment.md`
- `docs/**`
- `src/**`
- `tests/**`

**Status:** ✅ Complete

**Results:** Applied the downscope input-scope alignment. The coder pass rewrote `README.md` around camera-first official v1 gameplay input, future-labeled non-camera providers, and mouse/touch as menu-navigation support rather than gameplay parity; retiered contract comments/docs in `src/interfaces/input_provider.gd`, `src/interfaces/flow_input.gd`, `src/interfaces/boxing_input.gd`, and `src/input_manager.gd`; updated `InputManager` provider priority so camera providers are the explicit default path; refreshed `.testbed/scenes/test_scene.gd` teaching text; updated `.testbed/tests/unit/test_input_provider.gd` to validate the narrowed optional-capability framing; and aligned `plugin.cfg` metadata wording. Validation passed after installing testbed deps/importing resources and running the relevant GUT suites. Changes were committed/pushed as `f21bee7` (`Align input core with camera-first v1 scope`). The coder intentionally left pre-existing plan-file dirt out of the commit: modified `.plans/2026-04-20-core-repo-alignment.md` and untracked `.plans/2026-05-01-aerobeat-input-core-downscope-alignment.md`.

---

### Task 3: QA and audit the alignment

**Bead ID:** `aerobeat-input-core-4dn` (QA), `aerobeat-input-core-swc` (Auditor)  
**SubAgent:** `primary`  
**Role:** `qa` then `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Independently verify that this repo clearly distinguishes official camera-only v1 gameplay input from future/deprioritized non-camera providers and stays aligned with the updated docs/product truth.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `docs/`
- `src/`
- `tests/`

**Files Created/Deleted/Modified:**
- `.plans/2026-05-01-aerobeat-input-core-downscope-alignment.md`
- `docs/**`
- `src/**`
- `tests/**`

**Status:** ⏳ In Progress

**Results:** QA pass completed and recommended auditor handoff after one minimal fix. QA confirmed the repo is broadly aligned with the approved truth: camera is clearly framed as the official/default v1 gameplay path; non-camera providers remain but with future/experimental/deprioritized phrasing; mouse/touch are framed as UI/navigation support rather than gameplay parity; XR/haptics/lower-body language is mostly future/optional/provider-dependent; and `InputManager` now prefers camera providers first. QA found one remaining truth leak in `src/interfaces/boxing_input.gd`: `BoxingInput.has_capability()` still returned `true` for `LOWER_BODY` by default. QA fixed that by removing the default `LOWER_BODY` capability advertisement and updating `.testbed/tests/unit/test_input_provider.gd` to assert `LOWER_BODY == false` by default. The relevant GUT suites then passed again.

---

## Final Results

**Status:** ⚠️ Partial

**What We Built:** Draft repo-local plan for the next shared input-scope cleanup slice.

**Reference Check:** Pending repo audit and execution.

**Commits:**
- None yet.

**Lessons Learned:** Shared abstraction repos should preserve future flexibility without quietly undermining the active product truth.

---

*Completed on 2026-05-01*