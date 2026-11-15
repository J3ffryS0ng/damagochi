extends SceneTree

func _initialize() -> void:
    print("PROJECT=", ProjectSettings.globalize_path("res://"))
    print("USER_DIR=", ProjectSettings.globalize_path("user://"))
    print("ENGINE=", Engine.get_version_info().string)
    quit()
