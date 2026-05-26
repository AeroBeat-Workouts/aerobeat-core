extends "res://addons/gut/test.gd"

func test_ui_interaction_types_keep_canonical_phase_only_contract_values_stable() -> void:
	assert_true(AeroUiInteractionTypes.PHASES.has(&"hover_enter"))
	assert_true(AeroUiInteractionTypes.PHASES.has(&"press_begin"))
	assert_true(AeroUiInteractionTypes.PHASES.has(&"drag_move"))
	assert_true(AeroUiInteractionTypes.PHASES.has(&"press_end"))
	assert_false(AeroUiInteractionTypes.PHASES.has(&"tap"), "Tap should stay helper-derived, not canonical core phase")

func test_ui_interaction_event_ignores_action_key_and_keeps_phase_as_canonical_field() -> void:
	var event: AeroUiInteractionEvent = AeroUiInteractionEvent.create({
		"phase": AeroUiInteractionTypes.PHASE_PRESS_BEGIN,
		"action": &"tap",
		"pointer_id": &"mouse_0"
	})

	var event_dict: Dictionary = event.to_dictionary()
	assert_eq(event.phase, AeroUiInteractionTypes.PHASE_PRESS_BEGIN)
	assert_false(event_dict.has("action"))
	assert_eq(event.pointer_id, &"mouse_0")

func test_ui_interaction_bus_applies_truthful_verification_defaults() -> void:
	var bus: AeroUiInteractionBus = autofree(AeroUiInteractionBus.new())
	var mouse_event: AeroUiInteractionEvent = bus.publish({
		"pointer_id": &"mouse_0",
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
		"surface_type": AeroUiInteractionTypes.SURFACE_TYPE_SCREEN_2D,
		"phase": AeroUiInteractionTypes.PHASE_PRESS_BEGIN
	})
	assert_eq(mouse_event.verification_status, AeroUiVerificationStatus.PROTOTYPE)

	var xr_event: AeroUiInteractionEvent = bus.publish({
		"pointer_id": &"xr_right",
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_XR_RAY,
		"surface_type": AeroUiInteractionTypes.SURFACE_TYPE_WORLD_3D,
		"phase": AeroUiInteractionTypes.PHASE_PRESS_BEGIN
	})
	assert_eq(xr_event.verification_status, AeroUiVerificationStatus.UNVERIFIED)
	assert_string_contains(xr_event.verification_notes, "not yet validated")

func test_ui_interaction_listener_derives_tapped_without_core_tap_phase() -> void:
	var root: Node = add_child_autoqfree(Node.new())
	var bus: AeroUiInteractionBus = autofree(AeroUiInteractionBus.new())
	bus.name = "Bus"
	root.add_child(bus)
	var listener: AeroUiInteractionListener = autofree(AeroUiInteractionListener.new())
	listener.bus_path = NodePath("../Bus")
	listener.surface_id_filter = &"screen_ui"
	root.add_child(listener)

	await wait_process_frames(1)

	watch_signals(listener)
	bus.publish({
		"pointer_id": &"mouse_0",
		"surface_id": &"screen_ui",
		"surface_type": AeroUiInteractionTypes.SURFACE_TYPE_SCREEN_2D,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
		"phase": AeroUiInteractionTypes.PHASE_PRESS_BEGIN
	})
	bus.publish({
		"pointer_id": &"mouse_0",
		"surface_id": &"screen_ui",
		"surface_type": AeroUiInteractionTypes.SURFACE_TYPE_SCREEN_2D,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
		"phase": AeroUiInteractionTypes.PHASE_PRESS_END
	})

	assert_signal_emitted(listener, "tapped")
	assert_signal_emit_count(listener, "tapped", 1)

func test_screen_ui_input_adapter_publishes_press_and_drag_phases_for_mouse() -> void:
	var root: Node = add_child_autoqfree(Node.new())
	var bus: AeroUiInteractionBus = autofree(AeroUiInteractionBus.new())
	bus.name = "Bus"
	root.add_child(bus)
	var adapter: ScreenUiInputAdapter = autofree(ScreenUiInputAdapter.new())
	adapter.bus_path = NodePath("../Bus")
	adapter.drag_threshold_pixels = 4.0
	root.add_child(adapter)

	await wait_process_frames(1)

	var phases: Array[StringName] = []
	bus.interaction_event.connect(func(event: AeroUiInteractionEvent): phases.append(event.phase))

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(10, 10)
	assert_true(adapter.publish_input_event(press))

	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(20, 10)
	motion.relative = Vector2(10, 0)
	assert_true(adapter.publish_input_event(motion))

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(20, 10)
	assert_true(adapter.publish_input_event(release))

	assert_eq(phases, [
		AeroUiInteractionTypes.PHASE_PRESS_BEGIN,
		AeroUiInteractionTypes.PHASE_DRAG_BEGIN,
		AeroUiInteractionTypes.PHASE_DRAG_END,
		AeroUiInteractionTypes.PHASE_PRESS_END
	])

func test_screen_ui_input_adapter_clears_hover_when_host_explicitly_transitions_target_to_none() -> void:
	var root: Control = add_child_autoqfree(Control.new())
	root.size = Vector2(400, 300)

	var bus: AeroUiInteractionBus = autofree(AeroUiInteractionBus.new())
	bus.name = "Bus"
	root.add_child(bus)

	var target := Control.new()
	target.position = Vector2(20, 20)
	target.size = Vector2(120, 48)
	root.add_child(target)

	var adapter: ScreenUiInputAdapter = autofree(ScreenUiInputAdapter.new())
	adapter.bus_path = NodePath("../../Bus")
	target.add_child(adapter)

	await wait_process_frames(1)

	var phases: Array[StringName] = []
	var target_paths: Array[NodePath] = []
	bus.interaction_event.connect(func(event: AeroUiInteractionEvent):
		phases.append(event.phase)
		target_paths.append(event.target_path)
	)

	var hover_inside := InputEventMouseMotion.new()
	hover_inside.position = Vector2(40, 32)
	hover_inside.relative = Vector2.ZERO
	assert_true(adapter.publish_input_event(
		hover_inside,
		target.get_path(),
		{"respect_empty_target_path": true}
	))

	var hover_outside := InputEventMouseMotion.new()
	hover_outside.position = Vector2(220, 180)
	hover_outside.relative = Vector2(180, 148)
	assert_true(adapter.publish_input_event(
		hover_outside,
		NodePath(),
		{"respect_empty_target_path": true, "inside_window_exit": true}
	))

	assert_eq(phases, [
		AeroUiInteractionTypes.PHASE_HOVER_ENTER,
		AeroUiInteractionTypes.PHASE_HOVER_EXIT,
	])
	assert_eq(target_paths, [
		target.get_path(),
		target.get_path(),
	])
	assert_false(bool(adapter._pointer_states[adapter._hover_pointer_id].get("hovering", true)))
	assert_eq(adapter._pointer_states[adapter._hover_pointer_id].get("hover_target_path", target.get_path()), NodePath())

func test_screen_ui_input_adapter_preserves_mouse_press_owner_on_off_target_release() -> void:
	var root: Control = add_child_autoqfree(Control.new())
	root.size = Vector2(400, 300)

	var bus: AeroUiInteractionBus = autofree(AeroUiInteractionBus.new())
	bus.name = "Bus"
	root.add_child(bus)

	var target := Control.new()
	target.position = Vector2(20, 20)
	target.size = Vector2(120, 48)
	root.add_child(target)

	var adapter: ScreenUiInputAdapter = autofree(ScreenUiInputAdapter.new())
	adapter.bus_path = NodePath("../../Bus")
	target.add_child(adapter)

	await wait_process_frames(1)

	var events: Array[AeroUiInteractionEvent] = []
	bus.interaction_event.connect(func(event: AeroUiInteractionEvent): events.append(event))

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(40, 32)
	assert_true(adapter.publish_input_event(
		press,
		target.get_path(),
		{"respect_empty_target_path": true, "target_resolution": "native_control_bridge"}
	))

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(220, 180)
	assert_true(adapter.publish_input_event(
		release,
		NodePath(),
		{"respect_empty_target_path": true, "inside_window_exit": true, "target_resolution": "native_control_bridge"}
	))

	assert_eq(events.size(), 2)
	assert_eq(events[0].phase, AeroUiInteractionTypes.PHASE_PRESS_BEGIN)
	assert_eq(events[0].target_path, target.get_path())
	assert_eq(events[1].phase, AeroUiInteractionTypes.PHASE_PRESS_END)
	assert_eq(events[1].target_path, target.get_path())
	assert_true(bool(events[1].raw_metadata.get("off_surface_continuation", false)))
	assert_eq(str(events[1].raw_metadata.get("published_target_path", "")), str(target.get_path()))
	assert_eq(str(events[1].raw_metadata.get("owner_target_path", "")), str(target.get_path()))
	assert_eq(adapter._pointer_states[adapter._hover_pointer_id].get("owner_target_path", target.get_path()), NodePath())

func test_screen_ui_input_adapter_preserves_touch_press_owner_on_off_target_release() -> void:
	var root: Control = add_child_autoqfree(Control.new())
	root.size = Vector2(400, 300)

	var bus: AeroUiInteractionBus = autofree(AeroUiInteractionBus.new())
	bus.name = "Bus"
	root.add_child(bus)

	var target := Control.new()
	target.position = Vector2(20, 20)
	target.size = Vector2(120, 48)
	root.add_child(target)

	var adapter: ScreenUiInputAdapter = autofree(ScreenUiInputAdapter.new())
	adapter.bus_path = NodePath("../../Bus")
	target.add_child(adapter)

	await wait_process_frames(1)

	var events: Array[AeroUiInteractionEvent] = []
	bus.interaction_event.connect(func(event: AeroUiInteractionEvent): events.append(event))

	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = Vector2(40, 32)
	assert_true(adapter.publish_input_event(
		press,
		target.get_path(),
		{"respect_empty_target_path": true, "target_resolution": "native_control_bridge"}
	))

	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = Vector2(220, 180)
	assert_true(adapter.publish_input_event(
		release,
		NodePath(),
		{"respect_empty_target_path": true, "inside_window_exit": true, "target_resolution": "native_control_bridge"}
	))

	assert_eq(events.size(), 2)
	assert_eq(events[0].phase, AeroUiInteractionTypes.PHASE_PRESS_BEGIN)
	assert_eq(events[0].target_path, target.get_path())
	assert_eq(events[1].phase, AeroUiInteractionTypes.PHASE_PRESS_END)
	assert_eq(events[1].target_path, target.get_path())
	assert_true(bool(events[1].raw_metadata.get("off_surface_continuation", false)))
	assert_eq(str(events[1].raw_metadata.get("published_target_path", "")), str(target.get_path()))
	assert_eq(str(events[1].raw_metadata.get("owner_target_path", "")), str(target.get_path()))

func test_hybrid_and_xr_adapters_keep_future_ready_surface_and_source_shapes() -> void:
	var root: Node = add_child_autoqfree(Node.new())
	var bus: AeroUiInteractionBus = autofree(AeroUiInteractionBus.new())
	bus.name = "Bus"
	root.add_child(bus)

	var hybrid: HybridSubViewportInputAdapter = autofree(HybridSubViewportInputAdapter.new())
	hybrid.bus_path = NodePath("../Bus")
	hybrid.surface_id = &"panel_a"
	hybrid.surface_pixel_size = Vector2(400, 200)
	root.add_child(hybrid)

	var xr: XrUiInputAdapter = autofree(XrUiInputAdapter.new())
	xr.bus_path = NodePath("../Bus")
	xr.surface_id = &"panel_b"
	root.add_child(xr)

	await wait_process_frames(1)

	var hybrid_event: AeroUiInteractionEvent = hybrid.publish_projected_phase(
		AeroUiInteractionTypes.PHASE_PRESS_BEGIN,
		&"mouse_0",
		{
			"surface_normalized_position": Vector2(0.25, 0.5),
			"world_position": Vector3(1, 2, 3)
		},
		{
			"source_type": AeroUiInteractionTypes.SOURCE_TYPE_MOUSE,
			"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE
		}
	)
	assert_eq(hybrid_event.surface_type, AeroUiInteractionTypes.SURFACE_TYPE_HYBRID_3D_GUI)
	assert_eq(hybrid_event.surface_position, Vector2(100, 100))
	assert_eq(hybrid_event.verification_status, AeroUiVerificationStatus.PROTOTYPE)

	var xr_event: AeroUiInteractionEvent = xr.publish_pointer_phase(
		&"xr_right",
		AeroUiInteractionTypes.PHASE_PRESS_BEGIN,
		{
			"surface_position": Vector2(32, 48),
			"surface_normalized_position": Vector2(0.1, 0.2),
			"world_position": Vector3(0, 1, 2),
			"world_direction": Vector3.FORWARD
		}
	)
	assert_eq(xr_event.source_type, AeroUiInteractionTypes.SOURCE_TYPE_XR)
	assert_eq(xr_event.source_variant, AeroUiInteractionTypes.SOURCE_VARIANT_XR_RAY)
	assert_eq(xr_event.surface_type, AeroUiInteractionTypes.SURFACE_TYPE_WORLD_3D)
	assert_eq(xr_event.verification_status, AeroUiVerificationStatus.UNVERIFIED)
