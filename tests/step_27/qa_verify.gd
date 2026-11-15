extends SceneTree
var failures := 0
var gm: Node
var sm: Node
var game: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ",label)
    if not ok: failures += 1
func settle() -> void:
    for i in range(3): await process_frame
func enter(fault: bool=false) -> void:
    if current_scene:
        current_scene.queue_free()
        await settle()
    game=load("res://scenes/game/Game.tscn").instantiate()
    if fault: game.set_script(load("res://qa_failure_game.gd"))
    root.add_child(game)
    current_scene=game
    await settle()
func baby(a: int=0, level: int=2, threshold: int=10) -> void:
    gm.create_new_game("친밀도 독립 QA")
    var pet: Dictionary=gm.get_active_creature()
    pet.stage="baby"
    pet.affection=a
    pet.level=level
    pet.affection_to_next_level=threshold
func click(button: Button) -> void:
    for down in [true,false]:
        var event:=InputEventMouseButton.new()
        event.position=button.get_global_rect().get_center()
        event.button_index=MOUSE_BUTTON_LEFT
        event.pressed=down
        root.push_input(event,true)
        await process_frame
func values() -> Array:
    var pet: Dictionary=gm.get_active_creature()
    return [pet.affection,pet.level,pet.affection_to_next_level]
func begin(x: float=0) -> void:
    game.creature_sprite.position.x=x
    game._on_feed_button_pressed()
func finish_wait() -> void:
    var start:=Time.get_ticks_msec()
    while game.feeding_busy and Time.get_ticks_msec()-start<4500: await process_frame
    check(not game.feeding_busy,"sequence completes within duration")
func shot(label: String) -> void:
    if DisplayServer.get_name()=="headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://qa_"+label+".png")==OK,"render "+label)
func run() -> void:
    print("TEST_USER_DIR=",ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("step27-qa-"):
        quit(2)
        return
    gm=root.get_node("GameManager")
    sm=root.get_node("SaveManager")
    if OS.get_cmdline_user_args().has("resume"): await restore()
    else: await suite()
    print("RESULT QA failures=",failures)
    quit(failures)
func suite() -> void:
    baby()
    await enter()
    check(sm.save_game(gm.game_data),"isolated baseline save")
    var disk:=FileAccess.get_sha256(sm.SAVE_PATH)
    begin(-120)
    var gen: int=game.feeding_generation
    for i in range(10): game._on_feed_button_pressed()
    for i in range(100): game.load_current_creature()
    check(game.feeding_generation==gen and game.feed_button.disabled,"duplicate10 refresh100 one sequence")
    game._finish_feeding(gen)
    check(values()==[0,2,10],"early completion call denied")
    await create_timer(0.5).timeout
    check(values()==[0,2,10] and FileAccess.get_sha256(sm.SAVE_PATH)==disk,"approach no reward save")
    check(game.creature_sprite.position.x>-95 and game.creature_sprite.position.x<-85,"approach60px")
    await create_timer(1.65).timeout
    check(values()==[0,2,10] and game.feeding_busy,"eating no reward")
    while game.food_sprite.modulate.a>=1 and game.feeding_busy: await process_frame
    check(values()==[0,2,10] and game.feeding_busy,"fade no early reward")
    await finish_wait()
    check(values()==[1,2,10],"completed +1 exactly")
    check(game.affection_label.text=="친밀도 1 / 10" and game.affection_bar.value==1,"status updated")
    check(not game.feed_button.disabled and game.creature_movement_active and game.creature_idle_tween.is_running(),"normal controls restored")
    var saved: Dictionary=sm.load_game()
    check(saved.active_creatures[0].affection==1,"immediate disk reward")
    game._finish_feeding(gen)
    game._finish_feeding(gen-1)
    check(values()==[1,2,10],"duplicate stale finish no reward")
    for row in [[8,2,10,9,2,10],[9,2,10,0,3,13],[10,2,10,1,3,13]]:
        baby(row[0],row[1],row[2])
        await enter()
        begin()
        await finish_wait()
        check(values()==[row[3],row[4],row[5]],"threshold rule "+str(row))
        check(game.level_label.text=="LV. %d"%row[4] and game.affection_bar.max_value==row[5],"level gauge updated")
    for delay in [0.3,2.2,3.25]:
        baby()
        await enter()
        sm.save_game(gm.game_data)
        disk=FileAccess.get_sha256(sm.SAVE_PATH)
        begin(120)
        gen=game.feeding_generation
        await create_timer(delay).timeout
        game._cancel_feeding()
        game.update_creature_visual()
        game._finish_feeding(gen)
        await create_timer(0.3).timeout
        check(values()==[0,2,10] and FileAccess.get_sha256(sm.SAVE_PATH)==disk,"cancel stage no reward "+str(delay))
    for invalid in ["egg","adult","empty","hatch","target"]:
        baby()
        await enter()
        var old: Dictionary=gm.get_active_creature()
        begin()
        if invalid=="empty": game.current_creature={}
        elif invalid=="hatch": game.hatch_in_progress=true
        elif invalid=="target": gm.game_data.active_creatures[0]=old.duplicate(true)
        else: old.stage=invalid
        await settle()
        check(not game.feeding_busy and old.affection==0 and gm.get_active_creature().affection==0,"invalid target cancels "+invalid)
        game._on_feed_button_pressed()
        check(not game.feeding_busy,"invalid repeated input denied "+invalid)
    baby()
    await enter()
    var stale: Dictionary=game.current_creature
    gm.game_data.active_creatures[0]=stale.duplicate(true)
    game._on_feed_button_pressed()
    check(not game.feeding_busy and stale.affection==0,"stale idle identity new input denied")
    baby()
    await enter()
    begin()
    await create_timer(0.3).timeout
    game.queue_free()
    await create_timer(1.5).timeout
    check(values()==[0,2,10],"scene exit no reward")
    for field in ["affection_to_next_level","level","affection"]:
        for value in [0,-1,INF,NAN,1.5,"invalid",1e16]:
            if field=="affection" and typeof(value)==TYPE_INT and value==0: continue
            baby()
            await enter()
            var pet: Dictionary=gm.get_active_creature()
            pet[field]=value
            check(not game._feed_values_valid(pet),"invalid rejected "+field+"="+str(value))
    baby()
    await enter()
    game.current_creature.affection_to_next_level=0
    begin()
    await finish_wait()
    check(game.current_creature.affection==0 and game.feed_message.visible and not game.feed_button.disabled,"zero threshold no hang user message")
    for mode in ["apply","save"]:
        baby(9)
        await enter(true)
        sm.save_game(gm.game_data)
        disk=FileAccess.get_sha256(sm.SAVE_PATH)
        game.reject_apply=mode=="apply"
        game.reject_save=mode=="save"
        begin()
        await finish_wait()
        check(values()==[9,2,10],"rollback all three "+mode)
        check(FileAccess.get_sha256(sm.SAVE_PATH)==disk,"failure existing bytes "+mode)
        check(game.feed_message.visible and game.affection_bar.value==9 and game.level_label.text=="LV. 2","failure UI "+mode)
        check(not game.feed_button.disabled and game.creature_movement_active,"failure controls "+mode)
        for size in [Vector2i(405,720),Vector2i(720,1280)]:
            if DisplayServer.get_name()!="headless": root.size=size
            await settle()
            await shot("failure_"+mode+"_"+str(size.x))
        game.reject_apply=false
        game.reject_save=false
        begin()
        check(not game.feed_message.visible,"retry clears notice")
        await finish_wait()
        check(values()==[0,3,13],"new cycle reward once after failure "+mode)
    baby(9)
    await enter()
    sm.save_game(gm.game_data)
    disk=FileAccess.get_sha256(sm.SAVE_PATH)
    print("QA_READONLY_READY")
    var marker:=FileAccess.open("res://readonly.ready",FileAccess.WRITE)
    marker.store_string(ProjectSettings.globalize_path(sm.SAVE_PATH))
    marker.close()
    var wait_start:=Time.get_ticks_msec()
    while not FileAccess.file_exists("res://readonly.go") and Time.get_ticks_msec()-wait_start<10000: await process_frame
    begin()
    await finish_wait()
    check(values()==[9,2,10] and game.feed_message.visible,"real write open refusal rollback")
    check(FileAccess.get_sha256(sm.SAVE_PATH)==disk,"real write refusal bytes unchanged")
    marker=FileAccess.open("res://readonly.done",FileAccess.WRITE)
    marker.close()
    while not FileAccess.file_exists("res://readonly.released") and Time.get_ticks_msec()-wait_start<15000: await process_frame
    for size in [Vector2i(405,720),Vector2i(720,1280)]:
        if DisplayServer.get_name()!="headless": root.size=size
        await settle()
        game.creature_sprite.position.x=0
        await click(game.feed_button)
        check(game.feeding_busy,"actual viewport click begins")
        await shot("eating_"+str(size.x))
        await finish_wait()
        await shot("success_"+str(size.x))
    check(values()==[1,3,13],"two render cycles reward precisely")
func restore() -> void:
    var saved: Dictionary=sm.load_game()
    check(change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))==OK,"normal menu enters")
    await settle()
    await click(current_scene.continue_button)
    await settle()
    game=current_scene
    check(game.name=="Game" and game.current_creature.stage=="baby","normal continue baby")
    var restored: Dictionary=game.current_creature
    print("RESTORED_VALUES=",values()," TYPES=",typeof(restored.affection),",",typeof(restored.level),",",typeof(restored.affection_to_next_level))
    check(restored.affection==1 and restored.level==3 and restored.affection_to_next_level==13,"separate process numeric reward restored")
    check(gm.game_data==saved,"separate process entire saved data restored")
    check(game.affection_bar.value==1 and game.level_label.text=="LV. 3","restored UI")
    begin()
    await finish_wait()
    check(values()==[2,3,13],"restored next cycle +1")
