extends SceneTree

var failures := 0
var gm: Node
var sm: Node

func _initialize() -> void:
    call_deferred("run")

func check(value: bool, label: String) -> void:
    print("PASS " if value else "FAIL ", label)
    if not value:
        failures += 1

func scene(path: String) -> Node:
    check(change_scene_to_file(path) == OK, "load " + path)
    await process_frame
    await process_frame
    return current_scene

func fixture(age: float, level: int, stage: String = "egg") -> void:
    gm.create_new_game("S22 fixture")
    var creature: Dictionary = gm.get_active_creature()
    creature["egg_created_at"] = Time.get_unix_time_from_system() - age
    creature["level"] = level
    creature["stage"] = stage

func touch(game: Node, screen: bool = false) -> void:
    var event: InputEvent
    if screen:
        event = InputEventScreenTouch.new()
    else:
        event = InputEventMouseButton.new()
        event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = true
    game.egg_touch_area.input_event.emit(root, event, 0)

func run() -> void:
    var location := ProjectSettings.globalize_path("user://")
    print("TEST_USER_DIR=", location)
    if not location.contains("damagochi-step22-"):
        quit(2)
        return
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    if "restore" in OS.get_cmdline_user_args():
        var game = await scene("res://scenes/game/Game.tscn")
        check(game.current_creature.stage == "baby", "T07 fresh-process baby restore")
        check(game.creature_sprite.texture != null and game.creature_idle_tween.is_running(), "T07 image and Idle restored")
        check(sm.load_game().save_version == 1, "T07 save version preserved")
        await create_timer(0.6).timeout
        if DisplayServer.get_name() != "headless":
            await RenderingServer.frame_post_draw
            root.get_texture().get_image().save_png("res://restored_baby.png")
        quit(failures)
        return
    sm.delete_save()
    var menu = await scene("res://scenes/main/MainMenu.tscn")
    menu.start_button.pressed.emit()
    await process_frame
    await process_frame
    var entry = current_scene
    entry.name_input.text = "   "
    entry.confirm_button.pressed.emit()
    check(current_scene == entry and not sm.has_save_file(), "T02 empty name stays without save")
    # A directory at the isolated save path forces FileAccess.WRITE failure.
    DirAccess.make_dir_absolute(ProjectSettings.globalize_path(sm.SAVE_PATH))
    entry.name_input.text = "S22 failure"
    entry.confirm_button.pressed.emit()
    check(current_scene == entry and entry.message_label.text == "게임 저장에 실패했습니다.", "T02 expected save failure stays and reports")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(sm.SAVE_PATH))
    entry.name_input.text = "S22 normal"
    entry.confirm_button.pressed.emit()
    await process_frame
    await process_frame
    var game = current_scene
    check(game.name == "Game" and sm.has_save_file(), "T02 MainMenu-name-confirm-Game")
    touch(game)
    check(game.current_creature.affection == 1, "T03 mouse +1")
    for i in range(9):
        touch(game)
    check(game.current_creature.level == 2 and game.current_creature.affection == 0 and game.current_creature.affection_to_next_level == 13, "T03 ten inputs level2 target13")
    check(game.current_creature.stage == "egg", "T03 no early hatch")
    touch(game, true)
    check(game.current_creature.affection == 1, "T10 synthetic ScreenTouch +1")
    for values in [[0.0, 1], [0.0, 2], [120.0, 1], [120.0, 2]]:
        fixture(values[0], values[1])
        game = await scene("res://scenes/game/Game.tscn")
        var expected: bool = values[0] == 120.0 and values[1] == 2
        check(game.can_hatch() == expected and game.hatch_in_progress == expected, "T04 age=%s level=%s" % values)
    var affection_before: int = game.current_creature.affection
    for i in range(20):
        touch(game)
        game.check_hatch_effect()
    await create_timer(1.1).timeout
    check(game.current_creature.stage == "baby" and game.current_creature.affection == affection_before, "T06 hatch once; input blocked during effect")
    var hatch_time: float = game.current_creature.hatched_at
    game.check_hatch_effect()
    check(game.current_creature.hatched_at == hatch_time, "T06 repeated hatch check unchanged")
    check(game.creature_sprite.visible and game.creature_sprite.texture != null and not game.egg_sprite.visible and not game.egg_touch_area.input_pickable, "T06 image and egg/input visibility")
    check(is_zero_approx(game.hatch_flash.color.a), "T06 flash faded")
    check(game.creature_idle_tween != null and game.creature_idle_tween.is_running(), "T06 Idle starts at hatch")
    check(ResourceLoader.get_resource_uid("res://assets/creatures/001/creature_001_idle.png") == ResourceUID.text_to_id("uid://bvxbd2giroe7m"), "T01 PNG UID")
    var base: Vector2 = game.creature_idle_base_position
    var scale_before: Vector2 = game.creature_sprite.scale
    var rotation_before: float = game.creature_sprite.rotation
    var saved_before: Dictionary = gm.game_data.duplicate(true)
    var idle: Tween = game.creature_idle_tween
    for i in range(20):
        game.update_creature_visual()
    check(game.creature_idle_tween == idle and get_processed_tweens().size() == 1, "T08 20 refreshes exactly one Tween")
    game.stop_creature_idle()
    game.start_creature_idle()
    var min_y: float = base.y
    var max_y: float = base.y - 4.0
    var elapsed := 0.0
    var peak_error := 0.0
    while elapsed < 10.1:
        await process_frame
        elapsed += game.get_process_delta_time()
        var pos: Vector2 = game.creature_sprite.position
        min_y = min(min_y, pos.y)
        max_y = max(max_y, pos.y)
        peak_error = max(peak_error, abs(pos.y - (base.y - 2.0 + 2.0 * cos(PI * elapsed))))
    print("IDLE_MEASURE min=", min_y, " max=", max_y, " seconds=", elapsed, " sine_error=", peak_error)
    check(min_y >= base.y - 4.01 and min_y < base.y - 3.9 and max_y <= base.y + 0.01 and max_y > base.y - 0.1 and peak_error < 0.3, "T08 10s amplitude and 2s sine period")
    check(game.creature_sprite.position.x == base.x and game.creature_sprite.scale == scale_before and game.creature_sprite.rotation == rotation_before and gm.game_data == saved_before, "T08 x scale rotation data unchanged")
    for stage in ["egg", "adult", "baby"]:
        game.current_creature.stage = stage
        game.update_creature_visual()
        check((game.creature_idle_tween != null) == (stage == "baby"), "T09 stage " + stage)
        if stage != "baby":
            check(game.creature_sprite.position == base, "T09 base reset " + stage)
    game.current_creature = {}
    game.update_creature_visual()
    check(game.creature_idle_tween == null and game.creature_sprite.position == base, "T09 empty visual cleanup")
    game.stop_creature_idle()
    game.stop_creature_idle()
    game.load_current_creature()
    var old_idle: Tween = game.creature_idle_tween
    game = await scene("res://scenes/game/Game.tscn")
    check(not old_idle.is_valid() and game.creature_idle_tween.is_running(), "T09 scene exit kills old Idle and reentry restarts")
    gm.clear_game_data()
    game.load_current_creature()
    check(game.creature_idle_tween == null and game.creature_sprite.position == game.creature_idle_base_position, "T09 expected empty load error also cleans Idle")
    fixture(0.0, 2)
    game = await scene("res://scenes/game/Game.tscn")
    print("T05_WAIT_START")
    await create_timer(60.2).timeout
    check(game.can_hatch() and game.current_creature.stage == "egg" and not game.hatch_in_progress, "T05 no automatic hatch after 60 seconds")
    touch(game)
    await create_timer(1.1).timeout
    check(game.current_creature.stage == "baby", "T05 extra touch hatches")
    check(sm.save_game(gm.game_data), "T07 baby saved for fresh-process restore")
    print("RESULT failures=", failures)
    quit(failures)
