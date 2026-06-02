# AeroBeat Input Core Bump plugin.cfg Version and Refresh Consumer Pin

**Date:** 2026-04-24  
**Status:** Stale  
**Agent:** Pico 🐱‍🏍

---

## Goal

Update `aerobeat-input-core/plugin.cfg` so its internal version matches the released tag, then refresh the assembly consumer pin to install that corrected release.

---

## Overview

The prior release refresh fixed the installed naming/branding drift by tagging `v0.1.1` and updating the assembly consumer to pin that tag. One small mismatch remains: the released `plugin.cfg` still reports `version="0.1.0"` even when the consumer is installing release tag `v0.1.1`.

This pass should stay narrow. We are not reopening broader runtime or naming work. The truthful fix is to bump the source `plugin.cfg` version to match the release, cut a new tag, update the assembly consumer pin, reinstall the addon, and verify the installed payload now reports the corrected internal version.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Current source plugin metadata | `plugin.cfg` |
| `REF-02` | Current release/consumer cleanup plan | `.plans/2026-04-24-refresh-input-core-release-identity-and-consumer-pin.md` |
| `REF-03` | Current assembly consumer pin | `../aerobeat-assembly-community/addons.jsonc` |
| `REF-04` | Current installed payload in assembly | `../aerobeat-assembly-community/addons/aerobeat-input-core/plugin.cfg` |

---

## Tasks

### Task 1: Audit current source/release/plugin version mismatch

**Bead ID:** `oc-bl3`  
**SubAgent:** `primary`  
**Role:** `research`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Confirm the exact plugin version mismatch between current source, current tag, and installed consumer payload, then propose the smallest truthful fix. Do not implement yet.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-24-bump-plugin-cfg-version-and-refresh-consumer-pin.md`

**Status:** ✅ Complete

**Results:** Confirmed the mismatch is not between source `main` and the tagged payload contents; it is between the released tag / consumer pin and the plugin-internal version string. Current source `plugin.cfg` on `main` still reads `version="0.1.0"` (`REF-01`). Released tag `v0.1.1` also contains the same exact `plugin.cfg` payload with `version="0.1.0"` (`git show v0.1.1:plugin.cfg`; context from `REF-02`). The assembly consumer is pinned to `"checkout": "v0.1.1"` in `../aerobeat-assembly-community/addons.jsonc` (`REF-03`), and the installed payload at `../aerobeat-assembly-community/addons/aerobeat-input-core/plugin.cfg` likewise still reads `version="0.1.0"` (`REF-04`). Exact drift: release tag / consumer pin say `v0.1.1`, while source `main`, tagged payload, and installed payload all still self-report plugin version `0.1.0`. Smallest truthful fix: change only `plugin.cfg` version to `0.1.2`, create/push tag `v0.1.2`, then repin the assembly consumer to `v0.1.2` and reinstall. Do not rewrite `v0.1.1`; it already exists, so skipping to `0.1.2` keeps tag history and plugin metadata aligned truthfully. No source change beyond `plugin.cfg` is needed for this fix.

---

### Task 2: Bump plugin.cfg version, tag, repin consumer, and reinstall

**Bead ID:** `oc-ngn`  
**SubAgent:** `primary`  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Implement the smallest truthful fix: update `plugin.cfg` version to the next release, create/push the new tag, update the assembly consumer pin, reinstall the addon there, and record exact validation evidence. Keep scope tight.

**Folders Created/Deleted/Modified:**
- `.plans/`
- `../aerobeat-assembly-community/addons/`

**Files Created/Deleted/Modified:**
- `plugin.cfg`
- `../aerobeat-assembly-community/addons.jsonc`
- `.plans/2026-04-24-bump-plugin-cfg-version-and-refresh-consumer-pin.md`
- `../aerobeat-assembly-community/.plans/2026-04-24-rename-assembly-core-addon-key-to-aerobeat-input-core.md`

**Status:** ✅ Complete

**Results:** Implemented the narrow release-consumer correction exactly as planned. In `plugin.cfg` (`REF-01`), changed only the plugin-internal version string from `0.1.0` to `0.1.2`, then committed and pushed source commit `64bbcf8` (`Bump plugin.cfg version to 0.1.2`) to `main`. Created and pushed annotated tag `v0.1.2` from that commit without rewriting prior tags, keeping the release history truthful (`REF-02`).

In the assembly consumer manifest (`REF-03`), updated `../aerobeat-assembly-community/addons.jsonc` from `"checkout": "v0.1.1"` to `"checkout": "v0.1.2"`, then removed the stale installed/cache copies at `../aerobeat-assembly-community/addons/aerobeat-input-core` and `../aerobeat-assembly-community/.addons/aerobeat-input-core` before rerunning `godotenv addons install`. Exact validation evidence after reinstall: `git show v0.1.2:plugin.cfg` reports `version="0.1.2"`; `../aerobeat-assembly-community/addons.jsonc` now contains `8:      "checkout": "v0.1.2",`; and the refreshed installed payload at `../aerobeat-assembly-community/addons/aerobeat-input-core/plugin.cfg` now contains `5:version="0.1.2"` (`REF-03`, `REF-04`).

---

### Task 3: QA/audit the refreshed installed plugin version in the assembly consumer

**Bead ID:** `oc-76k`  
**SubAgent:** `primary`  
**Role:** `qa` / `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`  
**Prompt:** Independently verify that the assembly consumer now installs the refreshed release and that the installed `plugin.cfg` version matches the pinned tag truthfully. Close only if the evidence supports it.

**Folders Created/Deleted/Modified:**
- `.plans/`

**Files Created/Deleted/Modified:**
- `.plans/2026-04-24-bump-plugin-cfg-version-and-refresh-consumer-pin.md`

**Status:** ✅ Complete

**Results:** Independent QA/audit reran the evidence path instead of trusting the coder handoff. Source truth check passed in the core repo: `plugin.cfg` on `main` currently reads `5:version="0.1.2"` (`REF-01`), and `git show --stat --summary --oneline 64bbcf8` confirms the source bump commit only changed that file/version as claimed. Release-tag truth check also passed: local tag `v0.1.2` resolves to commit `64bbcf80556f333ec06ae734d7392f7d70e054d4`, `git show v0.1.2:plugin.cfg` reports `5:version="0.1.2"`, and `git ls-remote --tags origin refs/tags/v0.1.2 refs/tags/v0.1.2^{}` confirms the annotated tag object plus peeled commit are present on `origin` (`REF-02`).

Assembly consumer truth check passed independently in `../aerobeat-assembly-community`: `addons.jsonc` contains `8:      "checkout": "v0.1.2",` (`REF-03`). I reran `godotenv addons install` from the assembly repo root and it resolved `aerobeat-input-core` specifically on branch/tag `v0.1.2`, then rechecked the installed payload: `../aerobeat-assembly-community/addons/aerobeat-input-core/plugin.cfg` contains `5:version="0.1.2"` (`REF-04`). A light import smoke check also passed independently: `godot --headless --path . --import --quit-after 1000` exited `0` after plugin initialization/class registration, with no addon-resolution failure. Auditor verdict: the consumer pin, installed payload, and tagged source now agree truthfully on `0.1.2`, so this slice is complete and bead `oc-76k` should close.

---

## Final Results

**Status:** ✅ Complete

**What We Built:** `aerobeat-input-core` now truthfully publishes plugin metadata version `0.1.2`, release tag `v0.1.2` exists on `origin`, the assembly consumer is pinned to that tag, and a fresh reinstall in the assembly repo produces an installed `addons/aerobeat-input-core/plugin.cfg` that also reports `version="0.1.2"`.

**Reference Check:** `REF-01` satisfied independently: source `plugin.cfg` on `main` reads `5:version="0.1.2"`. `REF-02` satisfied independently: commit `64bbcf8` is the source bump commit, `git show v0.1.2:plugin.cfg` reports `5:version="0.1.2"`, and `git ls-remote --tags origin refs/tags/v0.1.2 refs/tags/v0.1.2^{}` confirms the pushed annotated tag plus peeled commit. `REF-03` satisfied independently: the assembly manifest still contains `8:      "checkout": "v0.1.2",`. `REF-04` satisfied independently after a fresh reinstall: `godotenv addons install` resolved `aerobeat-input-core` on `v0.1.2`, and the installed payload at `../aerobeat-assembly-community/addons/aerobeat-input-core/plugin.cfg` reads `5:version="0.1.2"`. Additional smoke validation passed: `godot --headless --path ../aerobeat-assembly-community --import --quit-after 1000` exited `0`, so the refreshed consumer state imports cleanly enough for this slice.

**Commits:**
- `64bbcf8` - Bump plugin.cfg version to 0.1.2
- `011de10` - Record v0.1.2 release consumer evidence

**Lessons Learned:** Release-truth work needs all three layers checked independently: source metadata, pushed tag payload, and freshly installed consumer output. Re-running install/import during audit is what turns “the manifest says the right thing” into “the consumer is actually using the right thing.”

---

*Completed on 2026-04-24*
