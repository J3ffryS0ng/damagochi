extends SceneTree
var failures := 0
var gm: Node
var sm: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
    print("PASS " if ok else "FAIL ", label)
    if not ok: failures += 1
func sample(id := "001", level: Variant = 5, stage: Variant = "baby") -> Dictionary:
    var data := GameDataFactory.create_new_game("STEP46", id)
    data.active_creatures[0].stage = stage
    data.active_creatures[0].level = level
    return data
func finish() -> void:
    print("RESULT failures=", failures)
    quit(failures)
func run() -> void:
    if not ProjectSettings.globalize_path("user://").contains("step46-dev-"):
        quit(2)
        return
    gm = root.get_node("GameManager")
    sm = root.get_node("SaveManager")
    var args := OS.get_cmdline_user_args()
    if not args.is_empty():
        if args[0] == "seed":
            gm.game_data = sample()
            gm.game_data.active_creatures.clear()
            for id in ["001", "002", "003", "004"]:
                for level in [4, 5, 6]:
                    gm.game_data.active_creatures.append(sample(id, level).active_creatures[0])
            check(sm.save_game(gm.game_data), "isolated save twelve species/boundary records")
        elif args[0] == "restore":
            check(gm.load_game_data(sm.load_game()), "separate process restore")
            for index in range(12):
                check(gm.is_evolution_level_met(index) == (index % 3 != 0), "restored level prerequisite %s" % index)
                check(gm.get_active_creature(index).stage == "baby", "restored baby preserved %s" % index)
        finish()
        return
    check(gm.BABY_TO_ADULT_MIN_LEVEL == 5, "one common level threshold")
    for id in ["001", "002", "003", "004"]:
        for level in [4, 5, 6, 5.0, 6.0]:
            gm.game_data = sample(id, level)
            check(gm.is_evolution_level_met() == (level >= 5), "species boundary %s %s" % [id, level])
        gm.game_data = sample(id, 4)
        gm.game_data.active_creatures[0].affection = 9
        gm.game_data.active_creatures[0].affection_to_next_level = 10
        check(not gm.is_evolution_level_met(), "actual levelup before %s" % id)
        check(gm.add_affection(0, 1), "actual affection reward %s" % id)
        check(gm.get_active_creature().level == 5 and gm.is_evolution_level_met(), "actual levelup reaches boundary %s" % id)
        check(gm.get_active_creature().stage == "baby", "levelup does not evolve %s" % id)
    for level in [null, true, false, "5", -5, -5.0, 0, 1, 4.999, 5.001, INF, -INF, NAN, [], {}]:
        gm.game_data = sample("001", level)
        check(not gm.is_evolution_level_met(), "invalid or insufficient level %s" % str(level))
    for stage in ["egg", "adult", "unknown", "BABY", "", null, 5, true, [], {}]:
        gm.game_data = sample("001", 99, stage)
        check(not gm.is_evolution_level_met(), "invalid stage %s" % str(stage))
    for field in ["creature_id", "level", "stage"]:
        gm.game_data = sample()
        gm.game_data.active_creatures[0].erase(field)
        check(not gm.is_evolution_level_met(), "missing field %s" % field)
        check(not gm.game_data.active_creatures[0].has(field), "missing field not repaired %s" % field)
    for id in [null, "999", "", 1, true, [], {}]:
        gm.game_data = sample()
        gm.game_data.active_creatures[0].creature_id = id
        check(not gm.is_evolution_level_met(), "unregistered target %s" % str(id))
    for list in [null, {}, "bad", 5, true, [], [null], [[]], ["bad"], [5]]:
        gm.game_data = {"active_creatures":list}
        check(not gm.is_evolution_level_met(), "malformed active collection %s" % str(list))
    gm.game_data = {}
    check(not gm.is_evolution_level_met(), "empty game")
    gm.game_data = sample()
    for index in [-1, 1, 999, null, true, "0", 0.0, [], {}]:
        check(not gm.is_evolution_level_met(index), "invalid index %s" % str(index))
    gm.game_data.active_creatures.append(sample("004", 5).active_creatures[0])
    check(gm.is_evolution_level_met(1), "second valid creature index")
    check(sm.save_game(gm.game_data), "save side effect baseline")
    var before: Dictionary = gm.game_data.duplicate(true)
    var disk_before := FileAccess.get_file_as_bytes(sm.get_save_path())
    var catalog_before: Array = gm.creature_catalog.get_definitions()
    var stages_before: Array = gm.creature_catalog.get_stages()
    gm.creature_catalog.set_random_seed(46001)
    var expected := []
    for i in range(64): expected.append(gm.creature_catalog.choose_id())
    gm.creature_catalog.set_random_seed(46001)
    for i in range(200): gm.is_evolution_level_met()
    var actual := []
    for i in range(64): actual.append(gm.creature_catalog.choose_id())
    check(before == gm.game_data, "query preserves all memory data")
    check(disk_before == FileAccess.get_file_as_bytes(sm.get_save_path()), "query preserves disk bytes")
    check(actual == expected, "query does not consume catalog RNG")
    check(catalog_before == gm.creature_catalog.get_definitions() and stages_before == gm.creature_catalog.get_stages(), "query preserves species/stage metadata")
    gm.game_data = sample("001", 5, "egg")
    check(not gm.is_evolution_level_met(), "egg excluded despite level")
    check(gm.hatch_creature() and gm.is_evolution_level_met(), "existing hatch becomes eligible baby")
    check(not gm.hatch_creature() and gm.get_active_creature().stage == "baby", "hatch never produces adult")
    finish()
