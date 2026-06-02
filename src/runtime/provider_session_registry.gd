class_name AeroProviderSessionRegistry
extends RefCounted
## Shared in-process registry for active AeroBeat input-provider sessions.
##
## Purpose:
## - let one repo/lane publish an already-active provider session
## - let another repo/lane query and reuse that live provider reference
## - keep ownership explicit so reuse does not silently transfer lifecycle control
##
## This is intentionally a small v1 seam:
## - in-process only (same Godot runtime)
## - owner publishes/unpublishes
## - consumers acquire/release borrower slots
## - registry never starts/stops providers on behalf of consumers

const STATUS_PUBLISHED := "published"
const STATUS_AVAILABLE := "available"
const STATUS_ACQUIRED := "acquired"
const STATUS_RELEASED := "released"
const STATUS_UNPUBLISHED := "unpublished"
const STATUS_MISSING := "missing"
const STATUS_INVALID_OWNER := "invalid_owner"
const STATUS_INVALID_PROVIDER := "invalid_provider"
const STATUS_SESSION_EXISTS := "session_exists"
const STATUS_OWNER_MISMATCH := "owner_mismatch"
const STATUS_CONSUMER_MISMATCH := "consumer_mismatch"
const STATUS_REQUEST_INVALID := "request_invalid"

const _KNOWN_CAPABILITIES := [
	AeroInputProvider.Capability.SPATIAL_TRANSFORM,
	AeroInputProvider.Capability.GESTURE_RECOGNITION,
	AeroInputProvider.Capability.LOWER_BODY,
	AeroInputProvider.Capability.HAPTICS,
	AeroInputProvider.Capability.VELOCITY,
]

static var _sessions: Dictionary = {}

## Publish or refresh a live provider session owned by one lane/repo.
##
## Required:
## - owner_id: stable owner identity string, for example
##   `aerobeat-input-mediapipe-python:testbed`
## - provider: the already-active provider instance to share
##
## Options:
## - session_key: explicit session key. Defaults to provider_id.
## - metadata: repo-agnostic descriptive metadata such as lane/device/source.
## - capabilities: optional override list. Defaults to capability inference.
static func publish_session(owner_id: String, provider: AeroInputProvider, options: Dictionary = {}) -> Dictionary:
	_prune_invalid_sessions()

	var normalized_owner_id := String(owner_id).strip_edges()
	if normalized_owner_id.is_empty():
		push_error("AeroProviderSessionRegistry: owner_id is required when publishing a session")
		return {
			"ok": false,
			"status": STATUS_INVALID_OWNER,
		}

	if provider == null or not is_instance_valid(provider):
		push_error("AeroProviderSessionRegistry: cannot publish a null or invalid provider")
		return {
			"ok": false,
			"status": STATUS_INVALID_PROVIDER,
		}

	var provider_id := _resolve_provider_id(provider, options)
	if provider_id.is_empty():
		push_error("AeroProviderSessionRegistry: provider_id resolved to an empty value")
		return {
			"ok": false,
			"status": STATUS_INVALID_PROVIDER,
		}

	var session_key := _resolve_session_key(provider_id, options)
	var existing: Dictionary = _sessions.get(session_key, {})
	if not existing.is_empty():
		var existing_owner_id := String(existing.get("owner_id", ""))
		var existing_provider: Variant = existing.get("provider", null)
		if existing_owner_id != normalized_owner_id:
			return {
				"ok": false,
				"status": STATUS_OWNER_MISMATCH,
				"session": _snapshot_session_record(existing),
			}
		if existing_provider != provider:
			return {
				"ok": false,
				"status": STATUS_SESSION_EXISTS,
				"session": _snapshot_session_record(existing),
			}

	var now_unix := int(Time.get_unix_time_from_system())
	var metadata := _normalize_metadata(options.get("metadata", {}))
	var capabilities := _normalize_capabilities(options.get("capabilities", _infer_capabilities(provider)))
	var borrowers: Dictionary = existing.get("borrowers", {}).duplicate(true) if not existing.is_empty() else {}
	var published_at_unix_time := int(existing.get("published_at_unix_time", now_unix)) if not existing.is_empty() else now_unix

	_sessions[session_key] = {
		"session_key": session_key,
		"provider_id": provider_id,
		"owner_id": normalized_owner_id,
		"provider": provider,
		"metadata": metadata,
		"capabilities": capabilities,
		"borrowers": borrowers,
		"published_at_unix_time": published_at_unix_time,
		"updated_at_unix_time": now_unix,
	}

	return {
		"ok": true,
		"status": STATUS_PUBLISHED,
		"session": _snapshot_session_record(_sessions[session_key]),
	}

## Query for an already-published session without changing borrower state.
##
## Request fields:
## - session_key: exact session to query
## - provider_id: required provider identity when not using session_key
## - owner_id: optional exact owner filter
## - required_capabilities: optional capability list that must all be present
## - metadata_match: optional exact-match subset against published metadata
static func request_session(request: Dictionary = {}) -> Dictionary:
	_prune_invalid_sessions()

	var session := _find_session_record(request)
	if session.is_empty():
		return {
			"ok": false,
			"status": STATUS_MISSING,
		}

	return {
		"ok": true,
		"status": STATUS_AVAILABLE,
		"session": _snapshot_session_record(session),
	}

## Register a borrower against a published session.
##
## Consumers use this when they actually attach to and reuse the shared provider.
## Borrower state is informational ownership bookkeeping only; it does not grant
## stop/unpublish rights and it does not start the provider automatically.
static func acquire_session(consumer_id: String, request: Dictionary = {}) -> Dictionary:
	_prune_invalid_sessions()

	var normalized_consumer_id := String(consumer_id).strip_edges()
	if normalized_consumer_id.is_empty():
		push_error("AeroProviderSessionRegistry: consumer_id is required when acquiring a session")
		return {
			"ok": false,
			"status": STATUS_REQUEST_INVALID,
		}

	var session := _find_session_record(request)
	if session.is_empty():
		return {
			"ok": false,
			"status": STATUS_MISSING,
		}

	var session_key := String(session.get("session_key", ""))
	var live_record: Dictionary = _sessions.get(session_key, {})
	var borrowers: Dictionary = live_record.get("borrowers", {}).duplicate(true)
	var current_count := int(borrowers.get(normalized_consumer_id, 0))
	borrowers[normalized_consumer_id] = current_count + 1
	live_record["borrowers"] = borrowers
	live_record["updated_at_unix_time"] = int(Time.get_unix_time_from_system())
	_sessions[session_key] = live_record

	return {
		"ok": true,
		"status": STATUS_ACQUIRED,
		"session": _snapshot_session_record(live_record),
	}

## Release one borrower reference previously acquired by a consumer.
##
## Releasing a borrower does not stop the provider and does not unpublish the
## session. Those remain owner responsibilities.
static func release_session(consumer_id: String, session_key: String) -> Dictionary:
	_prune_invalid_sessions()

	var normalized_consumer_id := String(consumer_id).strip_edges()
	var normalized_session_key := String(session_key).strip_edges()
	if normalized_consumer_id.is_empty() or normalized_session_key.is_empty():
		push_error("AeroProviderSessionRegistry: consumer_id and session_key are required when releasing a session")
		return {
			"ok": false,
			"status": STATUS_REQUEST_INVALID,
		}

	var live_record: Dictionary = _sessions.get(normalized_session_key, {})
	if live_record.is_empty():
		return {
			"ok": false,
			"status": STATUS_MISSING,
		}

	var borrowers: Dictionary = live_record.get("borrowers", {}).duplicate(true)
	if not borrowers.has(normalized_consumer_id):
		return {
			"ok": false,
			"status": STATUS_CONSUMER_MISMATCH,
			"session": _snapshot_session_record(live_record),
		}

	var next_count := int(borrowers.get(normalized_consumer_id, 0)) - 1
	if next_count > 0:
		borrowers[normalized_consumer_id] = next_count
	else:
		borrowers.erase(normalized_consumer_id)

	live_record["borrowers"] = borrowers
	live_record["updated_at_unix_time"] = int(Time.get_unix_time_from_system())
	_sessions[normalized_session_key] = live_record

	return {
		"ok": true,
		"status": STATUS_RELEASED,
		"session": _snapshot_session_record(live_record),
	}

## Unpublish a session. Only the publishing owner may do this.
static func unpublish_session(owner_id: String, session_key: String) -> Dictionary:
	_prune_invalid_sessions()

	var normalized_owner_id := String(owner_id).strip_edges()
	var normalized_session_key := String(session_key).strip_edges()
	if normalized_owner_id.is_empty() or normalized_session_key.is_empty():
		push_error("AeroProviderSessionRegistry: owner_id and session_key are required when unpublishing a session")
		return {
			"ok": false,
			"status": STATUS_REQUEST_INVALID,
		}

	var live_record: Dictionary = _sessions.get(normalized_session_key, {})
	if live_record.is_empty():
		return {
			"ok": false,
			"status": STATUS_MISSING,
		}

	if String(live_record.get("owner_id", "")) != normalized_owner_id:
		return {
			"ok": false,
			"status": STATUS_OWNER_MISMATCH,
			"session": _snapshot_session_record(live_record),
		}

	var snapshot := _snapshot_session_record(live_record)
	_sessions.erase(normalized_session_key)
	return {
		"ok": true,
		"status": STATUS_UNPUBLISHED,
		"session": snapshot,
	}

## Return a snapshot array of all currently-published sessions.
static func list_sessions() -> Array:
	_prune_invalid_sessions()

	var keys := _sessions.keys()
	keys.sort()

	var result: Array = []
	for key_variant in keys:
		var key := String(key_variant)
		var record: Dictionary = _sessions.get(key, {})
		if record.is_empty():
			continue
		result.append(_snapshot_session_record(record))
	return result

## Test-only escape hatch so repo-local unit tests can reset static state.
static func clear_registry_for_testing() -> void:
	_sessions.clear()

static func _find_session_record(request: Dictionary) -> Dictionary:
	var normalized_request := request.duplicate(true)
	var explicit_session_key := String(normalized_request.get("session_key", "")).strip_edges()
	if not explicit_session_key.is_empty():
		var lookup_keys := _lookup_session_keys(explicit_session_key)
		for candidate_key in lookup_keys:
			var exact_match: Dictionary = _sessions.get(candidate_key, {})
			if not exact_match.is_empty() and _session_matches_request(exact_match, normalized_request):
				return exact_match
		return {}

	var provider_id := _normalize_provider_lookup_id(normalized_request.get("provider_id", ""))
	if provider_id.is_empty():
		return {}

	var candidate_keys := _sessions.keys()
	candidate_keys.sort()
	for key_variant in candidate_keys:
		var key := String(key_variant)
		var record: Dictionary = _sessions.get(key, {})
		if record.is_empty():
			continue
		if _normalize_provider_lookup_id(record.get("provider_id", "")) != provider_id:
			continue
		if _session_matches_request(record, normalized_request):
			return record
	return {}


static func _lookup_session_keys(session_key: String) -> Array[String]:
	var normalized_session_key := String(session_key).strip_edges()
	if normalized_session_key.is_empty():
		return []
	return [normalized_session_key]

static func _normalize_provider_lookup_id(provider_id_variant: Variant) -> String:
	return String(provider_id_variant).strip_edges().to_snake_case()

static func _session_matches_request(record: Dictionary, request: Dictionary) -> bool:
	var owner_filter := String(request.get("owner_id", "")).strip_edges()
	if not owner_filter.is_empty() and String(record.get("owner_id", "")) != owner_filter:
		return false

	var required_capabilities := _normalize_capabilities(request.get("required_capabilities", []))
	if not _record_has_capabilities(record, required_capabilities):
		return false

	var metadata_filter := _normalize_metadata(request.get("metadata_match", {}))
	if not _metadata_matches(record.get("metadata", {}), metadata_filter):
		return false

	return true

static func _record_has_capabilities(record: Dictionary, required_capabilities: Array) -> bool:
	var published_capabilities := _normalize_capabilities(record.get("capabilities", []))
	for capability_variant in required_capabilities:
		var capability_value := int(capability_variant)
		if not published_capabilities.has(capability_value):
			return false
	return true

static func _metadata_matches(record_metadata_variant: Variant, metadata_filter: Dictionary) -> bool:
	if metadata_filter.is_empty():
		return true
	if not (record_metadata_variant is Dictionary):
		return false

	var record_metadata: Dictionary = record_metadata_variant
	for key_variant in metadata_filter.keys():
		var key := String(key_variant)
		if not record_metadata.has(key):
			return false
		if JSON.stringify(record_metadata.get(key, null)) != JSON.stringify(metadata_filter.get(key, null)):
			return false
	return true

static func _snapshot_session_record(record: Dictionary) -> Dictionary:
	var borrowers: Dictionary = record.get("borrowers", {}).duplicate(true)
	return {
		"session_key": String(record.get("session_key", "")),
		"provider_id": String(record.get("provider_id", "")),
		"owner_id": String(record.get("owner_id", "")),
		"provider": record.get("provider", null),
		"metadata": _normalize_metadata(record.get("metadata", {})),
		"capabilities": _normalize_capabilities(record.get("capabilities", [])),
		"borrowers": borrowers,
		"borrower_count": _borrower_total(borrowers),
		"published_at_unix_time": int(record.get("published_at_unix_time", 0)),
		"updated_at_unix_time": int(record.get("updated_at_unix_time", 0)),
	}

static func _borrower_total(borrowers: Dictionary) -> int:
	var total := 0
	for count_variant in borrowers.values():
		total += int(count_variant)
	return total

static func _resolve_provider_id(provider: AeroInputProvider, options: Dictionary) -> String:
	var explicit_provider_id := String(options.get("provider_id", "")).strip_edges().to_snake_case()
	if not explicit_provider_id.is_empty():
		return explicit_provider_id
	return String(provider.get_provider_id()).strip_edges().to_snake_case()

static func _resolve_session_key(provider_id: String, options: Dictionary) -> String:
	var explicit_session_key := String(options.get("session_key", "")).strip_edges()
	if not explicit_session_key.is_empty():
		return explicit_session_key
	return provider_id

static func _normalize_metadata(raw_metadata: Variant) -> Dictionary:
	if raw_metadata is Dictionary:
		return raw_metadata.duplicate(true)
	return {}

static func _normalize_capabilities(raw_capabilities: Variant) -> Array:
	var normalized: Array = []
	if raw_capabilities is Array:
		for capability_variant in raw_capabilities:
			var capability_value := int(capability_variant)
			if not normalized.has(capability_value):
				normalized.append(capability_value)
	return normalized

static func _infer_capabilities(provider: AeroInputProvider) -> Array:
	var inferred: Array = []
	for capability_variant in _KNOWN_CAPABILITIES:
		var capability_value := int(capability_variant)
		if provider.has_capability(capability_value):
			inferred.append(capability_value)
	return inferred

static func _prune_invalid_sessions() -> void:
	var stale_keys: Array[String] = []
	for key_variant in _sessions.keys():
		var key := String(key_variant)
		var record: Dictionary = _sessions.get(key, {})
		var provider: Variant = record.get("provider", null)
		if provider == null or not is_instance_valid(provider):
			stale_keys.append(key)

	for stale_key in stale_keys:
		_sessions.erase(stale_key)
