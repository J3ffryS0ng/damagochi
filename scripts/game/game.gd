extends Node2D


@onready var egg_touch_area: Area2D = (
    $PetArea/EggTouchArea
)


var current_creature: Dictionary = {}


func _ready() -> void:
    print("=== Game _ready 시작 ===")

    egg_touch_area.input_event.connect(
        _on_egg_touch_area_input_event
    )

    restore_game_data_if_needed()

    load_current_creature()

    print("=== Game _ready 종료 ===")


func restore_game_data_if_needed() -> void:
    if GameManager.has_game_data():
        print("GameManager 데이터가 이미 있습니다.")
        return

    if not SaveManager.has_save_file():
        print("Game Scene에서 불러올 세이브가 없습니다.")
        return

    var loaded_data: Dictionary = SaveManager.load_game()

    if loaded_data.is_empty():
        print("Game Scene 세이브 불러오기 실패")
        return

    var load_success: bool = GameManager.load_game_data(
        loaded_data
    )

    if not load_success:
        print("GameManager 데이터 복원 실패")
        return

    print("Game Scene에서 기존 세이브 복원 완료")


func load_current_creature() -> void:
    print("load_current_creature() 호출됨")

    print(
        "GameManager 데이터 전체:",
        GameManager.game_data
    )

    print(
        "활성 캐릭터 존재 여부:",
        GameManager.has_active_creature()
    )

    current_creature = GameManager.get_active_creature()

    if current_creature.is_empty():
        print("현재 활성 캐릭터 데이터가 없습니다.")
        return

    print(
        "현재 캐릭터 데이터:",
        current_creature
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

    print(
        "현재 친밀도:",
        affection
    )

    print(
        "다음 레벨까지 필요한 친밀도:",
        affection_to_next_level
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
    print("알을 터치했습니다.")