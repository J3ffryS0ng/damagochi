extends SceneTree
var failures := 0
var gm: Node
var sm: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ",label)
    if not ok: failures += 1
func settle() -> void:
    for i in range(3): await process_frame
func fixture(id: String="001", level: Variant=5, stage: Variant="baby") -> void:
    gm.game_data=GameDataFactory.create_new_game("Independent STEP46",id)
    gm.game_data.active_creatures[0].stage=stage
    gm.game_data.active_creatures[0].level=level
func query(index: Variant=0) -> bool: return gm.is_evolution_level_met(index)
func run() -> void:
    check(ProjectSettings.globalize_path("user://").contains("step46-qa-"),"isolated QA directory")
    if failures: quit(2); return
    create_timer(120.0).timeout.connect(func(): print("FAIL timeout"); quit(9))
    gm=root.get_node("GameManager")
    sm=root.get_node("SaveManager")
    var args:=OS.get_cmdline_user_args()
    var mode: String=args[0] if not args.is_empty() else "suite"
    if mode.begins_with("seed_"):
        var fields:=mode.split("_")
        fixture(fields[1],int(fields[2]))
        check(sm.save_game(gm.game_data),"seed separate process "+mode)
    elif mode.begins_with("restore_"):
        var fields:=mode.split("_")
        var before:=FileAccess.get_sha256(sm.SAVE_PATH)
        var expected: Dictionary=sm.load_game()
        check(gm.load_game_data(expected.duplicate(true)),"restore load")
        check(query()==(int(fields[2])>=5),"restored condition "+mode)
        check(gm.game_data==expected and FileAccess.get_sha256(sm.SAVE_PATH)==before,"restored memory/disk unchanged "+mode)
        check(gm.get_active_creature().stage=="baby" and gm.get_active_creature().creature_id==fields[1],"restored stage ID unchanged")
    else:
        boundaries()
        invalid_inputs()
        effects()
        await integration()
    if is_instance_valid(current_scene):
        current_scene.queue_free()
        current_scene=null
        await settle()
    print("RESULT STEP46 QA ",mode," failures=",failures)
    quit(failures)
func boundaries() -> void:
    check(gm.BABY_TO_ADULT_MIN_LEVEL==5,"approved common threshold 5")
    for id in ["001","002","003","004"]:
        for level in [4,5,6,4.0,5.0,6.0]:
            fixture(id,level)
            check(query()==(level>=5),"boundary "+id+" "+str(level)+" type "+str(typeof(level)))
        fixture(id,4)
        gm.get_active_creature().affection=9
        gm.get_active_creature().affection_to_next_level=10
        check(not query(),"before real level up "+id)
        check(gm.add_affection(0,1) and gm.get_active_creature().level==5 and query(),"real level-up reaches threshold "+id)
        check(gm.get_active_creature().stage=="baby","level-up does not evolve "+id)
func invalid_inputs() -> void:
    for value in [null,true,false,"5",[],{},-1,0,1,4.999,5.001,INF,-INF,NAN]:
        fixture("001",value)
        check(not query(),"reject level type/value "+str(value))
    fixture()
    gm.get_active_creature().erase("level")
    check(not query() and not gm.get_active_creature().has("level"),"missing level rejected without default mutation")
    for value in [null,true,5,[],{},"egg","adult","Baby","","unknown"]:
        fixture("001",999,value)
        check(not query(),"reject stage "+str(value))
    fixture()
    gm.get_active_creature().erase("stage")
    check(not query() and not gm.get_active_creature().has("stage"),"missing stage stays absent")
    for value in [null,true,false,"0",0.0,0.5,-1,1,999,[],{},INF,NAN]:
        fixture()
        check(not query(value),"reject index "+str(value))
    for value in [null,true,4,"array",{},[],[null],[true],[5],["baby"],[[]]]:
        gm.game_data={"active_creatures":value}
        check(not query(),"reject container/entry "+str(value))
    for value in [null,true,1,"999","",[],{}]:
        fixture()
        gm.get_active_creature().creature_id=value
        check(not query(),"reject species "+str(value))
    fixture()
    gm.get_active_creature().erase("creature_id")
    check(not query() and not gm.get_active_creature().has("creature_id"),"missing species remains absent")
    gm.game_data={}
    check(not query(),"empty root")
    gm.game_data={"other":1}
    check(not query(),"missing active creatures")
    fixture()
    gm.game_data.active_creatures.append({"creature_id":"002","stage":"baby","level":4})
    check(query(0) and not query(1),"index selects actual target")
    gm.game_data.active_creatures[1].level=5
    check(query(1),"second valid entry")
func effects() -> void:
    fixture()
    check(sm.save_game(gm.game_data),"side effect save baseline")
    var memory: Dictionary=gm.game_data.duplicate(true)
    var disk:=FileAccess.get_sha256(sm.SAVE_PATH)
    var definitions: Array=gm.creature_catalog.get_definitions()
    var stages: Array=gm.creature_catalog.get_stages()
    var reference:=CreatureCatalog.new()
    reference.set_random_seed(464601)
    gm.creature_catalog.set_random_seed(464601)
    for i in range(100):
        query()
        query(-1)
        check(gm.creature_catalog.choose_id()==reference.choose_id(),"query leaves RNG sequence "+str(i))
    check(gm.game_data==memory and FileAccess.get_sha256(sm.SAVE_PATH)==disk,"repeated query memory save no side effects")
    check(gm.creature_catalog.get_definitions()==definitions and gm.creature_catalog.get_stages()==stages,"catalog definitions stages unchanged")
    check(definitions.size()==4 and stages.size()==3,"four species three stages preserved")
    for entry in definitions: check(entry.weight==1,"uniform weight "+entry.id)
func integration() -> void:
    fixture("004",5,"baby")
    change_scene_to_file("res://scenes/game/Game.tscn")
    await settle()
    await create_timer(1.1).timeout
    check(query() and gm.get_active_creature().stage=="baby","eligible game does not auto evolve")
    check(current_scene.creature_sprite.texture.resource_path==gm.creature_catalog.get_definition("004").baby_image,"eligible baby keeps image")
    check(not current_scene.feed_button.disabled and not current_scene.play_button.disabled,"eligible baby care remains available")
    current_scene.queue_free()
    current_scene=null
    await settle()
    fixture("003",2,"egg")
    gm.get_active_creature().egg_created_at=Time.get_unix_time_from_system()-120
    check(not query(),"ready egg excluded")
    change_scene_to_file("res://scenes/game/Game.tscn")
    await settle()
    await create_timer(1.1).timeout
    check(gm.get_active_creature().stage=="baby" and gm.get_active_creature().level==2 and not query(),"existing natural hatch level 2 unchanged")

