extends "res://scripts/game/game.gd"

var deny_add := false
var deny_save := false

func _apply_feed_affection() -> bool:
    if deny_add: return false
    return super._apply_feed_affection()

func _save_feed_progress() -> bool:
    if deny_save: return false
    return super._save_feed_progress()
