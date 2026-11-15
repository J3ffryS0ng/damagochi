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
func enter() -> void:
    change_scene_to_file("res://scenes/game/Game.tscn")
    await settle()
    game = current_scene
func begin(x: float) -> Tween:
    game.creature_sprite.position.x = x
    game._on_play_button_pressed()
    var t: Tween = game.playing_tween
    t.pause()
    return t
func shot(label: String) -> void:
    if DisplayServer.get_name() == "headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://dev_"+label+".png")==OK,"capture "+label)
func click(button: Button) -> void:
    for down in [true,false]:
        var event := InputEventMouseButton.new()
        event.position = button.get_global_rect().get_center()
        event.button_index = MOUSE_BUTTON_LEFT
        event.pressed = down
        root.push_input(event,true)
        await process_frame
func run() -> void:
    if not ProjectSettings.globalize_path("user://").contains("step29-"):
        quit(2)
        return
    gm=root.get_node("GameManager")
    sm=root.get_node("SaveManager")
    gm.create_new_game("STEP29 DEV")
    await enter()
    game._on_play_button_pressed()
    check(not game.playing_busy and game.play_button.disabled,"egg rejects")
    gm.get_active_creature().stage="baby"
    game.load_current_creature()
    check(sm.save_game(gm.game_data),"isolated seed")
    var memory: Dictionary=gm.game_data.duplicate(true)
    var digest := FileAccess.get_sha256(sm.SAVE_PATH)
    var texture: Texture2D=game.creature_sprite.texture
    var scale_before: Vector2=game.creature_sprite.scale
    var base_y: float=game.creature_idle_base_position.y
    for x in [-120.0,0.0,120.0]:
        var t := begin(x)
        var generation: int=game.playing_generation
        check(game.playing_busy and not game.creature_movement_active and game.creature_idle_tween==null,"exclusive animation "+str(x))
        check(game.feed_button.disabled and game.play_button.disabled,"both buttons blocked")
        for i in range(100): game.load_current_creature()
        for i in range(10):
            game._on_play_button_pressed()
            game._on_feed_button_pressed()
            game.play_requested.emit()
            game.feed_requested.emit()
        game._finish_playing(generation)
        check(game.playing_tween==t and game.playing_generation==generation and not game.feeding_busy,"refresh spam early finish ignored")
        for cycle in range(3):
            t.custom_step(0.2)
            check(is_equal_approx(game.creature_sprite.position.y,base_y-18) and is_equal_approx(game.creature_sprite.position.x,x),"peak "+str(cycle))
            if cycle==0: await shot("peak_"+str(int(x)))
            t.custom_step(0.2)
            check(is_equal_approx(game.creature_sprite.position.y,base_y),"landing "+str(cycle))
        t.custom_step(0.001)
        check(not game.playing_busy and not game.play_button.disabled and game.creature_movement_active,"complete resumes")
        check(game.creature_sprite.texture==texture and game.creature_sprite.scale==scale_before and game.creature_sprite.rotation==0,"original appearance")
    check(gm.game_data==memory and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"play no data or save changes")
    for elapsed in [0.1,0.6,1.1]:
        var t := begin(40)
        var generation: int=game.playing_generation
        t.custom_step(elapsed)
        gm.game_data.active_creatures[0]=gm.get_active_creature().duplicate(true)
        game._process(0)
        check(not game.playing_busy and not t.is_valid() and game.creature_sprite.position==game.creature_idle_base_position,"replacement cancels "+str(elapsed))
        game.load_current_creature()
        game._finish_playing(generation)
        check(not game.playing_busy and not game.play_button.disabled,"old completion no effect")
    game.feed_message.text="저장 오류 안내 유지"
    game.feed_message.show()
    await click(game.play_button)
    check(game.playing_busy and game.feed_message.visible,"actual click and notice preserved")
    await create_timer(1.3).timeout
    check(not game.playing_busy and game.creature_idle_tween.is_running(),"real time 1.2s finishes")
    game.stop_creature_movement()
    game.creature_sprite.position.x=0
    game._on_feed_button_pressed()
    var feed: Tween=game.feeding_tween
    feed.pause()
    game._on_play_button_pressed()
    check(game.feeding_busy and not game.playing_busy,"feeding rejects play")
    feed.custom_step(1.401)
    check(gm.get_active_creature().affection==1 and not game.play_button.disabled,"feeding still awards")
    for state in ["adult","empty","hatch"]:
        var t := begin(40)
        if state=="adult": gm.get_active_creature().stage="adult"
        elif state=="empty": game.current_creature={}
        else: game.hatch_in_progress=true
        game._update_feed_button()
        check(not game.playing_busy and not t.is_valid() and game.play_button.disabled,"invalid cancels "+state)
        gm.get_active_creature().stage="baby"
        game.hatch_in_progress=false
        game.load_current_creature()
    var old_t := begin(50)
    await enter()
    check(not old_t.is_valid() and not game.playing_busy,"scene exit cleans play")
    check(game.play_requested.get_connections().size()==1 and game.play_button.pressed.get_connections().size()==1,"reentry single connection")
    for size in [Vector2i(405,720),Vector2i(720,1280)]:
        if DisplayServer.get_name()!="headless": root.size=size
        await settle()
        var t := begin(120)
        t.custom_step(0.2)
        await shot("jump_"+str(size.x))
        t.custom_step(1.001)
        await shot("restored_"+str(size.x))
    current_scene.queue_free()
    current_scene=null
    game=null
    await settle()
    if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
    print("RESULT failures=",failures)
    quit(failures)
