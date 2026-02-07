extends GutTest

func test_aero_input_provider_is_abstract():
    var provider = AeroInputProvider.new()
    
    var result = provider.get_left_hand_position()
    assert_null(result, "Abstract method should return null")

func test_tracking_mode_enum_values():
    assert_eq(AeroInputProvider.TrackingMode.MODE_2D, 0)
    assert_eq(AeroInputProvider.TrackingMode.MODE_3D, 1)

func test_body_track_flags_bitfield():
    assert_eq(AeroInputProvider.BodyTrackFlags.NONE, 0)
    assert_eq(AeroInputProvider.BodyTrackFlags.HEAD, 1)
    assert_eq(AeroInputProvider.BodyTrackFlags.LEFT_HAND, 2)
    assert_eq(AeroInputProvider.BodyTrackFlags.RIGHT_HAND, 4)
    
    var combined = AeroInputProvider.BodyTrackFlags.HEAD | AeroInputProvider.BodyTrackFlags.LEFT_HAND
    assert_eq(combined, 3, "Combined flags should work")
