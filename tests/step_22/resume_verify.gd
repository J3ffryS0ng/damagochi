extends SceneTree

var Menu: GDScript
var gm: Node
var sm: Node
var failures := 0

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ", label)
    if not ok:
        failures += 1

func settle() -> void:
    await process_frame
    await process_frame
    await process_frame

func menu() -> Node:
    change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
    await settle()
    return current_scene

func fixture(stage: String = "egg", ready: bool = false) -> Dictionary:
    var data := GameDataFactory.create_new_game("기존 이름")
    data["extra"] = {"preserve": [1, 2, 3]}
    data.active_creatures[0].stage = stage
    data.active_creatures[0].level = 2 if ready else 1
    data.active_creatures[0].affection = 3
    data.active_creatures[0].egg_created_at = Time.get_unix_time_from_system() - 120.0
    data.active_creatures[0].hatched_at = 123.0 if stage == "baby" else 0.0
    return data

func write_raw(value: String) -> void:
    var file := FileAccess.open(sm.SAVE_PATH, FileAccess.WRITE)
    file.store_string(value)
    file.close()

func digest() -> String:
    return FileAccess.get_sha256(sm.SAVE_PATH)

func capture(label: String) -> void:
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://resume_" + label + ".png")

func run() -> void:
    var location := ProjectSettings.globalize_path("user://")
    print("TEST_USER_DIR=", location)
    if not location.contains("damagochi-step22-resume-"):
        quit(2)
        return
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    Menu = load("res://scripts/main/main_menu.gd")
    var mode: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "suite"
    if mode.begins_with("seed_"):
        check(sm.save_game(fixture("baby" if mode == "seed_baby" else "egg", mode == "seed_hatch")), "seed isolated save " + mode)
    elif mode.begins_with("resume_"):
        await resume(mode)
    elif mode == "read_locked":
        await read_locked()
    elif mode == "write_locked":
        await write_locked()
    elif mode == "continue_scene_failure" or mode == "name_scene_failure":
        await scene_failure(mode)
    else:
        await suite()
    print("RESULT ", mode, " failures=", failures)
    quit(failures)

func resume(mode: String) -> void:
    var data: Dictionary = sm.load_game()
    var before := digest()
    var m = await menu()
    check(gm.game_data.is_empty(), "RC02/03 menu reads temporary data only")
    check(not m.continue_button.disabled and digest() == before, "RC02/03 continue enabled without write")
    await capture("menu")
    m.continue_button.pressed.emit()
    await settle()
    check(current_scene.name == "Game", "RC02/03/14 default MainMenu continue enters Game")
    if mode == "resume_hatch":
        await create_timer(1.1).timeout
        check(gm.get_active_creature().stage == "baby" and sm.load_game().active_creatures[0].stage == "baby", "RC14 natural ready egg hatches and saves")
        check(current_scene.creature_idle_tween.is_running(), "RC14 Idle after natural hatch")
    else:
        check(gm.game_data == data and digest() == before, "RC02/03 all fields and file bytes preserved across process restart")
    if mode == "resume_baby":
        var game = current_scene
        check(game.creature_sprite.visible and game.creature_sprite.texture != null, "RC04 PNG visible")
        var tween: Tween = game.creature_idle_tween
        for i in range(20):
            game.update_creature_visual()
        check(tween == game.creature_idle_tween and get_processed_tweens().size() == 1, "RC04 no duplicate Tween")
        var base: Vector2 = game.creature_idle_base_position
        game.stop_creature_idle()
        game.start_creature_idle()
        await create_timer(1.0).timeout
        check(abs(game.creature_sprite.position.y - base.y + 4.0) < 0.15, "RC04 1s up 4px")
        await create_timer(1.0).timeout
        check(abs(game.creature_sprite.position.y - base.y) < 0.15, "RC04 2s returns to base")
        await capture("baby")

func suite() -> void:
    sm.delete_save()
    var m = await menu()
    check(m.continue_button.disabled, "RC01 no save continue disabled")
    m.start_button.pressed.emit()
    m.start_button.pressed.emit()
    await settle()
    var entry = current_scene
    check(entry.name == "NameEntry" and not has_meta(Menu.NEW_GAME_AUTHORIZATION), "RC01 no-dialog entry consumes authorization")
    entry.name_input.text = " "
    entry.confirm_button.pressed.emit()
    check(not sm.has_save_file() and current_scene == entry, "RC01 empty name no save")
    entry.name_input.text = "새 이름"
    entry.confirm_button.pressed.emit()
    entry.name_input.text_submitted.emit("새 이름")
    await settle()
    check(current_scene.name == "Game" and gm.get_player_name() == "새 이름" and gm.get_active_creature().stage == "egg", "RC01/13 one new egg transition on repeated submission")
    var data := fixture("baby")
    sm.save_game(data)
    gm.game_data = {"sentinel": {"nested": 9}}
    var previous: Dictionary = gm.game_data.duplicate(true)
    var before := digest()
    m = await menu()
    await capture("valid_menu")
    for cancellation in ["cancel", "escape", "close"]:
        var message: String = m.message_label.text
        m.start_button.pressed.emit()
        m.start_button.pressed.emit()
        check(m.replace_save_dialog.visible and current_scene == m and gm.game_data == previous and digest() == before, "RC05 prompt before entry without changes " + cancellation)
        await capture("confirm")
        if cancellation == "cancel":
            m.replace_save_dialog.get_cancel_button().pressed.emit()
        elif cancellation == "escape":
            await create_timer(0.3).timeout
            var key := InputEventKey.new()
            key.keycode = KEY_ESCAPE
            key.physical_keycode = KEY_ESCAPE
            key.pressed = true
            root.push_input(key)
        else:
            m.replace_save_dialog.close_requested.emit()
        await settle()
        if cancellation == "escape":
            print("ESC_STATE visible=", m.replace_save_dialog.visible, " pending=", m.replacement_pending, " focus=", m.start_button.has_focus())
        check(not m.replace_save_dialog.visible and not m.start_button.disabled and not m.continue_button.disabled and m.start_button.has_focus() and m.message_label.text == message and gm.game_data == previous and digest() == before, "RC07 preserve state/focus/hash " + cancellation)
    m.start_button.pressed.emit()
    m.replace_save_dialog.confirmed.emit()
    m.replace_save_dialog.confirmed.emit()
    await settle()
    entry = current_scene
    check(entry.name == "NameEntry" and digest() == before and gm.game_data == previous, "RC06 confirmed entry leaves save and memory unchanged")
    entry.back_button.pressed.emit()
    await settle()
    check(current_scene.name == "MainMenu" and digest() == before and gm.game_data == previous and not has_meta(Menu.NEW_GAME_AUTHORIZATION), "RC12 back discards approval preserves data")
    change_scene_to_file("res://scenes/main/NameEntry.tscn")
    await settle()
    await settle()
    check(current_scene.name == "MainMenu" and digest() == before, "RC12 direct NameEntry rejected")
    m = current_scene
    m.start_button.pressed.emit()
    m.replace_save_dialog.confirmed.emit()
    await settle()
    entry = current_scene
    write_raw("changed externally")
    var changed := digest()
    entry.name_input.text = "blocked"
    entry.confirm_button.pressed.emit()
    check(current_scene == entry and digest() == changed and gm.game_data == previous and entry.message_label.text.contains("저장 상태가 변경"), "RC12 changed-file authorization blocked")
    entry.back_button.pressed.emit()
    await settle()
    m = current_scene
    check(m.continue_button.disabled and not m.message_label.text.is_empty(), "RC08 malformed JSON blocked")
    await capture("invalid_menu")
    m.continue_button.pressed.emit()
    await create_timer(0.2).timeout
    check(current_scene == m and gm.game_data == previous and digest() == changed, "RC09 invalid continue no automatic initialization")
    m.start_button.pressed.emit()
    check(m.replace_save_dialog.dialog_text.contains("기존 저장을 읽을 수 없습니다"), "RC11 corrupt save replacement warning")
    await capture("invalid_confirm")
    m.replace_save_dialog.get_cancel_button().pressed.emit()
    check(digest() == changed, "RC11 cancel corrupt file preserves bytes")
    m.start_button.pressed.emit()
    m.replace_save_dialog.confirmed.emit()
    await settle()
    entry = current_scene
    check(entry.name == "NameEntry" and digest() == changed, "RC11 explicit corrupt replacement enters without write")
    entry.name_input.text = "명시적 대체"
    entry.confirm_button.pressed.emit()
    await settle()
    check(current_scene.name == "Game" and sm.load_game().player_name == "명시적 대체", "RC06/11 only submitted name replaces file")
    # Never pass dangerous fixtures to GameManager; exercise the menu boundary.
    var invalid: Array[Dictionary] = []
    for value in [[], {}, ["wrong"], [null]]:
        var bad := fixture()
        bad.active_creatures = value
        invalid.append(bad)
    for field in ["level", "affection", "affection_to_next_level", "egg_created_at", "hatched_at"]:
        for value in ["wrong", -1, true]:
            var bad := fixture()
            bad.active_creatures[0][field] = value
            invalid.append(bad)
    for field in ["level", "affection_to_next_level"]:
        var bad := fixture()
        bad.active_creatures[0][field] = 0
        invalid.append(bad)
    for field in ["level", "affection", "affection_to_next_level"]:
        var bad := fixture()
        bad.active_creatures[0][field] = 1.5
        invalid.append(bad)
    for bad in invalid:
        write_raw(JSON.stringify(bad))
        before = digest()
        previous = gm.game_data.duplicate(true)
        m = await menu()
        m.continue_button.pressed.emit()
        check(m.continue_button.disabled and current_scene == m and digest() == before and gm.game_data == previous, "RC08 invalid structure blocked " + str(invalid.find(bad)))
    for value in [INF, NAN]:
        var bad := fixture()
        bad.active_creatures[0].level = value
        check(not Menu.is_valid_save(bad), "RC08 nonfinite helper rejects")
    var optional := {"save_version": 1.0, "player_name": "optional", "active_creatures": [{"creature_id": "001"}], "unknown": 42}
    write_raw(JSON.stringify(optional))
    before = digest()
    m = await menu()
    m.continue_button.pressed.emit()
    await settle()
    check(current_scene.name == "Game" and gm.get_active_creature().stage == "egg" and gm.game_data.unknown == 42 and digest() == before, "RC08 missing optional defaults/unknown keys/JSON float preserved")
    var other := fixture("adult")
    check(Menu.is_valid_save(other) and other.active_creatures[0].stage == "adult", "RC08 other nonempty stage not rewritten")
    sm.delete_save()
    m = await menu()
    m.start_button.pressed.emit()
    await settle()
    entry = current_scene
    sm.save_game(fixture())
    before = digest()
    entry.name_input.text = "blocked new file"
    entry.confirm_button.pressed.emit()
    check(current_scene == entry and digest() == before and entry.message_label.text.contains("저장 상태가 변경"), "RC12 file appeared after absent approval blocked")
    m = await menu()
    write_raw("invalidated after menu")
    before = digest()
    m.continue_button.pressed.emit()
    check(current_scene == m and m.continue_button.disabled and digest() == before, "RC08 continue rechecks disk after menu display")
    sm.delete_save()
    m = await menu()
    sm.save_game(fixture())
    m.start_button.pressed.emit()
    check(m.replace_save_dialog.visible, "RC05 new game rechecks file presence")
    m.replace_save_dialog.get_cancel_button().pressed.emit()
    m.encyclopedia_button.pressed.emit()
    await settle()
    check(current_scene.name == "Encyclopedia", "existing encyclopedia route retained")

func read_locked() -> void:
    gm.game_data = {"sentinel": 1}
    var m = await menu()
    check(m.continue_button.disabled and not m.message_label.text.is_empty(), "RC08 unreadable file disables continue")
    m.continue_button.pressed.emit()
    check(current_scene == m and gm.game_data == {"sentinel": 1}, "RC09 unreadable no automatic game")
    m.start_button.pressed.emit()
    m.replace_save_dialog.confirmed.emit()
    await settle()
    check(current_scene == m and m.message_label.text.contains("기존 저장을 확인할 수 없어") and not has_meta(Menu.NEW_GAME_AUTHORIZATION), "RC11 unreadable bytes cannot authorize new game")

func write_locked() -> void:
    gm.game_data = {"sentinel": {"deep": [1, 2]}}
    var previous: Dictionary = gm.game_data.duplicate(true)
    var before := digest()
    var m = await menu()
    m.start_button.pressed.emit()
    m.replace_save_dialog.confirmed.emit()
    await settle()
    var entry = current_scene
    entry.name_input.text = "write denied"
    entry.confirm_button.pressed.emit()
    entry.name_input.text_submitted.emit("write denied")
    check(current_scene == entry and not entry.transition_in_progress and gm.game_data == previous and digest() == before and entry.message_label.text == "게임 저장에 실패했습니다.", "RC13 write-open failure restores memory and file; retry guarded")

func scene_failure(mode: String) -> void:
    var path := "res://scenes/game/Game.tscn"
    var original := FileAccess.get_file_as_string(path)
    var before := digest()
    gm.game_data = {"sentinel": 77}
    var m = await menu()
    # Only this disposable copy is changed, before Game has ever been loaded.
    DirAccess.rename_absolute(path, path + ".held")
    if mode == "continue_scene_failure":
        m.continue_button.pressed.emit()
        check(current_scene == m and gm.game_data == {"sentinel": 77} and digest() == before and not m.continue_button.disabled and m.message_label.text.contains("전환에 실패"), "RC13 continue scene failure rolls back memory and restores buttons")
    else:
        m.start_button.pressed.emit()
        m.replace_save_dialog.confirmed.emit()
        await settle()
        var entry = current_scene
        entry.name_input.text = "saved once"
        entry.confirm_button.pressed.emit()
        before = digest()
        entry.name_input.text_submitted.emit("saved once")
        check(current_scene == entry and entry.new_game_saved and entry.new_game_authorization.is_empty() and digest() == before and entry.message_label.text.contains("전환에 실패"), "RC13 saved once despite scene failure and repeated Enter")
    DirAccess.rename_absolute(path + ".held", path)
    check(FileAccess.get_file_as_string(path) == original, "test restores disposable scene")
    if mode == "continue_scene_failure":
        m.continue_button.pressed.emit()
    else:
        current_scene.confirm_button.pressed.emit()
    await settle()
    check(current_scene.name == "Game" and digest() == before, "RC13 scene retry succeeds without another save")

