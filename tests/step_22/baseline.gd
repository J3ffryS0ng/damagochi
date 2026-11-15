extends SceneTree

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var location := ProjectSettings.globalize_path("user://")
    print("TEST_USER_DIR=", location)
    if not location.contains("damagochi-step22-"):
        quit(2)
        return
    var gm = root.get_node("GameManager")
    var sm = root.get_node("SaveManager")
    sm.delete_save()
    change_scene_to_file("res://scenes/main/MainMenu.tscn")
    await process_frame
    await process_frame
    print("BASELINE_MAIN=", current_scene.name)
    current_scene.start_button.pressed.emit()
    await process_frame
    await process_frame
    current_scene.name_input.text = "S22 baseline"
    current_scene.confirm_button.pressed.emit()
    await process_frame
    await process_frame
    print("BASELINE_AFTER_CONFIRM=", current_scene.name, " SAVE=", sm.has_save_file())
    change_scene_to_file("res://scenes/game/Game.tscn")
    await process_frame
    await process_frame
    var game = current_scene
    for i in range(10):
        var event := InputEventMouseButton.new()
        event.button_index = MOUSE_BUTTON_LEFT
        event.pressed = true
        game.egg_touch_area.input_event.emit(root, event, 0)
    print("BASELINE_TEN_INPUT=", gm.get_active_creature())
    gm.get_active_creature()["egg_created_at"] = Time.get_unix_time_from_system() - 120.0
    game.check_hatch_effect()
    await create_timer(1.1).timeout
    print("BASELINE_HATCH=", gm.get_active_creature()["stage"], " TEXTURE=", game.creature_sprite.texture)
    gm.clear_game_data()
    change_scene_to_file("res://scenes/main/MainMenu.tscn")
    await process_frame
    await process_frame
    print("BASELINE_RESTORE_STAGE=", gm.get_active_creature()["stage"])
    current_scene.start_button.pressed.emit()
    await process_frame
    await process_frame
    print("BASELINE_RESTART_TARGET=", current_scene.name)
    gm.clear_game_data()
    change_scene_to_file("res://scenes/game/Game.tscn")
    await process_frame
    await process_frame
    print("BASELINE_DIRECT_RESTORE=", gm.get_active_creature()["stage"], " TEXTURE=", current_scene.creature_sprite.texture)
    quit()
