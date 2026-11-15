# STEP 22 이어하기 DEV 결과

검증일: 2026-09-28 · 작업카드: S22-DEV-002 · 기준: STEP_22_RESUME.md / M-005 선택지 A

## [현재 STEP]

STEP 22 AC5 정상 시작·재시작 경로 복구. **DEV 구현 및 RC01~14 엔진 자체 검사 PASS, 독립 QA/관리자 최종 판정 대기**.

기존 S22-DEV-001 이미지·Idle 구현 및 저장 형식을 유지했다. 이 보고서는 STEP 전체 완료 또는 BUG-004 전체 해결 선언이 아니다.

## [수행한 작업]

### 구현 전 확인

- MASTER, STEP_PLAN, BUG_LOG, DECISION_LOG M-005, 원 STEP 22 카드와 DEV/QA 보고서, 후속 카드 및 관련 코드·장면을 확인했다.
- 메뉴의 기존 시작 버튼은 NameEntry로만 이동하고 기존 메모리가 있으면 파일 읽기를 건너뛰었다. 이어하기 버튼·확인창·화면 오류 안내는 없었다.
- 기존 NameEntry는 이름 검사 → 새 데이터 생성 → 저장 → Game 이동이며 저장 실패 시 이전 메모리 복구가 없었다.
- GameManager 기본값 보완과 SaveManager 저장 버전 1·경로를 확인했다. Game의 자동 부화와 baby Idle은 읽기 전용으로 유지했다.
- 기존 미커밋 변경(이동된 이미지, Game 장면, game.gd, name_entry.gd, 문서/테스트)을 보존했다. 원 작업 보고서와 baseline의 과거 결함 기대값을 고치지 않았다.
- 이번 카드의 필수 파일은 모두 존재한다. 기존 PROJECT_SPEC.md 부재를 새 정책으로 보충하지 않았다.

### 메뉴 및 승인 흐름

- ContinueButton ‘이어하기’를 기존 StartButton 앞에 추가하고 StartButton을 ‘새 게임’으로 표시했다. 기존 버튼 크기·글꼴·간격 및 도감 경로를 유지했다.
- 저장 없음은 이어하기 비활성, 정상 저장은 활성, 읽기/파싱/최소 구조 실패는 비활성과 화면 오류 안내로 처리한다. 메뉴 표시 시 임시 데이터만 검사하고 GameManager를 변경하지 않는다.
- 이어하기 클릭에서 파일을 다시 읽고 순수 검증 helper를 통과한 Dictionary만 GameManager에 전달한다. 오래된 메모리로 디스크 검사를 대신하지 않는다. 로드/전환 실패는 깊게 보관한 이전 메모리를 복구한다.
- player_name/save_version/active_creatures와 각 개체의 ID·선택 필드 타입/유한 숫자/정수/최소값을 검사한다. 누락 선택 필드는 기존 기본값 보완을 유지하며, 미지 키나 다른 비어 있지 않은 stage 문자열을 제거·초기화하지 않는다.
- 기존 파일이 있으면 NameEntry 진입 전에 대체 확인창을 표시한다. 잘못된 JSON의 대체에는 추가 안내를 표시한다. 취소·Esc·닫기는 같은 정리 경로로 메뉴 문구·버튼·새 게임 포커스를 복구한다.
- 확인 후 파일 존재 여부/SHA256에 연결된 SceneTree 일회성 승인을 전달한다. 바이트를 읽을 수 없어 해시를 구하지 못하면 이름 입력으로 진행하지 않는다.
- NameEntry는 승인을 로컬로 가져온 뒤 메타데이터를 제거한다. 승인 없는 직접 진입은 메뉴로 돌려보내고, 뒤로 가기는 로컬 승인을 버린다. 이름 제출 전 파일 상태가 승인 때와 달라졌으면 데이터를 만들거나 저장하지 않는다.
- 쓰기 실패 시 이전 메모리를 복구한다. 저장 성공 시 승인을 소진하고, 이후 Game 전환 실패의 재시도는 새 게임 생성/저장을 반복하지 않는다. 전환·확인 연타를 가드한다.

## [수정한 파일]

| 파일 | 이번 변경 |
|---|---|
| scenes/main/MainMenu.tscn | 이어하기·안내 라벨·대체 확인창, 새 게임 표시 |
| scripts/main/main_menu.gd | 최소 검사, 디스크 재로드, 이어하기·확인/취소·승인 및 오류/중복 방어 |
| scripts/main/name_entry.gd | 승인 소비·파일 상태 재확인·직접 진입 방어·저장 실패 메모리 복구·재시도 가드 |
| tests/step_22/resume_verify.gd | RC별 후속 검사, 별도 프로세스 복원·오류 주입 모드 |
| tests/step_22/run_resume.ps1 | 고유 사본/저장 격리, 원본 해시, 실제 파일 잠금, 전체 실행 보조 |
| docs/reports/STEP_22_RESUME_DEV_REPORT.md | 본 보고서 |
| docs/reports/step_22_resume/ | 실행 로그·캡처·보존 해시·실행 경로 |

project.godot, managers/*.gd, game.gd, Game.tscn, NameEntry.tscn 및 현재 캐릭터 PNG의 작업 전후 SHA256이 같다. `protected_before.json`/`protected_after.json` 참조. 자산·import·UID, 기존 보고서·카드·관리 문서·COMMON_OPERATIONS_TEMPLATE는 편집하지 않았다. 스테이징/커밋하지 않았다.

## [테스트 결과]

### 환경·저장 보존·실행 방법

- 엔진: `C:/Godot/Godot_console.exe`, **4.7.2.stable.official.ed1daf0bf**. 프로젝트 config/features 4.7과 호환.
- 실제 OpenGL 3.3 Compatibility / Intel Iris Xe 렌더링 및 headless 실행. 깨끗한 사본 import와 기본 시작 장면 실행 성공.
- 실행 명령: 프로젝트 루트에서 `./tests/step_22/run_resume.ps1`. 스크립트 전체 실제 실행 종료 코드 **0**.
- 원본 엔진 user 경로: `C:/Users/syj_1/AppData/Roaming/Godot/app_userdata/damagochi/`.
- 최종 테스트 사본: `C:/Users/syj_1/AppData/Local/Temp/damagochi-step22-resume-4cb5866a1fd64535a21978b40b975dcc/`.
- 엔진 확인 테스트 user 경로: `C:/Users/syj_1/AppData/Roaming/damagochi-step22-resume-4cb5866a1fd64535a21978b40b975dcc/`.
- 복사본의 custom user directory만 설정했다. 모든 fixture 저장 전에 harness가 엔진 해석 경로를 출력하고 테스트 이름을 검사한다. 원본 probe는 저장 작업 없이 경로/버전만 출력한다.
- 원본 저장 SHA256 전후 동일: `E5F0C0FE37F6F110FEF2E3FDCC3DB12A73F8BB765A76E10DB0EE02E1E232037D`. 이번에는 **테스트 시작 전부터** 해시를 확보했다.
- 아래 증거는 모두 [최종 실행 디렉터리](step_22_resume/damagochi-step22-resume-4cb5866a1fd64535a21978b40b975dcc/) 기준이다. `latest_run.json`에도 경로를 기록했다.

### RC01~14

PASS의 범위는 실제 Godot에서 수행한 UI 신호/합성 키 입력·장면·저장·렌더 검사다. 사람의 실제 마우스 클릭이나 터치 기기 조작까지 통과했다는 의미는 아니다.

| ID | 결과 | 입력 → 실제 결과 / 증거 |
|---|---|---|
| RC01 | PASS | 파일 없음 → 기본 MainMenu → 새 게임 → 확인창 없이 NameEntry. 공백 이름은 미저장, 유효 이름은 신규 egg 저장/Game 진입. suite.log |
| RC02 | PASS | 팩토리 egg(level1, 120초 경과, 친밀도3)를 저장한 프로세스 종료 → 새 프로세스의 기본 MainMenu → 이어하기. 전체 Dictionary 및 파일 SHA256 보존. resume_egg.log |
| RC03 | PASS | baby 저장 프로세스 종료 → 새 프로세스의 기본 MainMenu → 이어하기 → Game. 전체 데이터·파일 바이트 보존. resume_baby.log |
| RC04 | PASS | RC03의 실제 Game에서 PNG 표시, 1초 후 y-4/2초 후 기준 복귀, 화면 20회 갱신 후 동일 Tween 하나. resume_baby.log, resume_baby.png |
| RC05 | PASS | 파일 있는 새 게임은 NameEntry 이전 확인창 표시. 중복 클릭에도 메뉴 유지·메모리/해시 불변. 메뉴 표시 후 생긴 파일도 클릭 때 재확인. suite.log |
| RC06 | PASS | 확인 연타 후 NameEntry 1회 진입, 기존 파일·메모리 유지. 유효 이름 제출 때만 새 egg 저장/Game 진입. suite.log |
| RC07 | PASS | 취소 버튼 신호, 루트 viewport로 전달한 실제 KEY_ESCAPE 이벤트, 창 close_requested 신호 각각 확인. 메뉴 문구·버튼·새 게임 포커스·메모리/해시 보존. suite.log |
| RC08 | PASS | 실제 파일 읽기 잠금, 잘못된 JSON, 24개 잘못된 구조/수치 fixture 차단. 빈 배열·배열 아닌 값·요소 오류·0 목표·비숫자·음수·소수·bool 포함. INF/NAN helper 검사 및 누락 선택 필드/미지 키 보존 확인. 이어하기 직전 파일 변경도 재검사. suite.log, read_locked.log |
| RC09 | PASS | 잘못된 저장으로 메뉴 대기 및 비활성 이어하기 신호 강제 호출 → 자동 이름 입력/게임/새 데이터 생성 없음. 이전 메모리·파일 유지. suite.log, read_locked.log |
| RC10 | PASS | 기존 verify.gd를 수정 없이 재실행: **38 PASS, failures=0**. 입력·레벨·4조건·실제 60.2초 대기·부화·저장·Idle 10초·중복/정지/재진입 검사 통과. legacy_regression.log |
| RC11 | PASS | 읽을 수 있는 잘못된 JSON: 대체 추가 안내, 취소 시 바이트 보존, 확인 후 NameEntry까지 미저장. 바이트 잠금 상태: 해시 획득 불가 안내 후 메뉴 유지·승인 없음. suite.log, read_locked.log, locked_hashes.txt |
| RC12 | PASS | NameEntry 뒤로/승인 없는 직접 진입/승인 후 파일 변경/없던 파일 생성 모두 무단 저장 없음. 안내 또는 메뉴 복귀. suite.log |
| RC13 | PASS | 읽기는 허용하고 쓰기를 막는 실제 파일 잠금으로 쓰기 시작 실패 → 깊은 이전 메모리 복구·해시 보존·오류 안내. Game.tscn을 사본에서 일시 이동해 이어하기/이름 제출의 전환 실패 유도 → 메모리 복구 또는 성공 저장 소진, 파일 복구 후 재시도 성공. 확인/Enter 연타 시 중복 저장 방지. write_locked.log, continue_scene_failure.log, name_scene_failure.log |
| RC14 | PASS | level2·120초 egg 저장 후 새 프로세스 MainMenu 이어하기 → 기존 부화 판정으로 baby 전환·저장·Idle 시작. resume_hatch.log |

후속 주 검사 52 PASS, 별도 프로세스 egg/baby/부화 검사 17 PASS, 오류 주입 검사 10 PASS로 **후속 assertion 79 PASS**(fixture 생성 검사는 제외). 기존 회귀는 별도 38 PASS. 최종 실행에 FAIL assertion, SCRIPT ERROR, Parse Error 없음.

부화 조건을 이미 만족한 egg의 파일 변경은 RC14의 정상 게임 진행이며, 메뉴 이어하기 자체의 저장으로 집계하지 않았다. 보존 검사는 미충족 egg/baby로 따로 수행했다. 기존 QA의 ‘재시작이 NameEntry로 잘못 이동함’ 결함 재현은 새 성공 기준으로 재사용하지 않았다.

### 오류 로그·시험 도구 수정 이력

- 최종 오류 주입 로그의 JSON 파싱 실패, 읽기/쓰기 실패, Game.tscn 미존재 오류 및 기존 회귀의 빈 데이터 오류는 기대된 결과다. 정상 import/복원/기본 시작 경로에는 해당 오류가 없다.
- 최초 후속 harness가 Menu 스크립트를 autoload 초기화 전에 preload하여 SaveManager 식별 오류가 났다. harness를 autoload 생성 이후 load하도록 고쳤다. 제품에서 정상 장면을 여는 경로의 오류가 아니다.
- 최초 Esc 시험은 popup viewport에 직접 키를 넣어 취소를 재현하지 못했다. 루트 viewport의 내장 창 입력 전달 경로로 바꾼 뒤 취소와 보존 검사가 통과했다. 제품의 Esc 동작을 시험 편의로 바꾸지 않았다.
- 초기 실패 실행 디렉터리와 `escape_retry.log`, `escape_viewport.log`를 보존했다. 성공 판정은 위 최종 실행 전체에 근거한다.

### 실제 화면 확인 및 미검증

DEV가 실제 렌더 PNG를 열어 정상 메뉴의 두 버튼, 오류 메뉴의 비활성 이어하기·줄바꿈 안내, 대체 확인창과 취소 버튼, 복원 baby 표시를 확인했다. 현재 405×720 창에서 확인 문구와 추가 오류 문구가 화면 안에 표시된다.

- [정상 메뉴](step_22_resume/damagochi-step22-resume-4cb5866a1fd64535a21978b40b975dcc/resume_valid_menu.png)
- [오류 메뉴](step_22_resume/damagochi-step22-resume-4cb5866a1fd64535a21978b40b975dcc/resume_invalid_menu.png)
- [잘못된 저장 대체 확인](step_22_resume/damagochi-step22-resume-4cb5866a1fd64535a21978b40b975dcc/resume_invalid_confirm.png)
- [메뉴 이어하기 후 baby](step_22_resume/damagochi-step22-resume-4cb5866a1fd64535a21978b40b975dcc/resume_baby.png)

**미검증 / 사용자 환경 검증 필요:** 실제 마우스의 버튼·확인창 클릭 영역/OS 닫기 클릭, 실기기 터치, Idle의 체감 품질. 취소/닫기는 신호, Esc는 엔진 입력 이벤트로 검증했다. GameManager.load_game_data 자체가 유효 입력에도 false를 반환하도록 하는 별도 주입은 하지 않았으며, 그 반환 실패 복구 분기는 코드 검토 범위다. 장면 전환 실패 복구와 실제 파일 쓰기 시작 실패는 실행 검증했다.

## [발견된 문제]

- 최종 검사에서 이번 구현으로 인한 신규 제품 BUG 후보는 발견하지 않았다.
- 기존 SaveManager는 원자적 쓰기를 하지 않고 store_string 이후 디스크 오류도 충분히 확인하지 않는다. **쓰기 시작 후 디스크 장애·부분 파일 손상에 대한 보존/복구는 보장하지 않는다.** 이번 검사는 파일을 열기 전 쓰기 거부만 검증했다. 카드가 명시한 기존 한계로 남기고 managers를 수정하지 않았다.
- 메뉴 최소 검사는 이번 진입 방어다. 직접 Game 로드·다른 저장 진입점까지 포함하는 BUG-004 전체 검증/해결은 범위 밖이다.
- BUG-003 자동 판정, Game 메뉴 버튼, 원본 PNG 배경 등 기존 범위 밖 항목은 변경하지 않았다.

## [보류 사항]

새로운 정책 결정이나 구현 BLOCKER는 없다. M-005의 NameEntry 진입 전 확인 정책을 그대로 구현했다. **BUG-002 잔여/AC5는 DEV의 정상 메뉴·별도 프로세스 검사에서 해결을 확인했으나, 독립 QA와 WORK-MANAGER 최종 판정은 대기**다. STEP 전체 완료 상태를 변경하지 않았다.

## [다음 STEP]

STEP 23 착수 대신 WORK-QA가 RC01~14, 특히 실제 클릭 영역·취소/닫기·오류 화면·별도 프로세스 이어하기를 독립 검증하도록 전달한다. QA 보고서를 대신 작성하지 않았다. 이어서 관리자가 BUG-002 및 AC5/STEP 22 상태를 판정한다.

## [MASTER 갱신 내용]

“S22-DEV-002 구현 및 자체 검증 완료. MainMenu 이어하기/새 게임 분리, NameEntry 전 대체 확인과 일회성 파일 해시 승인, 로드 최소 검사·실패 복구·중복 방어 구현. Godot 4.7.2에서 RC01~14 엔진 자체 검사 및 기존 회귀 38개 통과. 별도 프로세스의 정상 메뉴를 통한 egg/baby 재개·파일 보존과 조건 충족 egg 자연 부화 확인. 기존 Idle/저장 코드·원본 저장 해시 보존. 신규 정책 BLOCKER 없음. 실제 마우스/실기기 및 독립 QA 대기, STEP 전체 완료는 관리자 판정 전 보류.”
