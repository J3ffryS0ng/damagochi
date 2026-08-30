extends Node2D


@onready var egg_touch_area: Area2D = (
    $PetArea/EggTouchArea
)

@onready var name_label: Label = (
    $UI/TopPanel/StatusContainer/NameLabel
)

@onready var level_label: Label = (
    $UI/TopPanel/StatusContainer/LevelLabel
)

@onready var affection_label: Label = (
    $UI/TopPanel/StatusContainer/AffectionLabel
)

@onready var affection_bar: ProgressBar = (
    $UI/TopPanel/StatusContainer/AffectionBar
)


var current_creature: Dictionary = {}


func _ready() -> void:
    egg_touch_area.input_event.connect(
        _on_egg_touch_area_input_event
    )

    restore_game_data_if_needed()
    load_current_creature()


func restore_game_data_if_needed() -> void:
    if GameManager.has_game_data():
        return

    if not SaveManager.has_save_file():
        return

    var loaded_data: Dictionary = SaveManager.load_game()

    if loaded_data.is_empty():
        return

    GameManager.load_game_data(
        loaded_data
    )


func load_current_creature() -> void:
    current_creature = GameManager.get_active_creature()

    if current_creature.is_empty():
        push_error("현재 활성 캐릭터 데이터가 없습니다.")
        return

    update_status_ui()


func update_status_ui() -> void:
    if current_creature.is_empty():
        return

    var player_name: String = GameManager.get_player_name()

    var level: int = int(
        current_creature.get(
            "level",
            1
        )
    )

    var affection: int = int(
        current_creature.get(
            "affection",
            0
        )
    )

    var affection_to_next_level: int = int(
        current_creature.get(
            "affection_to_next_level",
            10
        )
    )

    name_label.text = "이름: " + player_name
    level_label.text = "LV. %d" % level

    affection_label.text = "친밀도 %d / %d" % [
        affection,
        affection_to_next_level
    ]

    affection_bar.min_value = 0
    affection_bar.max_value = affection_to_next_level
    affection_bar.value = affection


func _on_egg_touch_area_input_event(
    _viewport: Node,
    event: InputEvent,
    _shape_idx: int
) -> void:
    if event is InputEventMouseButton:
        if (
            event.pressed
            and event.button_index == MOUSE_BUTTON_LEFT
        ):
            _handle_egg_touch()
            return

    if event is InputEventScreenTouch:
        if event.pressed:
            _handle_egg_touch()


func _handle_egg_touch() -> void:
    print("알을 터치했습니다.")