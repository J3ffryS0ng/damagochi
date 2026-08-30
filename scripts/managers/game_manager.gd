extends Node


var game_data: Dictionary = {}


func has_game_data() -> bool:
    return not game_data.is_empty()


func create_new_game(player_name: String) -> void:
    game_data = GameDataFactory.create_new_game(
        player_name
    )

    ensure_creature_defaults()


func load_game_data(loaded_data: Dictionary) -> bool:
    if loaded_data.is_empty():
        push_error("불러온 게임 데이터가 비어 있습니다.")
        return false

    game_data = loaded_data

    ensure_creature_defaults()

    return true


func clear_game_data() -> void:
    game_data = {}


func get_player_name() -> String:
    if not has_game_data():
        return ""

    return str(
        game_data.get(
            "player_name",
            ""
        )
    )


func has_active_creature() -> bool:
    if not has_game_data():
        return false

    var active_creatures: Array = game_data.get(
        "active_creatures",
        []
    )

    return not active_creatures.is_empty()


func get_active_creature(index: int = 0) -> Dictionary:
    if not has_active_creature():
        return {}

    var active_creatures: Array = game_data.get(
        "active_creatures",
        []
    )

    if index < 0 or index >= active_creatures.size():
        return {}

    return active_creatures[index]


func ensure_creature_defaults() -> void:
    if not has_active_creature():
        return

    var active_creatures: Array = game_data.get(
        "active_creatures",
        []
    )

    for index in range(active_creatures.size()):
        var creature: Dictionary = active_creatures[index]

        if not creature.has("stage"):
            creature["stage"] = "egg"

        if not creature.has("level"):
            creature["level"] = 1

        if not creature.has("affection"):
            creature["affection"] = 0

        if not creature.has("affection_to_next_level"):
            creature["affection_to_next_level"] = 10

        if not creature.has("egg_created_at"):
            creature["egg_created_at"] = (
                Time.get_unix_time_from_system()
            )

        if not creature.has("hatched_at"):
            creature["hatched_at"] = 0.0

        active_creatures[index] = creature

    game_data["active_creatures"] = active_creatures


func add_affection(
    index: int = 0,
    amount: int = 1
) -> bool:
    if not has_active_creature():
        return false

    var active_creatures: Array = game_data.get(
        "active_creatures",
        []
    )

    if index < 0 or index >= active_creatures.size():
        return false

    var creature: Dictionary = active_creatures[index]

    var affection: int = int(
        creature.get(
            "affection",
            0
        )
    )

    var level: int = int(
        creature.get(
            "level",
            1
        )
    )

    var affection_to_next_level: int = int(
        creature.get(
            "affection_to_next_level",
            10
        )
    )

    affection += amount

    while affection >= affection_to_next_level:
        affection -= affection_to_next_level
        level += 1

        affection_to_next_level = int(
            ceil(
                float(affection_to_next_level) * 1.25
            )
        )

    creature["affection"] = affection
    creature["level"] = level
    creature["affection_to_next_level"] = (
        affection_to_next_level
    )

    active_creatures[index] = creature
    game_data["active_creatures"] = active_creatures

    return true


func hatch_creature(index: int = 0) -> bool:
    if not has_active_creature():
        return false

    var active_creatures: Array = game_data.get(
        "active_creatures",
        []
    )

    if index < 0 or index >= active_creatures.size():
        return false

    var creature: Dictionary = active_creatures[index]

    var stage: String = str(
        creature.get(
            "stage",
            "egg"
        )
    )

    if stage != "egg":
        return false

    creature["stage"] = "baby"
    creature["hatched_at"] = (
        Time.get_unix_time_from_system()
    )

    active_creatures[index] = creature
    game_data["active_creatures"] = active_creatures

    return true