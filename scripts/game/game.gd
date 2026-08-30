extends Node2D


@onready var egg_touch_area: Area2D = (
    $PetArea/EggTouchArea
)


func _ready() -> void:
    egg_touch_area.input_event.connect(
        _on_egg_touch_area_input_event
    )


func _on_egg_touch_area_input_event(
    _viewport: Node,
    event: InputEvent,
    _shape_idx: int
) -> void:
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _handle_egg_touch()
            return

    if event is InputEventScreenTouch:
        if event.pressed:
            _handle_egg_touch()


func _handle_egg_touch() -> void:
    print("알을 터치했습니다.")