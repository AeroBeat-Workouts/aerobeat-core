class_name ScreenUiInputAdapter
extends Node
## Normalizes standard screen-space mouse/touch input into AeroUiInteractionEvent.
##
## This adapter is intentionally minimal v1 scaffolding: it publishes canonical
## pointer phases and surface metadata without forcing downstream UI scenes to
## parse raw InputEvent classes directly.

@export var bus_path: NodePath
@export var surface_id: StringName = &"screen_ui"
@export var surface_type: StringName = AeroUiInteractionTypes.SURFACE_TYPE_SCREEN_2D
@export var drag_threshold_pixels: float = 12.0
@export var emit_hover_events: bool = true

var _pointer_states: Dictionary = {}
var _hover_pointer_id: StringName = &"mouse_0"

func _ready() -> void:
	var bus := get_interaction_bus()
	if bus != null:
		bus.register_surface(surface_id, {"surface_type": surface_type})

func _exit_tree() -> void:
	var bus := get_interaction_bus()
	if bus != null:
		bus.unregister_surface(surface_id)

func _input(event: InputEvent) -> void:
	publish_input_event(event)

func publish_input_event(
	event: InputEvent,
	target_path: NodePath = NodePath(),
	extra_metadata: Dictionary = {}
) -> bool:
	if event is InputEventMouseButton:
		return _publish_mouse_button_event(event, target_path, extra_metadata)
	if event is InputEventMouseMotion:
		return _publish_mouse_motion_event(event, target_path, extra_metadata)
	if event is InputEventScreenTouch:
		return _publish_touch_event(event, target_path, extra_metadata)
	if event is InputEventScreenDrag:
		return _publish_touch_drag_event(event, target_path, extra_metadata)
	return false

func get_interaction_bus() -> AeroUiInteractionBus:
	if bus_path == NodePath():
		return null
	return get_node_or_null(bus_path) as AeroUiInteractionBus

func _publish_mouse_button_event(
	event: InputEventMouseButton,
	target_path: NodePath,
	extra_metadata: Dictionary
) -> bool:
	if event.button_index != MOUSE_BUTTON_LEFT \
	and event.button_index != MOUSE_BUTTON_RIGHT \
	and event.button_index != MOUSE_BUTTON_MIDDLE:
		return false

	var pointer_id: StringName = _hover_pointer_id
	var state: Dictionary = _ensure_pointer_state(pointer_id)
	var resolved_target_path := _resolve_target_path(target_path, extra_metadata)
	var screen_position: Vector2 = event.position
	var surface_position: Vector2 = _resolve_surface_position(screen_position)
	var normalized_surface_position: Vector2 = _resolve_surface_normalized_position(surface_position)
	var button := AeroUiInteractionTypes.normalize_mouse_button(event.button_index)
	var modifiers := _modifiers_for_event(event)

	state["last_screen_position"] = screen_position
	state["last_surface_position"] = surface_position
	state["source_type"] = AeroUiInteractionTypes.SOURCE_TYPE_MOUSE
	state["source_variant"] = AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE
	state["button"] = button

	if event.pressed:
		state["pressed"] = true
		state["dragging"] = false
		state["press_screen_position"] = screen_position
		state["press_surface_position"] = surface_position
		state["click_count"] = 2 if event.double_click else 1
		state["owner_target_path"] = resolved_target_path
		state["target_path"] = resolved_target_path
		_publish_event({
			"pointer_id": pointer_id,
			"source_type": AeroUiInteractionTypes.SOURCE_TYPE_MOUSE,
			"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
			"surface_type": surface_type,
			"surface_id": surface_id,
			"phase": AeroUiInteractionTypes.PHASE_PRESS_BEGIN,
			"target_path": resolved_target_path,
			"screen_position": screen_position,
			"surface_position": surface_position,
			"surface_normalized_position": normalized_surface_position,
			"primary": button == AeroUiInteractionTypes.BUTTON_PRIMARY,
			"pressed": true,
			"button": button,
			"contact_count": 1,
			"pressure": 1.0,
			"click_count": state["click_count"],
			"modifiers": modifiers,
			"raw_event_class": &"InputEventMouseButton",
			"raw_metadata": _merge_raw_metadata(extra_metadata, {
				"button_index": event.button_index,
				"published_target_path": str(resolved_target_path),
				"owner_target_path": str(state.get("owner_target_path", NodePath())),
				"hover_target_path": str(state.get("hover_target_path", NodePath())),
			})
		})
		return true

	var owner_target_path: NodePath = state.get("owner_target_path", NodePath())
	var published_target_path: NodePath = owner_target_path if owner_target_path != NodePath() else resolved_target_path
	state["target_path"] = published_target_path

	if bool(state.get("dragging", false)):
		_publish_event({
			"pointer_id": pointer_id,
			"source_type": AeroUiInteractionTypes.SOURCE_TYPE_MOUSE,
			"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
			"surface_type": surface_type,
			"surface_id": surface_id,
			"phase": AeroUiInteractionTypes.PHASE_DRAG_END,
			"target_path": published_target_path,
			"screen_position": screen_position,
			"surface_position": surface_position,
			"surface_normalized_position": normalized_surface_position,
			"primary": button == AeroUiInteractionTypes.BUTTON_PRIMARY,
			"pressed": false,
			"button": button,
			"contact_count": 0,
			"pressure": 0.0,
			"modifiers": modifiers,
			"raw_event_class": &"InputEventMouseButton",
			"raw_metadata": _merge_raw_metadata(extra_metadata, {
				"button_index": event.button_index,
				"published_target_path": str(published_target_path),
				"owner_target_path": str(owner_target_path),
				"hover_target_path": str(state.get("hover_target_path", NodePath())),
			})
		})

	state["pressed"] = false
	state["dragging"] = false
	state["owner_target_path"] = NodePath()
	_publish_event({
		"pointer_id": pointer_id,
		"source_type": AeroUiInteractionTypes.SOURCE_TYPE_MOUSE,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
		"surface_type": surface_type,
		"surface_id": surface_id,
		"phase": AeroUiInteractionTypes.PHASE_PRESS_END,
		"target_path": published_target_path,
		"screen_position": screen_position,
		"surface_position": surface_position,
		"surface_normalized_position": normalized_surface_position,
		"primary": button == AeroUiInteractionTypes.BUTTON_PRIMARY,
		"pressed": false,
		"button": button,
		"contact_count": 0,
		"pressure": 0.0,
		"click_count": int(state.get("click_count", 0)),
		"modifiers": modifiers,
		"raw_event_class": &"InputEventMouseButton",
		"raw_metadata": _merge_raw_metadata(extra_metadata, {
			"button_index": event.button_index,
			"published_target_path": str(published_target_path),
			"owner_target_path": str(owner_target_path),
			"hover_target_path": str(state.get("hover_target_path", NodePath())),
			"off_surface_continuation": resolved_target_path == NodePath() and owner_target_path != NodePath(),
		})
	})
	return true

func _publish_mouse_motion_event(
	event: InputEventMouseMotion,
	target_path: NodePath,
	extra_metadata: Dictionary
) -> bool:
	var pointer_id: StringName = _hover_pointer_id
	var state: Dictionary = _ensure_pointer_state(pointer_id)
	var resolved_target_path := _resolve_target_path(target_path, extra_metadata)
	var screen_position: Vector2 = event.position
	var surface_position: Vector2 = _resolve_surface_position(screen_position)
	var normalized_surface_position: Vector2 = _resolve_surface_normalized_position(surface_position)
	var delta: Vector2 = event.relative
	var is_pressed: bool = bool(state.get("pressed", false))
	var phase: StringName = AeroUiInteractionTypes.PHASE_HOVER_MOVE

	state["last_screen_position"] = screen_position
	state["last_surface_position"] = surface_position

	if is_pressed:
		var owner_target_path: NodePath = state.get("owner_target_path", NodePath())
		var published_target_path: NodePath = owner_target_path if owner_target_path != NodePath() else resolved_target_path
		var drag_distance := screen_position.distance_to(state.get("press_screen_position", screen_position))
		if bool(state.get("dragging", false)):
			phase = AeroUiInteractionTypes.PHASE_DRAG_MOVE
		elif drag_distance >= drag_threshold_pixels:
			state["dragging"] = true
			phase = AeroUiInteractionTypes.PHASE_DRAG_BEGIN
		else:
			phase = AeroUiInteractionTypes.PHASE_PRESS_HOLD

		state["target_path"] = published_target_path
		_publish_event({
			"pointer_id": pointer_id,
			"source_type": AeroUiInteractionTypes.SOURCE_TYPE_MOUSE,
			"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
			"surface_type": surface_type,
			"surface_id": surface_id,
			"phase": phase,
			"target_path": published_target_path,
			"screen_position": screen_position,
			"surface_position": surface_position,
			"surface_normalized_position": normalized_surface_position,
			"primary": true,
			"pressed": true,
			"button": StringName(state.get("button", AeroUiInteractionTypes.BUTTON_PRIMARY)),
			"contact_count": 1,
			"pressure": 1.0,
			"delta": delta,
			"velocity": delta,
			"modifiers": _modifiers_for_event(event),
			"raw_event_class": &"InputEventMouseMotion",
			"raw_metadata": _merge_raw_metadata(extra_metadata, {
				"published_target_path": str(published_target_path),
				"owner_target_path": str(owner_target_path),
				"hover_target_path": str(resolved_target_path),
				"off_surface_continuation": resolved_target_path == NodePath() and owner_target_path != NodePath(),
			})
		})
		return true
	elif emit_hover_events:
		return _publish_mouse_hover_transition(
			pointer_id,
			state,
			resolved_target_path,
			screen_position,
			surface_position,
			normalized_surface_position,
			delta,
			extra_metadata,
			event
		)
	else:
		return false

func _publish_touch_event(
	event: InputEventScreenTouch,
	target_path: NodePath,
	extra_metadata: Dictionary
) -> bool:
	var pointer_id := StringName("touch_%s" % event.index)
	var state: Dictionary = _ensure_pointer_state(pointer_id)
	var resolved_target_path := _resolve_target_path(target_path, extra_metadata)
	var screen_position: Vector2 = event.position
	var surface_position: Vector2 = _resolve_surface_position(screen_position)
	var normalized_surface_position: Vector2 = _resolve_surface_normalized_position(surface_position)

	state["last_screen_position"] = screen_position
	state["last_surface_position"] = surface_position
	state["press_screen_position"] = screen_position
	state["press_surface_position"] = surface_position
	state["source_type"] = AeroUiInteractionTypes.SOURCE_TYPE_TOUCH
	state["source_variant"] = AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH
	state["button"] = AeroUiInteractionTypes.BUTTON_CONTACT

	if event.pressed:
		state["pressed"] = true
		state["dragging"] = false
		state["owner_target_path"] = resolved_target_path
		state["target_path"] = resolved_target_path
		_publish_event({
			"pointer_id": pointer_id,
			"source_type": AeroUiInteractionTypes.SOURCE_TYPE_TOUCH,
			"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH,
			"surface_type": surface_type,
			"surface_id": surface_id,
			"phase": AeroUiInteractionTypes.PHASE_PRESS_BEGIN,
			"target_path": resolved_target_path,
			"screen_position": screen_position,
			"surface_position": surface_position,
			"surface_normalized_position": normalized_surface_position,
			"primary": event.index == 0,
			"pressed": true,
			"button": AeroUiInteractionTypes.BUTTON_CONTACT,
			"contact_count": 1,
			"pressure": 1.0,
			"raw_event_class": &"InputEventScreenTouch",
			"raw_metadata": _merge_raw_metadata(extra_metadata, {
				"index": event.index,
				"published_target_path": str(resolved_target_path),
				"owner_target_path": str(state.get("owner_target_path", NodePath())),
				"hover_target_path": str(resolved_target_path),
			})
		})
		return true

	var owner_target_path: NodePath = state.get("owner_target_path", NodePath())
	var published_target_path: NodePath = owner_target_path if owner_target_path != NodePath() else resolved_target_path
	state["target_path"] = published_target_path

	if bool(state.get("dragging", false)):
		_publish_event({
			"pointer_id": pointer_id,
			"source_type": AeroUiInteractionTypes.SOURCE_TYPE_TOUCH,
			"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH,
			"surface_type": surface_type,
			"surface_id": surface_id,
			"phase": AeroUiInteractionTypes.PHASE_DRAG_END,
			"target_path": published_target_path,
			"screen_position": screen_position,
			"surface_position": surface_position,
			"surface_normalized_position": normalized_surface_position,
			"primary": event.index == 0,
			"pressed": false,
			"button": AeroUiInteractionTypes.BUTTON_CONTACT,
			"contact_count": 0,
			"pressure": 0.0,
			"raw_event_class": &"InputEventScreenTouch",
			"raw_metadata": _merge_raw_metadata(extra_metadata, {
				"index": event.index,
				"published_target_path": str(published_target_path),
				"owner_target_path": str(owner_target_path),
				"hover_target_path": str(resolved_target_path),
			})
		})

	state["pressed"] = false
	state["dragging"] = false
	state["owner_target_path"] = NodePath()
	_publish_event({
		"pointer_id": pointer_id,
		"source_type": AeroUiInteractionTypes.SOURCE_TYPE_TOUCH,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH,
		"surface_type": surface_type,
		"surface_id": surface_id,
		"phase": AeroUiInteractionTypes.PHASE_PRESS_END,
		"target_path": published_target_path,
		"screen_position": screen_position,
		"surface_position": surface_position,
		"surface_normalized_position": normalized_surface_position,
		"primary": event.index == 0,
		"pressed": false,
		"button": AeroUiInteractionTypes.BUTTON_CONTACT,
		"contact_count": 0,
		"pressure": 0.0,
		"raw_event_class": &"InputEventScreenTouch",
		"raw_metadata": _merge_raw_metadata(extra_metadata, {
			"index": event.index,
			"published_target_path": str(published_target_path),
			"owner_target_path": str(owner_target_path),
			"hover_target_path": str(resolved_target_path),
			"off_surface_continuation": resolved_target_path == NodePath() and owner_target_path != NodePath(),
		})
	})
	return true

func _publish_touch_drag_event(
	event: InputEventScreenDrag,
	target_path: NodePath,
	extra_metadata: Dictionary
) -> bool:
	var pointer_id := StringName("touch_%s" % event.index)
	var state: Dictionary = _ensure_pointer_state(pointer_id)
	var resolved_target_path := _resolve_target_path(target_path, extra_metadata)
	var owner_target_path: NodePath = state.get("owner_target_path", NodePath())
	var published_target_path: NodePath = owner_target_path if owner_target_path != NodePath() else resolved_target_path
	var screen_position: Vector2 = event.position
	var surface_position: Vector2 = _resolve_surface_position(screen_position)
	var normalized_surface_position: Vector2 = _resolve_surface_normalized_position(surface_position)
	var drag_distance := screen_position.distance_to(state.get("press_screen_position", screen_position))
	var phase: StringName = AeroUiInteractionTypes.PHASE_PRESS_HOLD

	if bool(state.get("dragging", false)):
		phase = AeroUiInteractionTypes.PHASE_DRAG_MOVE
	elif drag_distance >= drag_threshold_pixels:
		state["dragging"] = true
		phase = AeroUiInteractionTypes.PHASE_DRAG_BEGIN

	state["last_screen_position"] = screen_position
	state["last_surface_position"] = surface_position
	state["target_path"] = published_target_path
	_publish_event({
		"pointer_id": pointer_id,
		"source_type": AeroUiInteractionTypes.SOURCE_TYPE_TOUCH,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH,
		"surface_type": surface_type,
		"surface_id": surface_id,
		"phase": phase,
		"target_path": published_target_path,
		"screen_position": screen_position,
		"surface_position": surface_position,
		"surface_normalized_position": normalized_surface_position,
		"primary": event.index == 0,
		"pressed": true,
		"button": AeroUiInteractionTypes.BUTTON_CONTACT,
		"contact_count": 1,
		"pressure": maxf(event.pressure, 1.0),
		"delta": event.relative,
		"velocity": event.velocity,
		"raw_event_class": &"InputEventScreenDrag",
		"raw_metadata": _merge_raw_metadata(extra_metadata, {
			"index": event.index,
			"published_target_path": str(published_target_path),
			"owner_target_path": str(owner_target_path),
			"hover_target_path": str(resolved_target_path),
			"off_surface_continuation": resolved_target_path == NodePath() and owner_target_path != NodePath(),
		})
	})
	return true

func _publish_mouse_hover_transition(
	pointer_id: StringName,
	state: Dictionary,
	resolved_target_path: NodePath,
	screen_position: Vector2,
	surface_position: Vector2,
	normalized_surface_position: Vector2,
	delta: Vector2,
	extra_metadata: Dictionary,
	event: InputEventMouseMotion
) -> bool:
	var previous_target_path: NodePath = state.get("hover_target_path", NodePath())
	var next_target_path: NodePath = _resolve_hover_target_path(resolved_target_path, surface_position)
	state["hover_target_path"] = next_target_path
	state["hovering"] = next_target_path != NodePath()
	state["target_path"] = next_target_path

	if previous_target_path != next_target_path:
		if previous_target_path != NodePath():
			_publish_mouse_hover_phase(
				AeroUiInteractionTypes.PHASE_HOVER_EXIT,
				pointer_id,
				state,
				previous_target_path,
				screen_position,
				surface_position,
				normalized_surface_position,
				delta,
				extra_metadata,
				event
			)
		if next_target_path != NodePath():
			_publish_mouse_hover_phase(
				AeroUiInteractionTypes.PHASE_HOVER_ENTER,
				pointer_id,
				state,
				next_target_path,
				screen_position,
				surface_position,
				normalized_surface_position,
				delta,
				extra_metadata,
				event
			)
		return previous_target_path != NodePath() or next_target_path != NodePath()

	if next_target_path == NodePath():
		return false

	_publish_mouse_hover_phase(
		AeroUiInteractionTypes.PHASE_HOVER_MOVE,
		pointer_id,
		state,
		next_target_path,
		screen_position,
		surface_position,
		normalized_surface_position,
		delta,
		extra_metadata,
		event
	)
	return true

func _publish_mouse_hover_phase(
	phase: StringName,
	pointer_id: StringName,
	state: Dictionary,
	target_path: NodePath,
	screen_position: Vector2,
	surface_position: Vector2,
	normalized_surface_position: Vector2,
	delta: Vector2,
	extra_metadata: Dictionary,
	event: InputEventMouseMotion
) -> AeroUiInteractionEvent:
	return _publish_event({
		"pointer_id": pointer_id,
		"source_type": AeroUiInteractionTypes.SOURCE_TYPE_MOUSE,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
		"surface_type": surface_type,
		"surface_id": surface_id,
		"phase": phase,
		"target_path": target_path,
		"screen_position": screen_position,
		"surface_position": surface_position,
		"surface_normalized_position": normalized_surface_position,
		"primary": true,
		"pressed": false,
		"button": StringName(state.get("button", AeroUiInteractionTypes.BUTTON_PRIMARY)),
		"contact_count": 0,
		"pressure": 0.0,
		"delta": delta,
		"velocity": delta,
		"modifiers": _modifiers_for_event(event),
		"raw_event_class": &"InputEventMouseMotion",
		"raw_metadata": _merge_raw_metadata(extra_metadata, {
			"hover_target_path": str(state.get("hover_target_path", NodePath())),
			"published_target_path": str(target_path),
			"owner_target_path": str(state.get("owner_target_path", NodePath())),
		})
	})

func _resolve_hover_target_path(resolved_target_path: NodePath, surface_position: Vector2) -> NodePath:
	if resolved_target_path == NodePath():
		return NodePath()
	if not _is_inside_surface(surface_position):
		return NodePath()
	return resolved_target_path

func _publish_event(event_data: Dictionary) -> AeroUiInteractionEvent:
	var bus := get_interaction_bus()
	if bus == null:
		return AeroUiInteractionEvent.create(event_data)
	return bus.publish(event_data)

func _ensure_pointer_state(pointer_id: StringName) -> Dictionary:
	if not _pointer_states.has(pointer_id):
		_pointer_states[pointer_id] = {
			"pressed": false,
			"dragging": false,
			"hovering": false,
			"hover_target_path": NodePath(),
			"owner_target_path": NodePath(),
			"click_count": 0,
			"button": AeroUiInteractionTypes.BUTTON_PRIMARY,
			"press_screen_position": Vector2.ZERO,
			"press_surface_position": Vector2.ZERO,
			"last_screen_position": Vector2.ZERO,
			"last_surface_position": Vector2.ZERO,
			"target_path": NodePath()
		}
	return _pointer_states[pointer_id]

func _resolve_target_path(explicit_target_path: NodePath, extra_metadata: Dictionary = {}) -> NodePath:
	if explicit_target_path != NodePath() or bool(extra_metadata.get("respect_empty_target_path", false)):
		return explicit_target_path
	var viewport := get_viewport()
	if viewport != null:
		var hovered := viewport.gui_get_hovered_control()
		if hovered != null:
			return hovered.get_path()
	return NodePath()

func _resolve_surface_control() -> Control:
	if get_parent() is Control:
		return get_parent() as Control
	return null

func _resolve_surface_position(screen_position: Vector2) -> Vector2:
	var control := _resolve_surface_control()
	if control == null:
		return screen_position
	return control.get_global_transform_with_canvas().affine_inverse() * screen_position

func _resolve_surface_normalized_position(surface_position: Vector2) -> Vector2:
	var control := _resolve_surface_control()
	if control == null:
		return surface_position
	if is_zero_approx(control.size.x) or is_zero_approx(control.size.y):
		return Vector2.ZERO
	return Vector2(
		clampf(surface_position.x / control.size.x, 0.0, 1.0),
		clampf(surface_position.y / control.size.y, 0.0, 1.0)
	)

func _is_inside_surface(surface_position: Vector2) -> bool:
	var control := _resolve_surface_control()
	if control == null:
		return true
	return Rect2(Vector2.ZERO, control.size).has_point(surface_position)

func _modifiers_for_event(event: InputEventWithModifiers) -> PackedStringArray:
	var modifiers := PackedStringArray()
	if event.alt_pressed:
		modifiers.append("alt")
	if event.ctrl_pressed:
		modifiers.append("ctrl")
	if event.meta_pressed:
		modifiers.append("meta")
	if event.shift_pressed:
		modifiers.append("shift")
	return modifiers

func _merge_raw_metadata(extra_metadata: Dictionary, event_metadata: Dictionary) -> Dictionary:
	var merged := extra_metadata.duplicate(true)
	for key in event_metadata.keys():
		merged[key] = event_metadata[key]
	return merged
