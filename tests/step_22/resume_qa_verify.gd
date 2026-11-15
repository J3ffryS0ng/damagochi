extends SceneTree

var gm: Node
var sm: Node
var menu_script: GDScript
var failures := 0

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, label: String) -> void:
    print("QA_PASS " if ok else "QA_FAIL ", label)
    if not ok:
        failures += 1

func settle() -> void:
    for i in range(4):
        await process_frame

func open_menu() -> Node:
    change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
    await settle()
    return current_scene

func fixture() -> Dictionary:
    var data := GameDataFactory.create_new_game("QA disk baby")
    data.active_creatures[0].stage = "baby"
    data.active_creatures[0].hatched_at = 100.5
    data["extra"] = {"nested": ["retain", 7]}
    return data

func run() -> void:
    print("QA_USER_DIR=", ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("damagochi-step22-resume-"):
        quit(2)
        return
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    menu_script = load("res://scripts/main/main_menu.gd")
    # Cover required fields not exercised by DEV's numeric fixture matrix.
    for key in ["player_name", "save_version"]:
        for value in [null, "", " ", true, [], {}]:
            var data := fixture()
            data[key] = value
            check(not menu_script.is_valid_save(data), "reject " + key + "=" + str(value))
    for key in ["creature_id", "stage"]:
        for value in [null, "", " ", 1, [], {}]:
            var data := fixture()
            data.active_creatures[0][key] = value
            check(not menu_script.is_valid_save(data), "reject creature " + key + "=" + str(value))
    var multiple := fixture()
    multiple.active_creatures.append({"creature_id": "002", "affection_to_next_level": 0})
    check(not menu_script.is_valid_save(multiple), "invalid non-active array member rejected")
    var valid := fixture()
    valid.save_version = 1.0
    valid.active_creatures[0].level = 2.0
    var unchanged := valid.duplicate(true)
    check(menu_script.is_valid_save(valid) and valid == unchanged, "validator pure and accepts JSON integer-valued float")
    sm.save_game(valid)
    var disk_data: Dictionary = sm.load_game()
    var before := FileAccess.get_sha256(sm.SAVE_PATH)
    gm.create_new_game("stale memory")
    var stale: Dictionary = gm.game_data.duplicate(true)
    var m = await open_menu()
    check(gm.game_data == stale, "menu inspection does not replace existing memory")
    m.continue_button.pressed.emit()
    m.continue_button.pressed.emit()
    await settle()
    print("QA_CONTINUE scene=", current_scene.name, " name=", gm.get_player_name(), " extra=", gm.game_data.extra)
    check(current_scene.name == "Game" and gm.get_player_name() == "QA disk baby" and gm.game_data == disk_data, "double Continue reads disk not stale memory")
    check(FileAccess.get_sha256(sm.SAVE_PATH) == before, "Continue preserves original bytes")
    var game = current_scene
    var idle: Tween = game.creature_idle_tween
    await create_timer(0.4).timeout
    var pos: Vector2 = game.creature_sprite.position
    for i in range(100):
        game.load_current_creature()
    check(game.creature_idle_tween == idle and game.creature_sprite.position == pos and get_processed_tweens().size() == 1, "100 load refreshes preserve one moving Idle")
    m = await open_menu()
    m.start_button.pressed.emit()
    m.replace_save_dialog.confirmed.emit()
    await settle()
    var entry = current_scene
    var old_memory: Dictionary = gm.game_data.duplicate(true)
    sm.delete_save()
    entry.name_input.text = "must not save"
    entry.confirm_button.pressed.emit()
    await settle()
    check(current_scene == entry and not sm.has_save_file() and gm.game_data == old_memory and entry.message_label.text.contains("저장 상태가 변경"), "deleted file invalidates existing-file authorization")
    entry.back_button.pressed.emit()
    await settle()
    check(current_scene.name == "MainMenu" and current_scene.continue_button.disabled and not has_meta(menu_script.NEW_GAME_AUTHORIZATION), "back discards approval after external deletion")
    sm.save_game(fixture())
    print("QA_RESULT failures=", failures)
    quit(failures)
