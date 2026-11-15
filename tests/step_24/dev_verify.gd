extends SceneTree

var failures := 0
var requests := 0
var gm: Node
var sm: Node

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ", label)
    if not ok: failures += 1

func settle() -> void:
    for i in range(3): await process_frame

func scene(path: String) -> Node:
    check(change_scene_to_file(path) == OK, "load " + path)
    await settle()
    return current_scene

func clicked() -> void:
    requests += 1

func mouse(button: Button, right: bool = false) -> void:
    var point := button.get_global_rect().get_center()
    var motion := InputEventMouseMotion.new()
    motion.position = point
    root.push_input(motion, true)
    for down in [true, false]:
        var event := InputEventMouseButton.new()
        event.position = point
        event.button_index = MOUSE_BUTTON_RIGHT if right else MOUSE_BUTTON_LEFT
        event.pressed = down
        root.push_input(event, true)
        await process_frame
    await settle()

func capture(label: String) -> void:
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        check(root.get_texture().get_image().save_png("res://dev_" + label + ".png") == OK, "capture " + label)

func run() -> void:
    print("TEST_USER_DIR=", ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("step24-"):
        quit(2)
        return
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    var args := OS.get_cmdline_user_args()
    var mode: String = args[0] if not args.is_empty() else "suite"
    if mode.begins_with("seed_"):
        gm.create_new_game("S24 restore")
        gm.get_active_creature().stage = mode.trim_prefix("seed_")
        check(sm.save_game(gm.game_data), "seed " + mode)
        quit(failures)
        return
    if mode.begins_with("restore_"):
        var hash_before := FileAccess.get_sha256(sm.SAVE_PATH)
        var menu = await scene(ProjectSettings.get_setting("application/run/main_scene"))
        menu.continue_button.pressed.emit()
        await settle()
        var restored = current_scene
        var baby := mode == "restore_baby"
        check(restored.name == "Game" and restored.feed_button.visible and restored.feed_button.disabled != baby, "normal menu restore feed state " + mode)
        restored.feed_requested.connect(clicked)
        await mouse(restored.feed_button)
        check(requests == (1 if baby else 0), "restored button routed mouse " + mode)
        check(FileAccess.get_sha256(sm.SAVE_PATH) == hash_before, "restore and feed preserve save")
        quit(failures)
        return
    gm.create_new_game("밥주기 DEV")
    var game = await scene("res://scenes/game/Game.tscn")
    game.feed_requested.connect(clicked)
    var button: Button = game.feed_button
    var menu_button: Button = game.get_node("UI/BottomPanel/MenuButton")
    check(button.text == "밥주기" and button.is_visible_in_tree() and button.disabled, "AC1 visible disabled egg button")
    check(not button.get_global_rect().intersects(menu_button.get_global_rect()) and button.size == menu_button.size, "AC1 same size and separate menu")
    await mouse(button)
    button.pressed.emit()
    check(requests == 0, "AC2 egg blocks routed and direct input")
    await capture("egg_405")
    gm.get_active_creature().egg_created_at = Time.get_unix_time_from_system() - 120.0
    gm.get_active_creature().level = 2
    game.load_current_creature()
    check(game.hatch_in_progress and button.disabled, "AC1 hatch starts disabled")
    await create_timer(0.5).timeout
    check(game.current_creature.stage == "baby" and game.hatch_flash.color.a > 0.0 and button.disabled, "AC1 baby during flash stays disabled")
    button.pressed.emit()
    check(requests == 0, "AC2 fade cannot feed")
    await create_timer(0.5).timeout
    check(not button.disabled and is_zero_approx(game.hatch_flash.color.a), "AC1 enables after full hatch effect")
    var original: Dictionary = gm.game_data.duplicate(true)
    var digest := FileAccess.get_sha256(sm.SAVE_PATH)
    var idle: Tween = game.creature_idle_tween
    var target: float = game.creature_move_target_x
    await mouse(button)
    check(requests == 1, "AC2 routed mouse sends exactly one request")
    await mouse(button, true)
    check(requests == 1, "AC2 right click ignored")
    button.grab_focus()
    for down in [true, false]:
        var key := InputEventKey.new()
        key.keycode = KEY_SPACE
        key.pressed = down
        root.push_input(key, true)
        await process_frame
    await settle()
    check(requests == 2, "AC2 focused Space sends one request")
    for i in range(100): game.load_current_creature()
    check(button.pressed.get_connections().size() == 1, "AC2 refreshes keep one input connection")
    for i in range(10): button.pressed.emit()
    check(requests == 12, "AC2 ten presses ten requests")
    check(gm.game_data == original and FileAccess.get_sha256(sm.SAVE_PATH) == digest, "AC3 input preserves data and save bytes")
    check(game.creature_idle_tween == idle and game.creature_movement_active and game.creature_move_target_x == target, "AC3 button preserves movement and Idle")
    await capture("baby_405")
    if DisplayServer.get_name() != "headless":
        root.size = Vector2i(720, 1280)
        await settle()
        await capture("baby_720")
    for stage in ["egg", "adult"]:
        game.current_creature.stage = stage
        game.update_creature_visual()
        button.pressed.emit()
        check(button.visible and button.disabled and requests == 12, "AC1 blocked stage " + stage)
    game.current_creature = {}
    game.update_creature_visual()
    button.pressed.emit()
    check(button.visible and button.disabled and requests == 12, "AC1 empty data blocked")
    gm.get_active_creature().stage = "baby"
    game = await scene("res://scenes/game/Game.tscn")
    game.feed_requested.connect(clicked)
    await mouse(game.feed_button)
    check(requests == 13 and game.feed_button.pressed.get_connections().size() == 1, "AC2 reentry has one working connection")
    gm.clear_game_data()
    game.load_current_creature()
    check(game.feed_button.disabled, "AC1 empty load disables button")
    print("RESULT failures=", failures)
    quit(failures)
