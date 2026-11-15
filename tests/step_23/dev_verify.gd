extends SceneTree

var failures := 0
var gm: Node
var sm: Node

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ", label)
    if not ok:
        failures += 1

func scene() -> Node:
    change_scene_to_file("res://scenes/game/Game.tscn")
    await process_frame
    await process_frame
    return current_scene

func run() -> void:
    print("TEST_USER_DIR=", ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("step23"):
        quit(2)
        return
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    gm.create_new_game("STEP23 DEV")
    var game = await scene()
    check(not game.creature_movement_active and not game.is_processing(), "AC3 egg never moves")
    gm.get_active_creature().stage = "baby"
    game.load_current_creature()
    check(game.creature_movement_active and game.creature_idle_tween.is_running(), "AC2 baby starts movement and Idle")
    # Godot removes the killed egg Tween from the tree on the next frame.
    await process_frame
    await process_frame
    var idle: Tween = game.creature_idle_tween
    var target: float = game.creature_move_target_x
    for i in range(100):
        game.load_current_creature()
    check(game.creature_idle_tween == idle and game.creature_move_target_x == target and get_processed_tweens().size() == 1, "AC3 100 refreshes preserve single Idle and movement")
    sm.save_game(gm.game_data)
    var digest := FileAccess.get_sha256(sm.SAVE_PATH)
    var data: Dictionary = gm.game_data.duplicate(true)
    var baseline: Vector2 = game.creature_idle_base_position
    var scale_before: Vector2 = game.creature_sprite.scale
    var pet_position: Vector2 = game.get_node("PetArea").position
    var touch_position: Vector2 = game.egg_touch_area.position
    game.set_process(false)
    game.creature_movement_rng.seed = 230060
    game.creature_sprite.position.x = 0.0
    game.creature_move_target_x = 120.0
    game.creature_wait_remaining = 0.0
    game._process(0.5)
    check(is_equal_approx(game.creature_sprite.position.x, 30.0), "AC1 60px per second")
    game._process(20.0)
    check(game.creature_sprite.position.x == 120.0, "AC1 long frame clamps at target")
    check(game.creature_wait_remaining >= 1.0 and game.creature_wait_remaining <= 3.0, "AC1 arrival wait in 1-3 seconds")
    game._process(0.25)
    check(game.creature_sprite.position.x == 120.0, "AC1 waiting holds position")
    var bounds_ok := true
    var speed_ok := true
    var wait_ok := true
    var left := false
    var right := false
    var destinations := {}
    for i in range(36000):
        var previous: float = game.creature_sprite.position.x
        game._process(1.0 / 60.0)
        var x: float = game.creature_sprite.position.x
        bounds_ok = bounds_ok and x >= -120.001 and x <= 120.001
        speed_ok = speed_ok and absf(x - previous) <= 1.001
        wait_ok = wait_ok and game.creature_wait_remaining >= 0.0 and game.creature_wait_remaining <= 3.0
        left = left or x < previous
        right = right or x > previous
        destinations[game.creature_move_target_x] = true
    check(bounds_ok and speed_ok and wait_ok, "AC1 ten simulated minutes bounds speed waits")
    check(left and right and destinations.size() > 10, "AC1 random destinations and both directions")
    game.set_process(true)
    var min_y := 999.0
    var max_y := -999.0
    var start := Time.get_ticks_msec()
    var initial_x: float = game.creature_sprite.position.x
    var moved := false
    var observations := FileAccess.open("res://dev_positions.csv", FileAccess.WRITE)
    observations.store_line("ms,x,y,wait")
    while Time.get_ticks_msec() - start < 6500:
        await process_frame
        var p: Vector2 = game.creature_sprite.position
        min_y = minf(min_y, p.y)
        max_y = maxf(max_y, p.y)
        moved = moved or absf(p.x - initial_x) > 1.0
        observations.store_line("%d,%f,%f,%f" % [Time.get_ticks_msec() - start, p.x, p.y, game.creature_wait_remaining])
    observations.close()
    check(moved and min_y < -3.9 and max_y > -0.1 and min_y >= -4.001 and max_y <= 0.001, "AC2 real time x movement with full 4px Idle")
    check(not game.creature_sprite.flip_h and game.creature_sprite.scale == scale_before and game.creature_sprite.rotation == 0.0, "AC2 original orientation scale rotation")
    check(game.get_node("PetArea").position == pet_position and game.egg_touch_area.position == touch_position, "AC2 PetArea and egg hitbox fixed")
    var half_width: float = game.creature_sprite.texture.get_width() * absf(scale_before.x) * 0.5
    check(240.0 - half_width >= 0.0 and 480.0 + half_width <= 720.0, "AC1 entire texture inside screen at both bounds")
    check(gm.game_data == data and FileAccess.get_sha256(sm.SAVE_PATH) == digest, "AC4 movement changes neither game data nor save")
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://dev_baby.png")
    for stage in ["egg", "unknown"]:
        game.current_creature.stage = stage
        game.update_creature_visual()
        check(not game.creature_movement_active and not game.is_processing() and game.creature_sprite.position == baseline, "AC3 stop/reset " + stage)
    game.current_creature.stage = "baby"
    game.update_creature_visual()
    game.current_creature = {}
    game.update_creature_visual()
    check(not game.creature_movement_active and game.creature_sprite.position == baseline, "AC3 empty cleanup")
    gm.get_active_creature().stage = "baby"
    game.load_current_creature()
    var old_game: WeakRef = weakref(game)
    var old_idle: Tween = game.creature_idle_tween
    game = await scene()
    check(old_game.get_ref() == null and not old_idle.is_valid() and game.creature_movement_active, "AC3 exit frees old movement and restarts")
    game.stop_creature_movement()
    game.stop_creature_movement()
    check(game.creature_sprite.position.x == baseline.x, "AC3 repeated stop resets x")
    print("RESULT failures=", failures)
    quit(failures)
