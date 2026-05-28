extends Node2D
## Test scene for AeroBeat Input Core.
## Verifies that the shared contracts load and communicates the current camera-first, intent-first v1 framing.

@onready var status_label: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var class_list: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/ClassList

const INTERFACE_PATH = "res://addons/aerobeat-input-core/src/interfaces/input_provider.gd"

func _ready():
	print("=== AeroBeat Input Core Test Scene ===")
	print("Official v1 gameplay path: camera-first providers")
	print("Official v1 gameplay contract: intent signals first, optional observation data second.")
	
	var file_exists = FileAccess.file_exists(INTERFACE_PATH)
	var script_loaded = false
	var script: Script = null
	
	if file_exists:
		script = load(INTERFACE_PATH)
		script_loaded = script != null
	
	if file_exists and script_loaded:
		status_label.text = "✓ AeroBeat Input Core Loaded (camera-first v1 intent contracts)"
		status_label.add_theme_color_override("font_color", Color.GREEN)
		print("✓ AeroInputProvider interface found at: " + INTERFACE_PATH)
		print("✓ Script resource loaded: " + str(script.resource_path))
		
		class_list.text = _get_class_info()
	else:
		status_label.text = "✗ AeroBeat Input Core NOT found"
		status_label.add_theme_color_override("font_color", Color.RED)
		class_list.text = "Error: Could not load\n" + INTERFACE_PATH
		push_error("AeroBeat Input Core interface not found!")
	
	print("================================")

func _get_class_info() -> String:
	var info = "Repo framing:\n"
	info += "- Official v1 gameplay: camera-first providers\n"
	info += "- Gameplay contract: stable intent signals\n"
	info += "- Raw pose/observation: optional provider-side richness\n"
	info += "- Mouse/touch: UI navigation, not gameplay parity\n"
	info += "- XR/controllers/keyboard: future or experimental paths\n"
	info += "\nAvailable Classes:\n"
	info += "- AeroInputProvider\n"
	info += "- FlowInput\n"
	info += "- BoxingInput\n"
	info += "- InputManager\n"
	info += "- AeroProviderSessionRegistry\n"
	info += "\nShared Session Reuse:\n"
	info += "  • owner publishes live provider sessions explicitly\n"
	info += "  • consumers request/acquire shared sessions explicitly\n"
	info += "  • reuse is in-process only and does not transfer ownership\n"
	info += "\nTracking Modes:\n"
	info += "  • MODE_2D (camera-first normalized coordinates)\n"
	info += "  • MODE_3D (optional richer provider coordinates)\n"
	info += "\nIntent Contract Highlights:\n"
	info += "  • Boxing: punch_left / punch_right, guard_start / guard_end\n"
	info += "  • Flow: swing_left/right + trail_left/right with placement + direction\n"
	info += "  • State intents: squat / lean / sidestep use start/end pairs\n"
	info += "\nOptional Capabilities:\n"
	info += "  • GESTURE_RECOGNITION\n"
	info += "  • VELOCITY\n"
	info += "  • SPATIAL_TRANSFORM\n"
	info += "  • LOWER_BODY\n"
	info += "  • HAPTICS"
	return info
