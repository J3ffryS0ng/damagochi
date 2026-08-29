extends Node


const SAVE_FILE_NAME := "savegame.json"
const SAVE_PATH := "user://" + SAVE_FILE_NAME


func has_save_file() -> bool:
    return FileAccess.file_exists(SAVE_PATH)


func get_save_path() -> String:
    return SAVE_PATH


func save_game(data: Dictionary) -> bool:
    if data.is_empty():
        push_error("저장할 게임 데이터가 없습니다.")
        return false

    var save_data: Dictionary = data.duplicate(true)

    save_data["last_played_at"] = Time.get_unix_time_from_system()

    var json_text: String = JSON.stringify(
        save_data,
        "\t"
    )

    var file: FileAccess = FileAccess.open(
        SAVE_PATH,
        FileAccess.WRITE
    )

    if file == null:
        push_error(
            "세이브 파일을 열 수 없습니다. 오류 코드: %s"
            % FileAccess.get_open_error()
        )
        return false

    file.store_string(json_text)
    file.close()

    print("게임 저장 성공:", SAVE_PATH)

    return true


func load_game() -> Dictionary:
    if not has_save_file():
        print("불러올 세이브 파일이 없습니다.")
        return {}

    var file: FileAccess = FileAccess.open(
        SAVE_PATH,
        FileAccess.READ
    )

    if file == null:
        push_error(
            "세이브 파일을 읽을 수 없습니다. 오류 코드: %s"
            % FileAccess.get_open_error()
        )
        return {}

    var json_text: String = file.get_as_text()

    file.close()

    var json := JSON.new()

    var parse_result: Error = json.parse(json_text)

    if parse_result != OK:
        push_error(
            "세이브 JSON 분석 실패. Line %d: %s"
            % [
                json.get_error_line(),
                json.get_error_message()
            ]
        )

        return {}

    if not json.data is Dictionary:
        push_error(
            "세이브 데이터의 최상위 구조가 Dictionary가 아닙니다."
        )
        return {}

    var loaded_data: Dictionary = json.data

    print("게임 불러오기 성공:", SAVE_PATH)

    return loaded_data


func delete_save() -> bool:
    if not has_save_file():
        return true

    var absolute_path: String = (
        ProjectSettings.globalize_path(SAVE_PATH)
    )

    var error: Error = DirAccess.remove_absolute(
        absolute_path
    )

    if error != OK:
        push_error(
            "세이브 파일 삭제 실패. 오류 코드: %s"
            % error
        )
        return false

    print("세이브 파일 삭제 완료")

    return true


func print_save_info() -> void:
    print("세이브 파일 이름:", SAVE_FILE_NAME)
    print("세이브 경로:", SAVE_PATH)

    print(
        "실제 저장 폴더:",
        ProjectSettings.globalize_path("user://")
    )

    print(
        "세이브 파일 존재 여부:",
        has_save_file()
    )