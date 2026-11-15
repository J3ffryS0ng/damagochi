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
func enter(inject: bool=false) -> void:
    if current_scene!=null:
        current_scene.queue_free()
        await settle()
    game=load("res://scenes/game/Game.tscn").instantiate()
    if inject: game.set_script(load("res://play_failure.gd"))
    root.add_child(game)
    current_scene=game
    await settle()
func begin() -> Tween:
    game._on_play_button_pressed()
    var t: Tween=game.playing_tween
    t.pause()
    return t
func complete() -> void:
    var t:=begin()
    t.custom_step(1.201)
func shot(label: String) -> void:
    if DisplayServer.get_name()=="headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://dev_"+label+".png")==OK,"capture "+label)
func click(button: Button) -> void:
    for down in [true,false]:
        var e:=InputEventMouseButton.new()
        e.position=button.get_global_rect().get_center()
        e.button_index=MOUSE_BUTTON_LEFT
        e.pressed=down
        root.push_input(e,true)
        await process_frame
func finish() -> void:
    current_scene.queue_free()
    current_scene=null
    game=null
    await settle()
    if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
    print("RESULT failures=",failures)
    quit(failures)
func run() -> void:
    if not ProjectSettings.globalize_path("user://").contains("step30-"):
        quit(2)
        return
    gm=root.get_node("GameManager")
    sm=root.get_node("SaveManager")
    if OS.get_cmdline_user_args().has("restore"):
        var saved: Dictionary=sm.load_game()
        var digest:=FileAccess.get_sha256(sm.SAVE_PATH)
        change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
        await settle()
        await click(current_scene.continue_button)
        await settle()
        game=current_scene
        check(game.name=="Game" and gm.game_data==saved,"normal menu exact restore")
        check(not game.playing_busy and not game.feed_message.visible,"no replay or stale notice")
        check(FileAccess.get_sha256(sm.SAVE_PATH)==digest,"restore no save")
        await finish()
        return
    gm.create_new_game("STEP30 DEV")
    gm.get_active_creature().stage="baby"
    await enter()
    var pet: Dictionary=gm.get_active_creature()
    check(sm.save_game(gm.game_data),"seed")
    var memory: Dictionary=gm.game_data.duplicate(true)
    var digest:=FileAccess.get_sha256(sm.SAVE_PATH)
    var t:=begin()
    var token: int=game.playing_generation
    for i in range(100): game.load_current_creature()
    for i in range(10):
        game._on_play_button_pressed()
        game._on_feed_button_pressed()
    game._finish_playing(token)
    t.custom_step(1.1)
    check(gm.game_data==memory and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"no early award")
    t.custom_step(0.101)
    game._finish_playing(token)
    check(pet.affection==1 and sm.load_game().active_creatures[0].affection==1,"completion once immediate save")
    check(game.affection_bar.value==1 and not game.play_button.disabled,"UI and controls")
    pet.affection=9
    complete()
    check(pet.level==2 and pet.affection==0 and pet.affection_to_next_level==13,"exact level threshold")
    pet.affection=13
    complete()
    check(pet.level==3 and pet.affection==1 and pet.affection_to_next_level==17,"remainder and next goal")
    for phase in [0.1,0.3,0.5,0.7,0.9,1.1]:
        check(sm.save_game(gm.game_data),"seed cancel")
        digest=FileAccess.get_sha256(sm.SAVE_PATH)
        var points: int=pet.affection
        t=begin()
        token=game.playing_generation
        t.custom_step(phase)
        game._cancel_playing()
        game._update_feed_button()
        game._finish_playing(token)
        check(pet.affection==points and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"cancel no award "+str(phase))
    t=begin()
    token=game.playing_generation
    gm.game_data.active_creatures[0]=pet.duplicate(true)
    game._process(0)
    game.load_current_creature()
    game._finish_playing(token)
    check(not game.playing_busy and gm.get_active_creature().affection==pet.affection,"target replacement no award")
    pet=gm.get_active_creature()
    await enter(true)
    for denied in ["deny_add","deny_save"]:
        pet.level=3
        pet.affection=16
        pet.affection_to_next_level=17
        check(sm.save_game(gm.game_data),"seed failure")
        memory=gm.game_data.duplicate(true)
        digest=FileAccess.get_sha256(sm.SAVE_PATH)
        game.set(denied,true)
        complete()
        check(gm.game_data==memory and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"three fields rollback "+denied)
        check(game.feed_message.visible and game.play_message_active and not game.play_button.disabled,"failure notice and controls")
        await shot(denied+"_405")
        game.hatch_in_progress=true
        game._on_play_button_pressed()
        check(game.feed_message.visible,"invalid input keeps notice")
        game.hatch_in_progress=false
        game.set(denied,false)
        t=begin()
        check(not game.feed_message.visible and not game.play_message_active,"fresh play clears own notice")
        t.custom_step(1.201)
        check(pet.level==4 and pet.affection==0 and pet.affection_to_next_level==22,"fresh retry once")
    check(sm.save_game(gm.game_data),"seed actual file refusal")
    memory=gm.game_data.duplicate(true)
    digest=FileAccess.get_sha256(sm.SAVE_PATH)
    check(DirAccess.rename_absolute(sm.SAVE_PATH,"user://preserved.json")==OK,"protect isolated save")
    check(DirAccess.make_dir_absolute(sm.SAVE_PATH)==OK,"block write with directory")
    complete()
    check(gm.game_data==memory and game.play_message_active,"actual open denial rollback")
    check(DirAccess.remove_absolute(sm.SAVE_PATH)==OK,"remove empty blocker")
    check(DirAccess.rename_absolute("user://preserved.json",sm.SAVE_PATH)==OK,"restore save path")
    check(FileAccess.get_sha256(sm.SAVE_PATH)==digest,"old bytes preserved")
    if DisplayServer.get_name()!="headless": root.size=Vector2i(720,1280)
    await settle()
    await shot("failure_720")
    for goal in [0,-1,NAN,INF]:
        pet.affection_to_next_level=goal
        var points: int=pet.affection
        complete()
        check(pet.affection==points and game.play_message_active,"invalid goal safe "+str(goal))
    pet.affection_to_next_level=22
    game.play_message_active=false
    game.feed_message.text="급식 실패 안내"
    game.feed_message.show()
    complete()
    check(game.feed_message.visible and game.feed_message.text=="급식 실패 안내","play keeps feed notice")
    game.stop_creature_movement()
    game.creature_sprite.position.x=0
    var points: int=pet.affection
    game._on_feed_button_pressed()
    var feed: Tween=game.feeding_tween
    feed.pause()
    game._on_play_button_pressed()
    feed.custom_step(1.401)
    check(pet.affection==points+1 and not game.playing_busy and not game.feed_message.visible,"feed still awards and clears notice")
    points=pet.affection
    await click(game.play_button)
    await create_timer(1.3).timeout
    check(pet.affection==points+1 and game.creature_movement_active,"real UI cycle awards once")
    await shot("success_720")
    t=begin()
    token=game.playing_generation
    points=pet.affection
    await enter()
    game._finish_playing(token)
    check(pet.affection==points and not game.playing_busy,"exit old cycle no award")
    await finish()
