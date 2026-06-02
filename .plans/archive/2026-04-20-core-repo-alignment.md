# AeroBeat Core Repo Alignment

**Date:** 2026-04-20  
**Status:** Stale  
**Agent:** Chip 🐱‍💻

---

## Goal

Align all AeroBeat `*-core` repos to the new lane-based architecture by fixing `aerobeat-input-core` to match its new name/purpose, normalizing all core-repo licenses to match `aerobeat-input-core`, and standardizing README style/content across the full core set.

---

## Overview

The six-core architecture is now documented and the repos exist locally, but the repos themselves are not yet internally consistent. `aerobeat-input-core` still carries old `aerobeat-core` identity text in at least its README and plugin metadata, and the newer sibling repos currently have placeholder READMEs with weaker wording and inconsistent license file shapes.

This pass should make the repos themselves tell the same story as the docs. That means `aerobeat-input-core` needs a direct identity correction, while `aerobeat-feature-core`, `aerobeat-content-core`, `aerobeat-asset-core`, `aerobeat-ui-core`, and `aerobeat-tool-core` should all present a consistent README style anchored to the `aerobeat-input-core` pattern but rewritten for their own lane and purpose.

The license requirement is also explicit: every core repo should use the same license as `aerobeat-input-core`. Derrick clarified that the correct file convention is the Markdown form already used in `aerobeat-input-core`, so this work should normalize both the actual license text and the file convention to **`LICENSE.md`** across all six core repos.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Local `aerobeat-input-core` repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core` |
| `REF-02` | Local `aerobeat-feature-core` repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-feature-core` |
| `REF-03` | Local `aerobeat-content-core` repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core` |
| `REF-04` | Local `aerobeat-asset-core` repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-asset-core` |
| `REF-05` | Local `aerobeat-ui-core` repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-ui-core` |
| `REF-06` | Local `aerobeat-tool-core` repo | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-core` |
| `REF-07` | Six-core architecture docs source of truth | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-docs/docs/architecture/overview.md` |
| `REF-08` | Current repo map | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-docs/docs/architecture/repository-map.md` |

---

## Working Direction

### Expected repo set

- `aerobeat-input-core`
- `aerobeat-feature-core`
- `aerobeat-content-core`
- `aerobeat-asset-core`
- `aerobeat-ui-core`
- `aerobeat-tool-core`

### Immediate alignment rules

1. `aerobeat-input-core` must no longer describe itself as generic `aerobeat-core`.
2. All core repos should carry the same license as `aerobeat-input-core`, using `LICENSE.md` as the canonical file name.
3. All core repos should have a README with the same structural style as `aerobeat-input-core`, but with lane-correct naming and purpose.
4. README wording should match the six-core docs: each core owns its lane’s contracts, not a generic universal hub.
5. If plugin metadata still uses old names/descriptions, it should be corrected where appropriate.

---

## Tasks

### Task 1: Inventory all core repos for identity, README, license, and metadata drift

**Bead ID:** `aerobeat-input-core-wjb`  
**SubAgent:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Inspect all six AeroBeat core repos and inventory the current state of README files, license files, plugin metadata, and any obvious old-name drift. Produce an exact per-repo list of what needs to change so the repos match the six-core architecture and `aerobeat-input-core` license baseline.

**Folders Created/Deleted/Modified:**
- all six local core repos

**Files Created/Deleted/Modified:**
- None expected during inventory

**Status:** ✅ Complete

**Results:** Inventory complete. Exact alignment work needed by repo:

- `aerobeat-input-core`
  - `README.md` still presents the repo as generic `# aerobeat-core` instead of `# aerobeat-input-core`.
  - README purpose line still says `Shared AeroBeat foundation addon for core contracts, interfaces, enums, constants, and low-level utilities.`; it needs lane-specific input-core wording instead of generic foundation/core wording.
  - README validation note still says downstream repos should consume tagged releases of `aerobeat-core`; this needs the renamed repo/package reference.
  - `plugin.cfg` still uses old identity metadata: `name="AeroBeat Core"` and `description="Core interfaces and utilities for AeroBeat ecosystem"`.
  - `.testbed/project.godot` still uses `config/name="AeroBeat Core Testbed"`.
  - `project.godot.disabled` still uses `config/name="AeroBeat Core"`.
  - `.testbed/scenes/test_scene.gd` and `.testbed/scenes/test_scene.tscn` still contain `AeroBeat Core` strings and should be renamed if the alignment pass is intended to clear the old identity from testbed-facing surfaces too.
  - License baseline is here already and uses the desired canonical file shape: `LICENSE.md` with the Markdown-formatted MPL 2.0 text.

- `aerobeat-feature-core`
  - `README.md` is a placeholder two-line stub and needs a full structured README matching the richer `aerobeat-input-core` / `aerobeat-ui-core` style.
  - README wording is wrong for the new architecture: `The 'Hub' of the AeroBeat project for features. Stores Interfaces, Enums, Constants, and Utils.` It should describe the feature lane’s contracts/purpose, not a generic hub.
  - License file is `LICENSE`, not `LICENSE.md`.
  - License content is MPL 2.0 but not byte-for-byte the same as `aerobeat-input-core`; it is the plain-text formatting variant, so the alignment pass should replace it with the exact `LICENSE.md` baseline content.
  - No plugin metadata files were present at top level, so this repo currently appears to need README + license normalization only.

- `aerobeat-content-core`
  - `README.md` is a placeholder two-line stub and needs the same structured README treatment.
  - README wording is wrong for the new architecture: `The 'Hub' of the AeroBeat project for content. Stores Interfaces, Enums, Constants, and Utils.`
  - License file is `LICENSE`, not `LICENSE.md`.
  - License content is MPL 2.0 but uses the same plain-text formatting variant instead of the exact Markdown-form baseline from `aerobeat-input-core`.
  - No plugin metadata files were present at top level, so this repo currently appears to need README + license normalization only.

- `aerobeat-asset-core`
  - `README.md` is a placeholder two-line stub and needs the same structured README treatment.
  - README wording is wrong for the new architecture: `The 'Hub' of the AeroBeat project for assets. Stores Interfaces, Enums, Constants, and Utils.`
  - License file is `LICENSE`, not `LICENSE.md`.
  - License content is MPL 2.0 but uses the same plain-text formatting variant instead of the exact Markdown-form baseline from `aerobeat-input-core`.
  - No plugin metadata files were present at top level, so this repo currently appears to need README + license normalization only.

- `aerobeat-ui-core`
  - `README.md` is already in the richer structured style and is a good template baseline for the other repos, but it still contains old dependency naming drift: it says the testbed installs tagged `aerobeat-core` and that the manifest pins `aerobeat-core` to `v0.1.0`.
  - `.testbed/addons.jsonc` still declares the dependency key `aerobeat-core` and points to `git@github.com:AeroBeat-Workouts/aerobeat-core.git`; this is an obvious old-name drift item if the dependency should now follow the renamed input-core repo.
  - `.testbed/tests/test_ui_core_base_classes.gd` still asserts that `res://addons/aerobeat-core/plugin.cfg` exists and still describes the dependency as `aerobeat-core`.
  - License file is `LICENSE`, not `LICENSE.md`.
  - License content is MPL 2.0 but uses the same plain-text formatting variant instead of the exact Markdown-form baseline from `aerobeat-input-core`.
  - `plugin.cfg` and `.testbed/project.godot` already use lane-correct `AeroBeat UI Core` naming and do not show the same identity drift as input-core.

- `aerobeat-tool-core`
  - `README.md` is a placeholder two-line stub and needs the same structured README treatment.
  - README wording is wrong for the new architecture: `The 'Hub' of the AeroBeat project for tools. Stores Interfaces, Enums, Constants, and Utils.`
  - License file is `LICENSE`, not `LICENSE.md`.
  - License content is MPL 2.0 but uses the same plain-text formatting variant instead of the exact Markdown-form baseline from `aerobeat-input-core`.
  - No plugin metadata files were present at top level, so this repo currently appears to need README + license normalization only.

Common inventory conclusion:
- Four repos (`feature`, `content`, `asset`, `tool`) are mostly placeholder README + license-shape normalization work.
- `aerobeat-input-core` has the heaviest identity drift and needs old `aerobeat-core` naming removed from README, plugin metadata, and testbed/project labels.
- `aerobeat-ui-core` is mostly aligned stylistically, but still references `aerobeat-core` as an upstream dependency in README, testbed manifest, and tests.
- All five non-input repos need `LICENSE` → exact `LICENSE.md` normalization to match the canonical baseline in `aerobeat-input-core`.

---

### Task 2: Fix `aerobeat-input-core` identity and normalize README/license style across all core repos

**Bead ID:** `aerobeat-input-core-13d`  
**SubAgent:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Update `aerobeat-input-core` so its README/plugin metadata match its new lane-specific name and purpose. Then normalize README structure/style across all six core repos so they share the same layout quality as `aerobeat-input-core`, but with lane-correct naming/purpose. Normalize license files so all six core repos use the same Markdown license file as `aerobeat-input-core`, with `LICENSE.md` as the canonical file convention.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-feature-core`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-asset-core`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-ui-core`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-core`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/plugin.cfg`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.testbed/project.godot`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/project.godot.disabled`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.testbed/scenes/test_scene.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.testbed/scenes/test_scene.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-ui-core/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-ui-core/.testbed/addons.jsonc`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-ui-core/.testbed/tests/test_ui_core_base_classes.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-ui-core/LICENSE.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-ui-core/LICENSE` (deleted)
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-feature-core/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-feature-core/LICENSE.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-feature-core/LICENSE` (deleted)
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core/LICENSE.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-content-core/LICENSE` (deleted)
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-asset-core/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-asset-core/LICENSE.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-asset-core/LICENSE` (deleted)
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-core/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-core/LICENSE.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-core/LICENSE` (deleted)

**Status:** ✅ Complete

**Results:**
- `aerobeat-input-core` identity was corrected from the old generic `aerobeat-core` branding to the lane-specific input-core name across the README, plugin metadata, hidden project labels, and obvious testbed-facing strings.
- `aerobeat-ui-core` stale dependency naming was normalized from `aerobeat-core` to `aerobeat-input-core` in the README, GodotEnv manifest, and test assertion path/message.
- `aerobeat-feature-core`, `aerobeat-content-core`, `aerobeat-asset-core`, and `aerobeat-tool-core` placeholder READMEs were rewritten into lane-specific architecture summaries aligned with the six-core docs rather than the old generic “hub” wording.
- License normalization was completed across every non-input core repo by replacing `LICENSE` with byte-identical `LICENSE.md` content copied from `aerobeat-input-core/LICENSE.md`.
- Repo-local commits pushed to `main` so far:
  - `aerobeat-ui-core`: `2b756f0` — `Align UI core dependency naming and license`
  - `aerobeat-feature-core`: `64ee1fe` — `Rewrite feature core README and normalize license`
  - `aerobeat-content-core`: `f926d68` — `Rewrite content core README and normalize license`
  - `aerobeat-asset-core`: `4aead55` — `Rewrite asset core README and normalize license`
  - `aerobeat-tool-core`: `901bf31` — `Rewrite tool core README and normalize license`
- Repo-local commit pushed to `main` for `aerobeat-input-core`: `fe859a9` — `Align input core identity with lane architecture`.

---

### Task 3: Audit the aligned core repos for consistency

**Bead ID:** `aerobeat-input-core-tef`  
**SubAgent:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`, `REF-08`  
**Prompt:** Independently verify that all six core repos now use the same license as `aerobeat-input-core`, that their READMEs match the same style standard while reflecting lane-correct purpose, and that `aerobeat-input-core` no longer presents itself as generic `aerobeat-core`.

**Folders Created/Deleted/Modified:**
- all six local core repos

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-input-core/.plans/2026-04-20-core-repo-alignment.md`

**Status:** ✅ Complete

**Results:**
- Audit passed after independent file-level inspection across all six core repos.
- `aerobeat-input-core` no longer presents itself as the old generic core in the targeted identity surfaces checked during audit: `README.md`, `plugin.cfg`, `.testbed/project.godot`, `project.godot.disabled`, `.testbed/scenes/test_scene.gd`, and `.testbed/scenes/test_scene.tscn` now consistently use `aerobeat-input-core` / `AeroBeat Input Core` lane-specific wording.
- `aerobeat-ui-core` no longer uses stale `aerobeat-core` dependency naming in the targeted dependency surfaces checked during audit: `README.md`, `.testbed/addons.jsonc`, and `.testbed/tests/test_ui_core_base_classes.gd` now reference `aerobeat-input-core` consistently.
- License normalization passed in all six repos: each repo now exposes only `LICENSE.md` at the repo root, and the SHA-256 hash for all six matched the `aerobeat-input-core/LICENSE.md` baseline (`86299535d4d06830eb8e53a37d074d7b51345eedfbe7edd89a1656bf35077662`).
- README review passed: all six repos now use a clear repo-title-plus-purpose format and lane-correct descriptive sections. `aerobeat-input-core` and `aerobeat-ui-core` intentionally include GodotEnv/testbed workflow sections because they are addon/testbed repos, while `feature`, `content`, `asset`, and `tool` use aligned architecture-role / intended-consumers / repository-status sections appropriate to contract-only lanes.
- Old-name grep was clean for live repo surfaces in `aerobeat-input-core` and `aerobeat-ui-core`; remaining `aerobeat-core` / `AeroBeat Core` matches were limited to this historical plan file and Beads interaction metadata, not shipping repo surfaces.
- Files inspected during audit:
  - `aerobeat-input-core/README.md`
  - `aerobeat-input-core/plugin.cfg`
  - `aerobeat-input-core/.testbed/project.godot`
  - `aerobeat-input-core/project.godot.disabled`
  - `aerobeat-input-core/.testbed/scenes/test_scene.gd`
  - `aerobeat-input-core/.testbed/scenes/test_scene.tscn`
  - `aerobeat-input-core/LICENSE.md`
  - `aerobeat-ui-core/README.md`
  - `aerobeat-ui-core/.testbed/addons.jsonc`
  - `aerobeat-ui-core/.testbed/tests/test_ui_core_base_classes.gd`
  - `aerobeat-ui-core/plugin.cfg`
  - `aerobeat-ui-core/.testbed/project.godot`
  - `aerobeat-ui-core/LICENSE.md`
  - `aerobeat-feature-core/README.md`
  - `aerobeat-feature-core/LICENSE.md`
  - `aerobeat-content-core/README.md`
  - `aerobeat-content-core/LICENSE.md`
  - `aerobeat-asset-core/README.md`
  - `aerobeat-asset-core/LICENSE.md`
  - `aerobeat-tool-core/README.md`
  - `aerobeat-tool-core/LICENSE.md`
- No remaining repo-surface gaps were found in the audited scope.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** All six AeroBeat core repos are now aligned to the lane-based architecture: `aerobeat-input-core` uses lane-correct identity surfaces, `aerobeat-ui-core` points at `aerobeat-input-core` instead of the stale generic dependency name, every core repo uses the shared `LICENSE.md` baseline, and each README now presents a consistent lane-specific purpose.

**Reference Check:** `REF-01` through `REF-06` were directly inspected during the audit and passed the requested repo-surface checks. The resulting lane descriptions and repo roles are consistent with the six-core architecture direction in `REF-07` and `REF-08`. No deliberate deviations were identified.

**Commits:**
- `fe859a9` - Align input core identity with lane architecture
- `f80c2ff` - Update core repo alignment plan progress
- `2b756f0` - Align UI core dependency naming and license
- `64ee1fe` - Rewrite feature core README and normalize license
- `f926d68` - Rewrite content core README and normalize license
- `4aead55` - Rewrite asset core README and normalize license
- `901bf31` - Rewrite tool core README and normalize license

**Lessons Learned:** For multi-repo naming migrations, the fastest reliable audit is to pair targeted surface inspection with a repo-root license hash check and an old-name grep that excludes planning/history artifacts.

---

*Completed on 2026-04-20*
