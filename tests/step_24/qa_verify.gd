extends SceneTree

var failures := 0
var count := 0
var gm: Node
var sm: Node

func _initialize() -> void:
    call_deferred("run")

func check(condition: bool, label: String) -> void:
    print("PASS " if condition else "FAIL ", label)
    if not condition: failures += 1

func frames() -> void:
    for i in range(3): await process_frame

func observed() -> void:
    count += 1

func mouse_at(point: Vector2, down: bool) -> void:
    var motion := InputEventMouseMotion.new()
    motion.position = point
    root.push_input(motion, true)
    var event := InputEventMouseButton.new()
    event.position = point
    event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = down
    root.push_input(event, true)
    await process_frame

func click(button: Button) -> void:
    await mouse_at(button.get_global_rect().get_center(), true)
    await mouse_at(button.get_global_rect().get_center(), false)
    await frames()

func enter() -> Node:
    check(change_scene_to_file("res://scenes/game/Game.tscn") == OK, "game scene loads")
    await frames()
    current_scene.feed_requested.connect(observed)
    return current_scene

func capture(label: String) -> void:
    if DisplayServer.get_name() == "headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://qa_" + label + ".png") == OK, "render " + label)

func run() -> void:
    print("TEST_USER_DIR=", ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("step24-qa-"):
        quit(2)
        return
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    gm.create_new_game("독립 QA")
    var game = await enter()
    var button: Button = game.get_node("UI/FeedPanel/FeedButton")
    check(button.is_visible_in_tree() and button.disabled and button.text == "밥주기", "AC1 egg visible disabled Korean label")
    await click(button)
    check(count == 0, "AC2 egg coordinate click blocked")
    await capture("egg_405")
    gm.get_active_creature().level = 2
    gm.get_active_creature().egg_created_at = Time.get_unix_time_from_system() - 90.0
    game.load_current_creature()
    check(button.disabled and game.hatch_in_progress, "AC1 hatch entry blocked")
    await create_timer(0.48).timeout
    check(game.current_creature.stage == "baby" and game.hatch_flash.color.a > 0.0 and button.disabled, "AC1 baby flash fade still blocked")
    await click(button)
    check(count == 0, "AC2 real UI click during fade blocked")
    await create_timer(0.5).timeout
    check(not button.disabled and is_zero_approx(game.hatch_flash.color.a), "AC1 fade completion enables without refresh")
    var data_before: Dictionary = gm.game_data.duplicate(true)
    var hash_before := FileAccess.get_sha256(sm.SAVE_PATH)
    var idle: Tween = game.creature_idle_tween
    var expected := count
    for i in range(5):
        await click(button)
        expected += 1
        check(count == expected, "AC2 coordinate click exactly once " + str(i))
    button.grab_focus()
    for down in [true, false]:
        var key := InputEventKey.new()
        key.keycode = KEY_SPACE
        key.pressed = down
        root.push_input(key, true)
        await process_frame
    expected += 1
    check(count == expected, "AC2 focused keyboard Space exactly once")
    for i in range(37): game.load_current_creature()
    await click(button)
    expected += 1
    check(count == expected and button.pressed.get_connections().size() == 1, "AC2 refresh no duplicate request connection")
    check(gm.game_data == data_before and FileAccess.get_sha256(sm.SAVE_PATH) == hash_before, "AC3 feed leaves full data and save bytes unchanged")
    check(game.creature_idle_tween == idle and idle.is_running() and game.creature_movement_active and not game.creature_sprite.flip_h, "AC3 feed preserves Idle movement original orientation")
    var menu: Button = game.get_node("UI/BottomPanel/MenuButton")
    check(button.size == menu.size and not button.get_global_rect().intersects(menu.get_global_rect()), "AC1 same size separate menu")
    check(Rect2(Vector2.ZERO, Vector2(720,1280)).encloses(button.get_global_rect()), "AC1 feed within logical viewport")
    await capture("baby_405")
    if DisplayServer.get_name() != "headless":
        root.size = Vector2i(720,1280)
        await frames()
        await click(button)
        expected += 1
        check(count == expected, "AC2 logical resolution coordinate click")
        await capture("baby_720")
    for stage in ["egg", "adult", "", "unknown", "baby"]:
        gm.get_active_creature().stage = stage
        game.load_current_creature()
        await click(button)
        if stage == "baby": expected += 1
        check(count == expected and button.disabled == (stage != "baby"), "AC1/2 stage transition " + stage)
    game.current_creature = {}
    game.update_creature_visual()
    await click(button)
    game._on_feed_button_pressed()
    check(button.disabled and count == expected, "AC1/2 empty data UI and handler blocked")
    gm.get_active_creature().stage = "baby"
    for i in range(3):
        game = await enter()
        await click(game.feed_button)
        expected += 1
        check(count == expected, "AC2 fresh scene one request " + str(i))
    check(gm.game_data == data_before and FileAccess.get_sha256(sm.SAVE_PATH) == hash_before, "AC3 reentry preserves data and save")
    gm.clear_game_data()
    game = await enter()
    check(game.current_creature.stage == "baby" and not game.feed_button.disabled, "AC3 actual save restored after memory clear")
    # SaveManager updates last_played_at only in its disk copy; restored data
    # must match that saved snapshot, not the earlier unsaved memory timestamp.
    var restored_before: Dictionary = gm.game_data.duplicate(true)
    var disk_snapshot: Dictionary = sm.load_game()
    print("RESTORE_BASELINE memory_timestamp=", data_before.get("last_played_at"), " disk_timestamp=", disk_snapshot.get("last_played_at"))
    check(restored_before == disk_snapshot, "AC3 restored memory matches disk snapshot")
    await click(game.feed_button)
    expected += 1
    check(count == expected, "AC2 restored feed single request")
    check(gm.game_data == restored_before, "AC3 restored feed preserves restored memory")
    check(FileAccess.get_sha256(sm.SAVE_PATH) == hash_before, "AC3 restored feed preserves save bytes")
    gm.clear_game_data()
    game.load_current_creature()
    await click(game.feed_button)
    check(game.feed_button.disabled and count == expected, "AC1/2 absent active creature fails closed")
    print("RESULT QA failures=", failures)
    quit(failures)
