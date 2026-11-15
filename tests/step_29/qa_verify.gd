extends SceneTree
var failures := 0
var requests := 0
var gm: Node
var sm: Node
var game: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ",label)
    if not ok: failures += 1
func settle() -> void:
    for i in range(3): await process_frame
func requested() -> void: requests += 1
func fixture(stage: String="baby") -> void:
    gm.create_new_game("STEP29 independent QA")
    gm.get_active_creature().stage=stage
    check(change_scene_to_file("res://scenes/game/Game.tscn")==OK,"enter "+stage)
    await settle()
    game=current_scene
    game.play_requested.connect(requested)
func mouse(button: Button, right: bool=false) -> void:
    for down in [true,false]:
        var event:=InputEventMouseButton.new()
        event.position=button.get_global_rect().get_center()
        event.button_index=MOUSE_BUTTON_RIGHT if right else MOUSE_BUTTON_LEFT
        event.pressed=down
        root.push_input(event,true)
        await process_frame
func space() -> void:
    game.play_button.grab_focus()
    for down in [true,false]:
        var key:=InputEventKey.new()
        key.keycode=KEY_SPACE
        key.pressed=down
        root.push_input(key,true)
        await process_frame
func shot(label: String) -> void:
    if DisplayServer.get_name()=="headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://qa_play_"+label+".png")==OK,"render "+label)
func run() -> void:
    print("TEST_USER_DIR=",ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("step29-qa-"):
        quit(2)
        return
    gm=root.get_node("GameManager")
    sm=root.get_node("SaveManager")
    var args:=OS.get_cmdline_user_args()
    if args.is_empty(): await suite()
    else: await restore_mode(args[0])
    print("RESULT STEP29 QA failures=",failures)
    if is_instance_valid(current_scene):
        current_scene.queue_free()
        current_scene=null
        await settle()
    if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
    quit(failures)
func restore_mode(mode: String) -> void:
    var stage:=mode.get_slice("_",1)
    if mode.begins_with("seed_"):
        await fixture(stage)
        check(sm.save_game(gm.game_data),"seed "+stage)
        if stage=="baby":
            game._on_play_button_pressed()
            check(game.playing_busy,"seed exits with play active")
        return
    var digest:=FileAccess.get_sha256(sm.SAVE_PATH)
    check(change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))==OK,"normal menu")
    await settle()
    await mouse(current_scene.continue_button)
    await settle()
    game=current_scene
    check(game.name=="Game" and game.current_creature.stage==stage,"normal continue "+stage)
    check(not game.playing_busy and game.playing_tween==null,"never restore play state")
    check(game.play_button.disabled==(stage=="egg"),"restored eligibility")
    await mouse(game.play_button)
    check(game.playing_busy==(stage=="baby"),"restored input")
    await create_timer(1.35).timeout
    check(FileAccess.get_sha256(sm.SAVE_PATH)==digest,"restore play disk unchanged")
func suite() -> void:
    for size in [Vector2i(405,720),Vector2i(720,1280)]:
        if DisplayServer.get_name()!="headless": root.size=size
        await fixture()
        check(sm.save_game(gm.game_data),"save isolated baseline")
        var memory: Dictionary=gm.game_data.duplicate(true)
        var digest:=FileAccess.get_sha256(sm.SAVE_PATH)
        for x in [-120.0,0.0,120.0]:
            game.creature_sprite.position.x=x
            game.creature_sprite.position.y=game.creature_idle_base_position.y-2.0
            var appearance: Array=[game.creature_sprite.texture,game.creature_sprite.scale,game.creature_sprite.rotation,game.creature_sprite.flip_h,game.creature_sprite.modulate]
            game._on_play_button_pressed()
            var generation: int=game.playing_generation
            var tween: Tween=game.playing_tween
            check(game.playing_busy and not game.creature_movement_active and game.creature_idle_tween==null,"play owns position")
            check(game.creature_sprite.position==Vector2(x,game.creature_idle_base_position.y),"idle start aligned without x travel")
            tween.pause()
            for cycle in range(3):
                tween.custom_step(0.1)
                check(absf(game.creature_sprite.position.y-(game.creature_idle_base_position.y-9.0))<0.02,"SINE halfway "+str(cycle))
                tween.custom_step(0.1)
                check(absf(game.creature_sprite.position.y-(game.creature_idle_base_position.y-18.0))<0.02,"18px peak "+str(cycle))
                check(game.creature_sprite.position.x==x,"fixed x "+str(x))
                if cycle==0: await shot(str(size.x)+"_peak_"+str(int(x)))
                tween.custom_step(0.2)
                check(absf(game.creature_sprite.position.y-game.creature_idle_base_position.y)<0.02,"return baseline "+str(cycle))
            tween.custom_step(0.00001)
            check(not game.playing_busy and game.creature_movement_active and game.creature_idle_tween!=null,"1.2 seconds completes and resumes")
            check(game.creature_sprite.position.x==x,"completion restores start x")
            check(appearance==[game.creature_sprite.texture,game.creature_sprite.scale,game.creature_sprite.rotation,game.creature_sprite.flip_h,game.creature_sprite.modulate],"appearance unchanged")
            game._finish_playing(generation)
            check(not game.playing_busy,"duplicate finish harmless")
        var before:=requests
        await mouse(game.play_button,true)
        check(requests==before,"right mouse ignored")
        var started:=Time.get_ticks_msec()
        await mouse(game.play_button)
        check(requests==before+1 and game.playing_busy,"real mouse starts one")
        var tween: Tween=game.playing_tween
        var generation: int=game.playing_generation
        for i in range(100): game.load_current_creature()
        check(game.playing_tween==tween and game.playing_generation==generation and game.play_button.pressed.get_connections().size()==1,"100 same target refresh preserves one sequence")
        for i in range(10):
            game._on_play_button_pressed()
            game._on_feed_button_pressed()
            game.play_button.pressed.emit()
            game.feed_button.pressed.emit()
        game._finish_playing(generation)
        check(requests==before+1 and game.playing_busy and not game.feeding_busy and not game.food_sprite.visible,"busy repeats feed and early finish rejected")
        check(game.play_button.disabled and game.feed_button.disabled,"both buttons disabled")
        while game.playing_busy and Time.get_ticks_msec()-started<2000: await process_frame
        var elapsed:=Time.get_ticks_msec()-started
        check(elapsed>=1150 and elapsed<1500,"wall clock 1.2 seconds: "+str(elapsed))
        check(not game.play_button.disabled and not game.feed_button.disabled,"completion enables no cooldown")
        await create_timer(0.15).timeout
        check(not game.playing_busy and not game.feeding_busy and requests==before+1,"no queued action")
        await space()
        check(requests==before+2 and game.playing_busy,"Space starts fresh cycle")
        await create_timer(1.3).timeout
        check(memory==gm.game_data and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"all play memory disk unchanged")
        game.feed_message.text="저장 실패 안내 유지"
        game.feed_message.show()
        await mouse(game.play_button)
        await shot(str(size.x)+"_notice")
        await create_timer(1.3).timeout
        check(game.feed_message.visible and game.feed_message.text=="저장 실패 안내 유지","notice survives play")
        game.creature_sprite.position.x=0
        game._on_feed_button_pressed()
        before=requests
        game._on_play_button_pressed()
        game.play_button.pressed.emit()
        check(game.feeding_busy and not game.playing_busy and requests==before,"feed blocks play")
        await create_timer(1.55).timeout
        check(not game.feeding_busy and game.current_creature.affection==1,"feed +1 after play")
        await fixture("egg")
        game._on_play_button_pressed()
        check(not game.playing_busy and game.play_button.disabled,"egg blocked")
        game.current_creature.egg_created_at=Time.get_unix_time_from_system()-120
        game.current_creature.level=2
        game.load_current_creature()
        await create_timer(0.5).timeout
        game._on_play_button_pressed()
        check(game.current_creature.stage=="baby" and game.hatch_flash.color.a>0 and not game.playing_busy,"hatch fade blocked")
        await create_timer(0.5).timeout
        check(not game.play_button.disabled,"hatch fade completion enables")
    for phase in [0.1,0.3,0.5,0.7,0.9,1.1]:
        for state in ["empty","adult","egg","replacement","hatch"]:
            await fixture()
            game._on_play_button_pressed()
            var tween: Tween=game.playing_tween
            tween.pause()
            tween.custom_step(phase)
            var old: Dictionary=game.current_creature
            if state=="empty": game.current_creature={}
            elif state=="replacement": gm.game_data.active_creatures[0]=old.duplicate(true)
            elif state=="hatch": game.hatch_in_progress=true
            else: game.current_creature.stage=state
            await settle()
            check(not game.playing_busy and game.playing_tween==null and not tween.is_valid(),"cancel "+state+" phase "+str(phase))
            check(game.creature_sprite.position==game.creature_idle_base_position and old.affection==0,"cancel base and no reward "+state)
            check(game.play_button.disabled and game.feed_button.disabled,"cancel ineligible buttons "+state)
    await fixture()
    game._on_play_button_pressed()
    var departing: Tween=game.playing_tween
    check(change_scene_to_file("res://scenes/main/MainMenu.tscn")==OK,"exit to menu during play")
    await settle()
    check(not departing.is_valid(),"exit kills tween")
    await fixture()
    check(not game.playing_busy and game.playing_tween==null,"reentry no active play")

