extends Node2D

signal feed_requested
signal play_requested
signal poop_requested

# Timer monitoring must remain active when movement disables the Game process.
class PoopTimer extends Timer:
    func _process(_delta: float) -> void:
        get_parent()._sync_poop_timer()

const HATCH_MIN_SECONDS: float = 60.0
const HATCH_REQUIRED_LEVEL: int = 2
const CREATURE_IDLE_AMPLITUDE: float = 4.0
const CREATURE_IDLE_LEG_SECONDS: float = 1.0
const CREATURE_MOVE_RADIUS: float = 120.0
const CREATURE_MOVE_SPEED: float = 60.0
const CREATURE_WAIT_MIN: float = 1.0
const CREATURE_WAIT_MAX: float = 3.0
const EAT_DIP_PIXELS: float = 6.0
const EAT_LEG_SECONDS: float = 0.2
const EAT_CYCLES: int = 3
const FOOD_FADE_SECONDS: float = 0.2
const FEED_AFFECTION: int = 1
const PLAY_JUMP_PIXELS: float = 18.0
const PLAY_LEG_SECONDS: float = 0.2
const PLAY_CYCLES: int = 3
const PLAY_AFFECTION: int = 1
const CLEAN_AFFECTION: int = 1
const CLEAN_LIFT_PIXELS: float = 6.0
const CLEAN_LEG_SECONDS: float = 0.3

const POOP_WAIT_MIN: float = 60.0
const POOP_WAIT_MAX: float = 120.0


@onready var egg_sprite: Sprite2D = (
    $PetArea/EggSprite
)

@onready var creature_sprite: Sprite2D = (
    $PetArea/CreatureSprite
)

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

@onready var hatch_flash: ColorRect = (
    $UI/HatchFlash
)

@onready var feed_button: Button = $UI/FeedPanel/FeedButton
@onready var play_button: Button = $UI/PlayPanel/PlayButton
@onready var poop_image: TextureRect = $UI/PoopImage
@onready var food_sprite: Sprite2D = $FoodSprite
@onready var feed_message: Label = $UI/FeedMessage


var current_creature: Dictionary = {}

var egg_wiggle_tween: Tween
var hatch_flash_tween: Tween
var creature_idle_tween: Tween
var creature_idle_base_position: Vector2
var creature_movement_active: bool = false
var creature_move_target_x: float = 0.0
var creature_wait_remaining: float = 0.0
var creature_movement_rng := RandomNumberGenerator.new()

var hatch_effect_played: bool = false
var hatch_in_progress: bool = false
var feeding_busy: bool = false
var feeding_tween: Tween
var feeding_target: Dictionary = {}
var feeding_generation: int = 0
var playing_busy: bool = false
var playing_tween: Tween
var playing_target: Dictionary = {}
var playing_generation: int = 0
var playing_start_x: float = 0.0
var play_message_active: bool = false
var cleaning_busy: bool = false
var cleaning_tween: Tween
var cleaning_target: Dictionary = {}
var cleaning_generation: int = 0
var cleaning_start_x: float = 0.0
var clean_message_active: bool = false
var poop_present: bool = false
var poop_timer: Timer
var poop_target: Dictionary = {}
var poop_rng := RandomNumberGenerator.new()


func _ready() -> void:
    creature_idle_base_position = creature_sprite.position
    set_process(false)
    poop_timer = PoopTimer.new()
    poop_timer.name = "PoopTimer"
    poop_timer.one_shot = true
    poop_timer.process_priority = -10
    poop_timer.timeout.connect(_on_poop_timeout)
    add_child(poop_timer)
    feed_button.pressed.connect(_on_feed_button_pressed)
    play_button.pressed.connect(_on_play_button_pressed)
    feed_requested.connect(_show_food)
    play_requested.connect(_start_playing)
    poop_requested.connect(_show_poop)

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
        stop_creature_idle()
        stop_creature_movement()
        _update_feed_button()
        push_error("현재 활성 캐릭터 데이터가 없습니다.")
        return

    update_status_ui()
    update_creature_visual()

    if is_egg_stage():
        print_hatch_status()
        check_hatch_effect()


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


func update_creature_visual() -> void:
    if not current_creature.is_empty():
        var definition: Dictionary = GameManager.creature_catalog.get_definition(str(current_creature.get("creature_id", "")))
        creature_sprite.texture = load(definition.baby_image)
        creature_sprite.scale = Vector2(definition.baby_scale[0], definition.baby_scale[1])
        egg_sprite.texture = load(definition.egg_image)
        egg_sprite.scale = Vector2(definition.egg_scale[0], definition.egg_scale[1])
    _update_feed_button()
    if current_creature.is_empty():
        stop_creature_idle()
        stop_creature_movement()
        return

    var stage: String = str(
        current_creature.get(
            "stage",
            "egg"
        )
    )

    if stage == "egg":
        stop_creature_idle()
        stop_creature_movement()
        egg_sprite.visible = true
        creature_sprite.visible = false
        egg_touch_area.input_pickable = true

        start_egg_wiggle()
        return

    egg_sprite.visible = false
    creature_sprite.visible = true
    egg_touch_area.input_pickable = false

    stop_egg_wiggle()

    if stage == "baby":
        start_creature_idle()
        start_creature_movement()
    else:
        stop_creature_idle()
        stop_creature_movement()


func _is_feed_eligible() -> bool:
    return (
        not current_creature.is_empty()
        and is_same(current_creature, GameManager.get_active_creature())
        and str(current_creature.get("stage", "egg")) == "baby"
        and not hatch_in_progress
        and not (hatch_flash_tween != null and hatch_flash_tween.is_running())
    )


func _update_feed_button() -> void:
    if not _is_feed_eligible() or (feeding_busy and not _feeding_target_matches()):
        _cancel_feeding()
    if not _is_feed_eligible() or (playing_busy and not _playing_target_matches()):
        _cancel_playing()
    if not _is_feed_eligible() or (cleaning_busy and not _cleaning_target_matches()):
        _cancel_cleaning()
    feed_button.disabled = not _can_request_feed()
    play_button.disabled = not _can_request_play()
    _sync_poop_timer()


func _next_poop_interval() -> float:
    return poop_rng.randf_range(POOP_WAIT_MIN, POOP_WAIT_MAX)


func _sync_poop_timer() -> void:
    if poop_timer == null:
        return
    if not _is_feed_eligible():
        poop_timer.stop()
        poop_timer.paused = false
        poop_target = {}
        _clear_poop()
        return
    if not is_same(poop_target, current_creature):
        _clear_poop()
        poop_target = current_creature
        poop_timer.start(_next_poop_interval())
    poop_timer.paused = feeding_busy or playing_busy or cleaning_busy or poop_present


func _on_poop_timeout() -> void:
    # Rearm before dispatch so duplicate callbacks cannot emit twice.
    if poop_timer.time_left > 0.0:
        return
    if not _is_feed_eligible() or not is_same(poop_target, current_creature):
        _sync_poop_timer()
        return
    if feeding_busy or playing_busy or cleaning_busy:
        return
    poop_timer.start(_next_poop_interval())
    poop_requested.emit()


func _can_request_play() -> bool:
    return _is_feed_eligible() and not feeding_busy and not playing_busy and not cleaning_busy


func _on_play_button_pressed() -> void:
    if _can_request_play():
        play_requested.emit()


func _can_request_feed() -> bool:
    return _is_feed_eligible() and not feeding_busy and not playing_busy and not cleaning_busy


func _start_playing() -> void:
    if not _can_request_play():
        return
    if play_message_active:
        feed_message.hide()
        play_message_active = false
    playing_busy = true
    playing_generation += 1
    playing_target = current_creature
    playing_start_x = creature_sprite.position.x
    creature_movement_active = false
    creature_wait_remaining = 0.0
    stop_creature_idle()
    set_process(true)
    _update_feed_button()
    playing_tween = create_tween()
    playing_tween.set_trans(Tween.TRANS_SINE)
    playing_tween.set_ease(Tween.EASE_IN_OUT)
    for cycle in range(PLAY_CYCLES):
        playing_tween.tween_property(creature_sprite, "position:y", creature_idle_base_position.y - PLAY_JUMP_PIXELS, PLAY_LEG_SECONDS)
        playing_tween.tween_property(creature_sprite, "position:y", creature_idle_base_position.y, PLAY_LEG_SECONDS)
    playing_tween.finished.connect(_finish_playing.bind(playing_generation))


func _playing_target_matches() -> bool:
    return (not playing_target.is_empty()
        and is_same(playing_target, current_creature)
        and is_same(playing_target, GameManager.get_active_creature()))


func _finish_playing(generation: int) -> void:
    if not playing_busy or generation != playing_generation:
        return
    # Completion is accepted only after all tween steps, never an early callback.
    if playing_tween == null or playing_tween.get_total_elapsed_time() + 0.000001 < PLAY_LEG_SECONDS * 2 * PLAY_CYCLES:
        return
    if not _is_feed_eligible() or not _playing_target_matches():
        _cancel_playing()
        _update_feed_button()
        return
    var target: Dictionary = playing_target
    playing_tween = null
    playing_target = {}
    playing_busy = false
    _award_play_affection(target)
    creature_sprite.position = Vector2(playing_start_x, creature_idle_base_position.y)
    _update_feed_button()
    start_creature_idle()
    start_creature_movement()


func _cancel_playing() -> void:
    playing_generation += 1
    playing_target = {}
    if playing_tween != null and playing_tween.is_valid():
        playing_tween.kill()
    playing_tween = null
    if playing_busy:
        stop_creature_idle()
        stop_creature_movement()
    playing_busy = false


func _apply_play_affection() -> bool:
    return GameManager.add_affection(0, PLAY_AFFECTION)


func _save_play_progress() -> bool:
    return SaveManager.save_game(GameManager.game_data)


func _award_play_affection(target: Dictionary) -> void:
    if not _feed_values_valid(target):
        feed_message.text = "놀이 친밀도를 반영하지 못했습니다.\n캐릭터 상태를 확인해 주세요."
        clean_message_active = false
        play_message_active = true
        feed_message.show()
        return
    var before: Dictionary = {}
    for field in ["affection", "level", "affection_to_next_level"]:
        before[field] = target[field]
    var added: bool = _apply_play_affection()
    var saved: bool = added and _save_play_progress()
    if not saved:
        for field in before:
            target[field] = before[field]
        feed_message.text = "놀이 친밀도를 저장하지 못해 반영하지 않았습니다.\n다시 놀아줄 수 있습니다."
        clean_message_active = false
        play_message_active = true
        feed_message.show()
    update_status_ui()


func _on_feed_button_pressed() -> void:
    if not _can_request_feed():
        return
    feed_requested.emit()


func _show_food() -> void:
    if not _can_request_feed():
        return
    feeding_busy = true
    feeding_generation += 1
    feeding_target = current_creature
    play_message_active = false
    clean_message_active = false
    feed_message.hide()
    # Pause x without stop_creature_movement's reset, preserving the entry position.
    creature_movement_active = false
    creature_wait_remaining = 0.0
    set_process(true)
    food_sprite.modulate.a = 1.0
    food_sprite.show()
    _update_feed_button()
    feeding_tween = create_tween()
    var center_x: float = creature_idle_base_position.x
    var travel_seconds: float = absf(creature_sprite.position.x - center_x) / CREATURE_MOVE_SPEED
    if travel_seconds > 0.0:
        feeding_tween.tween_property(creature_sprite, "position:x", center_x, travel_seconds)
    feeding_tween.tween_callback(_begin_eating)
    for cycle in range(EAT_CYCLES):
        feeding_tween.tween_property(creature_sprite, "position:y", creature_idle_base_position.y + EAT_DIP_PIXELS, EAT_LEG_SECONDS)
        feeding_tween.tween_property(creature_sprite, "position:y", creature_idle_base_position.y, EAT_LEG_SECONDS)
    feeding_tween.tween_property(food_sprite, "modulate:a", 0.0, FOOD_FADE_SECONDS)
    feeding_tween.tween_callback(_finish_feeding.bind(feeding_generation))


func _begin_eating() -> void:
    stop_creature_idle()


func _finish_feeding(generation: int = -1) -> void:
    # Only the current completed sequence can consume its reward once.
    if not feeding_busy or generation != feeding_generation:
        return
    if not _is_feed_eligible() or not _feeding_target_matches():
        _cancel_feeding()
        _update_feed_button()
        return
    if food_sprite.modulate.a > 0.0001:
        return
    var target: Dictionary = feeding_target
    feeding_target = {}
    feeding_tween = null
    feeding_busy = false
    _award_feed_affection(target)
    food_sprite.hide()
    food_sprite.modulate.a = 1.0
    creature_sprite.position.y = creature_idle_base_position.y
    _update_feed_button()
    if _is_feed_eligible():
        start_creature_idle()
        start_creature_movement()


func _feeding_target_matches() -> bool:
    return (not feeding_target.is_empty()
        and is_same(feeding_target, current_creature)
        and is_same(feeding_target, GameManager.get_active_creature()))


func _feed_values_valid(target: Dictionary) -> bool:
    for field in ["level", "affection", "affection_to_next_level"]:
        var value: Variant = target.get(field)
        if not (value is int or value is float):
            return false
        # Keep conversions and level-up arithmetic in an exactly representable range.
        if not is_finite(float(value)) or absf(float(value)) >= 1.0e15 or floor(float(value)) != float(value):
            return false
        if value < (0 if field == "affection" else 1):
            return false
    return true


func _apply_feed_affection() -> bool:
    return GameManager.add_affection(0, FEED_AFFECTION)


func _save_feed_progress() -> bool:
    return SaveManager.save_game(GameManager.game_data)


func _award_feed_affection(target: Dictionary) -> void:
    if not _feed_values_valid(target):
        feed_message.text = "친밀도를 반영하지 못했습니다.\n캐릭터 상태를 확인해 주세요."
        feed_message.show()
        return
    var before: Dictionary = {}
    for field in ["affection", "level", "affection_to_next_level"]:
        before[field] = target[field]
    var added: bool = _apply_feed_affection()
    var saved: bool = added and _save_feed_progress()
    if not saved:
        for field in before:
            target[field] = before[field]
        feed_message.text = "친밀도를 저장하지 못해 반영하지 않았습니다.\n다시 밥을 줄 수 있습니다."
        feed_message.show()
    update_status_ui()


func _cancel_feeding() -> void:
    feeding_generation += 1
    feeding_target = {}
    if feeding_tween != null and feeding_tween.is_valid():
        feeding_tween.kill()
    feeding_tween = null
    if feeding_busy:
        stop_creature_idle()
        stop_creature_movement()
    feeding_busy = false
    if is_instance_valid(food_sprite):
        food_sprite.hide()
        food_sprite.modulate.a = 1.0


func start_creature_idle() -> void:
    if feeding_busy or playing_busy or cleaning_busy:
        return
    if current_creature.is_empty():
        return
    if str(current_creature.get("stage", "egg")) != "baby":
        return
    if not creature_sprite.visible or creature_sprite.texture == null:
        return
    if creature_idle_tween != null and creature_idle_tween.is_valid():
        if creature_idle_tween.is_running():
            return

    stop_creature_idle()
    creature_idle_tween = create_tween()
    creature_idle_tween.set_loops()
    creature_idle_tween.set_trans(Tween.TRANS_SINE)
    creature_idle_tween.set_ease(Tween.EASE_IN_OUT)
    creature_idle_tween.tween_property(
        creature_sprite,
        "position:y",
        creature_idle_base_position.y - CREATURE_IDLE_AMPLITUDE,
        CREATURE_IDLE_LEG_SECONDS
    )
    creature_idle_tween.tween_property(
        creature_sprite,
        "position:y",
        creature_idle_base_position.y,
        CREATURE_IDLE_LEG_SECONDS
    )


func stop_creature_idle() -> void:
    if creature_idle_tween != null and creature_idle_tween.is_valid():
        creature_idle_tween.kill()
    creature_idle_tween = null
    if is_instance_valid(creature_sprite):
        creature_sprite.position.y = creature_idle_base_position.y


func start_creature_movement() -> void:
    if feeding_busy or playing_busy or cleaning_busy:
        return
    if current_creature.is_empty() or str(current_creature.get("stage", "egg")) != "baby":
        return
    if not creature_sprite.visible or creature_sprite.texture == null:
        return
    if creature_movement_active:
        return
    creature_movement_active = true
    creature_wait_remaining = 0.0
    _choose_creature_destination()
    set_process(true)


func _choose_creature_destination() -> void:
    creature_move_target_x = creature_movement_rng.randf_range(
        creature_idle_base_position.x - CREATURE_MOVE_RADIUS,
        creature_idle_base_position.x + CREATURE_MOVE_RADIUS
    )


func _process(delta: float) -> void:
    if cleaning_busy:
        if not _is_feed_eligible() or not _cleaning_target_matches():
            _update_feed_button()
        return
    if playing_busy:
        if not _is_feed_eligible() or not _playing_target_matches():
            _update_feed_button()
        return
    if feeding_busy:
        if not _is_feed_eligible() or not _feeding_target_matches():
            _update_feed_button()
        return
    if not creature_movement_active:
        return
    if (current_creature.is_empty()
        or str(current_creature.get("stage", "egg")) != "baby"
        or not creature_sprite.visible or creature_sprite.texture == null):
        stop_creature_movement()
        return
    if creature_wait_remaining > 0.0:
        creature_wait_remaining = maxf(0.0, creature_wait_remaining - delta)
        if creature_wait_remaining == 0.0:
            _choose_creature_destination()
        return
    # Movement owns x only; the existing Idle Tween owns y.
    creature_sprite.position.x = move_toward(
        creature_sprite.position.x, creature_move_target_x, CREATURE_MOVE_SPEED * delta
    )
    if creature_sprite.position.x == creature_move_target_x:
        creature_wait_remaining = creature_movement_rng.randf_range(
            CREATURE_WAIT_MIN, CREATURE_WAIT_MAX
        )


func stop_creature_movement() -> void:
    creature_movement_active = false
    creature_wait_remaining = 0.0
    creature_move_target_x = creature_idle_base_position.x
    set_process(false)
    if is_instance_valid(creature_sprite):
        creature_sprite.position.x = creature_idle_base_position.x


func _exit_tree() -> void:
    _clear_poop()
    _cancel_cleaning()
    if poop_timer != null:
        poop_timer.stop()
    poop_target = {}
    _cancel_playing()
    _cancel_feeding()
    stop_creature_idle()
    stop_creature_movement()


func is_egg_stage() -> bool:
    if current_creature.is_empty():
        return false

    var stage: String = str(
        current_creature.get(
            "stage",
            "egg"
        )
    )

    return stage == "egg"


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
    if not is_egg_stage():
        return false

    var elapsed_seconds: float = (
        get_egg_elapsed_seconds()
    )

    return elapsed_seconds >= HATCH_MIN_SECONDS


func is_hatch_level_ready() -> bool:
    if not is_egg_stage():
        return false

    var level: int = int(
        current_creature.get(
            "level",
            1
        )
    )

    return level >= HATCH_REQUIRED_LEVEL


func can_hatch() -> bool:
    if not is_egg_stage():
        return false

    return (
        is_hatch_time_ready()
        and is_hatch_level_ready()
    )


func print_hatch_status() -> void:
    if not is_egg_stage():
        return

    var elapsed_seconds: float = (
        get_egg_elapsed_seconds()
    )

    var remaining_seconds: float = max(
        0.0,
        HATCH_MIN_SECONDS - elapsed_seconds
    )

    var level: int = int(
        current_creature.get(
            "level",
            1
        )
    )

    print(
        "알 생성 후 경과 시간: %.1f초"
        % elapsed_seconds
    )

    if is_hatch_time_ready():
        print("시간 조건 충족")
    else:
        print(
            "부화 최소 시간까지 %.1f초 남음"
            % remaining_seconds
        )

    print(
        "현재 레벨: %d / 필요 레벨: %d"
        % [
            level,
            HATCH_REQUIRED_LEVEL
        ]
    )

    if is_hatch_level_ready():
        print("레벨 조건 충족")
    else:
        print("레벨 조건 미충족")

    if can_hatch():
        print("최종 판정: 부화 가능")
    else:
        print("최종 판정: 아직 부화 불가")


func start_egg_wiggle() -> void:
    if not is_egg_stage():
        return

    if hatch_in_progress:
        return

    if egg_wiggle_tween != null:
        egg_wiggle_tween.kill()

    egg_sprite.rotation = 0.0

    egg_wiggle_tween = create_tween()
    egg_wiggle_tween.set_loops()

    egg_wiggle_tween.tween_property(
        egg_sprite,
        "rotation",
        deg_to_rad(-8.0),
        0.35
    ).set_trans(
        Tween.TRANS_SINE
    ).set_ease(
        Tween.EASE_IN_OUT
    )

    egg_wiggle_tween.tween_property(
        egg_sprite,
        "rotation",
        deg_to_rad(8.0),
        0.7
    ).set_trans(
        Tween.TRANS_SINE
    ).set_ease(
        Tween.EASE_IN_OUT
    )

    egg_wiggle_tween.tween_property(
        egg_sprite,
        "rotation",
        0.0,
        0.35
    ).set_trans(
        Tween.TRANS_SINE
    ).set_ease(
        Tween.EASE_IN_OUT
    )


func stop_egg_wiggle() -> void:
    if egg_wiggle_tween != null:
        egg_wiggle_tween.kill()
        egg_wiggle_tween = null

    egg_sprite.rotation = 0.0


func check_hatch_effect() -> void:
    if hatch_effect_played:
        return

    if hatch_in_progress:
        return

    if not can_hatch():
        return

    play_hatch_flash()


func play_hatch_flash() -> void:
    if hatch_effect_played:
        return

    hatch_effect_played = true
    hatch_in_progress = true
    _update_feed_button()

    stop_egg_wiggle()

    egg_touch_area.input_pickable = false

    if hatch_flash_tween != null:
        hatch_flash_tween.kill()

    hatch_flash.color.a = 0.0

    hatch_flash_tween = create_tween()
    hatch_flash_tween.finished.connect(_update_feed_button)

    hatch_flash_tween.tween_property(
        hatch_flash,
        "color:a",
        0.9,
        0.25
    ).set_trans(
        Tween.TRANS_SINE
    ).set_ease(
        Tween.EASE_OUT
    )

    hatch_flash_tween.tween_interval(
        0.15
    )

    hatch_flash_tween.tween_callback(
        Callable(
            self,
            "_finish_hatch"
        )
    )

    hatch_flash_tween.tween_property(
        hatch_flash,
        "color:a",
        0.0,
        0.45
    ).set_trans(
        Tween.TRANS_SINE
    ).set_ease(
        Tween.EASE_IN
    )


func _finish_hatch() -> void:
    var hatch_success: bool = GameManager.hatch_creature(
        0
    )

    if not hatch_success:
        push_error("캐릭터 부화 처리에 실패했습니다.")
        hatch_in_progress = false
        return

    var save_success: bool = SaveManager.save_game(
        GameManager.game_data
    )

    if not save_success:
        push_error("부화 상태 저장에 실패했습니다.")

    current_creature = GameManager.get_active_creature()

    update_status_ui()
    update_creature_visual()

    hatch_in_progress = false

    print("부화 완료")


func _on_egg_touch_area_input_event(
    _viewport: Node,
    event: InputEvent,
    _shape_idx: int
) -> void:
    if hatch_in_progress:
        return

    if not is_egg_stage():
        return

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
    if not is_egg_stage():
        return

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


func _show_poop() -> void:
    if not _is_feed_eligible() or not is_same(poop_target, current_creature):
        return
    if poop_present or feeding_busy or playing_busy or cleaning_busy:
        return
    poop_present = true
    poop_image.show()
    _sync_poop_timer()


func _clear_poop() -> void:
    poop_present = false
    if is_instance_valid(poop_image):
        poop_image.hide()


func _input(event: InputEvent) -> void:
    if not poop_present or not _can_request_feed():
        return
    var pressed := false
    var point := Vector2.ZERO
    if event is InputEventMouseButton:
        pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
        point = event.position
    elif event is InputEventScreenTouch:
        pressed = event.pressed and not event.canceled
        point = event.position
    if pressed and poop_image.get_global_rect().has_point(point):
        get_viewport().set_input_as_handled()
        _clean_poop()


func _clean_poop() -> void:
    if not poop_present or not _can_request_feed() or not is_same(poop_target, current_creature):
        return
    # Consume input before the synchronous reward/save transaction.
    cleaning_busy = true
    if not _award_clean_affection(current_creature):
        cleaning_busy = false
        _update_feed_button()
        return
    if clean_message_active:
        feed_message.hide()
        clean_message_active = false
    _clear_poop()
    poop_timer.start(_next_poop_interval())
    cleaning_target = current_creature
    cleaning_generation += 1
    cleaning_start_x = creature_sprite.position.x
    creature_movement_active = false
    creature_wait_remaining = 0.0
    stop_creature_idle()
    set_process(true)
    _update_feed_button()
    cleaning_tween = create_tween()
    cleaning_tween.set_trans(Tween.TRANS_SINE)
    cleaning_tween.set_ease(Tween.EASE_IN_OUT)
    cleaning_tween.tween_property(creature_sprite, "position:y", creature_idle_base_position.y - CLEAN_LIFT_PIXELS, CLEAN_LEG_SECONDS)
    cleaning_tween.tween_property(creature_sprite, "position:y", creature_idle_base_position.y, CLEAN_LEG_SECONDS)
    cleaning_tween.finished.connect(_finish_cleaning.bind(cleaning_generation))


func _apply_clean_affection() -> bool:
    return GameManager.add_affection(0, CLEAN_AFFECTION)


func _save_clean_progress() -> bool:
    return SaveManager.save_game(GameManager.game_data)


func _award_clean_affection(target: Dictionary) -> bool:
    if not _feed_values_valid(target):
        feed_message.text = "청소 친밀도를 반영하지 못했습니다.\n캐릭터 상태를 확인한 뒤 다시 청소해 주세요."
        play_message_active = false
        clean_message_active = true
        feed_message.show()
        return false
    var before: Dictionary = {}
    for field in ["affection", "level", "affection_to_next_level"]:
        before[field] = target[field]
    var added: bool = _apply_clean_affection()
    var saved: bool = added and _save_clean_progress()
    if not saved:
        for field in before:
            target[field] = before[field]
        feed_message.text = "청소 친밀도를 저장하지 못해 반영하지 않았습니다.\n응가를 눌러 다시 청소할 수 있습니다."
        play_message_active = false
        clean_message_active = true
        feed_message.show()
    update_status_ui()
    return saved


func _cleaning_target_matches() -> bool:
    return (not cleaning_target.is_empty()
        and is_same(cleaning_target, current_creature)
        and is_same(cleaning_target, GameManager.get_active_creature()))


func _finish_cleaning(generation: int) -> void:
    if not cleaning_busy or generation != cleaning_generation:
        return
    if cleaning_tween == null or cleaning_tween.get_total_elapsed_time() + 0.000001 < CLEAN_LEG_SECONDS * 2:
        return
    if not _is_feed_eligible() or not _cleaning_target_matches():
        _cancel_cleaning()
        _update_feed_button()
        return
    cleaning_tween = null
    cleaning_target = {}
    cleaning_busy = false
    creature_sprite.position = Vector2(cleaning_start_x, creature_idle_base_position.y)
    _update_feed_button()
    start_creature_idle()
    start_creature_movement()


func _cancel_cleaning() -> void:
    cleaning_generation += 1
    cleaning_target = {}
    if cleaning_tween != null and cleaning_tween.is_valid():
        cleaning_tween.kill()
    cleaning_tween = null
    if cleaning_busy:
        stop_creature_idle()
        stop_creature_movement()
    cleaning_busy = false


