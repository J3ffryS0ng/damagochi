extends SceneTree
var failures := 0
var gm: Node
var sm: Node
var catalog: RefCounted
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ",label)
    if not ok: failures += 1
func settle() -> void:
    for i in range(3): await process_frame
func scene(path := "res://scenes/game/Game.tscn") -> Node:
    change_scene_to_file(path)
    await settle()
    return current_scene
func shutdown() -> void:
    if current_scene != null:
        current_scene.queue_free()
        current_scene = null
    await settle()
    if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
    print("RESULT failures=",failures)
    quit(failures)
func histogram(n: int) -> Dictionary:
    var result := {"001":0,"002":0,"003":0,"004":0}
    for i in range(n): result[catalog.choose_id()] += 1
    return result
func run() -> void:
    if not ProjectSettings.globalize_path("user://").contains("step45-dev-"):
        quit(2)
        return
    create_timer(150.0).timeout.connect(func(): print("FAIL watchdog"); quit(9))
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    catalog = gm.creature_catalog
    var args := OS.get_cmdline_user_args()
    if not args.is_empty() and args[0].begins_with("restore_"):
        var parts := args[0].trim_prefix("restore_").split("_")
        var id := parts[0]
        var stage := parts[1]
        var g = await scene()
        check(gm.get_active_creature().creature_id == id,"42/43 separate process ID "+id)
        check(gm.get_active_creature().stage == stage,"45 separate process stage "+id+stage)
        var sprite = g.egg_sprite if stage == "egg" else g.creature_sprite
        check(sprite.texture.resource_path == catalog.get_definition(id)[stage+"_image"],"45 separate process texture "+id+stage)
        await shutdown()
        return
    if not args.is_empty() and args[0].begins_with("seed_"):
        var parts := args[0].trim_prefix("seed_").split("_")
        var id := parts[0]
        var stage := parts[1]
        gm.game_data = GameDataFactory.create_new_game("restore",id)
        if stage == "baby": gm.hatch_creature()
        check(sm.save_game(gm.game_data),"36 seed save version1 "+id)
        await shutdown()
        return
    check(catalog.get_definitions().size() == 4,"36 loads four definitions")
    var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/creatures.json"))
    check(catalog.get_stages() == catalog.DEFAULT_STAGES,"45 approved stage order")
    check(catalog.get_next_stage("egg") == "baby" and catalog.get_next_stage("baby") == "adult" and catalog.get_next_stage("adult") == "","45 next metadata")
    check(catalog.get_stage("unknown").is_empty() and catalog.get_next_stage("unknown") == "","45 unknown safe lookup")
    var stages: Array = catalog.get_stages()
    stages[0].name = "changed"
    var stage_one: Dictionary = catalog.get_stage("baby")
    stage_one.next_stage = "egg"
    check(catalog.get_stage("egg").name == "알" and catalog.get_next_stage("baby") == "adult","45 stage deep copy")
    var legacy := original.duplicate(true)
    legacy.erase("stages")
    check(catalog.load_document(legacy) and catalog.get_stages() == catalog.DEFAULT_STAGES and catalog.get_definitions().size() == 4,"45 legacy definition compatibility")
    for invalid in [null,{},[],"egg",[{}]]:
        var bad_stage := original.duplicate(true)
        bad_stage.stages = invalid
        check(not catalog.load_document(bad_stage) and catalog.get_definitions().size() == 1 and catalog.get_stages() == catalog.DEFAULT_STAGES,"45 invalid stage structure fallback")
    for field in ["id","name","next_stage"]:
        for value in [null,1,true,"",[],{}]:
            var bad_stage := original.duplicate(true)
            bad_stage.stages[0][field] = value
            check(not catalog.load_document(bad_stage),"45 stage field rejection "+field+str(value))
        var missing_stage := original.duplicate(true)
        missing_stage.stages[0].erase(field)
        check(not catalog.load_document(missing_stage),"45 missing stage field "+field)
    for transitions in [["egg","adult",""],["baby","unknown",""],["baby","adult","egg"],["adult","baby",""]]:
        var bad_stage := original.duplicate(true)
        for i in range(3): bad_stage.stages[i].next_stage = transitions[i]
        check(not catalog.load_document(bad_stage),"45 rejects cycle/unregistered/skipped transition")
    var duplicate_stage := original.duplicate(true)
    duplicate_stage.stages[1].id = "egg"
    check(not catalog.load_document(duplicate_stage),"45 duplicate stage rejected")
    check(catalog.reload(),"45 valid metadata reload")
    var copy: Array = catalog.get_definitions()
    copy[0].baby_scale[0] = 99
    var one: Dictionary = catalog.get_definition("001")
    one.weight = 99
    check(catalog.get_definition("001").weight == 1 and catalog.get_definition("001").baby_scale[0] != 99,"37 deep copy lookup isolation")
    for bad in [null,[],{}, {"version":2,"creatures":[]}, {"version":true,"creatures":original.creatures}]:
        check(not catalog.load_document(bad) and catalog.choose_id() == "001","36 invalid document fallback")
    for field in ["id","name","rarity","weight","baby_image","baby_scale","egg_image","egg_scale"]:
        var doc := original.duplicate(true)
        doc.creatures[0].erase(field)
        check(not catalog.load_document(doc),"36 missing "+field)
    for weight in [-1,"1",true,INF,NAN,1000001]:
        var doc := original.duplicate(true)
        doc.creatures[0].weight = weight
        check(not catalog.load_document(doc),"40 rejects bad weight "+str(weight))
    var zero := original.duplicate(true)
    for entry in zero.creatures: entry.weight = 0
    check(not catalog.load_document(zero),"40 all zero rejected")
    var duplicate := original.duplicate(true)
    duplicate.creatures[1].id = "001"
    check(not catalog.load_document(duplicate),"37 duplicate rejected")
    var missing := original.duplicate(true)
    missing.creatures[0].baby_image = "res://assets/missing.png"
    check(not catalog.load_document(missing),"39 missing texture fallback")
    check(not catalog.reload("res://absent.json"),"36 missing file fallback")
    check(catalog.reload(),"36 reload valid file")
    catalog.set_random_seed(3644)
    var uniform := histogram(40000)
    catalog.set_random_seed(3644)
    check(histogram(40000) == uniform,"44 deterministic seed")
    for id in uniform: check(abs(float(uniform[id])/40000.0-0.25)<=0.01,"44 uniform "+id+" "+str(uniform[id]))
    var weighted := original.duplicate(true)
    for i in range(4): weighted.creatures[i].weight = [1,2,7,0][i]
    check(catalog.load_document(weighted),"40 custom weights accepted")
    catalog.set_random_seed(4144)
    var weights := histogram(40000)
    for i in range(4):
        var id: String = ["001","002","003","004"][i]
        check(abs(float(weights[id])/40000.0-[0.1,0.2,0.7,0.0][i])<=0.01,"44 1:2:7 "+id+" "+str(weights[id]))
    weighted.creatures[0].weight = 0
    weighted.creatures[1].weight = 0
    catalog.load_document(weighted)
    check(histogram(40000)["003"] == 40000,"40 zero excluded 40000 draws")
    var f := FileAccess.open("res://probabilities.json",FileAccess.WRITE)
    f.store_string(JSON.stringify({"n":40000,"uniform_seed":3644,"uniform":uniform,"weighted_seed":4144,"weighted":weights},"  "))
    f.close()
    catalog.reload()
    var reached := {}
    catalog.set_random_seed(36)
    for i in range(30):
        sm.delete_save()
        var menu = await scene("res://scenes/main/MainMenu.tscn")
        menu.start_button.pressed.emit()
        await settle()
        current_scene.name_input.text = "신규 "+str(i)
        current_scene.confirm_button.pressed.emit()
        await settle()
        var id: String = gm.get_active_creature().creature_id
        reached[id] = true
        check(sm.load_game().active_creatures[0].creature_id == id,"41 actual menu/name/save selected "+id)
        var g = current_scene
        g.load_current_creature()
        check(gm.get_active_creature().creature_id == id,"41 refresh keeps ID")
        if reached.size() == 4: break
    check(reached.size()==4,"44 actual new games reach all species")
    for id in ["001","002","003","004"]:
        gm.game_data = GameDataFactory.create_new_game("integration",id)
        var g = await scene()
        check(g.egg_sprite.texture.resource_path == catalog.get_definition(id).egg_image,"39 common egg "+id)
        gm.get_active_creature().level = 2
        gm.get_active_creature().egg_created_at -= 120
        g.check_hatch_effect()
        await create_timer(1.2).timeout
        check(gm.get_active_creature().creature_id == id and gm.get_active_creature().stage == "baby","39 hatch keeps species "+id)
        check(g.creature_sprite.texture.resource_path == catalog.get_definition(id).baby_image,"39 data texture "+id)
        var scale_data: Array = catalog.get_definition(id).baby_scale
        check(g.creature_sprite.scale.is_equal_approx(Vector2(scale_data[0],scale_data[1])),"38 original/data scale "+id)
        var size: Vector2 = g.creature_sprite.texture.get_size() * g.creature_sprite.scale
        check(size.x < 260 and size.y < 260 and size.x > 250 and size.y > 250,"45 PNG display bounds "+id)
        sm.save_game(gm.game_data)
        var state_before: String = JSON.stringify(gm.game_data)
        var bytes_before := FileAccess.get_sha256(sm.SAVE_PATH)
        catalog.get_next_stage("baby")
        catalog.get_stage("adult")
        check(JSON.stringify(gm.game_data) == state_before and FileAccess.get_sha256(sm.SAVE_PATH) == bytes_before,"45 metadata does not evolve/save "+id)
        var before: int = gm.get_active_creature().affection
        g._on_feed_button_pressed()
        g.feeding_tween.pause()
        g.feeding_tween.custom_step(5.0)
        g._on_play_button_pressed()
        g.playing_tween.pause()
        g.playing_tween.custom_step(1.201)
        g._show_poop()
        g._clean_poop()
        g.cleaning_tween.pause()
        g.cleaning_tween.custom_step(0.601)
        check(gm.get_active_creature().affection == before+3,"42/43 all care +3 "+id)
        check(g.creature_movement_active and g.creature_idle_tween.is_running(),"38 movement/idle resumed "+id)
        if DisplayServer.get_name() != "headless":
            g.stop_creature_idle()
            g.stop_creature_movement()
            await RenderingServer.frame_post_draw
            check(root.get_texture().get_image().save_png("res://dev_species_"+id+".png") == OK,"39 rendered "+id)
        await scene()
        check(gm.get_active_creature().creature_id == id,"41 scene reentry no redraw "+id)
    gm.game_data = GameDataFactory.create_new_game("unknown","999")
    gm.hatch_creature()
    sm.save_game(gm.game_data)
    var digest := FileAccess.get_sha256(sm.SAVE_PATH)
    var g = await scene()
    check(gm.get_active_creature().creature_id=="999" and FileAccess.get_sha256(sm.SAVE_PATH)==digest,"37 unknown stored ID and bytes preserved")
    check(g.creature_sprite.texture.resource_path==catalog.FALLBACK.baby_image,"37 unknown display fallback")
    var expected_keys: Array = GameDataFactory.create_new_game("old").keys()
    check(gm.game_data.keys()==expected_keys and gm.game_data.save_version==1,"36 save schema unchanged")
    await shutdown()

