class_name GameDataFactory
extends RefCounted


static func create_new_game(player_name: String) -> Dictionary:
    var current_time: float = Time.get_unix_time_from_system()

    return {
        "save_version": 1,
        "player_name": player_name,
        "created_at": current_time,
        "last_played_at": current_time,

        "active_creatures": [
            {
                "creature_id": "001",
                "stage": "egg",
                "level": 1,
                "affection": 0,
                "affection_to_next_level": 10,
                "egg_created_at": current_time
            }
        ],

        "encyclopedia": {},

        "settings": {
            "bgm_volume": 1.0,
            "sfx_volume": 1.0
        }
    }