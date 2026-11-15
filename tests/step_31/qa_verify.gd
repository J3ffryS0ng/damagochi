extends SceneTree
var failures := 0
var gm: Node
var sm: Node
var game: Node
var requests := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ",label)
    if not ok: failures+=1
func settle() -> void:
    for i in range(3): await process_frame
func fixture(stage: String="baby") -> void:
    if is_instance_valid(current_scene):
        current_scene.queue_free()
        current_scene=null
        await settle()
    gm.create_new_game("STEP31 QA")
    var pet: Dictionary=gm.get_active_creature()
    pet.stage=stage
    pet.level=2 if stage=="baby" else 1
    game=load("res://scenes/game/Game.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    game.poop_requested.connect(func(): requests+=1)
    await settle()
func valid_interval() -> bool:
    return game.poop_timer.wait_time>=60.0 and game.poop_timer.wait_time<=120.0
func run() -> void:
    print("TEST_USER_DIR=",ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("step31-qa-"):
        quit(2)
        return
    gm=root.get_node("GameManager")
    sm=root.get_node("SaveManager")
    var args:=OS.get_cmdline_user_args()
    if args.has("resume"): await restore()
    elif args.has("render"): await render_suite()
    elif args.has("completion"): await completion_suite()
    else: await suite()
    if is_instance_valid(current_scene):
        current_scene.queue_free()
        current_scene=null
        await settle()
    print("RESULT STEP31 QA failures=",failures)
    quit(failures)
func suite() -> void:
    await fixture()
    check(valid_interval() and requests==0,"eligible baby starts full random interval without request")
    check(game.poop_timer is Timer and game.poop_timer.one_shot,"real one-shot Timer")
    check(game.poop_timer.timeout.get_connections().size()==1,"single timeout connection")
    var movement_state: int=game.creature_movement_rng.state
    game.poop_rng.seed=313131
    var low:=0
    var high:=0
    var total:=0.0
    for i in range(1000):
        var v: float=game._next_poop_interval()
        if v<90: low+=1
        else: high+=1
        total+=v
        if v<60 or v>120: failures+=1
    check(low>400 and high>400 and abs(total/1000.0-90.0)<2,"1000 uniform-range samples low=%d high=%d mean=%f"%[low,high,total/1000.0])
    check(game.creature_movement_rng.state==movement_state,"timer sampling does not consume movement RNG")
    var interval: float=game.poop_timer.wait_time
    var remaining: float=game.poop_timer.time_left
    for i in range(100): game.load_current_creature()
    check(game.poop_timer.wait_time==interval and game.poop_timer.time_left==remaining,"100 refresh preserve running timer exactly")
    check(game.poop_timer.timeout.get_connections().size()==1,"refresh does not duplicate connection")
    check(sm.save_game(gm.game_data),"isolated save seeded")
    var digest:=FileAccess.get_sha256(sm.SAVE_PATH)
    var data: Dictionary=gm.game_data.duplicate(true)
    var x: float=game.creature_sprite.position.x
    await create_timer(0.5).timeout
    check(game.creature_movement_active and game.creature_idle_tween.is_running(),"timer coexists with movement and Idle")
    for action in ["play","feed"]:
        game.creature_sprite.position.x=game.creature_idle_base_position.x
        if action=="play": game._on_play_button_pressed()
        else: game._on_feed_button_pressed()
        remaining=game.poop_timer.time_left
        await create_timer(0.35).timeout
        check(game.poop_timer.paused and is_equal_approx(game.poop_timer.time_left,remaining),action+" preserves remaining while busy")
        if action=="play": game._cancel_playing()
        else: game._cancel_feeding()
        game.update_creature_visual()
        await create_timer(0.15).timeout
        check(not game.poop_timer.paused and game.poop_timer.time_left<remaining,action+" cancel resumes")
    check(gm.game_data==data and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"cancel and timer no memory/save effect")
    for action in ["play","feed"]:
        game.creature_sprite.position.x=game.creature_idle_base_position.x
        remaining=game.poop_timer.time_left
        if action=="play": game._on_play_button_pressed()
        else: game._on_feed_button_pressed()
        var action_start:=Time.get_ticks_msec()
        while (game.playing_busy or game.feeding_busy) and Time.get_ticks_msec()-action_start<2200: await process_frame
        check(not game.playing_busy and not game.feeding_busy,action+" normal completion")
        check(not game.poop_timer.paused and abs(game.poop_timer.time_left-remaining)<0.1,action+" completion preserves countdown")
    data=gm.game_data.duplicate(true)
    digest=FileAccess.get_sha256(sm.SAVE_PATH)
    remaining=game.poop_timer.time_left
    paused=true
    await create_timer(0.3,true).timeout
    check(is_equal_approx(game.poop_timer.time_left,remaining),"SceneTree pause preserves remaining")
    paused=false
    await settle()
    check(game.poop_timer.time_left<remaining,"SceneTree unpause resumes")
    for stage in ["egg","adult","baby"]:
        game.current_creature.stage=stage
        await settle()
        check(game.poop_timer.is_stopped() if stage!="baby" else valid_interval(),"unrefreshed stage monitor "+stage)
    game.hatch_in_progress=true
    await settle()
    check(game.poop_timer.is_stopped(),"hatch in progress stops")
    game.hatch_in_progress=false
    game.hatch_flash_tween=game.create_tween()
    game.hatch_flash_tween.tween_interval(0.2)
    await settle()
    check(game.poop_timer.is_stopped(),"flash still running blocks timer")
    await create_timer(0.3).timeout
    check(not game.poop_timer.is_stopped() and valid_interval(),"flash completion starts full interval")
    var old: Dictionary=game.current_creature
    gm.game_data.active_creatures[0]=old.duplicate(true)
    await settle()
    check(game.poop_timer.is_stopped() and game.poop_target.is_empty(),"unrefreshed identical-value new target stops stale timer")
    game.load_current_creature()
    check(is_same(game.poop_target,gm.get_active_creature()) and valid_interval(),"explicit target refresh starts new interval")
    game.current_creature={}
    await settle()
    check(game.poop_timer.is_stopped(),"empty target stops")
    game.load_current_creature()
    var count:=requests
    game.poop_timer.start(0.001)
    await process_frame
    await process_frame
    check(requests==count+1 and valid_interval(),"accelerated natural timeout sends one request and rearms")
    game._on_poop_timeout()
    game._on_poop_timeout()
    check(requests==count+1,"duplicate timeout callbacks ignored after rearm")
    game.poop_timer.start(0.001)
    OS.delay_msec(150)
    await process_frame
    await process_frame
    check(requests==count+2,"long frame yields one request without catch-up burst")
    check(gm.game_data==data and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"requests preserve full memory and save bytes")
    await fixture()
    game.poop_rng.seed=77
    game.poop_timer.start(game._next_poop_interval())
    interval=game.poop_timer.wait_time
    remaining=game.poop_timer.time_left
    count=requests
    var start:=Time.get_ticks_msec()
    print("REAL_CYCLE_START interval=",interval)
    while requests==count and Time.get_ticks_msec()-start<125000: await process_frame
    var elapsed: float=(Time.get_ticks_msec()-start)/1000.0
    print("REAL_CYCLE_END elapsed=",elapsed," interval=",interval)
    check(requests==count+1 and elapsed>=interval-0.1 and elapsed<interval+1.0,"actual default-range wall-clock cycle")
    check(valid_interval() and game.poop_timer.time_left>59,"real cycle rearms full default-range interval")
    check(sm.save_game(gm.game_data),"save for separate process")
    game.poop_timer.start(1.0)
    var stale=game.poop_timer
    game.queue_free()
    current_scene=null
    await settle()
    check(not is_instance_valid(stale),"scene exit frees Timer")
    game=load("res://scenes/game/Game.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    await settle()
    check(game.poop_timer.time_left>59,"same-process scene reentry resets countdown")
func restore() -> void:
    var saved: Dictionary=sm.load_game()
    check(not saved.is_empty(),"separate process isolated save exists")
    check(change_scene_to_file("res://scenes/game/Game.tscn")==OK,"direct game restore scene")
    await settle()
    game=current_scene
    check(gm.game_data==saved and game.poop_timer.time_left>59,"separate process restores data but starts full new timer")
    check(not saved.has("poop_timer") and not game.current_creature.has("poop_timer"),"no Timer persistence fields")
func render_suite() -> void:
    await fixture()
    for size in [Vector2i(405,720),Vector2i(720,1280)]:
        root.size=size
        await settle()
        await RenderingServer.frame_post_draw
        check(root.get_texture().get_image().save_png("res://qa_timer_"+str(size.x)+".png")==OK,"render "+str(size))
        check(not game.feed_button.disabled and not game.play_button.disabled and valid_interval(),"render controls and timer "+str(size))

func completion_suite() -> void:
    await fixture()
    for action in ["play","feed"]:
        game.creature_sprite.position.x=game.creature_idle_base_position.x
        var remaining: float=game.poop_timer.time_left
        if action=="play": game._on_play_button_pressed()
        else: game._on_feed_button_pressed()
        var action_start:=Time.get_ticks_msec()
        while (game.playing_busy or game.feeding_busy) and Time.get_ticks_msec()-action_start<2200: await process_frame
        check(not game.playing_busy and not game.feeding_busy,action+" supplemental normal completion")
        check(not game.poop_timer.paused and abs(game.poop_timer.time_left-remaining)<0.1,action+" supplemental completion countdown retained")
        await create_timer(0.2).timeout
        check(game.poop_timer.time_left<remaining-0.1,action+" supplemental after completion resumes countdown")
    check(gm.get_active_creature().affection==2,"supplemental feed and play each +1")

