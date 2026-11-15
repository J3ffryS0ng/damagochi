extends SceneTree
var failures := 0
var gm: Node
var sm: Node
var game: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
    print("PASS " if ok else "FAIL ",label)
    if not ok: failures+=1
func settle() -> void:
    for i in range(3): await process_frame
func fixture(a: int=0, fault: bool=false) -> void:
    if is_instance_valid(current_scene):
        current_scene.queue_free()
        current_scene=null
        await settle()
    gm.create_new_game("STEP30 Independent QA")
    var pet: Dictionary=gm.get_active_creature()
    pet.stage="baby"
    pet.level=2
    pet.affection=a
    pet.affection_to_next_level=10
    game=load("res://scenes/game/Game.tscn").instantiate()
    if fault: game.set_script(load("res://play_failure_game.gd"))
    root.add_child(game)
    current_scene=game
    await settle()
func values() -> Array:
    var pet: Dictionary=gm.get_active_creature()
    return [pet.affection,pet.level,pet.affection_to_next_level]
func mouse(button: Button) -> void:
    for down in [true,false]:
        var event:=InputEventMouseButton.new()
        event.position=button.get_global_rect().get_center()
        event.button_index=MOUSE_BUTTON_LEFT
        event.pressed=down
        root.push_input(event,true)
        await process_frame
func finish() -> void:
    var start:=Time.get_ticks_msec()
    while game.playing_busy and Time.get_ticks_msec()-start<2500: await process_frame
    check(not game.playing_busy,"completion bounded")
func fast_finish() -> void:
    game.playing_tween.pause()
    game.playing_tween.custom_step(1.2001)
func shot(label: String) -> void:
    if DisplayServer.get_name()=="headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://qa_play_"+label+".png")==OK,"render "+label)
func run() -> void:
    print("TEST_USER_DIR=",ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("step30-qa-"):
        quit(2)
        return
    gm=root.get_node("GameManager")
    sm=root.get_node("SaveManager")
    if OS.get_cmdline_user_args().has("resume"): await restore()
    else: await suite()
    if is_instance_valid(current_scene):
        current_scene.queue_free()
        current_scene=null
        await settle()
    if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
    print("RESULT STEP30 QA failures=",failures)
    quit(failures)
func suite() -> void:
    await fixture()
    check(sm.save_game(gm.game_data),"isolated baseline")
    var digest:=FileAccess.get_sha256(sm.SAVE_PATH)
    var start:=Time.get_ticks_msec()
    await mouse(game.play_button)
    var generation: int=game.playing_generation
    for i in range(10):
        game._on_play_button_pressed()
        game._on_feed_button_pressed()
    for i in range(100): game.load_current_creature()
    game._finish_playing(generation)
    check(values()==[0,2,10] and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"early/repeat/refresh no award")
    check(game.playing_generation==generation and game.play_button.disabled and game.feed_button.disabled and not game.feeding_busy,"one cycle and mutually exclusive")
    await create_timer(0.6).timeout
    check(values()==[0,2,10] and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"midpoint no reward/save")
    await finish()
    var elapsed:=Time.get_ticks_msec()-start
    check(elapsed>=1150 and elapsed<1700,"actual runtime 1.2 seconds "+str(elapsed))
    check(values()==[1,2,10],"completed plus one")
    check(sm.load_game().active_creatures[0].affection==1,"immediate disk award")
    check(game.affection_label.text=="친밀도 1 / 10" and game.affection_bar.value==1,"updated UI")
    game._finish_playing(generation)
    game._finish_playing(generation-1)
    check(values()==[1,2,10],"duplicate/stale finish ignored")
    check(game.creature_movement_active and game.creature_idle_tween.is_running() and not game.play_button.disabled,"normal state restored")
    for row in [[8,9,2,10],[9,0,3,13],[10,1,3,13]]:
        await fixture(row[0])
        game._on_play_button_pressed()
        fast_finish()
        check(values()==[row[1],row[2],row[3]],"threshold and remainder "+str(row))
        check(game.level_label.text=="LV. %d"%row[2] and game.affection_bar.max_value==row[3],"level UI")
        game._on_play_button_pressed()
        fast_finish()
        check(gm.get_active_creature().affection==(0 if row[1]+1==row[3] else row[1]+1),"consecutive normal cycle")
    for segment in range(6):
        await fixture()
        sm.save_game(gm.game_data)
        digest=FileAccess.get_sha256(sm.SAVE_PATH)
        game._on_play_button_pressed()
        generation=game.playing_generation
        game.playing_tween.pause()
        game.playing_tween.custom_step(segment*0.2+0.1)
        game._cancel_playing()
        game.update_creature_visual()
        game._finish_playing(generation)
        check(values()==[0,2,10] and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"cancel leg "+str(segment))
        check(not game.playing_busy and not game.play_button.disabled,"cancel controls "+str(segment))
    for invalid in ["egg","adult","empty","hatch","target"]:
        await fixture()
        var original: Dictionary=game.current_creature
        game._on_play_button_pressed()
        if invalid=="empty": game.current_creature={}
        elif invalid=="hatch": game.hatch_in_progress=true
        elif invalid=="target": gm.game_data.active_creatures[0]=original.duplicate(true)
        else: original.stage=invalid
        await settle()
        game._on_play_button_pressed()
        check(not game.playing_busy and original.affection==0 and gm.get_active_creature().affection==0,"invalid/identity cancels and denies "+invalid)
    await fixture()
    game._on_play_button_pressed()
    game.queue_free()
    current_scene=null
    await create_timer(1.3).timeout
    check(values()==[0,2,10],"scene exit no reward")
    for field in ["affection","level","affection_to_next_level"]:
        for value in [-1,INF,NAN,1.5,"bad",1e16,0]:
            if field=="affection" and value is int and value==0: continue
            await fixture()
            var pet: Dictionary=gm.get_active_creature()
            pet[field]=value
            game._on_play_button_pressed()
            fast_finish()
            check(game.feed_message.visible and game.feed_message.text.contains("놀이") and not game.playing_busy,"invalid actual completion "+field+str(value))
    for fault in ["apply","save"]:
        await fixture(9,true)
        sm.save_game(gm.game_data)
        digest=FileAccess.get_sha256(sm.SAVE_PATH)
        game.reject_apply=fault=="apply"
        game.reject_save=fault=="save"
        game._on_play_button_pressed()
        fast_finish()
        check(values()==[9,2,10] and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"three field rollback bytes "+fault)
        check(game.play_message_active and game.feed_message.visible and game.feed_message.text.contains("놀이") and game.affection_bar.value==9,"failure notice/UI "+fault)
        for size in [Vector2i(405,720),Vector2i(720,1280)]:
            if DisplayServer.get_name()!="headless": root.size=size
            await settle()
            await shot(fault+str(size.x))
        game.hatch_in_progress=true
        game._on_play_button_pressed()
        check(game.feed_message.visible,"invalid input keeps play notice")
        game.hatch_in_progress=false
        game.reject_apply=false
        game.reject_save=false
        game._on_play_button_pressed()
        check(not game.feed_message.visible and not game.play_message_active,"new valid play clears own notice")
        fast_finish()
        check(values()==[0,3,13],"retry awards once "+fault)
        game.feed_message.text="급식 저장 실패 안내"
        game.feed_message.show()
        game._on_play_button_pressed()
        fast_finish()
        check(game.feed_message.visible and game.feed_message.text=="급식 저장 실패 안내","play preserves feed notice")
        game.creature_sprite.position.x=0
        game._on_feed_button_pressed()
        check(not game.feed_message.visible,"feed retains notice clear contract")
        game._on_play_button_pressed()
        check(not game.playing_busy,"feed blocks play")
        await create_timer(1.55).timeout
        check(values()==[2,3,13],"feed reward after play")
    await fixture(9)
    sm.save_game(gm.game_data)
    digest=FileAccess.get_sha256(sm.SAVE_PATH)
    var marker:=FileAccess.open("res://readonly.ready",FileAccess.WRITE)
    marker.store_string(ProjectSettings.globalize_path(sm.SAVE_PATH))
    marker.close()
    var started:=Time.get_ticks_msec()
    while not FileAccess.file_exists("res://readonly.go") and Time.get_ticks_msec()-started<10000: await process_frame
    game._on_play_button_pressed()
    fast_finish()
    check(values()==[9,2,10] and game.feed_message.visible,"real readonly save refusal rollback")
    check(FileAccess.get_sha256(sm.SAVE_PATH)==digest,"real readonly bytes unchanged")
    marker=FileAccess.open("res://readonly.done",FileAccess.WRITE)
    marker.close()
    while not FileAccess.file_exists("res://readonly.released") and Time.get_ticks_msec()-started<15000: await process_frame
    for size in [Vector2i(405,720),Vector2i(720,1280)]:
        if DisplayServer.get_name()!="headless": root.size=size
        await settle()
        await mouse(game.play_button)
        check(game.playing_busy,"real screen input "+str(size))
        await finish()
        await shot("success"+str(size.x))
    check(values()==[1,3,13],"two valid cycles reward")
func restore() -> void:
    var saved: Dictionary=sm.load_game()
    check(change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))==OK,"normal menu")
    await settle()
    await mouse(current_scene.continue_button)
    await settle()
    game=current_scene
    var pet: Dictionary=game.current_creature
    check(pet.affection==1 and pet.level==3 and pet.affection_to_next_level==13,"separate process reward restore")
    check(gm.game_data==saved and not game.playing_busy,"full data and no replay")
    await create_timer(1.35).timeout
    check(gm.game_data==saved,"reentry awards nothing")
    game._on_play_button_pressed()
    await finish()
    check(gm.get_active_creature().affection==2,"restored new play +1")

