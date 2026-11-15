extends SceneTree

var failures := 0
var gm: Node
var sm: Node

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ", label)
    if not ok: failures += 1
func settle() -> void:
    for i in range(3): await process_frame
func enter(inject: bool = false) -> Node:
    if current_scene != null:
        current_scene.queue_free()
        await settle()
    var game = load("res://scenes/game/Game.tscn").instantiate()
    if inject: game.set_script(load("res://dev_failure.gd"))
    root.add_child(game)
    current_scene = game
    await settle()
    return game
func begin(game: Node) -> Tween:
    game.stop_creature_movement()
    game.creature_sprite.position.x = 0.0
    game._on_feed_button_pressed()
    var t: Tween = game.feeding_tween
    t.pause()
    return t
func complete(game: Node) -> void:
    var t := begin(game)
    t.custom_step(1.401)
func shot(name: String) -> void:
    if DisplayServer.get_name() == "headless": return
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png("res://dev_"+name+".png") == OK, "capture "+name)
func click(button: Button) -> void:
    for down in [true,false]:
        var e := InputEventMouseButton.new()
        e.position = button.get_global_rect().get_center()
        e.button_index = MOUSE_BUTTON_LEFT
        e.pressed = down
        root.push_input(e,true)
        await process_frame

func run() -> void:
    print("TEST_USER_DIR=",ProjectSettings.globalize_path("user://"))
    if not ProjectSettings.globalize_path("user://").contains("step27-"):
        quit(2)
        return
    gm=root.get_node("GameManager")
    sm=root.get_node("SaveManager")
    if OS.get_cmdline_user_args().has("restore"):
        var saved: Dictionary=sm.load_game()
        var hash_before:=FileAccess.get_sha256(sm.SAVE_PATH)
        change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
        await settle()
        await click(current_scene.continue_button)
        await settle()
        check(current_scene.name=="Game" and gm.game_data==saved,"normal menu restores exact progress")
        check(not current_scene.feeding_busy and not current_scene.food_sprite.visible,"no reward or animation on restore")
        check(FileAccess.get_sha256(sm.SAVE_PATH)==hash_before,"restore does not save")
        print("RESULT failures=",failures)
        quit(failures)
        return
    gm.create_new_game("STEP27 DEV")
    gm.get_active_creature().stage="baby"
    var game=await enter()
    var pet: Dictionary=gm.get_active_creature()
    check(sm.save_game(gm.game_data),"seed save")
    var before: Dictionary=gm.game_data.duplicate(true)
    var digest:=FileAccess.get_sha256(sm.SAVE_PATH)
    var t:=begin(game)
    var token: int=game.feeding_generation
    for i in range(10): game._on_feed_button_pressed()
    for i in range(100): game.load_current_creature()
    game._finish_feeding(token)
    t.custom_step(1.3)
    check(gm.game_data==before and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"early finish and fade cannot award")
    t.custom_step(0.101)
    check(pet.affection==1 and not game.feeding_busy,"one completion adds one")
    game._finish_feeding(token)
    game._finish_feeding()
    check(pet.affection==1,"duplicate completion no award")
    check(sm.load_game().active_creatures[0].affection==1,"immediately saved")
    check(game.affection_bar.value==1 and game.affection_label.text=="친밀도 1 / 10","UI update")
    pet.affection=9
    complete(game)
    check(pet.affection==0 and pet.level==2 and pet.affection_to_next_level==13,"threshold levelup and next target")
    check(game.level_label.text=="LV. 2" and game.affection_bar.max_value==13,"level UI")
    pet.affection=13
    complete(game)
    check(pet.affection==1 and pet.level==3 and pet.affection_to_next_level==17,"remainder carried")
    for elapsed in [0.2,0.8,1.3]:
        check(sm.save_game(gm.game_data),"save cancel fixture")
        digest=FileAccess.get_sha256(sm.SAVE_PATH)
        var points: int=pet.affection
        t=begin(game)
        token=game.feeding_generation
        t.custom_step(elapsed)
        game._cancel_feeding()
        game._finish_feeding(token)
        game.update_creature_visual()
        check(pet.affection==points and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"cancel no reward "+str(elapsed))
    t=begin(game)
    token=game.feeding_generation
    var original: Dictionary=pet
    var replacement: Dictionary=pet.duplicate(true)
    gm.game_data.active_creatures[0]=replacement
    game._process(0.0)
    game._on_feed_button_pressed()
    check(not game.feeding_busy and game.feeding_tween==null,"stale view rejects new input before reload")
    game.load_current_creature()
    game._finish_feeding(token)
    check(not game.feeding_busy and original.affection==replacement.affection,"equal content different target cancels")
    pet=replacement
    game=await enter(true)
    for denied in ["deny_add","deny_save"]:
        pet.affection=16
        pet.level=3
        pet.affection_to_next_level=17
        check(sm.save_game(gm.game_data),"save refusal fixture")
        before=gm.game_data.duplicate(true)
        digest=FileAccess.get_sha256(sm.SAVE_PATH)
        game.set(denied,true)
        complete(game)
        check(gm.game_data==before and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"failure restores all three fields "+denied)
        check(game.feed_message.visible and game.affection_bar.value==16 and not game.feed_button.disabled,"failure UI and controls "+denied)
        await shot(denied+"_405")
        game.set(denied,false)
        complete(game)
        check(pet.affection==0 and pet.level==4 and pet.affection_to_next_level==22 and not game.feed_message.visible,"next fresh cycle pays exactly once "+denied)
    # Real FileAccess open denial: replace only this isolated fixture path with a directory.
    check(sm.save_game(gm.game_data),"save filesystem failure fixture")
    digest=FileAccess.get_sha256(sm.SAVE_PATH)
    before=gm.game_data.duplicate(true)
    check(DirAccess.rename_absolute(sm.SAVE_PATH,"user://preserved.json")==OK,"protect isolated save")
    check(DirAccess.make_dir_absolute(sm.SAVE_PATH)==OK,"directory blocks writing")
    complete(game)
    check(gm.game_data==before and game.feed_message.visible,"actual open denial rolls back")
    check(DirAccess.remove_absolute(sm.SAVE_PATH)==OK,"remove empty fixture directory")
    check(DirAccess.rename_absolute("user://preserved.json",sm.SAVE_PATH)==OK,"restore isolated save path")
    check(FileAccess.get_sha256(sm.SAVE_PATH)==digest,"protected save bytes unchanged")
    if DisplayServer.get_name()!="headless": root.size=Vector2i(720,1280)
    await settle()
    await shot("failure_720")
    for value in [0,-1,NAN,INF]:
        pet.affection_to_next_level=value
        var points: int=pet.affection
        complete(game)
        check(pet.affection==points and game.feed_message.visible,"invalid threshold rejected "+str(value))
    pet.affection_to_next_level=22
    game.load_current_creature()
    var points: int=pet.affection
    await click(game.feed_button)
    await create_timer(3.6).timeout
    check(pet.affection==points+1 and not game.feeding_busy and game.creature_movement_active,"real UI full cycle rewards and resumes")
    await shot("success_720")
    if DisplayServer.get_name()!="headless": root.size=Vector2i(405,720)
    await settle()
    await shot("success_405")
    points=pet.affection
    t=begin(game)
    token=game.feeding_generation
    game=await enter()
    game._finish_feeding(token)
    await create_timer(1.5).timeout
    check(pet.affection==points and not game.feeding_busy,"exit old generation no reward")
    print("RESULT failures=",failures)
    quit(failures)
