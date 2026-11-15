extends SceneTree

var failures := 0
var gm: Node
var sm: Node
var requests := 0

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ", label)
    if not ok: failures += 1

func settle() -> void:
    for i in range(3): await process_frame

func received() -> void:
    requests += 1

func click(button: Button) -> void:
    var p := button.get_global_rect().get_center()
    var motion := InputEventMouseMotion.new()
    motion.position = p
    root.push_input(motion, true)
    for down in [true, false]:
        var ev := InputEventMouseButton.new()
        ev.position = p
        ev.button_index = MOUSE_BUTTON_LEFT
        ev.pressed = down
        root.push_input(ev, true)
        await process_frame
    await settle()

func enter() -> Node:
    check(change_scene_to_file("res://scenes/game/Game.tscn") == OK, "scene load")
    await settle()
    current_scene.feed_requested.connect(received)
    return current_scene

func screenshot(label: String) -> void:
    if DisplayServer.get_name() == "headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://qa_" + label + ".png") == OK, "render " + label)

func run() -> void:
    var user_dir := ProjectSettings.globalize_path("user://")
    print("TEST_USER_DIR=", user_dir)
    if not user_dir.contains("step25-qa-"):
        quit(2)
        return
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    var mode := "suite" if OS.get_cmdline_user_args().is_empty() else OS.get_cmdline_user_args()[0]
    if mode == "resume":
        await restore()
    else:
        await suite()
    print("RESULT QA ", mode, " failures=", failures)
    quit(failures)

func suite() -> void:
    gm.create_new_game("음식 독립 QA")
    var game = await enter()
    var food: Sprite2D = game.get_node("FoodSprite")
    check(not food.visible and game.feed_button.disabled, "AC2 egg initially hidden disabled")
    await click(game.feed_button)
    game.feed_requested.emit()
    check(not food.visible and requests == 1, "AC2 invalid egg UI and direct signal cannot show food")
    await screenshot("egg_405")
    gm.get_active_creature().level = 2
    gm.get_active_creature().egg_created_at = Time.get_unix_time_from_system() - 120.0
    game.load_current_creature()
    check(game.hatch_in_progress and not food.visible, "AC2 hatch start hidden")
    await create_timer(0.47).timeout
    check(game.current_creature.stage == "baby" and game.hatch_flash.color.a > 0, "RC hatch transitions baby while fading")
    await click(game.feed_button)
    game._show_food()
    check(not food.visible and game.feed_button.disabled, "AC2 baby fade rejects input")
    await create_timer(0.5).timeout
    check(not game.feed_button.disabled and not food.visible, "AC2 fade complete enabled still hidden")
    check(food.texture.resource_path == "res://assets/food/rice_bowl.svg" and food.texture.get_size() == Vector2(96,96), "AC1 approved single 96 asset loaded")
    check(food.global_position == Vector2(360,900) and food.get_parent() == game, "AC1 fixed global center independent of pet")
    var image: Image = food.texture.get_image()
    check(image.get_pixel(0,0).a == 0 and image.get_pixel(95,95).a == 0, "AC1 transparent canvas corners")
    var before: Dictionary = gm.game_data.duplicate(true)
    var saved := FileAccess.get_sha256(sm.SAVE_PATH)
    check(not saved.is_empty() and sm.has_save_file(), "AC4 isolated hatch save exists before invariance checks")
    var idle: Tween = game.creature_idle_tween
    var connections: int = game.feed_requested.get_connections().size()
    var expected := requests
    for i in range(10):
        await click(game.feed_button)
        expected += 1
        check(food.visible and requests == expected and game.get_node("FoodSprite") == food, "AC2 click one retained image " + str(i))
    for i in range(100): game.load_current_creature()
    check(food.visible and game.feed_requested.get_connections().size() == connections and game.feed_button.pressed.get_connections().size() == 1, "AC2 100 refresh no duplicate callbacks or image")
    game.feed_button.grab_focus()
    for down in [true,false]:
        var key := InputEventKey.new()
        key.keycode = KEY_SPACE
        key.pressed = down
        root.push_input(key,true)
        await process_frame
    expected += 1
    check(requests == expected and food.visible, "AC2 keyboard Space retained single food")
    var bounds := Rect2(food.global_position - food.texture.get_size()/2, food.texture.get_size())
    check(not bounds.intersects(game.feed_button.get_global_rect()) and not bounds.intersects(game.get_node("UI/TopPanel").get_global_rect()) and not bounds.intersects(game.get_node("UI/BottomPanel").get_global_rect()), "AC1 no overlap status or buttons")
    var creature_bounds: Rect2 = game.creature_sprite.get_global_transform() * game.creature_sprite.get_rect()
    check(not bounds.intersects(creature_bounds), "AC1 food separate from creature")
    game.creature_wait_remaining = 0
    game.creature_sprite.position.x = -110
    game.creature_move_target_x = 110
    var start_y: float = game.creature_sprite.position.y
    await create_timer(0.4).timeout
    check(game.creature_sprite.position.x > -95 and game.creature_sprite.position.x < -75 and food.global_position == Vector2(360,900), "AC3 movement continues and food does not follow")
    check(idle == game.creature_idle_tween and idle.is_running() and not is_equal_approx(start_y,game.creature_sprite.position.y) and not game.creature_sprite.flip_h, "AC3 original direction and Idle maintained")
    check(gm.game_data == before and FileAccess.get_sha256(sm.SAVE_PATH) == saved, "AC4 clicks and movement preserve data and disk bytes")
    await screenshot("food_405")
    if DisplayServer.get_name() != "headless":
        root.size = Vector2i(720,1280)
        await settle()
        await screenshot("food_720")
    for stage in ["egg", "adult", "unknown"]:
        gm.get_active_creature().stage = stage
        game.load_current_creature()
        await click(game.feed_button)
        game._on_feed_button_pressed()
        check(not food.visible and game.feed_button.disabled and requests == expected, "AC2/3 stage clears rejects " + stage)
        gm.get_active_creature().stage = "baby"
        game.load_current_creature()
        check(not food.visible, "AC3 qualifying again does not resurrect food " + stage)
        await click(game.feed_button)
        expected += 1
    game.current_creature = {}
    game.update_creature_visual()
    await click(game.feed_button)
    game._on_feed_button_pressed()
    check(not food.visible and game.feed_button.disabled and requests == expected, "AC2/3 empty data hides and rejects")
    game.load_current_creature()
    await click(game.feed_button)
    check(food.visible, "AC3 food can be requested after data returns")
    var old_food = weakref(food)
    game = await enter()
    check(old_food.get_ref() == null and not game.food_sprite.visible, "AC3 scene destroys old image reentry hidden")
    await click(game.feed_button)
    check(game.food_sprite.visible, "AC3 scene reentry request works")
    check(gm.game_data == before and FileAccess.get_sha256(sm.SAVE_PATH) == saved, "AC4 entire state matrix preserves memory and save")
    # Leave the existing hatch-generated baby save for a separate process.
    var fixture: Dictionary = sm.load_game()
    check(not fixture.is_empty() and fixture.active_creatures[0].stage == "baby", "AC3 separate-process baby fixture remains persisted without food")

func restore() -> void:
    var saved := FileAccess.get_sha256(sm.SAVE_PATH)
    var disk: Dictionary = sm.load_game()
    check(change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene")) == OK, "RC normal MainMenu load")
    await settle()
    check(gm.game_data.is_empty() and not current_scene.continue_button.disabled, "RC menu continue available without loading memory")
    await click(current_scene.continue_button)
    check(current_scene.name == "Game" and current_scene.current_creature.stage == "baby", "AC3 normal menu coordinate continue restores baby")
    check(not current_scene.food_sprite.visible and not current_scene.feed_button.disabled, "AC3 process restart food initially hidden")
    check(gm.game_data == disk and FileAccess.get_sha256(sm.SAVE_PATH) == saved, "AC4 continue preserves all saved fields bytes")
    await click(current_scene.feed_button)
    check(current_scene.food_sprite.visible, "AC2 restored baby food request works")
    check(gm.game_data == disk and FileAccess.get_sha256(sm.SAVE_PATH) == saved, "AC4 restored request preserves memory and bytes")
