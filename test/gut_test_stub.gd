# Stub class for GutTest when GUT addon is not installed
# This prevents parse errors in test files when GUT is not available
# Install the GUT addon from the Asset Library to run tests properly
class_name GutTest
extends RefCounted

# Reference to self for gut.p() calls
var gut: GutTest = self

func p(text: String) -> void:
	push_warning("GUT addon is not installed. Install it from the Asset Library to run tests.")
	print(text)

func assert_eq(_got, _expected, _text: String = "") -> void:
	push_warning("GUT addon is not installed. Install it from the Asset Library to run tests.")

func assert_null(_value, _text: String = "") -> void:
	push_warning("GUT addon is not installed. Install it from the Asset Library to run tests.")
