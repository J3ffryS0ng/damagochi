extends SceneTree
var failures := 0
var gm: Node
var sm: Node
func _initialize() -> void:
    call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("QA_PASS " if ok else "QA_FAIL ", label)
    if not ok: failures += 1
func settle() -> void:
    await process_frame
    await process_frame
    await process_frame
func enter(path: String) -> Node:
    check(change_scene_to_file(path) == OK, "scene opens " + path)
    await settle()
    return current_scene
func run() -> void:
    print("QA_USER_DIR=", ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("step23-qa-"):
        quit(99)
        return
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    sm.delete_save()
    var menu = await enter(ProjectSettings.get_setting("application/run/main_scene"))
    check(menu.continue_button.disabled, "new user continue disabled")
    menu.start_button.pressed.emit()
    await settle()
    check(current_scene.name == "NameEntry", "normal new game reaches name entry")
    current_scene.name_input.text = "독립 QA"
    current_scene.confirm_button.pressed.emit()
    await settle()
    var game = current_scene
    check(game.name == "Game" and gm.get_active_creature().stage == "egg", "normal name submission creates egg")
    var pos: Vector2 = game.creature_sprite.position
    await create_timer(0.4).timeout
    check(game.creature_sprite.position == pos and not game.is_processing(), "egg never moves")
    gm.get_active_creature().egg_created_at = Time.get_unix_time_from_system() - 61.0
    var click := InputEventMouseButton.new()
    click.button_index = MOUSE_BUTTON_LEFT
    click.pressed = true
    for i in range(10): game._on_egg_touch_area_input_event(root, click, 0)
    check(game.hatch_in_progress and not game.egg_touch_area.input_pickable, "level and time permit hatch; input locked")
    await create_timer(0.15).timeout
    check(game.hatch_flash.color.a > 0.0, "hatch light appears")
    await create_timer(1.0).timeout
    check(gm.get_active_creature().stage == "baby" and sm.load_game().active_creatures[0].stage == "baby", "hatch persists baby")
    check(game.creature_movement_active and game.creature_idle_tween.is_running(), "hatched baby moves with Idle")
    var data: Dictionary = gm.game_data.duplicate(true)
    var digest := FileAccess.get_sha256(sm.SAVE_PATH)
    var original_scale: Vector2 = game.creature_sprite.scale
    var fixed_hitbox: Transform2D = game.egg_touch_area.global_transform
    game.set_process(false)
    game.creature_movement_rng.seed = 97023
    game.creature_sprite.position.x = -120.0
    game.creature_move_target_x = 120.0
    game.creature_wait_remaining = 0.0
    game._process(0.125)
    check(is_equal_approx(game.creature_sprite.position.x, -112.5), "60px/s measured with 125ms delta")
    game._process(30.0)
    check(game.creature_sprite.position.x == 120.0, "30s delayed frame clamps to boundary destination")
    var wait: float = game.creature_wait_remaining
    check(wait >= 1.0 and wait <= 3.0, "arrival samples 1-3 second wait")
    game._process(wait * 0.5)
    check(game.creature_sprite.position.x == 120.0 and is_equal_approx(game.creature_wait_remaining, wait * 0.5), "wait consumes time without movement")
    game._process(wait * 0.5)
    check(game.creature_wait_remaining == 0.0 and game.creature_move_target_x >= -120.0 and game.creature_move_target_x <= 120.0, "wait expiry chooses bounded new destination")
    var bounds := true
    var speed := true
    var waits := true
    var left := 0
    var right := 0
    var destinations := {}
    var arrivals := {}
    for i in range(20000):
        var before: float = game.creature_sprite.position.x
        var prior_wait: float = game.creature_wait_remaining
        var delta: float = [0.005, 0.017, 0.033, 0.08][i % 4]
        game._process(delta)
        var after: float = game.creature_sprite.position.x
        bounds = bounds and after >= -120.0001 and after <= 120.0001
        speed = speed and absf(after - before) <= 60.0 * delta + 0.001
        if prior_wait > 0.0: waits = waits and before == after
        if prior_wait == 0.0 and game.creature_wait_remaining > 0.0:
            waits = waits and game.creature_wait_remaining >= 1.0 and game.creature_wait_remaining <= 3.0
            arrivals[game.creature_wait_remaining] = true
        if after < before: left += 1
        if after > before: right += 1
        destinations[game.creature_move_target_x] = true
    check(bounds and speed and waits, "675 simulated seconds variable-frame speed bounds waiting")
    check(left > 0 and right > 0 and destinations.size() > 30 and arrivals.size() > 30, "random targets and waits vary; both directions occur")
    print("QA_SAMPLES destinations=", destinations.size(), " arrivals=", arrivals.size(), " left=", left, " right=", right)
    game.stop_creature_idle()
    game.start_creature_idle()
    game.creature_sprite.position.x = -120.0
    game.creature_move_target_x = 120.0
    game.creature_wait_remaining = 0.0
    game.set_process(true)
    var elapsed := 0.0
    var min_y := 100.0
    var max_y := -100.0
    var csv := FileAccess.open("res://qa_positions.csv", FileAccess.WRITE)
    csv.store_line("seconds,x,y,waiting")
    while elapsed < 7.0:
        await process_frame
        elapsed += game.get_process_delta_time()
        var p: Vector2 = game.creature_sprite.position
        min_y = minf(min_y,p.y)
        max_y = maxf(max_y,p.y)
        csv.store_line("%f,%f,%f,%f" % [elapsed,p.x,p.y,game.creature_wait_remaining])
    csv.close()
    check(min_y >= -4.001 and min_y < -3.95 and max_y <= 0.001 and max_y > -0.05, "actual 7s Idle amplitude and baseline")
    check(not game.creature_sprite.flip_h and not game.creature_sprite.flip_v and game.creature_sprite.scale == original_scale and game.creature_sprite.rotation == 0.0, "original orientation scale rotation unchanged")
    check(game.egg_touch_area.global_transform == fixed_hitbox and game.get_node("PetArea").global_position == Vector2(360,650), "hitbox and center remain fixed")
    var half: float = game.creature_sprite.texture.get_width() * original_scale.x / 2.0
    check(240.0-half >= 0.0 and 480.0+half <= 720.0, "full sprite fits viewport at extreme centers")
    check(gm.game_data == data and FileAccess.get_sha256(sm.SAVE_PATH) == digest, "movement preserves complete game data and save bytes")
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        check(root.get_texture().get_image().save_png("res://qa_baby.png") == OK, "actual renderer capture")
    var idle: Tween = game.creature_idle_tween
    var target: float = game.creature_move_target_x
    for i in range(100): game.load_current_creature()
    await settle()
    check(idle == game.creature_idle_tween and target == game.creature_move_target_x and get_processed_tweens().size() == 1, "100 refreshes preserve one Idle and one movement target")
    for stage in ["egg", "adult", "baby"]:
        gm.get_active_creature().stage = stage
        game.load_current_creature()
        if stage != "baby": check(not game.is_processing() and game.creature_sprite.position == Vector2.ZERO, "nonbaby cleanup " + stage)
    game.current_creature = {}
    game.update_creature_visual()
    check(not game.is_processing() and game.creature_sprite.position == Vector2.ZERO, "empty visual cleanup")
    game.load_current_creature()
    var old: WeakRef = weakref(game)
    var old_idle: Tween = game.creature_idle_tween
    game = await enter("res://scenes/game/Game.tscn")
    check(old.get_ref() == null and not old_idle.is_valid(), "scene exit removes old node and Tween")
    check(game.creature_idle_base_position == Vector2.ZERO and absf(game.creature_sprite.position.x) < 8.0 and game.creature_movement_active, "reentry starts near center, ignoring previous x")
    print("QA_RESULT failures=", failures)
    quit(failures)
