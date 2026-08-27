class_name GameDataFactory
extends RefCounted


static func create_new_game(player_name: String) -> Dictionary:
    return {
        "save_version": 1,
        "player_name": player_name,
        "created_at": Time.get_unix_time_from_system(),
        "last_played_at": Time.get_unix_time_from_system(),

        "active_creatures": [],

        "encyclopedia": {},

        "settings": {
            "bgm_volume": 1.0,
            "sfx_volume": 1.0
        }
    }