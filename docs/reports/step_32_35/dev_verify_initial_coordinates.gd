extends SceneTree
var failures := 0
var gm: Node
var sm: Node
var game: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ", label)
    if not ok: failures += 1
func settle() -> void:
    for i in range(3): await process_frame
func enter(fault := false) -> void:
    if current_scene != null:
        current_scene.queue_free()
        current_scene = null
        await settle()
    game = load("res://scenes/game/Game.tscn").instantiate()
    if fault: game.set_script(load("res://dev_failure.gd"))
    root.add_child(game)
    current_scene = game
    await settle()
func spawn_poop() -> void:
    game.poop_timer.paused = false
    game.poop_timer.start(0.03)
    await create_timer(0.08).timeout
    check(game.poop_present and game.poop_image.visible, "32 actual Timer spawns image")
func press(point := Vector2(540,900), button := MOUSE_BUTTON_LEFT, down := true) -> void:
    var event := InputEventMouseButton.new()
    event.position = point
    event.button_index = button
    event.pressed = down
    root.push_input(event)
func touch(point := Vector2(540,900), down := true) -> void:
    var event := InputEventScreenTouch.new()
    event.position = point
    event.index = 0
    event.pressed = down
    root.push_input(event)
func finish() -> void:
    game.cleaning_tween.pause()
    game.cleaning_tween.custom_step(0.601)
func shot(label: String) -> void:
    if DisplayServer.get_name() == "headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://dev_"+label+".png") == OK,"35 capture "+label)
func end() -> void:
    current_scene.queue_free()
    current_scene = null
    game = null
    await settle()
    if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
    print("RESULT failures=", failures)
    quit(failures)
func run() -> void:
    if not ProjectSettings.globalize_path("user://").contains("step32-35-dev-"):
        quit(2)
        return
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    if OS.get_cmdline_user_args().has("restore"):
        gm.game_data = {}
        await enter()
        check(game.current_creature.level == 2 and game.current_creature.affection == 0, "34 separate process saved level boundary")
        check(not game.poop_present and game.poop_timer.time_left > 59, "32 restored game fresh timer no poop persistence")
        await end()
        return
    gm.create_new_game("STEP32-35 DEV")
    await enter()
    check(game.poop_timer.is_stopped() and not game.poop_present, "32 egg no poop")
    game._show_poop()
    check(not game.poop_present, "32 invalid direct spawn ignored")
    gm.get_active_creature().stage = "baby"
    game.load_current_creature()
    check(game.poop_timer.time_left >= 60 and game.poop_timer.time_left <= 120, "32 baby full interval")
    check(game.poop_image.get_global_rect() == Rect2(492,852,96,96), "32 fixed size and position")
    if OS.get_cmdline_user_args().has("real"):
        var wait: float = game.poop_timer.time_left
        var started := Time.get_ticks_msec()
        while not game.poop_present and Time.get_ticks_msec()-started < 125000: await process_frame
        var elapsed := (Time.get_ticks_msec()-started)/1000.0
        print("REAL_INTERVAL=",wait," ELAPSED=",elapsed)
        check(game.poop_present and absf(wait-elapsed)<0.3, "32 full real timer visible poop")
        var remaining: float = game.poop_timer.time_left
        await create_timer(0.2).timeout
        check(game.poop_timer.paused and is_equal_approx(remaining,game.poop_timer.time_left), "32 real occupied timer paused")
        await end()
        return
    await spawn_poop()
    var remaining: float = game.poop_timer.time_left
    game._show_poop()
    game._on_poop_timeout()
    await create_timer(0.1).timeout
    check(game.poop_present and is_equal_approx(remaining,game.poop_timer.time_left), "32 max one and paused remaining")
    await shot("poop")
    var before: int = gm.get_active_creature().affection
    press(Vector2(491,900))
    press(Vector2(540,900),MOUSE_BUTTON_RIGHT)
    press(Vector2(540,900),MOUSE_BUTTON_LEFT,false)
    touch(Vector2(540,900),false)
    touch(Vector2(600,900))
    check(game.poop_present and gm.get_active_creature().affection == before,"33 invalid mouse touch ignored")
    for action in ["feed","play"]:
        game.creature_sprite.position.x = 0
        if action == "feed": game._on_feed_button_pressed()
        else: game._on_play_button_pressed()
        press()
        check(game.poop_present and not game.cleaning_busy,"33 blocked while "+action)
        var tween: Tween = game.feeding_tween if action == "feed" else game.playing_tween
        tween.pause()
        tween.custom_step(1.401 if action == "feed" else 1.201)
        check(game.poop_present and game.poop_timer.paused,"33 no queued cleanup "+action)
    before = gm.get_active_creature().affection
    game.creature_sprite.position.x = 67
    var texture: Texture2D = game.creature_sprite.texture
    var scale: Vector2 = game.creature_sprite.scale
    press()
    check(not game.poop_present and game.cleaning_busy and gm.get_active_creature().affection == before+1,"33 mouse cleanup 34 exactly one immediate reward")
    check(game.feed_button.disabled and game.play_button.disabled and game.poop_timer.paused,"35 all care and timer blocked")
    var full: float = game.poop_timer.time_left
    check(full >= 60 and full <= 120,"32 success new full interval")
    game.cleaning_tween.pause()
    var generation: int = game.cleaning_generation
    game._finish_cleaning(generation)
    check(game.cleaning_busy,"35 early callback ignored")
    game._on_feed_button_pressed()
    game._on_play_button_pressed()
    touch()
    press()
    game._clean_poop()
    game._show_poop()
    check(not game.feeding_busy and not game.playing_busy and not game.poop_present and gm.get_active_creature().affection==before+1,"33/34/35 duplicates and other actions ignored")
    game.cleaning_tween.custom_step(0.3)
    check(is_equal_approx(game.creature_sprite.position.y,-6) and is_equal_approx(game.creature_sprite.position.x,67),"35 midpoint 6px and current x")
    check(game.creature_sprite.texture==texture and game.creature_sprite.scale==scale and game.creature_sprite.rotation==0,"35 original appearance unchanged")
    await shot("relief")
    game.cleaning_tween.custom_step(0.301)
    check(not game.cleaning_busy and game.creature_movement_active and game.creature_idle_tween.is_running(),"35 completion resumes idle and movement")
    check(is_equal_approx(game.creature_sprite.position.x,67) and is_zero_approx(game.creature_sprite.position.y),"35 exact completion position")
    game._finish_cleaning(generation)
    check(gm.get_active_creature().affection==before+1 and not game.poop_timer.paused,"34 no completion reward and timer resumes")
    await spawn_poop()
    before = gm.get_active_creature().affection
    touch()
    check(not game.poop_present and game.cleaning_busy and gm.get_active_creature().affection==before+1,"33 synthetic touchscreen real viewport input")
    finish()
    await enter(true)
    for failure in ["add","save"]:
        await spawn_poop()
        var target: Dictionary = gm.get_active_creature()
        target.affection = 9
        target.level = 1
        target.affection_to_next_level = 10
        sm.save_game(gm.game_data)
        var digest := FileAccess.get_sha256(sm.SAVE_PATH)
        game.deny_add = failure=="add"
        game.deny_save = failure=="save"
        press()
        check(target.affection==9 and target.level==1 and target.affection_to_next_level==10,"34 three field rollback "+failure)
        check(game.poop_present and not game.cleaning_busy and game.feed_message.visible,"34 keeps poop and offers retry "+failure)
        check(FileAccess.get_sha256(sm.SAVE_PATH)==digest,"34 failure leaves disk unchanged "+failure)
        game.deny_add = false
        game.deny_save = false
        touch()
        check(not game.poop_present and target.level==2 and target.affection==0,"34 retry boundary level up "+failure)
        check(game.level_label.text=="LV. 2" and game.affection_bar.value==0 and not game.feed_message.visible,"34 UI and retry clears own notice "+failure)
        finish()
    for invalid in [-1,"bad",1.5,INF]:
        await spawn_poop()
        var old: Variant = game.current_creature.affection
        game.current_creature.affection = invalid
        press()
        check(game.poop_present and not game.cleaning_busy and game.current_creature.affection==invalid,"34 invalid input rejected "+str(invalid))
        game.current_creature.affection = old
        game._clear_poop()
        game._sync_poop_timer()
    await spawn_poop()
    game.current_creature.stage = "egg"
    game._update_feed_button()
    check(not game.poop_present and game.poop_timer.is_stopped(),"32 invalid stage clears poop")
    game.current_creature.stage = "baby"
    game.load_current_creature()
    await spawn_poop()
    press()
    var old_target: Dictionary = game.current_creature
    var old_affection: int = old_target.affection
    generation = game.cleaning_generation
    gm.create_new_game("Replacement")
    gm.get_active_creature().stage = "baby"
    game.load_current_creature()
    game._finish_cleaning(generation)
    check(not game.cleaning_busy and not game.poop_present and game.cleaning_tween==null,"35 replacement cancels sequence")
    check(old_target.affection==old_affection and gm.get_active_creature().affection==0,"34 replacement no extra reward")
    check(game.poop_timer.time_left>=60,"32 replacement fresh interval")
    await spawn_poop()
    await enter()
    check(not game.poop_present and not game.cleaning_busy,"32 reentry clears poop")
    await spawn_poop()
    press()
    await enter()
    check(not game.cleaning_busy and game.creature_idle_tween.is_running(),"35 exit mid relief clears and reentry resumes")
    game.current_creature.level = 1
    game.current_creature.affection = 9
    game.current_creature.affection_to_next_level = 10
    await spawn_poop()
    press()
    finish()
    check(game.current_creature.level==2 and game.current_creature.affection==0,"34 final restore seed")
    await end()
