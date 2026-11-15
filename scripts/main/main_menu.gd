extends Control

const NEW_GAME_AUTHORIZATION := "step22_new_game_authorization"
const LOAD_ERROR := "저장 데이터를 읽을 수 없습니다. 기존 저장은 변경하지 않았습니다."
const REPLACE_TEXT := "새 게임을 시작하면 기존 진행 데이터가 대체될 수 있습니다. 계속하시겠습니까?"

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var encyclopedia_button: Button = $CenterContainer/VBoxContainer/EncyclopediaButton
@onready var message_label: Label = $CenterContainer/VBoxContainer/MessageLabel
@onready var replace_save_dialog: ConfirmationDialog = $ReplaceSaveDialog

var transition_in_progress := false
var replacement_pending := false
var save_is_valid := false


func _ready() -> void:
    if get_tree().has_meta(NEW_GAME_AUTHORIZATION):
        get_tree().remove_meta(NEW_GAME_AUTHORIZATION)
    start_button.pressed.connect(_on_start_button_pressed)
    continue_button.pressed.connect(_on_continue_button_pressed)
    encyclopedia_button.pressed.connect(_on_encyclopedia_button_pressed)
    replace_save_dialog.confirmed.connect(_on_replace_confirmed)
    replace_save_dialog.canceled.connect(_on_replace_canceled)
    replace_save_dialog.close_requested.connect(_on_replace_canceled)
    load_existing_save()


static func is_valid_save(data: Dictionary) -> bool:
    if not _nonempty_string(data.get("player_name")):
        return false
    if not _number_at_least(data.get("save_version"), 1.0, true) or data["save_version"] != 1:
        return false
    var creatures = data.get("active_creatures")
    if not creatures is Array or creatures.is_empty():
        return false
    for creature in creatures:
        if not creature is Dictionary or not _nonempty_string(creature.get("creature_id")):
            return false
        if creature.has("stage") and not _nonempty_string(creature["stage"]):
            return false
        for field in ["level", "affection", "affection_to_next_level"]:
            var minimum := 0.0 if field == "affection" else 1.0
            if creature.has(field) and not _number_at_least(creature[field], minimum, true):
                return false
        for field in ["egg_created_at", "hatched_at"]:
            if creature.has(field) and not _number_at_least(creature[field], 0.0, false):
                return false
    return true


static func _nonempty_string(value: Variant) -> bool:
    return value is String and not value.strip_edges().is_empty()


static func _number_at_least(value: Variant, minimum: float, integer: bool) -> bool:
    if not (value is int or value is float):
        return false
    return is_finite(float(value)) and value >= minimum and (not integer or floor(value) == value)


# Shared by NameEntry: no writes and no changes to the save schema.
static func capture_save_state() -> Dictionary:
    if not FileAccess.file_exists(SaveManager.SAVE_PATH):
        return {"exists": false, "sha256": ""}
    var digest := FileAccess.get_sha256(SaveManager.SAVE_PATH)
    if digest.is_empty():
        return {}
    return {"exists": true, "sha256": digest}


func load_existing_save() -> void:
    save_is_valid = false
    message_label.text = ""
    if SaveManager.has_save_file():
        save_is_valid = is_valid_save(SaveManager.load_game())
        if not save_is_valid:
            message_label.text = LOAD_ERROR
    _update_buttons()


func _update_buttons() -> void:
    var busy := transition_in_progress or replacement_pending
    continue_button.disabled = busy or not save_is_valid
    start_button.disabled = busy
    encyclopedia_button.disabled = busy


func _on_continue_button_pressed() -> void:
    if transition_in_progress or replacement_pending:
        return
    var loaded_data: Dictionary = SaveManager.load_game()
    if not is_valid_save(loaded_data):
        save_is_valid = false
        message_label.text = LOAD_ERROR
        _update_buttons()
        return
    var previous_data: Dictionary = GameManager.game_data.duplicate(true)
    transition_in_progress = true
    _update_buttons()
    if not GameManager.load_game_data(loaded_data):
        GameManager.game_data = previous_data
        transition_in_progress = false
        message_label.text = LOAD_ERROR
        _update_buttons()
        return
    var error := get_tree().change_scene_to_file("res://scenes/game/Game.tscn")
    if error != OK:
        GameManager.game_data = previous_data
        transition_in_progress = false
        save_is_valid = true
        message_label.text = "게임 화면 전환에 실패했습니다."
        _update_buttons()


func _on_start_button_pressed() -> void:
    if transition_in_progress or replacement_pending:
        return
    if not SaveManager.has_save_file():
        _authorize_new_game()
        return
    var readable := is_valid_save(SaveManager.load_game())
    replace_save_dialog.dialog_text = REPLACE_TEXT
    if not readable:
        replace_save_dialog.dialog_text += "\n기존 저장을 읽을 수 없습니다. 새 게임 저장 시 해당 파일이 대체될 수 있습니다."
    replacement_pending = true
    _update_buttons()
    replace_save_dialog.popup_centered(Vector2i(560, 240))


func _on_replace_confirmed() -> void:
    if not replacement_pending or transition_in_progress:
        return
    replacement_pending = false
    replace_save_dialog.hide()
    _authorize_new_game()


func _on_replace_canceled() -> void:
    if not replacement_pending or transition_in_progress:
        return
    replacement_pending = false
    replace_save_dialog.hide()
    _update_buttons()
    start_button.grab_focus()


func _authorize_new_game() -> void:
    var authorization := capture_save_state()
    if authorization.is_empty():
        message_label.text = "기존 저장을 확인할 수 없어 새 게임을 진행할 수 없습니다."
        _update_buttons()
        return
    transition_in_progress = true
    _update_buttons()
    get_tree().set_meta(NEW_GAME_AUTHORIZATION, authorization)
    var error := get_tree().change_scene_to_file("res://scenes/main/NameEntry.tscn")
    if error != OK:
        get_tree().remove_meta(NEW_GAME_AUTHORIZATION)
        transition_in_progress = false
        message_label.text = "이름 입력 화면 전환에 실패했습니다."
        _update_buttons()


func _on_encyclopedia_button_pressed() -> void:
    if transition_in_progress or replacement_pending:
        return
    transition_in_progress = true
    _update_buttons()
    if get_tree().change_scene_to_file("res://scenes/encyclopedia/Encyclopedia.tscn") != OK:
        transition_in_progress = false
        message_label.text = "도감 화면 전환에 실패했습니다."
        _update_buttons()
