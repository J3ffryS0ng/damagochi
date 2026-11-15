extends SceneTree
var failures := 0
var gm: Node
var sm: Node
var catalog: RefCounted
var document: Dictionary
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ", label)
    if not ok: failures += 1
func settle() -> void:
    for i in range(3): await process_frame
func scene(path: String) -> Node:
    change_scene_to_file(path)
    await settle()
    return current_scene
func run() -> void:
    check(ProjectSettings.globalize_path("user://").contains("step36-44-qa-"), "QA isolated user dir")
    if failures: quit(2); return
    create_timer(150.0).timeout.connect(func(): print("FAIL QA watchdog timeout"); quit(9))
    gm=root.get_node("GameManager")
    sm=root.get_node("SaveManager")
    catalog=CreatureCatalog.new()
    document=JSON.parse_string(FileAccess.get_file_as_string("res://data/creatures.json"))
    var args:=OS.get_cmdline_user_args()
    var mode: String=args[0] if not args.is_empty() else "suite"
    if mode.begins_with("seed_"): seed_save(mode)
    elif mode.begins_with("restore_"): await restore_save(mode)
    elif mode=="render": await render()
    elif mode=="retry": await retry()
    else:
        definitions()
        probabilities()
        await integration()
    if is_instance_valid(current_scene):
        current_scene.queue_free()
        current_scene=null
        await settle()
    if DisplayServer.get_name()!="headless": await RenderingServer.frame_post_draw
    print("RESULT STEP36-44 QA ",mode," failures=",failures)
    quit(failures)
func reject(value: Variant, label: String) -> void:
    check(not catalog.load_document(value),"reject "+label)
    check(not catalog.last_error.is_empty() and catalog.get_definitions().size()==1 and catalog.choose_id()=="001","whole fallback + diagnostic "+label)
func definitions() -> void:
    check(catalog.get_definitions().size()==3 and catalog.last_error.is_empty(),"36 three definitions load")
    var original: Dictionary=catalog.get_definition("001")
    check(original.baby_image=="res://assets/creatures/001/creature_001_idle.png" and original.baby_scale==[0.2633197,0.24048276],"38 original 001 path scale")
    for id in ["001","002","003"]:
        var entry: Dictionary=catalog.get_definition(id)
        check(entry.id==id and entry.weight==1 and entry.rarity=="test","37/40 ID lookup test equal weight "+id)
        check(load(entry.baby_image) is Texture2D and load(entry.egg_image) is Texture2D,"39 textures load "+id)
    var copied: Array=catalog.get_definitions()
    copied[0].baby_scale[0]=99
    copied[1].id="999"
    original.baby_scale[1]=99
    check(catalog.get_definition("001").baby_scale==[0.2633197,0.24048276] and catalog.get_definition("002").id=="002","37 nested query copies immutable")
    for bad in [null,[],{}, {"version":2,"creatures":document.creatures},{"version":true,"creatures":document.creatures},{"version":1,"creatures":[]}]: reject(bad,"root "+str(bad).left(30))
    for field in ["id","name","rarity","weight","baby_image","baby_scale","egg_image","egg_scale"]:
        var missing: Dictionary=document.duplicate(true)
        missing.creatures[1].erase(field)
        reject(missing,"missing "+field)
    for invalid_id in ["", "1", "0001", "-01", "a01", " 01", 2, null, "001"]:
        var bad: Dictionary=document.duplicate(true)
        bad.creatures[1].id=invalid_id
        reject(bad,"id "+str(invalid_id))
    for field in ["name","rarity"]:
        for value in ["   ",2,null]:
            var bad: Dictionary=document.duplicate(true)
            bad.creatures[1][field]=value
            reject(bad,field+str(value))
    for value in [-1,1000001,"1",true,null,INF,NAN]:
        var bad: Dictionary=document.duplicate(true)
        bad.creatures[1].weight=value
        reject(bad,"weight "+str(value))
    var all_zero: Dictionary=document.duplicate(true)
    for item in all_zero.creatures: item.weight=0
    reject(all_zero,"all zero")
    for field in ["baby_image","egg_image"]:
        for value in ["res://assets/no-such.svg","res://scripts/game/game.gd","user://save.json","https://invalid/image.png",42]:
            var bad: Dictionary=document.duplicate(true)
            bad.creatures[1][field]=value
            reject(bad,field+str(value))
    for value in [[],[0,1],[-1,1],[1],[INF,1],[1,"1"],[true,1],[101,1]]:
        var bad: Dictionary=document.duplicate(true)
        bad.creatures[1].baby_scale=value
        reject(bad,"scale "+str(value))
    var file:=FileAccess.open("res://qa_bad.json",FileAccess.WRITE)
    file.store_string('{"version":1,"creatures":[')
    file.close()
    check(not catalog.reload("res://qa_bad.json") and not catalog.last_error.is_empty(),"36 invalid JSON diagnostic fallback")
    check(not catalog.reload("res://qa_missing.json") and catalog.get_definitions().size()==1,"36 missing file fallback")
    check(catalog.reload(),"36 reload recovery")
    var input: Dictionary=document.duplicate(true)
    catalog.load_document(input)
    input.creatures[0].weight=99
    check(catalog.get_definition("001").weight==1,"37 loaded input deep copied")
    check(catalog.get_definition("999").id=="001" and catalog.get_definitions().size()==3,"37 unknown lookup fallback keeps catalog")
func draw(count: int) -> Dictionary:
    var result:={"001":0,"002":0,"003":0}
    for i in range(count):
        var id: String=catalog.choose_id()
        result[id]=int(result.get(id,0))+1
    return result
func probabilities() -> void:
    catalog.reload()
    catalog.set_random_seed(736441)
    var counts:=draw(30000)
    print("QA_UNIFORM_30000=",JSON.stringify(counts))
    for id in counts: check(abs(float(counts[id])/30000.0-1.0/3.0)<=0.01,"44 30k uniform tolerance "+id)
    catalog.set_random_seed(736441)
    check(draw(30000)==counts,"44 identical seed reproduces 30k counts")
    var weighted: Dictionary=document.duplicate(true)
    for i in range(3): weighted.creatures[i].weight=[1,2,7][i]
    check(catalog.load_document(weighted),"40 alternate weights load")
    catalog.set_random_seed(964431)
    counts=draw(30000)
    print("QA_WEIGHTED_30000=",JSON.stringify(counts))
    for i in range(3): check(abs(float(counts[["001","002","003"][i]])/30000.0-[0.1,0.2,0.7][i])<=0.01,"44 1:2:7 tolerance "+str(i))
    weighted.creatures[0].weight=0
    weighted.creatures[1].weight=0
    catalog.load_document(weighted)
    counts=draw(30000)
    check(counts=={"001":0,"002":0,"003":30000},"40/44 30k zero weight excluded")
    catalog.reload()
func seed_save(mode: String) -> void:
    var bits:=mode.split("_")
    gm.create_new_game("QA restore "+bits[1])
    var pet: Dictionary=gm.get_active_creature()
    pet.creature_id=bits[1]
    pet.stage=bits[2]
    pet.affection=3
    check(sm.save_game(gm.game_data),"42/43 seed "+mode)
func restore_save(mode: String) -> void:
    var bits:=mode.split("_")
    var hash_before:=FileAccess.get_sha256(sm.SAVE_PATH)
    var expected: Dictionary=sm.load_game()
    var menu=await scene("res://scenes/main/MainMenu.tscn")
    check(gm.game_data.is_empty() and not menu.continue_button.disabled,"41 menu read only before continue "+mode)
    menu.continue_button.pressed.emit()
    await settle()
    check(gm.game_data==expected and FileAccess.get_sha256(sm.SAVE_PATH)==hash_before,"41/42/43 restore no reroll or save "+mode)
    check(gm.get_active_creature().creature_id==bits[1],"42/43 process ID preserved "+mode)
    var game=current_scene
    if bits[2]=="baby":
        check(game.creature_sprite.texture.resource_path==catalog.get_definition(bits[1]).baby_image,"39 process texture "+bits[1])
    else: check(game.egg_sprite.visible and not game.creature_sprite.visible,"39 restored egg visible "+bits[1])
func integration() -> void:
    gm.creature_catalog.set_random_seed(1644036)
    var seen:={}
    for attempt in range(24):
        var menu=await scene("res://scenes/main/MainMenu.tscn")
        menu.start_button.pressed.emit()
        if menu.replacement_pending: menu.replace_save_dialog.confirmed.emit()
        await settle()
        check(current_scene.name=="NameEntry","41 actual menu new game name entry "+str(attempt))
        current_scene.name_input.text="QA "+str(attempt)
        current_scene.confirm_button.pressed.emit()
        await settle()
        var id: String=gm.get_active_creature().creature_id
        check(["001","002","003"].has(id) and sm.load_game().active_creatures[0].creature_id==id,"41 actual new game selected saved ID")
        seen[id]=true
        if seen.size()==3: break
    check(seen.size()==3,"44 actual new game reaches three species within 24 seeded requests")
    for id in ["001","002","003"]:
        gm.get_active_creature().creature_id=id
        gm.get_active_creature().stage="egg"
        gm.get_active_creature().level=2
        gm.get_active_creature().affection=0
        gm.get_active_creature().egg_created_at=Time.get_unix_time_from_system()-120
        var game=await scene("res://scenes/game/Game.tscn")
        check(game.egg_sprite.visible,"39 natural hatch begins egg "+id)
        await create_timer(1.1).timeout
        check(gm.get_active_creature().stage=="baby" and gm.get_active_creature().creature_id==id,"41 natural hatch ID unchanged "+id)
        var definition: Dictionary=catalog.get_definition(id)
        check(game.creature_sprite.texture.resource_path==definition.baby_image and game.creature_sprite.scale.is_equal_approx(Vector2(definition.baby_scale[0],definition.baby_scale[1])),"38/39/42/43 baby appearance "+id)
        check(game.creature_movement_active and not game.feed_button.disabled,"42/43 movement care enabled "+id)
        game.creature_sprite.position.x=0
        game.feed_button.pressed.emit()
        await create_timer(1.6).timeout
        check(gm.get_active_creature().affection==1 and not game.feeding_busy,"42/43 feed reward "+id)
        game.play_button.pressed.emit()
        await create_timer(1.4).timeout
        check(gm.get_active_creature().affection==2 and not game.playing_busy,"42/43 play reward "+id)
        game._show_poop()
        var click:=InputEventMouseButton.new()
        click.position=Vector2(540,900)
        click.button_index=MOUSE_BUTTON_LEFT
        click.pressed=true
        root.push_input(click,true)
        await create_timer(0.8).timeout
        check(gm.get_active_creature().affection==3 and not game.cleaning_busy and not game.poop_present,"42/43 cleanup reward "+id)
        check(sm.load_game().active_creatures[0].creature_id==id,"42/43 care save ID unchanged "+id)
        var hash_before:=FileAccess.get_sha256(sm.SAVE_PATH)
        var menu=await scene("res://scenes/main/MainMenu.tscn")
        menu.start_button.pressed.emit()
        menu.replace_save_dialog.canceled.emit()
        check(FileAccess.get_sha256(sm.SAVE_PATH)==hash_before and gm.get_active_creature().creature_id==id,"41 cancellation preserves saved ID "+id)
        menu.continue_button.pressed.emit()
        await settle()
        check(current_scene.creature_sprite.texture.resource_path==definition.baby_image,"39 reentry correct species "+id)
    catalog.set_random_seed(81736)
    gm.creature_catalog.set_random_seed(81736)
    var expected_id: String=catalog.choose_id()
    for i in range(100):
        current_scene.creature_movement_rng.randf()
        current_scene.poop_rng.randf()
    check(gm.creature_catalog.choose_id()==expected_id,"41 catalog RNG independent of movement poop RNG")
    var old: Dictionary=GameDataFactory.create_new_game("old fixture")
    var old_keys: Array=old.keys()
    gm.create_new_game("new fixture")
    check(gm.game_data.keys()==old_keys and gm.get_active_creature().keys()==old.active_creatures[0].keys() and gm.game_data.save_version==1,"36 save field contract unchanged")
    gm.get_active_creature().stage="baby"
    gm.get_active_creature().creature_id="unregistered-old-id"
    sm.save_game(gm.game_data)
    var saved: Dictionary=sm.load_game()
    var before:=FileAccess.get_sha256(sm.SAVE_PATH)
    var m=await scene("res://scenes/main/MainMenu.tscn")
    check(not m.continue_button.disabled,"37 valid nonempty unknown saved ID accepted")
    m.continue_button.pressed.emit()
    await settle()
    check(current_scene.creature_sprite.texture.resource_path==catalog.get_definition("001").baby_image,"37 unknown ID display fallback 001")
    check(gm.game_data==saved and gm.get_active_creature().creature_id=="unregistered-old-id","37 unknown saved ID and loaded values preserved no reroll")
    check(FileAccess.get_sha256(sm.SAVE_PATH)==before,"37 unknown ID no automatic disk write")
    var menu_script=load("res://scripts/main/main_menu.gd")
    saved.active_creatures[0].erase("creature_id")
    check(not menu_script.is_valid_save(saved),"37 missing saved ID remains explicit rejection")
func render() -> void:
    for id in ["001","002","003"]:
        gm.create_new_game("QA "+id)
        gm.get_active_creature().creature_id=id
        gm.get_active_creature().stage="baby"
        var game=await scene("res://scenes/game/Game.tscn")
        game.stop_creature_movement()
        game.stop_creature_idle()
        await RenderingServer.frame_post_draw
        check(root.get_texture().get_image().save_png("res://qa_species_"+id+".png")==OK,"render PNG "+id)
func retry() -> void:
    seed_save("seed_002_baby")
    var menu=await scene("res://scenes/main/MainMenu.tscn")
    menu.start_button.pressed.emit()
    menu.replace_save_dialog.confirmed.emit()
    await settle()
    var entry=current_scene
    var path:="res://scenes/game/Game.tscn"
    check(DirAccess.rename_absolute(path,path+".held")==OK,"retry isolated scene held")
    entry.name_input.text="QA saved ID retry"
    entry.confirm_button.pressed.emit()
    var first: Dictionary=gm.game_data.duplicate(true)
    var digest:=FileAccess.get_sha256(sm.SAVE_PATH)
    entry.name_input.text_submitted.emit("duplicate")
    check(entry.new_game_saved and gm.game_data==first and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"41 failed scene retry no reroll no save")
    check(DirAccess.rename_absolute(path+".held",path)==OK,"retry isolated scene restored")
    entry.confirm_button.pressed.emit()
    await settle()
    check(current_scene.name=="Game" and gm.game_data==first and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"41 successful retry preserves chosen ID")



