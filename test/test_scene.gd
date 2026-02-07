extends Node2D
## Test scene for AeroBeat Core
## Verifies that the core interface classes are available

@onready var status_label: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var class_list: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/ClassList

const INTERFACE_PATH = "res://src/interfaces/input_provider.gd"

func _ready():
	print("=== AeroBeat Core Test Scene ===")
	
	# Verify the core interface file exists and can be loaded
	var file_exists = FileAccess.file_exists(INTERFACE_PATH)
	var script_loaded = false
	var script: Script = null
	
	if file_exists:
		script = load(INTERFACE_PATH)
		script_loaded = script != null
	
	if file_exists and script_loaded:
		status_label.text = "✓ AeroBeat Core Loaded Successfully"
		status_label.add_theme_color_override("font_color", Color.GREEN)
		print("✓ AeroInputProvider interface found at: " + INTERFACE_PATH)
		print("✓ Script resource loaded: " + str(script.resource_path))
		
		# Show class info
		var class_info = _get_class_info()
		class_list.text = class_info
	else:
		status_label.text = "✗ AeroBeat Core NOT found"
		status_label.add_theme_color_override("font_color", Color.RED)
		class_list.text = "Error: Could not load\n" + INTERFACE_PATH
		push_error("AeroBeat Core interface not found!")
	
	print("================================")

func _get_class_info() -> String:
	var info = "Available Classes:\n"
	info += "- AeroInputProvider\n"
	info += "\nTracking Modes:\n"
	info += "  • MODE_2D (2D viewport coordinates)\n"
	info += "  • MODE_3D (3D world coordinates)\n"
	info += "\nBody Track Flags:\n"
	info += "  • HEAD\n"
	info += "  • LEFT_HAND\n"
	info += "  • RIGHT_HAND\n"
	info += "  • LEFT_FOOT\n"
	info += "  • RIGHT_FOOT"
	return info
