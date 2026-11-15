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
    check(change_scene_to_file(path) == OK, "load scene")
    await settle()
    return current_scene

func mouse(button: Button) -> void:
    for down in [true,false]:
        var event := InputEventMouseButton.new()
        event.position = button.get_global_rect().get_center()
        event.button_index = MOUSE_BUTTON_LEFT
        event.pressed = down
        root.push_input(event,true)
        await process_frame

func capture(label: String) -> void:
    if DisplayServer.get_name() == "headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://dev_"+label+".png") == OK, "capture "+label)

func run() -> void:
    print("TEST_USER_DIR=",ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("step26-"):
        quit(2)
        return
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    var args := OS.get_cmdline_user_args()
    if args.has("restore"):
        var digest := FileAccess.get_sha256(sm.SAVE_PATH)
        var menu = await scene(ProjectSettings.get_setting("application/run/main_scene"))
        await mouse(menu.continue_button)
        await settle()
        var game = current_scene
        check(game.name == "Game" and game.current_creature.stage == "baby", "normal menu baby restore")
        check(not game.feeding_busy and not game.food_sprite.visible and not game.feed_button.disabled, "restart clears food animation")
        check(not digest.is_empty() and FileAccess.get_sha256(sm.SAVE_PATH) == digest, "continue preserves disk")
        print("RESULT failures=", failures)
        quit(failures)
        return
    gm.create_new_game("STEP26 DEV")
    var game = await scene()
    await mouse(game.feed_button)
    game.feed_requested.emit()
    check(not game.feeding_busy and not game.food_sprite.visible, "egg blocks input")
    gm.get_active_creature().level = 2
    gm.get_active_creature().egg_created_at = Time.get_unix_time_from_system() - 120.0
    game.load_current_creature()
    await create_timer(0.5).timeout
    game.feed_requested.emit()
    check(game.current_creature.stage == "baby" and not game.feeding_busy and not game.food_sprite.visible, "baby hatch fade blocks input")
    await create_timer(0.5).timeout
    check(sm.save_game(gm.game_data), "seed save succeeds")
    var data: Dictionary = gm.game_data.duplicate(true)
    var digest := FileAccess.get_sha256(sm.SAVE_PATH)
    check(not digest.is_empty(), "nonempty save hash")
    var baseline: Vector2 = game.creature_idle_base_position
    var scale_before: Vector2 = game.creature_sprite.scale
    # Deterministic engine Tween sampling verifies exact approach, dips and fade.
    for offset in [-120.0, 0.0, 120.0]:
        game.stop_creature_movement()
        game.creature_sprite.position.x = baseline.x + offset
        game._on_feed_button_pressed()
        var tween: Tween = game.feeding_tween
        tween.pause()
        check(game.feeding_busy and game.feed_button.disabled and game.food_sprite.visible, "starts busy with food "+str(offset))
        check(game.creature_sprite.position.x == baseline.x + offset, "no entry teleport "+str(offset))
        for i in range(10): game._on_feed_button_pressed()
        for i in range(100): game.load_current_creature()
        check(game.feeding_tween == tween and not game.creature_movement_active, "repeat refresh does not restart "+str(offset))
        if offset != 0.0:
            tween.custom_step(1.0)
            check(absf(game.creature_sprite.position.x - (baseline.x + offset * 0.5)) < 0.01, "60px per second approach "+str(offset))
            tween.custom_step(1.0)
        tween.custom_step(0.00001)
        check(absf(game.creature_sprite.position.x - baseline.x) < 0.01 and game.creature_idle_tween == null, "center reached and Idle paused")
        for cycle in range(3):
            tween.custom_step(0.2)
            check(absf(game.creature_sprite.position.y - baseline.y - 6.0) < 0.01, "dip 6px cycle "+str(cycle))
            tween.custom_step(0.2)
            check(absf(game.creature_sprite.position.y - baseline.y) < 0.01, "return cycle "+str(cycle))
        tween.custom_step(0.1)
        check(absf(game.food_sprite.modulate.a - 0.5) < 0.01 and game.feeding_busy, "fade half at .1")
        tween.custom_step(0.1001)
        check(not game.feeding_busy and not game.food_sprite.visible and game.food_sprite.modulate.a == 1.0, "cycle completes and resets food")
        check(game.creature_idle_tween.is_running() and game.creature_movement_active and not game.feed_button.disabled, "normal movement Idle button return")
    # Cancel in each phase, then wait beyond the previous cycle to catch stale callbacks.
    for elapsed in [0.4, 2.3, 3.3]:
        game.stop_creature_movement()
        game.creature_sprite.position.x = baseline.x + 120.0
        game._on_feed_button_pressed()
        var tween: Tween = game.feeding_tween
        tween.pause()
        tween.custom_step(elapsed)
        game.current_creature.stage = "adult"
        game.update_creature_visual()
        check(not tween.is_valid() and not game.feeding_busy and not game.food_sprite.visible, "cancel phase "+str(elapsed))
        check(game.creature_sprite.position == baseline and game.food_sprite.modulate.a == 1.0, "cancel phase resets transforms")
        game.current_creature.stage = "baby"
        game.update_creature_visual()
    game.stop_creature_movement()
    game.creature_sprite.position.x = baseline.x - 120.0
    await mouse(game.feed_button)
    check(game.feeding_busy, "routed mouse begins real time cycle")
    await create_timer(0.45).timeout
    check(game.creature_sprite.position.x > baseline.x - 120.0 and game.creature_sprite.position.x < baseline.x, "real approach moves toward center")
    await capture("approach_405")
    await create_timer(1.7).timeout
    check(game.feeding_busy and not game.creature_movement_active, "real eating phase busy")
    await capture("eating_405")
    if DisplayServer.get_name() != "headless":
        root.size = Vector2i(720,1280)
        await settle()
        await capture("eating_720")
    await create_timer(1.5).timeout
    check(not game.feeding_busy and not game.food_sprite.visible and game.creature_movement_active, "real cycle complete no queued feed")
    await capture("completed_720")
    check(game.creature_sprite.scale == scale_before and not game.creature_sprite.flip_h and is_zero_approx(game.creature_sprite.rotation), "original appearance preserved")
    check(gm.game_data == data and FileAccess.get_sha256(sm.SAVE_PATH) == digest, "all cycles preserve game data and save")
    game.feed_button.grab_focus()
    for down in [true,false]:
        var key := InputEventKey.new()
        key.keycode = KEY_SPACE
        key.pressed = down
        root.push_input(key,true)
        await process_frame
    check(game.feeding_busy, "Space starts next cycle without cooldown")
    var old: Tween = game.feeding_tween
    game = await scene()
    check(not old.is_valid() and not game.feeding_busy and not game.food_sprite.visible, "exit kills tween reentry idle")
    await create_timer(3.5).timeout
    check(not game.feeding_busy and not game.food_sprite.visible and game.creature_movement_active, "old callbacks never resurrect cycle")
    game._on_feed_button_pressed()
    game.current_creature = {}
    game.update_creature_visual()
    game.feed_requested.emit()
    check(not game.feeding_busy and not game.food_sprite.visible and game.feed_button.disabled, "empty data cancels and blocks")
    print("RESULT failures=", failures)
    quit(failures)
