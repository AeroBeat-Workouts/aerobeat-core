class_name AeroInputProvider
extends Node
## Abstract interface for all input strategies
## All input drivers must implement this interface

enum TrackingMode {
    MODE_2D,      # 2D viewport coordinates (x, y)
    MODE_3D       # 3D world coordinates (x, y, z)
}

enum BodyTrackFlags {
    NONE = 0,
    HEAD = 1,
    LEFT_HAND = 2,
    RIGHT_HAND = 4,
    LEFT_FOOT = 8,
    RIGHT_FOOT = 16,
    ALL = 31
}

# Core interface methods - must be implemented by all providers
func get_left_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    push_error("AeroInputProvider: get_left_hand_position() must be overridden")
    return null

func get_right_hand_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    push_error("AeroInputProvider: get_right_hand_position() must be overridden")
    return null

func get_head_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    push_error("AeroInputProvider: get_head_position() must be overridden")
    return null

func get_left_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    push_error("AeroInputProvider: get_left_foot_position() must be overridden")
    return null

func get_right_foot_position(mode: TrackingMode = TrackingMode.MODE_2D) -> Variant:
    push_error("AeroInputProvider: get_right_foot_position() must be overridden")
    return null

func set_tracking_mode(mode: TrackingMode) -> void:
    push_error("AeroInputProvider: set_tracking_mode() must be overridden")

func set_body_track_flags(flags: int) -> void:
    push_error("AeroInputProvider: set_body_track_flags() must be overridden")

func is_tracking() -> bool:
    push_error("AeroInputProvider: is_tracking() must be overridden")
    return false

func get_tracking_confidence(body_part: int) -> float:
    push_error("AeroInputProvider: get_tracking_confidence() must be overridden")
    return 0.0
