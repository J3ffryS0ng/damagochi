extends Control

const MenuScript = preload("res://scripts/main/main_menu.gd")
var new_game_authorization: Dictionary = {}
var transition_in_progress := false
var new_game_saved := false


@onready var name_input: LineEdit = (
    $CenterContainer/VBoxContainer/NameInput
)

@onready var message_label: Label = (
    $CenterContainer/VBoxContainer/MessageLabel
)

@onready var confirm_button: Button = (
    $CenterContainer/VBoxContainer/ConfirmButton
)

@onready var back_button: Button = (
    $CenterContainer/VBoxContainer/BackButton
)


func _ready() -> void:
    var authorization = get_tree().get_meta(MenuScript.NEW_GAME_AUTHORIZATION, {})
    if get_tree().has_meta(MenuScript.NEW_GAME_AUTHORIZATION):
        get_tree().remove_meta(MenuScript.NEW_GAME_AUTHORIZATION)
    if authorization is Dictionary:
        new_game_authorization = authorization.duplicate(true)
    if new_game_authorization.is_empty():
        call_deferred("_on_back_button_pressed")

    confirm_button.pressed.connect(
        _on_confirm_button_pressed
    )

    back_button.pressed.connect(
        _on_back_button_pressed
    )

    name_input.text_submitted.connect(
        _on_name_submitted
    )

    name_input.grab_focus()


func _on_confirm_button_pressed() -> void:
    validate_name()


func _on_name_submitted(_text: String) -> void:
    validate_name()


func validate_name() -> void:
    if transition_in_progress:
        return
    # Retry only the scene load once the authorized save has succeeded.
    if new_game_saved:
        _enter_game()
        return
    if new_game_authorization.is_empty():
        return
    var entered_name := name_input.text.strip_edges()

    if entered_name.is_empty():
        message_label.text = "이름을 입력해주세요."
        return

    var current_save_state := MenuScript.capture_save_state()
    if current_save_state.is_empty() or current_save_state != new_game_authorization:
        message_label.text = "저장 상태가 변경되었습니다. 뒤로 돌아가 다시 새 게임을 선택해 주세요."
        return

    transition_in_progress = true
    var previous_data: Dictionary = GameManager.game_data.duplicate(true)
    GameManager.create_new_game(
        entered_name
    )

    var save_success: bool = SaveManager.save_game(
		GameManager.game_data
	)

    if not save_success:
        GameManager.game_data = previous_data
        transition_in_progress = false
        message_label.text = "게임 저장에 실패했습니다."
        return

    message_label.text = "새 게임 생성 및 저장 완료"

    print("GameManager에 저장된 데이터:")
    print(GameManager.game_data)

    new_game_authorization = {}
    new_game_saved = true
    _enter_game()


func _enter_game() -> void:
    transition_in_progress = true
    var scene_error: Error = get_tree().change_scene_to_file(
        "res://scenes/game/Game.tscn"
    )
    if scene_error != OK:
        transition_in_progress = false
        message_label.text = "게임 화면 전환에 실패했습니다."


func _on_back_button_pressed() -> void:
    if transition_in_progress:
        return
    new_game_authorization = {}
    transition_in_progress = true
    var scene_error: Error = get_tree().change_scene_to_file(
        "res://scenes/main/MainMenu.tscn"
    )
    if scene_error != OK:
        transition_in_progress = false
        message_label.text = "메뉴 화면 전환에 실패했습니다."
