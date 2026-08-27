extends Node


const SAVE_FILE_NAME := "savegame.json"
const SAVE_PATH := "user://" + SAVE_FILE_NAME


func has_save_file() -> bool:
    return FileAccess.file_exists(SAVE_PATH)


func get_save_path() -> String:
    return SAVE_PATH


func print_save_info() -> void:
    print("세이브 파일 이름:", SAVE_FILE_NAME)
    print("세이브 경로:", SAVE_PATH)
    print("세이브 파일 존재 여부:", has_save_file())