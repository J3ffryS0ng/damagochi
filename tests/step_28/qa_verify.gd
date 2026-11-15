extends SceneTree
var failures := 0
var requests := 0
var gm: Node
var sm: Node
var game: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ", label)
    if not ok: failures += 1
func settle() -> void:
    for i in range(3): await process_frame
func requested() -> void: requests += 1
func enter() -> void:
    check(change_scene_to_file("res://scenes/game/Game.tscn")==OK,"enter game")
    await settle()
    game=current_scene
    game.play_requested.connect(requested)
func create_fixture(stage: String) -> void:
    gm.create_new_game("놀아주기 독립 QA")
    gm.get_active_creature().stage=stage
func mouse(button: Button, right: bool=false) -> void:
    for down in [true,false]:
        var event:=InputEventMouseButton.new()
        event.position=button.get_global_rect().get_center()
        event.button_index=MOUSE_BUTTON_RIGHT if right else MOUSE_BUTTON_LEFT
        event.pressed=down
        root.push_input(event,true)
        await process_frame
func shot(label: String) -> void:
    if DisplayServer.get_name()=="headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://qa_play_"+label+".png")==OK,"render "+label)
func layouts() -> void:
    var play: Rect2=game.play_button.get_global_rect()
    check(play==Rect2(280,1160,160,80),"central fixed play rectangle")
    for path in ["UI/FeedPanel/FeedButton","UI/BottomPanel/MenuButton","UI/FeedMessage"]:
        check(not play.intersects(game.get_node(path).get_global_rect()),"no overlap "+path)
    check(game.play_button.text=="놀아주기" and game.play_button.is_visible_in_tree(),"visible Korean label")
func run() -> void:
    print("TEST_USER_DIR=",ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("step28-qa-"):
        quit(2)
        return
    gm=root.get_node("GameManager")
    sm=root.get_node("SaveManager")
    var args:=OS.get_cmdline_user_args()
    if not args.is_empty():
        await restore_mode(args[0])
    else:
        await suite()
    print("RESULT STEP28 QA failures=",failures)
    # Drain the many synthetic scene/input fixtures before renderer teardown.
    if is_instance_valid(current_scene):
        current_scene.queue_free()
        current_scene=null
        await settle()
    if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
    quit(failures)
func restore_mode(mode: String) -> void:
    var stage:=mode.get_slice("_",1)
    if mode.begins_with("seed_"):
        create_fixture(stage)
        check(sm.save_game(gm.game_data),"separate process seed "+stage)
        return
    var digest:=FileAccess.get_sha256(sm.SAVE_PATH)
    check(change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))==OK,"normal menu load")
    await settle()
    await mouse(current_scene.continue_button)
    await settle()
    game=current_scene
    check(game.name=="Game" and game.current_creature.stage==stage,"normal continue "+stage)
    game.play_requested.connect(requested)
    check(game.play_button.visible and game.play_button.disabled==(stage=="egg"),"restored play eligibility "+stage)
    await mouse(game.play_button)
    check(requests==(1 if stage=="baby" else 0),"restored click "+stage)
    check(FileAccess.get_sha256(sm.SAVE_PATH)==digest,"restore play no disk mutation")
func suite() -> void:
    for size in [Vector2i(405,720),Vector2i(720,1280)]:
        if DisplayServer.get_name()!="headless": root.size=size
        create_fixture("egg")
        await enter()
        layouts()
        check(game.play_button.disabled,"egg disabled "+str(size.x))
        var before:=requests
        await mouse(game.play_button)
        game.play_button.pressed.emit()
        check(requests==before,"egg rejects UI and synthetic signal")
        await shot("egg_"+str(size.x))
        game.current_creature.egg_created_at=Time.get_unix_time_from_system()-120
        game.current_creature.level=2
        game.load_current_creature()
        check(game.hatch_in_progress and game.play_button.disabled,"hatch starts blocked")
        await create_timer(0.5).timeout
        check(game.current_creature.stage=="baby" and game.hatch_flash.color.a>0 and game.play_button.disabled,"baby fade remains blocked")
        game.play_button.pressed.emit()
        check(requests==before,"fade handler rejects")
        await shot("hatch_"+str(size.x))
        await create_timer(0.5).timeout
        check(not game.play_button.disabled,"full fade enables")
        layouts()
        var memory: Dictionary=gm.game_data.duplicate(true)
        var digest:=FileAccess.get_sha256(sm.SAVE_PATH)
        var idle: Tween=game.creature_idle_tween
        await mouse(game.play_button)
        check(requests==before+1,"left mouse one request")
        await mouse(game.play_button,true)
        check(requests==before+1,"right mouse zero")
        game.play_button.grab_focus()
        for down in [true,false]:
            var key:=InputEventKey.new()
            key.keycode=KEY_SPACE
            key.pressed=down
            root.push_input(key,true)
            await process_frame
        check(requests==before+2,"Space one request")
        for i in range(100): game.load_current_creature()
        check(game.play_button.pressed.get_connections().size()==1,"100 refresh one connection")
        for i in range(10): await mouse(game.play_button)
        check(requests==before+12,"10 actual clicks 10 requests")
        check(memory==gm.game_data and digest==FileAccess.get_sha256(sm.SAVE_PATH),"play memory and disk unchanged")
        check(game.creature_movement_active and game.creature_idle_tween==idle and idle.is_running(),"play leaves movement and Idle active")
        await shot("baby_"+str(size.x))
        game.creature_sprite.position.x=120
        game._on_feed_button_pressed()
        var generation: int=game.feeding_generation
        before=requests
        check(game.feeding_busy and game.play_button.disabled,"feeding disables play")
        await mouse(game.play_button)
        for i in range(10): game.play_button.pressed.emit()
        check(requests==before and game.feeding_generation==generation,"busy input ignored without interrupt")
        await shot("feeding_"+str(size.x))
        await create_timer(3.6).timeout
        check(not game.feeding_busy and not game.play_button.disabled and requests==before,"completion enables no queued play")
        check(game.current_creature.affection==1,"feed completion retains +1")
        await mouse(game.play_button)
        check(requests==before+1,"post feed fresh click once")
        game._on_feed_button_pressed()
        game.current_creature.stage="adult"
        await settle()
        check(not game.feeding_busy and game.play_button.disabled,"invalid stage cancels and blocks")
        check(game.current_creature.affection==1,"cancel zero reward")
        game.current_creature.stage="baby"
        game.update_creature_visual()
        check(not game.play_button.disabled,"eligible refresh after cancel enables")
        game.feed_message.text="친밀도를 저장하지 못해 반영하지 않았습니다.\n다시 밥을 줄 수 있습니다."
        game.feed_message.show()
        await mouse(game.play_button)
        check(game.feed_message.visible,"play preserves failure notice")
        await shot("notice_"+str(size.x))
    for state in ["adult","empty","stale","hatch"]:
        create_fixture("baby")
        await enter()
        var count:=requests
        if state=="adult": game.current_creature.stage="adult"
        elif state=="empty": game.current_creature={}
        elif state=="stale": gm.game_data.active_creatures[0]=game.current_creature.duplicate(true)
        else: game.hatch_in_progress=true
        game._on_play_button_pressed()
        game.update_creature_visual()
        await mouse(game.play_button)
        check(requests==count and game.play_button.disabled,"ineligible direct and UI "+state)
    create_fixture("baby")
    await enter()
    var count:=requests
    await mouse(game.play_button)
    check(requests==count+1 and game.play_button.pressed.get_connections().size()==1,"reentry connection single")

