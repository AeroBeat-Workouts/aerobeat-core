# AeroBeat Input Core Release Identity Refresh and Consumer Pin Update

**Date:** 2026-04-24  
**Status:** Stale  
**Agent:** Pico 🐱‍🏍

---

## Goal

Refresh the released identity of `aerobeat-input-core` so tagged consumers no longer install old `aerobeat-core` branding, then update the assembly consumer to pin the corrected release.

---

## Overview

The recent assembly rename pass revealed that the generated addon payload under `addons/aerobeat-input-core/` still shows old-name branding like `# aerobeat-core` and `AeroBeat Core`. The source repo on `main` is already corrected — `README.md` and `plugin.cfg` now say `aerobeat-input-core` / `AeroBeat Input Core`. The mismatch exists because the assembly currently pins tag `v0.1.0`, and that tag still points to an older commit created before the input-core identity refresh landed.

So the cleanup we identified is really a release-consumer mismatch, not just a local docs typo. The truthful fix is: audit the release drift, cut a new tagged release from the corrected `aerobeat-input-core` state, update the assembly consumer to pin that new tag, regenerate addons, and verify the installed payload branding now matches reality.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current `aerobeat-input-core` source identity on `main` | `README.md`, `plugin.cfg` |
| `REF-02` | Current installed payload in assembly showing old-name branding | `../aerobeat-assembly-community/addons/aerobeat-input-core/README.md`, `../aerobeat-assembly-community/addons/aerobeat-input-core/plugin.cfg` |
| `REF-03` | Current pinned release in assembly manifest | `../aerobeat-assembly-community/addons.jsonc` |
| `REF-04` | Current tag history in `aerobeat-input-core` | git tag / git log |
| `REF-05` | Recent assembly rename plan that identified this as upstream identity drift | `../aerobeat-assembly-community/.plans/2026-04-24-rename-assembly-core-addon-key-to-aerobeat-input-core.md` |

---

## Tasks

### Task 1: Audit release/tag identity drift between source repo and tagged consumer payload

**Bead ID:** `oc-jd6`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Confirm exactly why tagged consumers still install old `aerobeat-core` branding even though `aerobeat-input-core` main is already updated. Compare current source files, the pinned tag, and the installed assembly payload, then propose the smallest truthful fix. Do not implement yet.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-24-refresh-input-core-release-identity-and-consumer-pin.md`

**Status:** ✅ Complete

**Results:** Confirmed exact release drift. `README.md` on `main` now starts with `# aerobeat-input-core` and `plugin.cfg` now uses `name="AeroBeat Input Core"` / `description="Shared input abstractions and provider contracts for the AeroBeat ecosystem"` (`REF-01`). The assembly consumer is still pinned to `"checkout": "v0.1.0"` in `../aerobeat-assembly-community/addons.jsonc` (`REF-03`). Tag `v0.1.0` resolves to commit `04a396d8fd5778feb939e9bed7dfcfb1a8895cb1`, which predates the identity refresh and still ships `# aerobeat-core`, `AeroBeat Core`, and the old core-focused description in both `README.md` and `plugin.cfg` (`REF-04`). A direct diff between `git show v0.1.0:README.md` / `plugin.cfg` and the installed assembly payload under `../aerobeat-assembly-community/addons/aerobeat-input-core/` was empty, confirming the installed branding drift is coming from the pinned tag payload, not from a separate assembly-side mutation (`REF-02`, `REF-03`, `REF-04`). The identity refresh already landed on source `main` in commit `fe859a9` (`Align input core identity with lane architecture`), and current source does not need another branding fix before release. Smallest truthful next step: cut a new tag from current `main` (or the exact corrected commit to release), then update the assembly consumer from `v0.1.0` to that new tag and reinstall/regenerate so the installed addon payload matches current source branding.

---

### Task 2: Cut a corrected `aerobeat-input-core` release and update the assembly pin

**Bead ID:** `oc-gt6`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Create the smallest truthful release-consumer fix: tag the corrected `aerobeat-input-core` state with a new release tag, push it, update the assembly consumer to pin that new tag, regenerate addons, and record exact evidence. Keep scope tight.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `../aerobeat-assembly-community/addons/`

**Files Created/Deleted/Modified:**
- release/tag metadata as needed
- `../aerobeat-assembly-community/addons.jsonc`
- `../aerobeat-assembly-community/.plans/2026-04-24-rename-assembly-core-addon-key-to-aerobeat-input-core.md`
- `.plans/2026-04-24-refresh-input-core-release-identity-and-consumer-pin.md`

**Status:** ✅ Complete

**Results:** Tagged the corrected current `main` state at commit `12daf1c77bcb3d80a38ffc98ef257f5ac6dcfa1c` as `v0.1.1` and pushed that tag to `origin`, with the tag SHA matching `HEAD` exactly (`git rev-list -n 1 v0.1.1` == `git rev-parse HEAD`) (`REF-01`, `REF-04`). In `../aerobeat-assembly-community/addons.jsonc`, the `aerobeat-input-core` consumer pin was updated from `"checkout": "v0.1.0"` to `"checkout": "v0.1.1"` (`REF-03`). After removing the stale installed/cache copies at `../aerobeat-assembly-community/addons/aerobeat-input-core` and `../aerobeat-assembly-community/.addons/aerobeat-input-core`, rerunning `godotenv addons install` resolved `aerobeat-input-core` from branch/tag `v0.1.1` and regenerated the mounted payload. The refreshed installed files now match current source identity exactly: `../aerobeat-assembly-community/addons/aerobeat-input-core/README.md` starts with `# aerobeat-input-core`, and `../aerobeat-assembly-community/addons/aerobeat-input-core/plugin.cfg` now reads `name="AeroBeat Input Core"` with description `"Shared input abstractions and provider contracts for the AeroBeat ecosystem"` (`REF-01`, `REF-02`, `REF-03`). I also updated the assembly rename plan (`REF-05`) with the exact new release-pin evidence so downstream audit notes no longer describe the branding drift as still outstanding.

---

### Task 3: QA/audit the refreshed installed payload branding in the assembly consumer

**Bead ID:** `oc-hl1`  
**SubAgent:** `primary`  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`  
**Prompt:** Independently verify that the assembly consumer now installs the refreshed `aerobeat-input-core` release, that the installed README/plugin branding matches reality, and that the project still imports cleanly. Close only if the evidence supports it.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-24-refresh-input-core-release-identity-and-consumer-pin.md`

**Status:** ✅ Complete

**Results:** Independent QA/audit passed against the live assembly consumer state and fresh reruns, not just prior notes. In `aerobeat-input-core`, the pushed annotated tag `v0.1.1` exists on `origin` and peels to commit `12daf1c77bcb3d80a38ffc98ef257f5ac6dcfa1c` (`git rev-parse v0.1.1^{}` / `git ls-remote origin 'refs/tags/v0.1.1^{}'`), which is the documented corrected source state from Task 1 rather than the later plan-only commit `1138e61` (`REF-04`). Inspecting the tagged payload directly confirms the intended branding source: `git show v0.1.1:README.md` starts with `# aerobeat-input-core`, and `git show v0.1.1:plugin.cfg` contains `name="AeroBeat Input Core"` with description `"Shared input abstractions and provider contracts for the AeroBeat ecosystem"` (`REF-01`, `REF-04`).

In `../aerobeat-assembly-community/addons.jsonc`, the live consumer pin now reads `"checkout": "v0.1.1"` under addon key `aerobeat-input-core`, and that repo’s `origin/main` matches local commit `77fdba72ed9964c24295f5e25ab3a6fcd0a81f84`, confirming the pin update is pushed (`REF-03`). For a fresh consumer-proof check, I removed the mounted/cache copies at `addons/aerobeat-input-core` and `.addons/aerobeat-input-core`, reran `godotenv addons install`, and captured `.qa-logs/task3-refresh-audit-install.log`, which resolves `aerobeat-input-core` from `addons.jsonc` on branch/tag `v0.1.1` of `git@github.com:AeroBeat-Workouts/aerobeat-input-core.git`. The regenerated installed payload then matched the release identity directly: `addons/aerobeat-input-core/README.md:1` is `# aerobeat-input-core`, `addons/aerobeat-input-core/plugin.cfg:2` is `name="AeroBeat Input Core"`, and the mounted MediaPipe adapter at `addons/aerobeat-input-mediapipe/src/input_provider.gd:1` still extends `res://addons/aerobeat-input-core/src/interfaces/input_provider.gd` (`REF-02`, `REF-03`, `REF-05`).

Fresh assembly validation reruns also passed. `godot --headless --path . --import --quit-after 1000` exited 0 and logged normal import progress in `../aerobeat-assembly-community/.qa-logs/task3-refresh-audit-import.log`. `godot --headless --path . --script src/main.gd --check-only` also exited 0 in `../aerobeat-assembly-community/.qa-logs/task3-refresh-audit-check-main.log`, confirming the project still imports and parses cleanly with the refreshed pin installed. The only remaining caveat is that `plugin.cfg` still reports internal `version="0.1.0"` even though the shipped Git release tag is `v0.1.1`. I do not judge that as blocker-level for this slice because the consumer pin, installed README, plugin name/description, and import behavior all truthfully validate the intended release identity. It should be tracked as a follow-up metadata cleanup so plugin-internal version text matches future Git tags.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** Cut and pushed refreshed release tag `v0.1.1` for `aerobeat-input-core`, updated the assembly consumer to pin that release, regenerated the mounted addon payload in `aerobeat-assembly-community`, and independently verified that the installed README/plugin branding now matches reality while the assembly still imports cleanly.

**Reference Check:** `REF-01` satisfied by the tagged source payload at `v0.1.1`, where `README.md` and `plugin.cfg` carry `aerobeat-input-core` / `AeroBeat Input Core` branding. `REF-02` satisfied by the refreshed installed assembly payload under `../aerobeat-assembly-community/addons/aerobeat-input-core/`, where the README header and plugin name now match the source identity exactly. `REF-03` satisfied by `../aerobeat-assembly-community/addons.jsonc` now pinning `"checkout": "v0.1.1"`. `REF-04` satisfied by the remote tag audit showing `origin` tag `v0.1.1` peels to commit `12daf1c77bcb3d80a38ffc98ef257f5ac6dcfa1c`. `REF-05` satisfied because the assembly-side rename plan now reflects that the prior live branding drift was resolved by this release/pin refresh.

**Commits:**
- `12daf1c` - Document input-core release identity drift
- `1138e61` - Record input-core release pin refresh evidence
- `77fdba7` - Refresh input-core assembly pin to v0.1.1
- `Pending` - Plan update with independent Task 3 audit evidence

**Lessons Learned:** For tagged GodotEnv consumers, truth lives in the released tag plus a fresh reinstall, not in current source alone. Auditing the mounted payload after purging install/cache state is what proves the fix is real. Also, plugin metadata version strings can drift independently from Git release tags; treat that as explicit release metadata work instead of assuming the tag alone updates in-addon version text.

---

*Completed on 2026-04-24*
