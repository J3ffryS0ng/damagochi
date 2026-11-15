extends "res://scripts/game/game.gd"
var reject_apply := false
var reject_save := false
func _apply_feed_affection() -> bool:
    if reject_apply:
        current_creature.affection=777
        current_creature.level=777
        current_creature.affection_to_next_level=777
        return false
    return super._apply_feed_affection()
func _save_feed_progress() -> bool:
    if reject_save: return false
    return super._save_feed_progress()
