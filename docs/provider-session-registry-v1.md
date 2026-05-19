# Provider Session Registry v1

`AeroProviderSessionRegistry` is the smallest honest shared seam for reusing an already-active AeroBeat input provider session inside the **same Godot runtime**.

## Why this exists

Some downstream tool lanes, including camera-gesture proving work, can consume the same live MediaPipe-capable provider data that another lane already started.

Without a shared seam, each lane tends to do its own private `load(...).new(); start(...)`, which can:

- spawn duplicate MediaPipe sidecars
- open duplicate camera handles
- create confusing double ownership of provider shutdown
- make cross-repo coordination a pile of private hacks

This registry gives repos a small shared contract instead:

- **owner lane publishes** an already-active provider session
- **consumer lane requests** a compatible existing session
- **consumer lane acquires/releases** a borrower slot when it actually reuses the live provider
- **owner lane remains responsible** for start/stop/unpublish

## Scope and truth boundary

This is intentionally narrow.

What it does:

- shares a live `AeroInputProvider` reference in-process
- tracks explicit `owner_id`
- tracks borrower counts per `consumer_id`
- lets consumers filter by `provider_id`, `session_key`, optional capabilities, owner, and metadata

What it does **not** do:

- discover providers across different Godot processes
- start or stop providers automatically
- transfer provider ownership to borrowers
- guarantee that every provider repo auto-publishes itself yet
- solve all future input/runtime orchestration

## Class and location

- Class: `AeroProviderSessionRegistry`
- File: `res://addons/aerobeat-input-core/src/runtime/provider_session_registry.gd`

## Contract summary

### Owner flow

```gdscript
var publish := AeroProviderSessionRegistry.publish_session(
    "aerobeat-input-mediapipe-python:testbed",
    provider,
    {
        "session_key": "mediapipe_python/desktop_main",
        "metadata": {
            "lane": "desktop_main",
            "device": "camera0",
        },
    }
)
```

- `owner_id` is required.
- `provider` must already exist and be valid.
- `session_key` defaults to the provider id when omitted.
- only the same owner can refresh or unpublish that session key.

### Consumer query flow

```gdscript
var request := AeroProviderSessionRegistry.request_session({
    "provider_id": "mediapipe_python",
    "required_capabilities": [AeroInputProvider.Capability.GESTURE_RECOGNITION],
    "metadata_match": {
        "lane": "desktop_main",
    },
})

if request.get("ok", false):
    var session: Dictionary = request.get("session", {})
    var shared_provider := session.get("provider", null) as Node
```

Query does **not** change borrower state.

### Consumer reuse flow

```gdscript
var acquire := AeroProviderSessionRegistry.acquire_session(
    "aerobeat-tool-camera-gesture-control:testbed",
    {"session_key": "mediapipe_python/desktop_main"}
)

if acquire.get("ok", false):
    var session: Dictionary = acquire.get("session", {})
    var shared_provider := session.get("provider", null) as Node
    controller.attach_input_source(shared_provider)
```

When the consumer is done:

```gdscript
AeroProviderSessionRegistry.release_session(
    "aerobeat-tool-camera-gesture-control:testbed",
    "mediapipe_python/desktop_main"
)
```

Releasing a borrower slot does **not** stop the provider.

## Suggested `session_key` / ownership style

Use stable, explicit identities.

Examples:

- `session_key`: `mediapipe_python/desktop_main`
- `session_key`: `mediapipe_python/camera0`
- `owner_id`: `aerobeat-input-mediapipe-python:testbed`
- `owner_id`: `aerobeat-assembly-community:input_manager`
- `consumer_id`: `aerobeat-tool-camera-gesture-control:testbed`

## Camera-gesture adoption path

For `aerobeat-tool-camera-gesture-control`, the next adoption step should be:

1. before constructing/starting its own MediaPipe provider, call `request_session(...)` for `provider_id = "mediapipe_python"`
2. if a matching session exists, call `acquire_session(...)` and attach that shared provider to `CameraGestureController`
3. if no matching session exists, create/start the provider the way the repo already does today
4. after that provider is live, publish it with `publish_session(...)` so later lanes can reuse it
5. on teardown, `release_session(...)` if it borrowed one, or `unpublish_session(...)` if it owned the session it published

## Current honest limitation for downstream repos

Today this registry is available in `aerobeat-input-core`, but downstream provider repos still need to adopt it explicitly.

That means:

- camera-gesture can start using this seam immediately
- it will only avoid duplicate MediaPipe sessions when the involved owner/consumer lanes both use the registry
- until `aerobeat-input-mediapipe-python` or another owner lane auto-publishes its live provider, consumers may still need to publish the provider they themselves started so later consumers can reuse it
