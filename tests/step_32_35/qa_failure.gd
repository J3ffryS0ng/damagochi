extends "res://scripts/game/game.gd"
var reject_apply := false
var reject_save := false
func _apply_clean_affection() -> bool:
    if reject_apply:
        current_creature.affection=777
        current_creature.level=777
        current_creature.affection_to_next_level=777
        return false
    return super._apply_clean_affection()
func _save_clean_progress() -> bool:
    if reject_save: return false
    return super._save_clean_progress()
var reject_play_save := false
func _save_play_progress() -> bool:
    if reject_play_save: return false
    return super._save_play_progress()
var reject_feed_save := false
func _save_feed_progress() -> bool:
    if reject_feed_save: return false
    return super._save_feed_progress()
