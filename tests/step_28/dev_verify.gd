extends SceneTree

var failures := 0
var requests := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ", label)
    if not ok: failures += 1
func settle() -> void:
    for i in range(3): await process_frame
func click(button: Button, which: int = MOUSE_BUTTON_LEFT) -> void:
    for down in [true, false]:
        var e := InputEventMouseButton.new()
        e.position = button.get_global_rect().get_center()
        e.button_index = which
        e.pressed = down
        root.push_input(e, true)
        await process_frame
func shot(label: String) -> void:
    if DisplayServer.get_name() == "headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://dev_"+label+".png") == OK, "capture "+label)
func run() -> void:
    if not ProjectSettings.globalize_path("user://").contains("step28-"):
        quit(2)
        return
    var gm = root.get_node("GameManager")
    var sm = root.get_node("SaveManager")
    gm.create_new_game("STEP28 DEV")
    var game = load("res://scenes/game/Game.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    await settle()
    game.play_requested.connect(func(): requests += 1)
    check(game.play_button.visible and game.play_button.disabled, "egg visible disabled")
    await click(game.play_button)
    game._on_play_button_pressed()
    check(requests == 0, "egg UI and handler reject")
    await shot("egg_405")
    var pet: Dictionary = gm.get_active_creature()
    pet.stage = "baby"
    game.load_current_creature()
    check(not game.play_button.disabled, "baby enabled")
    check(game.play_button.get_global_rect() == Rect2(280,1160,160,80), "central rect")
    check(game.play_button.text == "놀아주기", "label")
    check(sm.save_game(gm.game_data), "seed isolated save")
    var before: Dictionary = gm.game_data.duplicate(true)
    var digest := FileAccess.get_sha256(sm.SAVE_PATH)
    for i in range(100): game.load_current_creature()
    check(game.play_button.pressed.get_connections().size() == 1, "single connection after refresh")
    for i in range(10): await click(game.play_button)
    check(requests == 10, "ten clicks ten requests")
    await click(game.play_button, MOUSE_BUTTON_RIGHT)
    check(requests == 10, "right click ignored")
    game.play_button.grab_focus()
    for down in [true,false]:
        var key := InputEventKey.new()
        key.keycode = KEY_SPACE
        key.pressed = down
        root.push_input(key,true)
        await process_frame
    check(requests == 11, "space emits once")
    check(gm.game_data == before and FileAccess.get_sha256(sm.SAVE_PATH) == digest, "play never mutates progress or disk")
    check(game.creature_movement_active and game.creature_idle_tween.is_running() and not game.food_sprite.visible, "play preserves idle movement and food")
    game.hatch_in_progress = true
    game._update_feed_button()
    game._on_play_button_pressed()
    check(game.play_button.disabled and requests == 11, "hatch blocked")
    game.hatch_in_progress = false
    game._update_feed_button()
    game.stop_creature_movement()
    game.creature_sprite.position.x = 0
    game._on_feed_button_pressed()
    var feeding: Tween = game.feeding_tween
    feeding.pause()
    for i in range(10): game._on_play_button_pressed()
    await click(game.play_button)
    check(game.play_button.disabled and requests == 11, "feeding blocks without queue")
    await shot("feeding_405")
    feeding.custom_step(1.401)
    check(not game.play_button.disabled and requests == 11 and pet.affection == 1, "feed completion enables without replay")
    game.feed_message.text = "저장 실패: 다시 시도해 주세요."
    game.feed_message.show()
    await click(game.play_button)
    check(requests == 12 and game.feed_message.visible, "play keeps failure notice")
    for size in [Vector2i(405,720), Vector2i(720,1280)]:
        if DisplayServer.get_name() != "headless": root.size = size
        await settle()
        var rect: Rect2 = game.play_button.get_global_rect()
        check(not rect.intersects(game.feed_button.get_global_rect()) and not rect.intersects(game.get_node("UI/BottomPanel").get_global_rect()) and not rect.intersects(game.feed_message.get_global_rect()), "no overlap "+str(size))
        await shot("baby_"+str(size.x))
    pet.stage = "unknown"
    game.load_current_creature()
    game._on_play_button_pressed()
    check(game.play_button.disabled and requests == 12, "unsupported blocked")
    pet.stage = "baby"
    game.load_current_creature()
    gm.game_data.active_creatures[0] = pet.duplicate(true)
    game._on_play_button_pressed()
    check(requests == 12, "stale target rejected")
    game.load_current_creature()
    game._on_play_button_pressed()
    check(requests == 13, "replacement refresh enables")
    gm.game_data.active_creatures.clear()
    game.load_current_creature()
    game._on_play_button_pressed()
    check(game.play_button.disabled and requests == 13, "empty blocked")
    print("RESULT failures=", failures)
    quit(failures)

