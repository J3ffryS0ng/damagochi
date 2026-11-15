# STEP 22 이어하기 독립 QA 결과

검증일: 2026-09-28 · 작업: S22-DEV-002 · 대상: 현재 미커밋 프로젝트 코드

## [QA 최종 판정]

**PASS WITH ISSUE**

S22-DEV-002의 RC01~RC14는 아래에 명시한 엔진 실행 범위에서 모두 PASS다. 기존 STEP 22의 **AC5를 FAIL/BLOCKER → PASS로 재판정**한다. 기본 MainMenu를 통한 별도 프로세스 egg/baby 이어하기, baby Idle, 새 게임 사전 확인, 취소·실패 시 저장 보존이 확인됐다. AC1~AC4 회귀는 발견하지 못했다.

이번 구현의 신규 제품 결함과 새 정책 결정 사항은 발견하지 못했다. PASS WITH ISSUE는 실기기 터치·전체 플레이의 실제 입력 검증 공백과 기존 저장의 비원자적 쓰기 한계를 명시한 판정이며, AC5가 여전히 차단됐다는 뜻은 아니다. STEP 전체 완료 상태 확정은 WORK-MANAGER에 남긴다.

## [검증 범위와 환경]

먼저 docs/tasks/STEP_22_RESUME.md의 S22-DEV-002/R1~R5/RC01~14, 최신 STEP_22_RESUME_DEV_REPORT.md, 기존 STEP_22_DEV_REPORT.md·STEP_22_QA_REPORT.md 및 DECISION_LOG.md M-005를 확인했다. 실제 main_menu.gd, name_entry.gd, MainMenu.tscn과 회귀 테스트 코드를 읽고 대조했다. 기존 보고서의 PASS를 실행 증거로 대체하지 않고 새 사본에서 재실행했다.

| 항목 | 독립 확인 결과 |
|---|---|
| 엔진 | C:/Godot/Godot_console.exe, `--version`: 4.7.2.stable.official.ed1daf0bf |
| 호환성 | 깨끗한 사본 import와 기본 시작, headless/실제 렌더 실행 성공 |
| 렌더 | OpenGL 3.3 Compatibility / Intel Iris Xe / 드라이버 32.0.101.5542 |
| 해상도 | 논리 720×1280 / 기본 게임 영역 405×720 |
| QA 실행 사본 | C:/Users/syj_1/AppData/Local/Temp/damagochi-step22-resume-a6d21c11c0534ffda45eb4fc90f4e847/ |
| 엔진이 해석한 테스트 user:// | C:/Users/syj_1/AppData/Roaming/damagochi-step22-resume-a6d21c11c0534ffda45eb4fc90f4e847/ |
| 원본 user:// | C:/Users/syj_1/AppData/Roaming/Godot/app_userdata/damagochi/ |

사본의 custom user directory만 변경했다. 원본 저장·설정·제품 코드는 수정하지 않았다. 원본 저장의 실행 전후 SHA256은 `E5F0C0FE37F6F110FEF2E3FDCC3DB12A73F8BB765A76E10DB0EE02E1E232037D`로 동일하다. 원본 해시 검사는 읽기만 수행했다.

현재 제품 코드와 실행 사본은 [copy_comparison.json](step_22_resume_qa/copy_comparison.json)에서 일치를 확인했다. game.gd, Game.tscn, 세 manager 코드, 001 PNG는 **2026-09-13 독립 QA 당시 해시와 동일**하다: [이전 QA 비교](step_22_resume_qa/legacy_comparison.json). 이번 QA 전후 제품 코드·MASTER·STEP_PLAN·공통 운영 템플릿의 해시도 동일하다: [검사 전](step_22_resume_qa/source_before.json), [검사 후](step_22_resume_qa/source_after.json).

### 실행 방법과 증거 디렉터리

1. 프로젝트 루트에서 `./tests/step_22/run_resume.ps1`를 새로 실행했다. 별도 사본 생성, import, 후속 검사, 별도 프로세스 복원, 읽기/쓰기 잠금, 장면 전환 실패, 기존 회귀, 기본 시작까지 래퍼 종료 코드 0.
2. QA가 별도로 작성한 `tests/step_22/resume_qa_verify.gd`를 사본에 복사하고 `C:/Godot/Godot_console.exe --headless --path <사본> --script res://resume_qa_verify.gd --log-file <로그>`로 실행했다. 수정된 최종 QA harness 종료 코드 0.
3. 테스트 스크립트 없이 `C:/Godot/Godot_console.exe --path <사본> --log-file <로그>`로 실제 게임 창을 열고 Windows Computer Use의 마우스·키보드 입력으로 UI를 검사했다. 두 번째 조작 세션은 X로 게임을 종료했고 종료 코드 0.

DEV 테스트의 **QA 재실행 증거**는 [고유 실행 디렉터리](step_22_resume/damagochi-step22-resume-a6d21c11c0534ffda45eb4fc90f4e847/)다. 이하 RC 표의 로그는 이 디렉터리를 기준으로 한다. QA 추가 증거는 [독립 로그](step_22_resume_qa/independent.log), [실제 UI 로그](step_22_resume_qa/native_ui_second.log), [실행 경로](step_22_resume_qa/run_paths.json), [집계](step_22_resume_qa/rerun_summary.json)에 보관했다.

## [S22-DEV-002 검증 결과]

PASS는 해당 행의 수행 방식에 한정한다. 마우스 조작을 수행하지 않은 경로는 합성 신호/실제 엔진 검사와 구분했다.

| ID | 상태 | 입력·기대 결과와 독립 실행 결과 | 증거 |
|---|---|---|---|
| RC01 | PASS | 저장 없음 → 기본 메뉴의 이어하기 비활성 → 새 게임은 확인창 없이 NameEntry. 공백 이름 미저장, 정상 이름은 egg 생성·저장·Game. 확인/Enter 연속 신호에도 한 번만 진행 | suite.log, legacy_regression.log. 실제 UI에서도 빈 이름 확인 후 오류 표시·화면 유지 확인 |
| RC02 | PASS | level1/age120/affection3 egg를 별도 프로세스에서 저장하고 종료 → 새 프로세스의 MainMenu 이어하기. 전체 데이터와 파일 SHA256 동일, Game에서 egg 유지 | resume_egg.log |
| RC03 | PASS | baby 저장 프로세스 종료 → 새 프로세스 기본 메뉴 → 이어하기 → Game. 전체 Dictionary·파일 바이트 보존. 직접 Game 진입으로 대체하지 않음 | resume_baby.log. 실제 마우스 이어하기도 QA disk baby 복원 |
| RC04 | PASS | RC03의 Game에서 이미지 표시, 1초 후 기준 y-4/2초 후 기준 복귀, 20회 갱신해도 Tween 1개. 독립 QA는 움직이는 중 load_current_creature 100회에도 같은 Tween·같은 즉시 위치 확인 | resume_baby.log, independent.log, native_baby.png |
| RC05 | PASS | 정상 저장에서 새 게임 선택 즉시 NameEntry 전 확인창. 중복 클릭에도 메모리/파일 불변. 메뉴 표시 후 파일이 생겨도 새 게임 클릭 때 재확인 | suite.log. 실제 새 게임 클릭·확인창 표시 확인 |
| RC06 | PASS | 확인 연타 후 NameEntry 1회, 기존 파일/메모리 유지. 유효 이름 제출 때만 새 egg로 저장·Game 진입 | suite.log. 실제 ‘새 게임 진행’ 클릭으로 NameEntry 진입 확인; 실제 유효 이름 대체 제출은 수행하지 않음 |
| RC07 | PASS | 취소 버튼·Esc·닫기 모두 메뉴 문구·버튼·포커스 복원 및 메모리/파일 해시 유지 | suite.log의 세 경로 통과. 별도 실제 마우스 취소/X와 실제 Esc에서도 복원 확인 |
| RC08 | PASS | 실제 바이트 읽기 잠금, JSON 오류, 빈 배열/잘못된 배열 요소/0 임계값/비숫자/음수/소수/bool 등 24개 fixture 차단. 이어하기 직전 디스크 변화 재검사. QA는 player_name/save_version/creature_id/stage의 null·공백·잘못된 타입과 두 번째 개체의 잘못된 값도 추가 확인 | suite.log, read_locked.log, independent.log. 이전 메모리를 로드 성공으로 사용하지 않음 |
| RC09 | PASS | 잘못된 저장에서 대기·비활성 이어하기 강제 신호 → 메뉴 유지, 자동 NameEntry/Game/새 게임 생성 없음. 메모리와 파일 보존 | suite.log, read_locked.log |
| RC10 | PASS | 기존 verify.gd를 그대로 실행해 알 입력·레벨업·4조건·60.2초 관찰·부화·저장·Idle·상태 정리·장면 재진입 38개 assertion 통과. 과거의 ‘이어하기가 NameEntry로 감’ 결함 기대값은 사용하지 않음 | legacy_regression.log |
| RC11 | PASS | 읽을 수 있는 잘못된 JSON에 추가 대체 안내. 취소 시 바이트 보존, 명시적 확인 이후만 NameEntry, 이름 제출 이전 미저장. 실제 읽기 잠금으로 해시 획득 불가 시 메뉴·오류 안내·승인 없음 | suite.log, read_locked.log, locked_hashes.txt |
| RC12 | PASS | 승인 후 뒤로·승인 없는 직접 NameEntry·외부 파일 변경·없던 파일 생성에 무단 저장 없음. QA 추가로 승인 후 기존 파일 삭제 시에도 파일 재생성/메모리 초기화 없이 재선택 안내 확인 | suite.log, independent.log. 실제 뒤로가기 메뉴 복귀 확인 |
| RC13 | PASS (시험한 오류) | 실제 읽기 허용/쓰기 거부 파일 잠금으로 쓰기 시작 실패 → 이전 메모리 복원·해시 보존·오류 안내. 사본 Game.tscn 일시 이동으로 이어하기/이름 제출 전환 실패 유도 → 복구/재시도. 저장 성공 후 전환 실패 재시도는 추가 저장 없음. 확인/Enter 연타 방어 | write_locked.log, continue_scene_failure.log, name_scene_failure.log. 쓰기 도중 디스크 장애는 미검증·기존 한계 |
| RC14 | PASS | level2/age120 egg 저장 후 새 프로세스의 정상 MainMenu 이어하기 → 기존 로직으로 baby 부화·저장·Idle 시작 | resume_hatch.log. 정상 부화 저장을 메뉴의 불필요한 덮어쓰기로 오판하지 않음 |

### 코드·계약 대조

- MainMenu의 ContinueButton/StartButton은 ‘이어하기’/‘새 게임’으로 분리됐다. 기존 StartButton 이름, 도감 경로, 버튼 규격·간격이 유지된다. MessageLabel과 ReplaceSaveDialog 문구·확인/취소 신호가 연결돼 있다.
- 메뉴 _ready는 임시 Dictionary만 검사한다. 이어하기는 매번 디스크를 새로 읽고 순수 최소 검사를 통과한 데이터만 GameManager에 전달한다. 이전 메모리 깊은 복제와 전환 실패 복원 경로가 있다.
- 검사는 JSON 정수값 float를 허용하며 NaN/INF·음수·0 목표 등 위험 값을 차단한다. 누락된 선택 필드는 기존 기본값 보완을 유지한다. 다른 비어 있지 않은 stage 문자열을 egg로 바꾸지 않고 미지 키도 제거하지 않는다.
- 이어하기에 create_new_game/save_game/delete_save/clear_game_data 호출은 없다. 정상 baby·미부화 egg는 파일 바이트가 그대로였으며 조건 충족 egg는 Game 진입 이후 원래 부화 저장이 발생했다.
- 새 게임 승인에는 파일 존재/SHA256이 포함된다. NameEntry는 승인을 로컬로 가져와 SceneTree 메타데이터를 제거하고, 이름 제출 직전에 파일 상태를 다시 확인한다. 승인 없는 직접 진입은 메뉴로 돌아간다.
- 저장 실패 시 이전 메모리를 복구한다. 저장 성공 후 승인 소진·new_game_saved 가드로 장면 전환만 재시도한다. 기존 save_version=1, 저장 경로, managers·알 조건·Idle 수치는 그대로다.
- 전환 가드·Dialog pending 가드가 있어 반복 확인과 연속 입력을 차단한다. 게임 코드에서 참조 누락·import/파싱·노드 경로 오류는 확인되지 않았다.

## [AC1~AC5 결과]

| 조건 | 상태 | 이번 근거 |
|---|---|---|
| AC1 PNG 연결·부화/복원 표시 | PASS | PNG UID·부화 상태·새 프로세스 메뉴 이어하기 화면 및 실제 창의 baby 표시 |
| AC2 baby 전용 4px/2초 Idle | PASS | 10.106746초 수치 검사 y=-3.9999976~-0.0000099, SINE 예상 최대 오차 약 0.000347px. 1초/2초 복원 검사 통과 |
| AC3 중복·정리·재진입 | PASS | 20회 갱신, baby→egg/기타/빈 데이터, stop/장면 종료 및 재진입 회귀. QA 추가 100회 load 갱신에서도 Tween 1개 |
| AC4 기존 육성·부화·저장 | PASS (엔진·합성 입력) | 친밀도·레벨업·시간/레벨 조건표·입력 차단·단일 부화·빛 효과·저장 회귀 통과. 이번 실제 알 클릭 전체 흐름은 미검증 |
| AC5 정상 시작·프로세스 재실행 이어하기 | PASS | 신규 시작 및 별도 프로세스 egg/baby의 MainMenu→이어하기→Game 통과. 실제 baby 이어하기 클릭도 확인. 이전 B-01 해소 |

AC6의 QA 보고·범위 확인·원본 보존은 완료했다. 관리자 문서 상태 갱신과 최종 완료 표시는 수행하지 않았다.

## [회귀 테스트 결과]

- DEV 후속 테스트를 QA가 새로 실행: 주 검사 52 + 프로세스 복원 17 + 오류 주입 10 = **79 PASS**, failures=0. fixture 생성 assertion은 제외했다.
- 기존 Idle/알/저장 회귀: **38 PASS**, failures=0.
- 별도 작성한 QA 검사: **32 QA_PASS**, failures=0. 잘못된 필수 필드, 배열의 후속 개체, 순수 검사, JSON float, 오래된 메모리, 연속 이어하기, 100회 화면 갱신, 승인 후 파일 삭제를 보완했다.
- 정상 import/기본 시작/egg·baby 복원에 SCRIPT ERROR·Parse Error가 없다. 오류 주입 로그의 JSON 분석 실패, 읽기·쓰기 거부, 의도적으로 숨긴 장면 로드 실패 및 기존 빈 데이터 오류는 예상 결과다.

QA harness 초기 1건 실패는 source fixture의 중첩 정수 배열과 JSON 역직렬화 float 배열을 직접 비교한 시험 코드 문제였다. 실제 화면은 Game, 이름은 QA disk baby, 미지 키는 `["retain", 7.0]`으로 보존돼 있었다. 기대값을 디스크에서 읽은 전체 Dictionary로 바꿔 재검사했고 제품 코드는 변경하지 않았다. [초기 로그](step_22_resume_qa/independent_initial.log)도 남겼다.

실제 UI 첫 세션은 창 접근 승인 시간 초과 후 재시도했으며 사용자 입력·전경 변경으로 조작 결과가 섞여 합격 근거에서 제외했다. Alt+F4 종료 세션의 프로세스 종료 코드는 1이었고 로그에 스크립트 오류는 없었다. 두 번째 명확한 세션에서 아래 조작을 다시 수행했으며 X 종료 코드 0을 확인했다.

## [실제 마우스·화면 검증]

테스트 스크립트 없는 기본 시작으로 열린 격리 게임 창을 Windows Computer Use로 대상으로 선택했다. 관찰한 현재 화면 좌표에 한 번씩 입력하고 매번 다시 화면을 확인했다.

| 실제 조작/관찰 | 상태 | 결과 |
|---|---|---|
| 새 게임 버튼 클릭 | PASS | 메뉴의 두 진입 버튼 구분, NameEntry 전에 대체 확인창 표시 |
| 취소 버튼 클릭 | PASS | 메뉴 복귀·새 게임 포커스 테두리 복원 |
| Escape 키 | PASS | 동일 취소 동작 |
| 확인창 X 클릭 | PASS | 동일 취소 동작 |
| ‘새 게임 진행’ 클릭 | PASS | NameEntry 표시 |
| 빈 이름 상태 확인 클릭 | PASS | ‘이름을 입력해주세요.’ 표시, 화면 유지 |
| 뒤로가기 클릭 | PASS | MainMenu 복귀 |
| 이어하기 클릭 | PASS | 기존 QA disk baby의 Game 표시. 유효 이름 대체 제출을 하지 않아 기존 baby 유지 |
| 오류 메뉴/추가 대체 안내 렌더 | PASS | QA 재실행 PNG를 직접 열어 비활성 이어하기·줄바꿈 오류·추가 안내·확인/취소 표시 확인 |
| baby 표시·배치 | PASS | 실제 창과 렌더에서 이미지 잘림·화면 이탈·UI 겹침 없음 |

[실제 마우스 이어하기 후 baby](step_22_resume_qa/native_baby.png), [오류 메뉴 렌더](step_22_resume/damagochi-step22-resume-a6d21c11c0534ffda45eb4fc90f4e847/resume_invalid_menu.png), [오류 파일 대체 안내](step_22_resume/damagochi-step22-resume-a6d21c11c0534ffda45eb4fc90f4e847/resume_invalid_confirm.png), [정상 baby 렌더](step_22_resume/damagochi-step22-resume-a6d21c11c0534ffda45eb4fc90f4e847/resume_baby.png).

메뉴 버튼과 확인창 취소·확인·X의 실제 클릭 영역은 이번에 확인했다. 이전 QA의 해당 미검증 부분은 이 범위에서 해소됐다. 해시·메모리 보존은 실제 엔진 suite와 오류 주입 검사로 별도 검증했으며 UI 화면만 보고 파일 보존을 추정하지 않았다.

## [사용자 확인 필요]

| 항목 | 상태 | 이유 |
|---|---|---|
| 실제 모바일 터치·기기별 화면 | 사용자 확인 필요 | 합성 ScreenTouch 회귀만 실행. 실기기 없음 |
| 실제 마우스로 이름 입력부터 알 10회 입력·부화 전체 플레이 | 미검증 | 이번 실제 입력 검사는 메뉴/확인창/빈 이름/뒤로/baby 이어하기에 한정. 전체 기능은 합성 신호로 엔진 검증 |
| Idle의 체감 자연스러움 | 사용자 확인 필요 | 수치·렌더·중복 검사는 통과. 사람의 연속 플레이 체감 평가는 별도 |
| 쓰기 도중 디스크 장애·부분 파일 손상 | 미검증 | 이번 카드가 제외한 기존 SaveManager 비원자적 쓰기 한계. 실제 쓰기 시작 거부는 검증 |
| GameManager가 정상 입력에도 false 반환하도록 하는 주입 | 미검증 | 해당 복구 분기는 코드 확인. 실제 읽기·구조 검사·장면 전환 실패는 실행 검증 |

현재 이어하기/새 게임 정책에 관해 새 사용자 결정이 필요한 사항은 없다. 위 미검증을 임의 정책 추가나 범위 확장의 근거로 사용하지 않았다.

## [BLOCKER]

**S22-DEV-002 및 STEP 22 AC5 구현 BLOCKER 없음.** 이전 일반 재시작 진입 경로 부재 B-01은 이번 QA에서 해소됐다.

BUG-003의 60초 무입력 자동 부화 부재는 실제 60.2초 대기 후 추가 입력으로 부화하는 기존 동작으로 재확인했다. 작업카드의 현행 유지 요구와 일치하며 BLOCKER가 아니다. PROJECT_SPEC 부재, Game 메뉴 버튼, 원본 PNG 흰 배경, 저장 안정화 전체 범위도 이번 신규 결함으로 취급하지 않는다. 메뉴 진입 최소 검사의 PASS를 BUG-004 전체 해결로 확대하지 않는다.

## [WORK-MANAGER에 전달할 내용]

1. S22-DEV-002 RC01~14의 실행 근거와 AC1~AC5 PASS를 채택할 수 있다. BUG-002 잔여 정상 이어하기 경로와 이전 AC5 BLOCKER는 QA에서 해결 확인했다.
2. 최종 QA 의견은 **PASS WITH ISSUE**다. 제품의 새 결함·새 정책 BLOCKER는 없으며, 실기기 터치·전체 실제 입력·체감 품질과 기존 디스크 장애 한계를 잔여 항목으로 유지한다. 이 한계는 DEV 보고서의 PASS 범위를 넓혀 해석하지 않았다.
3. 위 사용자 환경 항목을 어떤 출시/완료 기준에 포함할지 관리자가 판단하고 MASTER.md·STEP_PLAN.md·BUG_LOG.md·PROJECT_STATE 등의 최종 상태를 갱신한다. QA는 STEP 22 전체 완료 체크나 STEP 23 착수를 결정하지 않았다.
4. QA 산출물은 본 보고서, tests/step_22/resume_qa_verify.gd, docs/reports/step_22_resume_qa/ 및 DEV 래퍼 재실행의 고유 로그·latest_run.json이다. 제품 파일·기존 보고서·작업카드·COMMON_OPERATIONS_TEMPLATE.md·MASTER.md·STEP_PLAN.md는 변경하지 않았다. 커밋/스테이징하지 않았다.
