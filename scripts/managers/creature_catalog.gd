class_name CreatureCatalog
extends RefCounted

const DATA_PATH := "res://data/creatures.json"
const DEFAULT_STAGES := [
    {"id":"egg", "name":"알", "next_stage":"baby"},
    {"id":"baby", "name":"유아", "next_stage":"adult"},
    {"id":"adult", "name":"성체", "next_stage":""}
]
const FALLBACK := {"id":"001", "name":"테스트 캐릭터 001", "rarity":"test", "weight":1.0, "baby_image":"res://assets/creatures/001/creature_001_idle.png", "baby_scale":[0.2633197,0.24048276], "egg_image":"res://assets/eggs/egg_001.svg", "egg_scale":[0.7,0.7]}
var _definitions: Array = []
var _stages: Array = []
var _rng := RandomNumberGenerator.new()
var last_error := ""

func _init() -> void:
    reload()

func reload(path: String = DATA_PATH) -> bool:
    if not FileAccess.file_exists(path):
        return _reject("정의 파일 없음: " + path)
    var parser := JSON.new()
    if parser.parse(FileAccess.get_file_as_string(path)) != OK:
        return _reject("정의 JSON 문법 오류")
    return load_document(parser.data)

func _reject(reason: String) -> bool:
    last_error = reason
    _definitions = [FALLBACK.duplicate(true)]
    _stages = DEFAULT_STAGES.duplicate(true)
    push_warning("CreatureCatalog: " + reason + "; 내장 001 사용")
    return false

func _number(value: Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value))

func _image(path: Variant) -> bool:
    return path is String and path.begins_with("res://assets/") and ResourceLoader.exists(path, "Texture2D") and load(path) is Texture2D

func _scale(value: Variant) -> bool:
    return value is Array and value.size() == 2 and _number(value[0]) and _number(value[1]) and float(value[0]) > 0.0 and float(value[1]) > 0.0 and float(value[0]) <= 100.0 and float(value[1]) <= 100.0

func load_document(document: Variant) -> bool:
    if not document is Dictionary or not _number(document.get("version")) or document.version != 1 or not document.get("creatures") is Array or document.creatures.is_empty():
        return _reject("version/creatures 구조 오류")
    # Legacy version 1 catalog documents omit stages; explicit invalid values fail.
    var stages: Variant = document.get("stages", DEFAULT_STAGES)
    if not stages is Array or stages.size() != DEFAULT_STAGES.size():
        return _reject("stages 구조 오류")
    for i in range(DEFAULT_STAGES.size()):
        var stage: Variant = stages[i]
        if not stage is Dictionary or not stage.get("id") is String or not stage.get("name") is String or not stage.get("next_stage") is String:
            return _reject("stage 필드 타입 오류")
        if stage.name.strip_edges().is_empty() or stage.id != DEFAULT_STAGES[i].id or stage.next_stage != DEFAULT_STAGES[i].next_stage:
            return _reject("stage 순서/이름/전이 오류")
    var ids := {}
    var total := 0.0
    var checked: Array = []
    for entry in document.creatures:
        if not entry is Dictionary:
            return _reject("종 정의는 객체여야 함")
        var id: Variant = entry.get("id")
        if not id is String or id.length() != 3 or not id.is_valid_int() or id.to_int() < 0 or ("%03d" % id.to_int()) != id or ids.has(id):
            return _reject("ID 형식 또는 중복 오류")
        for key in ["name", "rarity"]:
            if not entry.get(key) is String or entry[key].strip_edges().is_empty():
                return _reject(key + " 값 오류")
        if not _number(entry.get("weight")) or float(entry.weight) < 0.0 or float(entry.weight) > 1000000.0:
            return _reject("weight 값 오류")
        if not _image(entry.get("baby_image")) or not _image(entry.get("egg_image")) or not _scale(entry.get("baby_scale")) or not _scale(entry.get("egg_scale")):
            return _reject("이미지 또는 scale 오류")
        ids[id] = true
        total += float(entry.weight)
        checked.append(entry.duplicate(true))
    if total <= 0.0 or not is_finite(total):
        return _reject("양수 가중치 합 필요")
    _definitions = checked
    _stages = stages.duplicate(true)
    last_error = ""
    return true

func get_definitions() -> Array:
    return _definitions.duplicate(true)

# Metadata only: these accessors never change a creature or save data.
func get_stages() -> Array:
    return _stages.duplicate(true)

func get_stage(id: String) -> Dictionary:
    for stage in _stages:
        if stage.id == id:
            return stage.duplicate(true)
    return {}

func get_next_stage(id: String) -> String:
    return str(get_stage(id).get("next_stage", ""))

func get_definition(id: String) -> Dictionary:
    for entry in _definitions:
        if entry.id == id:
            return entry.duplicate(true)
    push_warning("CreatureCatalog: 미등록 ID " + id + "; 표시만 내장 001 사용")
    return FALLBACK.duplicate(true)

func set_random_seed(value: int) -> void:
    _rng.seed = value

func choose_id() -> String:
    var total := 0.0
    for entry in _definitions:
        total += float(entry.weight)
    var roll := _rng.randf() * total
    var last_positive := "001"
    for entry in _definitions:
        if float(entry.weight) <= 0.0:
            continue
        last_positive = entry.id
        roll -= float(entry.weight)
        if roll < 0.0:
            return entry.id
    return last_positive
