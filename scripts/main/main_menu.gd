extends Control


@onready var start_button: Button = (
    $CenterContainer/VBoxContainer/StartButton
)

@onready var encyclopedia_button: Button = (
    $CenterContainer/VBoxContainer/EncyclopediaButton
)


func _ready() -> void:
    start_button.pressed.connect(
        _on_start_button_pressed
    )

    encyclopedia_button.pressed.connect(
        _on_encyclopedia_button_pressed
    )

    load_existing_save()


func load_existing_save() -> void:
    if GameManager.has_game_data():
        print(
            "GameManager에 이미 게임 데이터가 있습니다."
        )

        print(
            "플레이어 이름:",
            GameManager.get_player_name()
        )

        return

    if not SaveManager.has_save_file():
        print("기존 세이브 파일이 없습니다.")
        return

    var loaded_data: Dictionary = SaveManager.load_game()

    if loaded_data.is_empty():
        print("세이브 데이터를 불러오지 못했습니다.")
        return

    var load_success: bool = GameManager.load_game_data(
        loaded_data
    )

    if not load_success:
        print("GameManager 데이터 복원에 실패했습니다.")
        return

    print("기존 게임 데이터 복원 완료")

    print(
        "플레이어 이름:",
        GameManager.get_player_name()
    )


func _on_start_button_pressed() -> void:
    get_tree().change_scene_to_file(
        "res://scenes/main/NameEntry.tscn"
    )


func _on_encyclopedia_button_pressed() -> void:
    get_tree().change_scene_to_file(
        "res://scenes/encyclopedia/Encyclopedia.tscn"
    )