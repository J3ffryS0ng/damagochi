extends "res://scripts/game/game.gd"
var deny_add := false
var deny_save := false
func _apply_clean_affection() -> bool:
    if deny_add:
        current_creature.affection += 4
        return false
    return super._apply_clean_affection()
func _save_clean_progress() -> bool:
    if deny_save: return false
    return super._save_clean_progress()
var deny_play_save := false
func _save_play_progress() -> bool:
    if deny_play_save: return false
    return super._save_play_progress()
