extends Control


@onready var start_button: Button = (
    $CenterContainer/VBoxContainer/StartButton
)

@onready var encyclopedia_button: Button = (
    $CenterContainer/VBoxContainer/EncyclopediaButton
)


func _ready() -> void:
    start_button.pressed.connect(_on_start_button_pressed)
    encyclopedia_button.pressed.connect(_on_encyclopedia_button_pressed)


func _on_start_button_pressed() -> void:
    get_tree().change_scene_to_file(
        "res://scenes/main/NameEntry.tscn"
    )


func _on_encyclopedia_button_pressed() -> void:
    get_tree().change_scene_to_file(
        "res://scenes/encyclopedia/Encyclopedia.tscn"
    )