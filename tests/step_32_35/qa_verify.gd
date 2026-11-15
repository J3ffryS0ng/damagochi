extends SceneTree
var failures := 0
var gm: Node
var sm: Node
var game: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ",label)
    if not ok: failures+=1
func settle() -> void:
    for i in range(3): await process_frame
func fixture(fault: bool=false) -> void:
    if is_instance_valid(current_scene):
        current_scene.queue_free()
        current_scene=null
        await settle()
    gm.create_new_game("CLEAN QA")
    var pet: Dictionary=gm.get_active_creature()
    pet.stage="baby"
    pet.level=2
    game=load("res://scenes/game/Game.tscn").instantiate()
    if fault: game.set_script(load("res://qa_failure.gd"))
    root.add_child(game)
    current_scene=game
    await settle()
func spawn() -> void:
    game.poop_timer.start(0.001)
    await settle()
    check(game.poop_present and game.poop_image.visible,"natural accelerated timeout creates poop")
func mouse(point: Vector2, button: int=MOUSE_BUTTON_LEFT, down: bool=true) -> void:
    var event:=InputEventMouseButton.new()
    event.position=point
    event.button_index=button
    event.pressed=down
    root.push_input(event,true)
func touch(point: Vector2, down: bool=true, cancel: bool=false) -> void:
    var event:=InputEventScreenTouch.new()
    event.position=point
    event.pressed=down
    event.canceled=cancel
    root.push_input(event,true)
func run() -> void:
    check(ProjectSettings.globalize_path("user://").contains("step32-35-qa-"),"isolated user directory")
    if failures: quit(2); return
    gm=root.get_node("GameManager")
    sm=root.get_node("SaveManager")
    var args:=OS.get_cmdline_user_args()
    if args.has("resume"): await restore()
    elif args.has("render"): await render_suite()
    elif args.has("real"): await real_suite()
    else: await suite()
    if is_instance_valid(current_scene):
        current_scene.queue_free()
        current_scene=null
        await settle()
    print("RESULT STEP32-35 QA failures=",failures)
    quit(failures)
func suite() -> void:
    await fixture()
    check(game.poop_image.get_global_rect()==Rect2(492,852,96,96),"96 square centered 540,900")
    check(not game.poop_present and not game.poop_image.visible,"entry no poop")
    var keys: Array=game.current_creature.keys()
    await spawn()
    var remaining: float=game.poop_timer.time_left
    var data: Dictionary=gm.game_data.duplicate(true)
    game.poop_requested.emit()
    await create_timer(0.2).timeout
    check(game.poop_timer.paused and game.poop_timer.time_left==remaining,"existing poop freezes timer and duplicate request")
    check(gm.game_data==data,"spawn no growth/save contract changes")
    for point in [Vector2(491,900),Vector2(588,900),Vector2(540,851),Vector2(540,948)]: mouse(point)
    mouse(Vector2(540,900),MOUSE_BUTTON_RIGHT)
    mouse(Vector2(540,900),MOUSE_BUTTON_LEFT,false)
    touch(Vector2(540,900),false)
    touch(Vector2(540,900),true,true)
    check(game.poop_present and game.current_creature.affection==0,"outside right release canceled touch ignored")
    paused=true
    mouse(Vector2(540,900))
    touch(Vector2(540,900))
    await create_timer(0.2,true).timeout
    check(game.poop_present and game.current_creature.affection==0,"SceneTree pause ignores cleanup input")
    paused=false
    await settle()
    game.creature_sprite.position.x=81
    var tex: Texture2D=game.creature_sprite.texture
    var scale_before: Vector2=game.creature_sprite.scale
    mouse(Vector2(492,852))
    mouse(Vector2(540,900))
    touch(Vector2(540,900))
    check(not game.poop_present and game.cleaning_busy and game.current_creature.affection==1,"inclusive top-left cleans exactly once across duplicate mouse touch")
    check(game.feed_button.disabled and game.play_button.disabled and game.poop_timer.paused,"clean locks controls and timer")
    check(not game.creature_movement_active and game.creature_idle_tween==null,"clean pauses move Idle")
    game._on_feed_button_pressed()
    game._on_play_button_pressed()
    game._show_poop()
    game._finish_cleaning(game.cleaning_generation)
    check(game.cleaning_busy and not game.feeding_busy and not game.playing_busy and not game.poop_present,"busy commands and early completion rejected")
    await create_timer(0.29).timeout
    check(game.cleaning_busy and abs(game.creature_sprite.position.y+6)<0.15 and game.creature_sprite.position.x==81,"sigh apex -6 at 0.3 current x")
    check(game.creature_sprite.texture==tex and game.creature_sprite.scale==scale_before and game.creature_sprite.rotation==0,"source appearance unchanged")
    await create_timer(0.36).timeout
    check(not game.cleaning_busy and game.creature_idle_tween.is_running() and game.creature_movement_active,"0.6 second completion resumes Idle movement")
    check(not game.poop_timer.paused and game.poop_timer.time_left>59 and game.poop_timer.wait_time<=120,"successful cleanup starts fresh full countdown")
    check(game.current_creature.affection==1 and game.current_creature.keys()==keys,"completion no extra award no new save fields")
    for action in ["feed","play"]:
        await spawn()
        game.creature_sprite.position.x=0
        if action=="feed": game._on_feed_button_pressed()
        else: game._on_play_button_pressed()
        mouse(Vector2(540,900))
        check(game.poop_present and not game.cleaning_busy,action+" rejects clean")
        await create_timer(1.7).timeout
        check(game.poop_present and not game.cleaning_busy,action+" ignored input never queued")
        var before: int=game.current_creature.affection
        touch(Vector2(587,947))
        check(not game.poop_present and game.current_creature.affection==before+1,"touch inside bottom-right cleans")
        await create_timer(0.7).timeout
    await fixture()
    await spawn()
    game.current_creature.affection=9
    check(sm.save_game(gm.game_data),"real readonly seed")
    var disk_before:=FileAccess.get_sha256(sm.SAVE_PATH)
    var marker:=FileAccess.open("res://readonly.ready",FileAccess.WRITE)
    marker.store_string(ProjectSettings.globalize_path(sm.SAVE_PATH))
    marker.close()
    var started:=Time.get_ticks_msec()
    while not FileAccess.file_exists("res://readonly.go") and Time.get_ticks_msec()-started<10000: await process_frame
    check(FileAccess.file_exists("res://readonly.go"),"readonly handshake completed")
    touch(Vector2(540,900))
    check(game.poop_present and not game.cleaning_busy and game.current_creature.affection==9 and game.current_creature.level==2,"actual readonly save refusal restores reward and poop")
    check(FileAccess.get_sha256(sm.SAVE_PATH)==disk_before,"actual readonly bytes unchanged")
    marker=FileAccess.open("res://readonly.done",FileAccess.WRITE)
    marker.close()
    while not FileAccess.file_exists("res://readonly.released") and Time.get_ticks_msec()-started<15000: await process_frame
    touch(Vector2(540,900))
    check(not game.poop_present and game.current_creature.level==3,"actual writable retry succeeds")
    await create_timer(0.7).timeout
    await fixture(true)
    for failure in ["reject_apply","reject_save"]:
        await spawn()
        game.current_creature.affection=9
        game.current_creature.level=2
        game.current_creature.affection_to_next_level=10
        check(sm.save_game(gm.game_data),"seed fault baseline")
        var hash_before:=FileAccess.get_sha256(sm.SAVE_PATH)
        game.set(failure,true)
        mouse(Vector2(540,900))
        check(game.current_creature.affection==9 and game.current_creature.level==2 and game.current_creature.affection_to_next_level==10,failure+" rolls back all growth fields")
        check(game.poop_present and not game.cleaning_busy and game.clean_message_active and game.feed_message.visible,failure+" preserves retry poop and notice")
        check(FileAccess.get_sha256(sm.SAVE_PATH)==hash_before,failure+" original isolated disk bytes retained")
        game.set(failure,false)
        touch(Vector2(540,900))
        check(game.current_creature.level==3 and game.current_creature.affection==0 and game.current_creature.affection_to_next_level==13,"retry level-up correct")
        check(not game.feed_message.visible and game.level_label.text=="LV. 3" and game.affection_bar.value==0,"retry notice cleared and UI updated")
        await create_timer(0.7).timeout
    for action in ["play","feed"]:
        await fixture(true)
        await spawn()
        game.reject_save=true
        touch(Vector2(540,900))
        check(game.clean_message_active and game.feed_message.visible,"cross notice clean failure seeded "+action)
        game.reject_save=false
        game.set("reject_"+action+"_save",true)
        game.creature_sprite.position.x=0
        if action=="play": game._on_play_button_pressed()
        else: game._on_feed_button_pressed()
        await create_timer(1.7).timeout
        var action_message: String=game.feed_message.text
        check(game.feed_message.visible and not game.clean_message_active,"other failure owns notice after clean failure "+action)
        touch(Vector2(540,900))
        check(not game.poop_present and game.feed_message.visible and game.feed_message.text==action_message,"clean success preserves newer other action failure "+action)
        await create_timer(0.7).timeout
    for invalid in [null,"9",true,-1,1.5,INF,NAN,1.0e15]:
        await spawn()
        game.current_creature.affection=invalid
        mouse(Vector2(540,900))
        check(game.poop_present and not game.cleaning_busy,"invalid affection rejected "+str(invalid))
        game.current_creature.affection=0
        game._clear_poop()
        game._sync_poop_timer()
    for field in ["level","affection_to_next_level"]:
        await spawn()
        var saved: Variant=game.current_creature[field]
        game.current_creature[field]=0
        mouse(Vector2(540,900))
        check(game.poop_present and not game.cleaning_busy,"zero "+field+" rejected")
        game.current_creature[field]=saved
        game._clear_poop()
        game._sync_poop_timer()
    await spawn()
    var old: Dictionary=game.current_creature
    gm.game_data.active_creatures[0]=old.duplicate(true)
    mouse(Vector2(540,900))
    await settle()
    check(not game.poop_present and old.affection==0,"stale identity input rejects and clears poop")
    game.load_current_creature()
    await spawn()
    touch(Vector2(540,900))
    var generation: int=game.cleaning_generation
    gm.game_data.active_creatures[0]=game.current_creature.duplicate(true)
    await settle()
    check(not game.cleaning_busy and game.cleaning_tween==null,"identity replacement cancels active sigh")
    game._finish_cleaning(generation)
    check(gm.get_active_creature().affection==1,"late cancel callback no second award")
    game.load_current_creature()
    await spawn()
    game.current_creature.stage="egg"
    await settle()
    check(not game.poop_present and game.poop_timer.is_stopped(),"stage invalidation clears poop timer")
    game.current_creature.stage="baby"
    game.load_current_creature()
    await spawn()
    touch(Vector2(540,900))
    var old_tween: Tween=game.cleaning_tween
    game.queue_free()
    current_scene=null
    await settle()
    check(not old_tween.is_valid(),"scene exit kills sigh tween")
    game=load("res://scenes/game/Game.tscn").instantiate()
    root.add_child(game)
    current_scene=game
    await settle()
    check(not game.poop_present and not game.cleaning_busy and game.poop_timer.time_left>59,"same-process reentry resets poop and animation")
    game.current_creature.level=2
    game.current_creature.affection=9
    game.current_creature.affection_to_next_level=10
    await spawn()
    touch(Vector2(540,900))
    check(game.current_creature.level==3 and game.current_creature.affection==0,"final persisted cleanup level-up")
func restore() -> void:
    check(change_scene_to_file("res://scenes/game/Game.tscn")==OK,"separate process scene load")
    await settle()
    game=current_scene
    check(game.current_creature.level==3 and game.current_creature.affection==0 and game.current_creature.affection_to_next_level==13,"separate process restores cleanup growth")
    check(not game.poop_present and game.poop_timer.time_left>59,"separate process poop and countdown reset")
func real_suite() -> void:
    await fixture()
    var interval: float=game.poop_timer.wait_time
    var start:=Time.get_ticks_msec()
    print("REAL_INTERVAL ",interval)
    while not game.poop_present and Time.get_ticks_msec()-start<125000: await process_frame
    var elapsed: float=(Time.get_ticks_msec()-start)/1000.0
    print("REAL_ELAPSED ",elapsed)
    check(game.poop_present and elapsed>=interval-0.15 and elapsed<interval+1,"real unaccelerated timer creates image")
    check(game.poop_timer.paused and game.poop_image.visible,"real generation freezes until cleanup")
func render_suite() -> void:
    await fixture()
    await spawn()
    for size in [Vector2i(405,720),Vector2i(720,1280)]:
        root.size=size
        await settle()
        await RenderingServer.frame_post_draw
        check(root.get_texture().get_image().save_png("res://qa_poop_"+str(size.x)+".png")==OK,"poop render "+str(size))
        touch(Vector2(540,900))
        await create_timer(0.28).timeout
        await RenderingServer.frame_post_draw
        check(root.get_texture().get_image().save_png("res://qa_sigh_"+str(size.x)+".png")==OK,"sigh render "+str(size))
        await create_timer(0.5).timeout
        await spawn()




