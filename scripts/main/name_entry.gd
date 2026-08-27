extends Control


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
    confirm_button.pressed.connect(_on_confirm_button_pressed)
    back_button.pressed.connect(_on_back_button_pressed)

    name_input.text_submitted.connect(_on_name_submitted)

    name_input.grab_focus()


func _on_confirm_button_pressed() -> void:
    validate_name()


func _on_name_submitted(_text: String) -> void:
    validate_name()


func validate_name() -> void:
    var entered_name := name_input.text.strip_edges()

    if entered_name.is_empty():
        message_label.text = "이름을 입력해주세요."
        return

    var new_game_data := GameDataFactory.create_new_game(
        entered_name
    )

    message_label.text = "새 게임 데이터 생성 완료"

    print("새 게임 데이터:")
    print(new_game_data)


func _on_back_button_pressed() -> void:
    get_tree().change_scene_to_file(
        "res://scenes/main/MainMenu.tscn"
    )