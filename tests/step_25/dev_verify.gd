extends SceneTree

var failures := 0
var gm: Node
var sm: Node

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ", label)
    if not ok: failures += 1

func settle() -> void:
    for i in range(3): await process_frame

func scene(path: String = "res://scenes/game/Game.tscn") -> Node:
    check(change_scene_to_file(path) == OK, "scene load")
    await settle()
    return current_scene

func click(button: Button) -> void:
    var point := button.get_global_rect().get_center()
    for down in [true, false]:
        var e := InputEventMouseButton.new()
        e.position = point
        e.button_index = MOUSE_BUTTON_LEFT
        e.pressed = down
        root.push_input(e, true)
        await process_frame
    await settle()

func capture(label: String) -> void:
    if DisplayServer.get_name() == "headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://dev_" + label + ".png") == OK, "screenshot " + label)

func run() -> void:
    print("TEST_USER_DIR=", ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("step25-"):
        quit(2)
        return
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    var args := OS.get_cmdline_user_args()
    var mode: String = args[0] if not args.is_empty() else "suite"
    if mode == "restore":
        var digest := FileAccess.get_sha256(sm.SAVE_PATH)
        var menu = await scene(ProjectSettings.get_setting("application/run/main_scene"))
        menu.continue_button.pressed.emit()
        await settle()
        var restored = current_scene
        check(restored.name == "Game" and restored.current_creature.stage == "baby", "normal menu restores baby")
        check(not restored.food_sprite.visible, "separate process does not restore food")
        await click(restored.feed_button)
        check(restored.food_sprite.visible, "restored baby can show food")
        check(FileAccess.get_sha256(sm.SAVE_PATH) == digest, "restore and request preserve disk")
        print("RESULT failures=", failures)
        quit(failures)
        return
    gm.create_new_game("STEP25 DEV")
    var game = await scene()
    check(not game.food_sprite.visible, "initial egg food hidden")
    await click(game.feed_button)
    game.feed_requested.emit()
    check(not game.food_sprite.visible, "egg UI and direct request blocked")
    gm.get_active_creature().level = 2
    gm.get_active_creature().egg_created_at = Time.get_unix_time_from_system() - 120.0
    game.load_current_creature()
    game.feed_requested.emit()
    check(not game.food_sprite.visible, "hatch request blocked")
    await create_timer(0.5).timeout
    check(game.current_creature.stage == "baby" and game.hatch_flash.color.a > 0.0, "baby while fade")
    game.feed_requested.emit()
    check(not game.food_sprite.visible, "baby fade request blocked")
    await create_timer(0.5).timeout
    check(not game.feed_button.disabled and not game.food_sprite.visible, "ready baby still hidden before input")
    check(sm.save_game(gm.game_data), "save fixture")
    var data: Dictionary = gm.game_data.duplicate(true)
    var hash_before := FileAccess.get_sha256(sm.SAVE_PATH)
    await click(game.feed_button)
    check(game.food_sprite.visible, "routed mouse displays food")
    var food: Sprite2D = game.food_sprite
    check(food.global_position == Vector2(360,900) and food.texture.get_size() == Vector2(96,96), "A fixed position and texture size")
    check(food.texture.get_image().get_pixel(0,0).a == 0.0, "transparent background")
    var food_id := food.get_instance_id()
    var idle: Tween = game.creature_idle_tween
    for i in range(10): game.feed_button.pressed.emit()
    for i in range(100): game.load_current_creature()
    check(food.visible and food.get_instance_id() == food_id and game.find_children("FoodSprite", "Sprite2D").size() == 1, "repeated input and refresh retain one image")
    check(game.feed_requested.get_connections().size() == 1, "single consumer after refresh")
    game.creature_wait_remaining = 0.0
    game.creature_move_target_x = 120.0
    var old_x: float = game.creature_sprite.position.x
    await create_timer(0.35).timeout
    check(game.creature_sprite.position.x != old_x and game.creature_idle_tween == idle and idle.is_running(), "movement and Idle continue")
    check(food.global_position == Vector2(360,900) and food.visible, "food remains fixed and visible")
    check(gm.game_data == data and FileAccess.get_sha256(sm.SAVE_PATH) == hash_before, "requests and movement preserve data and disk")
    await capture("food_405")
    if DisplayServer.get_name() != "headless":
        root.size = Vector2i(720,1280)
        await settle()
        await capture("food_720")
    for stage in ["egg", "adult", "unknown"]:
        game.current_creature.stage = stage
        game.update_creature_visual()
        game.feed_requested.emit()
        check(not food.visible, "food clears and blocks " + stage)
        game.current_creature.stage = "baby"
        game.update_creature_visual()
        check(not food.visible, "return to baby stays hidden " + stage)
        game.feed_button.pressed.emit()
    game.current_creature = {}
    game.update_creature_visual()
    game.feed_requested.emit()
    check(not food.visible, "empty state hides and blocks")
    game.load_current_creature()
    game.feed_button.grab_focus()
    for down in [true,false]:
        var key := InputEventKey.new()
        key.keycode = KEY_SPACE
        key.pressed = down
        root.push_input(key,true)
        await process_frame
    check(food.visible, "keyboard Space displays food")
    game = await scene()
    check(not is_instance_valid(food) and not game.food_sprite.visible, "scene reentry releases old food and starts hidden")
    game.feed_button.pressed.emit()
    check(game.food_sprite.visible, "reentry accepts request")
    check(sm.save_game(gm.game_data), "persist baby for separate process")
    print("RESULT failures=", failures)
    quit(failures)
