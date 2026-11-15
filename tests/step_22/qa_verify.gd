extends SceneTree

# Independent QA harness. Run only in the copy created by step_22/run.ps1.
var failures := 0
var gm: Node
var sm: Node

func _initialize() -> void:
    call_deferred("run")

func verify(ok: bool, label: String) -> void:
    print("QA_PASS " if ok else "QA_FAIL ", label)
    if not ok:
        failures += 1

func open_scene(path: String) -> Node:
    verify(change_scene_to_file(path) == OK, "scene loads " + path)
    await process_frame
    await process_frame
    return current_scene

func capture(label: String) -> void:
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        verify(root.get_texture().get_image().save_png("res://qa_" + label + ".png") == OK, "capture " + label)

func run() -> void:
    var location := ProjectSettings.globalize_path("user://")
    print("QA_USER_DIR=", location)
    if not location.contains("damagochi-step22-"):
        quit(2)
        return
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    if "restart" in OS.get_cmdline_user_args():
        var previous: Dictionary = sm.load_game()
        var menu = await open_scene(ProjectSettings.get_setting("application/run/main_scene"))
        verify(gm.get_active_creature().stage == "baby", "default menu restores baby data")
        menu.start_button.pressed.emit()
        await process_frame
        await process_frame
        print("QA_RESTART_DESTINATION=", current_scene.scene_file_path)
        verify(current_scene.scene_file_path == "res://scenes/main/NameEntry.tscn", "existing restart limitation reproduced")
        verify(sm.load_game() == previous, "menu navigation preserves existing save")
        var restored = await open_scene("res://scenes/game/Game.tscn")
        verify(restored.creature_idle_tween.is_running() and restored.creature_sprite.texture != null, "direct Game restore starts Idle")
        verify(gm.get_active_creature() == previous.active_creatures[0], "all creature fields survive process exit")
        await create_timer(0.4).timeout
        await capture("restored_baby")
        print("QA_RESULT failures=", failures)
        quit(failures)
        return

    sm.delete_save()
    var menu = await open_scene(ProjectSettings.get_setting("application/run/main_scene"))
    menu.start_button.pressed.emit()
    await process_frame
    await process_frame
    var entry = current_scene
    entry.name_input.text = " "
    entry.name_input.text_submitted.emit(" ")
    await process_frame
    await process_frame
    verify(current_scene == entry and not sm.has_save_file(), "empty submission no deferred transition or save")
    DirAccess.make_dir_absolute(ProjectSettings.globalize_path(sm.SAVE_PATH))
    entry.name_input.text = "QA save failure"
    entry.confirm_button.pressed.emit()
    await process_frame
    await process_frame
    verify(current_scene == entry and entry.message_label.text == "게임 저장에 실패했습니다.", "failed save no deferred transition")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(sm.SAVE_PATH))
    entry.name_input.text = "  QA 독립  "
    entry.name_input.text_submitted.emit(entry.name_input.text)
    await process_frame
    await process_frame
    var game = current_scene
    verify(game.scene_file_path == "res://scenes/game/Game.tscn", "Enter key submission enters Game")
    verify(gm.get_player_name() == "QA 독립" and sm.load_game().player_name == "QA 독립", "trimmed Korean name persisted")
    verify(game.egg_sprite.visible and game.creature_idle_tween == null, "new egg has no Idle")
    await capture("new_egg")
    var click := InputEventMouseButton.new()
    click.pressed = true
    click.button_index = MOUSE_BUTTON_LEFT
    for i in range(10):
        game.egg_touch_area.input_event.emit(root, click, 0)
    verify(game.current_creature.level == 2 and game.current_creature.affection == 0, "ten clicks level up")
    game.current_creature.egg_created_at = Time.get_unix_time_from_system() - 61.0
    game.egg_touch_area.input_event.emit(root, click, 0)
    await create_timer(0.3).timeout
    await capture("hatch_flash")
    await create_timer(0.8).timeout
    verify(game.current_creature.stage == "baby" and not game.egg_sprite.visible and game.creature_sprite.visible, "hatch changes visible sprite")
    await capture("hatched_baby")
    var baseline: Vector2 = game.creature_idle_base_position
    var sprite_scale: Vector2 = game.creature_sprite.scale
    var sprite_rotation: float = game.creature_sprite.rotation
    var pet_position: Vector2 = game.get_node("PetArea").position
    var state: Dictionary = gm.game_data.duplicate(true)
    var tween: Tween = game.creature_idle_tween
    var min_y := 1000.0
    var max_y := -1000.0
    var transforms_ok := true
    var single_tween := true
    var positions := FileAccess.open("res://qa_positions.csv", FileAccess.WRITE)
    positions.store_line("seconds,x,y,tweens")
    var start := Time.get_ticks_usec()
    var captured_low := false
    var captured_high := false
    while Time.get_ticks_usec() - start < 10200000:
        await process_frame
        for i in range(20):
            game.update_creature_visual()
        var p: Vector2 = game.creature_sprite.position
        min_y = min(min_y, p.y)
        max_y = max(max_y, p.y)
        transforms_ok = transforms_ok and p.x == baseline.x and game.creature_sprite.scale == sprite_scale and game.creature_sprite.rotation == sprite_rotation and game.get_node("PetArea").position == pet_position
        single_tween = single_tween and game.creature_idle_tween == tween and get_processed_tweens().size() == 1
        positions.store_line("%.6f,%f,%f,%d" % [(Time.get_ticks_usec() - start) / 1000000.0, p.x, p.y, get_processed_tweens().size()])
        if p.y < baseline.y - 3.99 and not captured_high:
            await capture("idle_up")
            captured_high = true
        if p.y > baseline.y - 0.01 and not captured_low:
            await capture("idle_base")
            captured_low = true
    positions.close()
    print("QA_IDLE_RANGE=", min_y, "..", max_y)
    verify(min_y >= baseline.y - 4.001 and max_y <= baseline.y + 0.001 and captured_low and captured_high, "Idle measured within 4px including extremes")
    verify(transforms_ok and gm.game_data == state, "every frame x scale rotation PetArea and data preserved")
    verify(single_tween, "20 refreshes per frame retain same single Tween")
    game.creature_idle_tween.pause()
    game.start_creature_idle()
    verify(not tween.is_valid() and game.creature_idle_tween.is_running(), "paused Tween replaced safely")
    game.stop_creature_idle()
    game.stop_creature_idle()
    game.creature_sprite.visible = false
    game.start_creature_idle()
    verify(game.creature_idle_tween == null, "hidden sprite does not start Idle")
    game.creature_sprite.visible = true
    var texture: Texture2D = game.creature_sprite.texture
    game.creature_sprite.texture = null
    game.start_creature_idle()
    verify(game.creature_idle_tween == null, "missing texture does not start Idle")
    game.creature_sprite.texture = texture
    game.update_creature_visual()
    verify(sm.save_game(gm.game_data), "save baby for new process")
    await open_scene("res://scenes/main/MainMenu.tscn")
    var custom = load("res://scenes/game/Game.tscn").instantiate()
    custom.get_node("PetArea/CreatureSprite").position = Vector2(11, 17)
    root.add_child(custom)
    await create_timer(0.3).timeout
    verify(custom.creature_idle_base_position == Vector2(11, 17), "nonzero initial base captured")
    custom.current_creature.stage = "egg"
    custom.update_creature_visual()
    verify(custom.creature_sprite.position == Vector2(11, 17) and custom.creature_idle_tween == null, "egg restores nonzero base")
    custom.queue_free()
    await process_frame
    print("QA_RESULT failures=", failures)
    quit(failures)
