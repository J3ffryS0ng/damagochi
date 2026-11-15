extends SceneTree
var failures := 0
var requests := 0
var gm: Node
var sm: Node
var game: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
    print("PASS " if ok else "FAIL ",label)
    if not ok: failures+=1
func settle() -> void:
    for i in range(3): await process_frame
func enter() -> void:
    change_scene_to_file("res://scenes/game/Game.tscn")
    await settle()
    game=current_scene
    game.poop_requested.connect(func(): requests+=1)
func shot(label: String) -> void:
    if DisplayServer.get_name()=="headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://dev_"+label+".png")==OK,"capture "+label)
func end() -> void:
    current_scene.queue_free()
    current_scene=null
    game=null
    await settle()
    if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
    print("RESULT failures=",failures)
    quit(failures)
func run() -> void:
    if not ProjectSettings.globalize_path("user://").contains("step31-"):
        quit(2)
        return
    gm=root.get_node("GameManager")
    sm=root.get_node("SaveManager")
    gm.create_new_game("STEP31 DEV")
    await enter()
    check(game.poop_timer.is_stopped() and requests==0,"egg stopped")
    gm.get_active_creature().stage="baby"
    game.load_current_creature()
    check(game.poop_timer.time_left>=60 and game.poop_timer.time_left<=120,"first full interval")
    check(sm.save_game(gm.game_data),"seed save")
    var memory: Dictionary=gm.game_data.duplicate(true)
    var digest:=FileAccess.get_sha256(sm.SAVE_PATH)
    if OS.get_cmdline_user_args().has("real"):
        var interval: float=game.poop_timer.time_left
        var start:=Time.get_ticks_msec()
        print("REAL_INTERVAL=",interval)
        while requests==0 and Time.get_ticks_msec()-start<125000: await process_frame
        var elapsed: float=(Time.get_ticks_msec()-start)/1000.0
        check(requests==1 and absf(elapsed-interval)<0.3,"real default timer elapsed "+str(elapsed))
        check(game.poop_timer.time_left>=59.9 and game.poop_timer.time_left<=120,"real timeout rearms")
        check(gm.game_data==memory and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"real request leaves data and save unchanged")
        await end()
        return
    var remaining: float=game.poop_timer.time_left
    for i in range(100): game.load_current_creature()
    check(is_equal_approx(game.poop_timer.time_left,remaining) and game.poop_timer.timeout.get_connections().size()==1,"100 refresh preserves countdown single link")
    var low:=120.0
    var high:=60.0
    var total:=0.0
    var bounded:=true
    for i in range(2000):
        var value: float=game._next_poop_interval()
        bounded=bounded and value>=60 and value<=120
        low=minf(low,value)
        high=maxf(high,value)
        total+=value
    check(bounded and low<65 and high>115 and absf(total/2000-90)<3,"interval samples range and mean")
    game.stop_creature_movement()
    await create_timer(0.15).timeout
    check(game.poop_timer.time_left<remaining,"timer independent of movement process")
    for action in ["play","feed"]:
        game.creature_sprite.position.x=0
        if action=="play": game._on_play_button_pressed()
        else: game._on_feed_button_pressed()
        var tween: Tween=game.playing_tween if action=="play" else game.feeding_tween
        tween.pause()
        remaining=game.poop_timer.time_left
        await create_timer(0.15).timeout
        check(game.poop_timer.paused and is_equal_approx(remaining,game.poop_timer.time_left),"busy preserves "+action)
        tween.custom_step(1.201 if action=="play" else 1.401)
        check(not game.poop_timer.paused and is_equal_approx(remaining,game.poop_timer.time_left),"completion resumes same "+action)
    remaining=game.poop_timer.time_left
    paused=true
    await create_timer(0.15).timeout
    check(is_equal_approx(remaining,game.poop_timer.time_left),"tree pause freezes")
    paused=false
    # Short injected timeout tests dispatch; real mode separately uses default interval.
    game.poop_timer.start(0.05)
    await create_timer(0.12).timeout
    check(requests==1 and game.poop_timer.time_left>59,"timeout exactly once and rearm")
    game._on_poop_timeout()
    check(requests==1,"duplicate timeout ignored")
    for state in ["adult","empty","hatch","replacement"]:
        if state=="adult": gm.get_active_creature().stage="adult"
        elif state=="empty": game.current_creature={}
        elif state=="hatch": game.hatch_in_progress=true
        else: gm.game_data.active_creatures[0]=gm.get_active_creature().duplicate(true)
        await settle()
        check(game.poop_timer.is_stopped() and requests==1,"invalid stopped "+state)
        gm.get_active_creature().stage="baby"
        game.hatch_in_progress=false
        game.load_current_creature()
        check(game.poop_timer.time_left>=60 and game.poop_timer.time_left<=120,"fresh eligible interval "+state)
    var old_timer: Timer=game.poop_timer
    await enter()
    check(not is_instance_valid(old_timer) and game.poop_timer.time_left>59,"exit frees and reentry fresh")
    for size in [Vector2i(405,720),Vector2i(720,1280)]:
        if DisplayServer.get_name()!="headless": root.size=size
        await settle()
        await shot("unchanged_"+str(size.x))
    check(not game.food_sprite.visible and game.creature_movement_active,"normal visuals and movement")
    await end()
