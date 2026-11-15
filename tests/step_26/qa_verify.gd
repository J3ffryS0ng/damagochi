extends SceneTree
var failures := 0
var gm: Node
var sm: Node
var requests := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ",label)
    if not ok: failures += 1
func settle() -> void:
    for i in range(3): await process_frame
func received() -> void: requests += 1
func click(button: Button) -> void:
    var p := button.get_global_rect().get_center()
    var motion := InputEventMouseMotion.new()
    motion.position = p
    root.push_input(motion,true)
    for down in [true,false]:
        var ev := InputEventMouseButton.new()
        ev.position=p
        ev.button_index=MOUSE_BUTTON_LEFT
        ev.pressed=down
        root.push_input(ev,true)
        await process_frame
func enter() -> Node:
    check(change_scene_to_file("res://scenes/game/Game.tscn")==OK,"scene enters")
    await settle()
    current_scene.feed_requested.connect(received)
    return current_scene
func shot(label: String) -> void:
    if DisplayServer.get_name()=="headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://qa_"+label+".png")==OK,"render "+label)
func run() -> void:
    print("TEST_USER_DIR=",ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("step26-qa-"):
        quit(2)
        return
    gm=root.get_node("GameManager")
    sm=root.get_node("SaveManager")
    if OS.get_cmdline_user_args().has("resume"): await restore()
    else: await suite()
    print("RESULT QA failures=",failures)
    quit(failures)
func suite() -> void:
    gm.create_new_game("먹기 독립 QA")
    var game = await enter()
    await click(game.feed_button)
    game._show_food()
    check(game.feed_button.disabled and not game.feeding_busy and not game.food_sprite.visible,"AC2 egg denied")
    gm.get_active_creature().level=2
    gm.get_active_creature().egg_created_at=Time.get_unix_time_from_system()-120
    game.load_current_creature()
    await create_timer(0.48).timeout
    game._on_feed_button_pressed()
    game._show_food()
    check(game.current_creature.stage=="baby" and game.hatch_flash.color.a>0 and not game.feeding_busy,"AC2 hatch fade baby denied")
    await create_timer(0.5).timeout
    var before: Dictionary=gm.game_data.duplicate(true)
    var disk := FileAccess.get_sha256(sm.SAVE_PATH)
    check(not disk.is_empty(),"AC4 isolated save exists")
    var original_scale: Vector2=game.creature_sprite.scale
    for start in [-120.0,120.0,0.0]:
        game.creature_sprite.position.x=start
        var initial: Vector2=game.creature_sprite.position
        game._on_feed_button_pressed()
        var expected := requests
        var sequence: Tween=game.feeding_tween
        check(game.creature_sprite.position==initial and game.feeding_busy,"AC1 no teleport at start "+str(start))
        for i in range(10):
            game._on_feed_button_pressed()
            game._show_food()
        for i in range(100): game.load_current_creature()
        check(requests==expected and game.feeding_tween==sequence and game.food_sprite.visible and game.feed_button.disabled,"AC2 duplicate10 refresh100 stable "+str(start))
        check(game.feed_button.pressed.get_connections().size()==1 and game.feed_requested.get_connections().size()==2,"AC2 no duplicate connections")
        var arrival_time := absf(start)/60.0
        if start != 0:
            await create_timer(0.5).timeout
            var sampled_seconds := sequence.get_total_elapsed_time()
            check(sampled_seconds>0.45 and sampled_seconds<0.7 and absf((120-absf(game.creature_sprite.position.x))/sampled_seconds-60)<0.5,"AC1 approach speed60 "+str(start)+" t="+str(sampled_seconds)+" x="+str(game.creature_sprite.position.x))
            check(game.creature_idle_tween!=null and game.creature_idle_tween.is_running(),"AC1 approach Idle maintained")
            await create_timer(arrival_time-0.6).timeout
            check(absf(game.creature_sprite.position.x)<9 and absf(game.creature_sprite.position.x)>2,"AC1 arrival near2sec")
            await create_timer(0.1).timeout
        else: await process_frame
        var started := Time.get_ticks_msec()
        var max_y := -100.0
        var min_y := 100.0
        var dips := 0
        var descending := false
        var fading := false
        var last_y: float=game.creature_sprite.position.y
        var fixed_x := true
        while game.feeding_busy and Time.get_ticks_msec()-started<2000:
            await process_frame
            if not game.feeding_busy: break
            var y: float=game.creature_sprite.position.y
            max_y=maxf(max_y,y)
            min_y=minf(min_y,y)
            if y<last_y-0.01 and not descending:
                dips+=1
                descending=true
            if y>last_y+0.01: descending=false
            last_y=y
            fixed_x=fixed_x and absf(game.creature_sprite.position.x)<0.05
            fading=fading or (game.food_sprite.modulate.a<0.99 and game.food_sprite.modulate.a>0)
        var elapsed := float(Time.get_ticks_msec()-started)/1000
        check(not game.feeding_busy and elapsed>1.25 and elapsed<1.6,"AC1 eating1.2 fade0.2 "+str(start))
        check(dips==3 and max_y>5.3 and max_y<=6.01 and min_y>=-0.1,"AC1 three6px dips "+str(start)+" observed="+str(dips))
        check(fading and fixed_x,"AC1 fixed center then fade")
        check(not game.food_sprite.visible and game.food_sprite.modulate.a==1 and not game.feed_button.disabled,"AC3 finished reset")
        check(game.creature_movement_active and game.creature_idle_tween!=null and game.creature_idle_tween.is_running(),"AC3 movement Idle resumed")
        check(game.creature_sprite.scale==original_scale and game.creature_sprite.rotation==0 and not game.creature_sprite.flip_h,"AC1 original transform")
        check(gm.game_data==before and FileAccess.get_sha256(sm.SAVE_PATH)==disk,"AC4 cycle data save invariant")
    # Cancellation and destruction in each temporal phase.
    for phase in ["approach","dip","fade"]:
        game.creature_sprite.position.x=120 if phase=="approach" else 0
        game._on_feed_button_pressed()
        await create_timer(0.25 if phase!="fade" else 1.28).timeout
        check(game.feeding_busy,"AC3 phase active "+phase)
        var old: Tween=game.feeding_tween
        gm.get_active_creature().stage="adult"
        game.load_current_creature()
        check(not old.is_valid() and not game.feeding_busy and not game.food_sprite.visible and game.creature_sprite.position==Vector2.ZERO,"AC3 cancels "+phase)
        await create_timer(1.5).timeout
        check(not game.feeding_busy and game.feed_button.disabled and not game.creature_movement_active,"AC3 no delayed callback "+phase)
        gm.get_active_creature().stage="baby"
        game.load_current_creature()
        game.creature_sprite.position.x=120 if phase=="approach" else 0
        game._on_feed_button_pressed()
        await create_timer(0.25 if phase!="fade" else 1.28).timeout
        var old_scene=weakref(game)
        game=await enter()
        await create_timer(1.5).timeout
        check(old_scene.get_ref()==null and not game.feeding_busy and not game.food_sprite.visible and not game.feed_button.disabled,"AC3 scene exit reentry "+phase)
    # Synthetic eligibility matrix must not invoke an unrelated ready-egg hatch.
    game.hatch_effect_played=true
    for stage in ["egg","adult","unknown"]:
        gm.get_active_creature().stage=stage
        game.load_current_creature()
        game._show_food()
        check(not game.feeding_busy and game.feed_button.disabled,"AC2 rejects "+stage)
    gm.get_active_creature().stage="baby"
    game.load_current_creature()
    game.current_creature={}
    game.update_creature_visual()
    game._show_food()
    check(not game.feeding_busy and not game.food_sprite.visible,"AC2 empty denied")
    game.load_current_creature()
    game.creature_sprite.position.x=0
    var count := requests
    await click(game.feed_button)
    check(requests==count+1 and game.feeding_busy,"AC2 coordinate starts one")
    for i in range(10): await click(game.feed_button)
    check(requests==count+1,"AC2 busy actual clicks10 ignored")
    await create_timer(1.5).timeout
    game.feed_button.grab_focus()
    for down in [true,false]:
        var key := InputEventKey.new()
        key.keycode=KEY_SPACE
        key.pressed=down
        root.push_input(key,true)
        await process_frame
    check(requests==count+2 and game.feeding_busy,"AC2 keyboard starts next")
    await create_timer(3.5).timeout
    for size in [Vector2i(405,720),Vector2i(720,1280)]:
        if DisplayServer.get_name()!="headless": root.size=size
        await settle()
        game.creature_sprite.position.x=0
        game._on_feed_button_pressed()
        await create_timer(0.25).timeout
        await shot("eating_"+str(size.x))
        await create_timer(1.3).timeout
        await shot("finished_"+str(size.x))
    check(gm.game_data==before and FileAccess.get_sha256(sm.SAVE_PATH)==disk,"AC4 full suite data disk invariant")
func restore() -> void:
    var disk: Dictionary=sm.load_game()
    var hash_before := FileAccess.get_sha256(sm.SAVE_PATH)
    check(change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))==OK,"RC menu entry")
    await settle()
    await click(current_scene.continue_button)
    await settle()
    check(current_scene.name=="Game" and current_scene.current_creature.stage=="baby","AC3 normal continue baby")
    check(not current_scene.feeding_busy and not current_scene.food_sprite.visible,"AC3 restart reset")
    await click(current_scene.feed_button)
    check(current_scene.feeding_busy,"AC3 restored feed works")
    await create_timer(3.5).timeout
    check(not current_scene.feeding_busy and not current_scene.food_sprite.visible,"AC3 restored cycle finishes")
    check(gm.game_data==disk and FileAccess.get_sha256(sm.SAVE_PATH)==hash_before,"AC4 restored bytes unchanged")


