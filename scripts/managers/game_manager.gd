extends Node


var game_data: Dictionary = {}


func has_game_data() -> bool:
    return not game_data.is_empty()


func create_new_game(player_name: String) -> void:
    game_data = GameDataFactory.create_new_game(player_name)


func clear_game_data() -> void:
    game_data = {}


func get_player_name() -> String:
    if not has_game_data():
        return ""

    return str(game_data.get("player_name", ""))