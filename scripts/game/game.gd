extends Node2D


const HATCH_MIN_SECONDS: float = 60.0


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
    print_hatch_time_status()


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


func get_egg_elapsed_seconds() -> float:
    if current_creature.is_empty():
        return 0.0

    var egg_created_at: float = float(
        current_creature.get(
            "egg_created_at",
            0.0
        )
    )

    if egg_created_at <= 0.0:
        return 0.0

    var current_time: float = (
        Time.get_unix_time_from_system()
    )

    return max(
        0.0,
        current_time - egg_created_at
    )


func is_hatch_time_ready() -> bool:
    if current_creature.is_empty():
        return false

    var elapsed_seconds: float = (
        get_egg_elapsed_seconds()
    )

    return elapsed_seconds >= HATCH_MIN_SECONDS


func print_hatch_time_status() -> void:
    if current_creature.is_empty():
        return

    var elapsed_seconds: float = (
        get_egg_elapsed_seconds()
    )

    var remaining_seconds: float = max(
        0.0,
        HATCH_MIN_SECONDS - elapsed_seconds
    )

    print(
        "알 생성 후 경과 시간: %.1f초"
        % elapsed_seconds
    )

    if is_hatch_time_ready():
        print("부화 최소 시간 조건 충족")
    else:
        print(
            "부화까지 최소 %.1f초 남음"
            % remaining_seconds
        )


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
    var affection_added: bool = GameManager.add_affection(
        0,
        1
    )

    if not affection_added:
        push_error("친밀도 증가에 실패했습니다.")
        return

    var save_success: bool = SaveManager.save_game(
        GameManager.game_data
    )

    if not save_success:
        push_error("친밀도 저장에 실패했습니다.")
        return

    load_current_creature()