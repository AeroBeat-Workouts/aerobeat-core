# aerobeat-input-core

Shared AeroBeat input abstractions, gameplay-intent contracts, and runtime coordination for the camera-first v1 product slice.

## Architecture role

`aerobeat-input-core` is the lane owner for shared gameplay-facing input abstractions. It gives AeroBeat one contract home for normalized provider lifecycle, gameplay-intent payloads, optional observation/capability surfaces, shared provider-session reuse, and the canonical UI interaction contract / native 2D bridge path described in the architecture docs.

## V1 scope stance

AeroBeat v1 gameplay is officially **camera-first**.

This repo keeps the broader input abstraction surface so downstream packages can stay future-friendly, but the current product truth is narrower:

- **Official v1 gameplay path:** camera providers
- **Official v1 gameplay contract:** gameplay-facing intent signals, not raw pose streams
- **Supported UI/navigation inputs:** mouse on desktop and touch on mobile
- **Future / experimental / deprioritized gameplay paths:** XR, controllers, keyboard, haptics, and other non-camera providers
- **Optional advanced capability surface:** lower-body tracking, richer 3D transforms, haptics, and other provider-specific extensions remain available in the contracts, but they are not required for v1 gameplay parity

## Lane boundaries

This repo intentionally owns:

- normalized input/provider lifecycle contracts
- camera-first Boxing and Flow gameplay-intent surfaces
- optional capability and observation seams that providers may expose
- shared in-process provider/session reuse contracts
- the canonical UI interaction contract and native 2D bridge lane that gameplay and UI can both consume

This repo intentionally does **not** own:

- concrete detector implementations for specific providers
- feature/runtime scoring or gameplay-rule interpretation
- authored content schemas or package validation
- themed UI widgets, concrete shell scenes, or platform presentation layers
- tool-specific workflow orchestration

## Current repository contents

Current checked-in surfaces include:

- `AeroInputProvider` base contract for normalized provider lifecycle, optional capability reporting, and optional observation/spatial queries
- `FlowInput` contract for camera-first Flow gameplay intents
- `BoxingInput` contract for camera-first Boxing gameplay intents
- `InputManager` runtime coordinator that proxies the gameplay-facing intent surface
- `AeroProviderSessionRegistry` for explicit owner/borrower reuse of already-active provider sessions in one Godot runtime
- `src/ui/` interaction contracts, buses, adapters, and listener/interactable helpers for screen-space, hybrid 3D GUI, and future XR/world paths
- `docs/` notes for the provider-session registry and UI interaction contract
- hidden `.testbed/` workbench content for manual inspection and GUT-based validation

## Intended consumers

Input provider repos, feature repos, UI repos, and assembly/shell repos should depend on this package when they need stable shared input contracts without coupling themselves to one concrete detector or one concrete platform path.

## Development and validation

This repo uses the AeroBeat Phase 1 GodotEnv package/foundation convention.

- Canonical dev/test manifest: `.testbed/addons.jsonc`
- Installed dev/test addons: `.testbed/addons/`
- GodotEnv cache: `.testbed/.addons/`
- Hidden workbench project: `.testbed/project.godot`

Restore dev/test dependencies from the repo root with:

```bash
cd .testbed
godotenv addons install
```

Open the hidden workbench with:

```bash
godot --editor --path .testbed
```

Validation notes:

- repo-local unit tests live under `.testbed/tests/`
- manual/workbench scene content lives under `.testbed/scenes/`
- downstream repos should consume tagged releases of `aerobeat-input-core` in `tag` mode
- validation should keep the camera-first, intent-first v1 framing intact while ensuring future-facing non-camera abstractions remain explicitly optional

## Repository status

This repo is the canonical home for shared Input-lane contracts in the current six-core AeroBeat architecture. Keep the public surface centered on normalized gameplay-facing input contracts and session/UI interaction seams rather than turning the repo into a generic foundation bucket or implying equal-status v1 gameplay support for every provider family.
