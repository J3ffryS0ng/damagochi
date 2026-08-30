extends Node


var game_data: Dictionary = {}


func has_game_data() -> bool:
    return not game_data.is_empty()


func create_new_game(player_name: String) -> void:
    game_data = GameDataFactory.create_new_game(
        player_name
    )


func load_game_data(loaded_data: Dictionary) -> bool:
    if loaded_data.is_empty():
        push_error("불러온 게임 데이터가 비어 있습니다.")
        return false

    game_data = loaded_data

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