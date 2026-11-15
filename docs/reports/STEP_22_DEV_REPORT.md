# STEP 22 DEV 결과 — S22-DEV-001

작성일: 2026-09-13. 구현 담당 결과이며 최종 STEP 완료 판정은 WORK-MANAGER/WORK-QA에 남긴다.

## [Godot 환경 확인]

- project.godot 존재. 시작 UID는 MainMenu, 자동 로드는 기존 GameManager/SaveManager이며 변경하지 않았다.
- 실행 파일: `C:/Godot/Godot_console.exe` 및 `C:/Godot/Godot.exe`.
- 실측 버전: `4.7.2.stable.official.ed1daf0bf`. 프로젝트 `config/features`의 4.7과 호환되며 import, GDScript, 장면, PNG 로드 실행 성공.
- 명령줄 headless 검사와 실제 OpenGL 렌더링 가능. 렌더 장치: Intel Iris Xe / OpenGL 3.3 Compatibility.
- 최초 sandbox 실행은 사용자 데이터/편집기 캐시 접근 제한으로 실패했다. 첫 복사본의 절대 custom_user_dir_name도 Godot에서 상대 이름으로 정규화되어 잘못된 경로로 해석되었다. 저장 테스트 전에 고유한 상대 이름으로 바로잡고 권한 승인 후 재실행했다. 이 실패를 프로젝트 파싱 오류로 집계하지 않는다. `step_22/baseline_import.log`와 재시도 로그 보존.
- 기본 시작 설정을 그대로 실행한 `normal_start.log`에는 파싱/런타임 오류 없음. 주 회귀 검사에는 의도적으로 유발한 저장 실패와 빈 데이터 오류 각 1건이 있으며 정상 시나리오 오류와 구분한다.

## [22-P1 재현 결과]

수정 전 코드를 복사한 프로젝트에서 `baseline.gd` 실행. UI 버튼의 실제 연결 신호를 발행해 시작 흐름을 진행했으며 실제 사람의 마우스 조작은 아니다.

| 항목 | 실제 관찰 | 근거 |
|---|---|---|
| 신규 시작 | MainMenu → NameEntry → 유효 이름 확인 후 저장 성공하지만 NameEntry 유지 | baseline.log: BASELINE_AFTER_CONFIRM=NameEntry SAVE=true |
| 알 입력 | 분리된 Game 장면 진입 후 마우스 이벤트 신호 10회: level=2, affection=0, 목표=13, 60초 전 egg 유지 | BASELINE_TEN_INPUT |
| 부화 | 팩토리 개체의 경과 시간만 120초로 설정하고 기존 판정 호출: baby 전환/저장 성공, 텍스처 null | BASELINE_HATCH |
| 메뉴 복원 | 메모리 비운 뒤 MainMenu가 저장 baby 복원, 시작 버튼은 NameEntry로 이동 | BASELINE_RESTORE_STAGE / BASELINE_RESTART_TARGET |
| 직접 Game 복원 | 메모리 비운 뒤 Game은 저장 baby 복원, 텍스처 null | BASELINE_DIRECT_RESTORE |

이 결과는 신규 시작 누락 및 BUG-001/002의 실행 근거다. 직접 Game 복원은 일반 재시작 경로의 통과를 뜻하지 않는다.

### 저장 격리 및 보존

- 원본 프로젝트의 실제 `user://`: `C:/Users/syj_1/AppData/Roaming/Godot/app_userdata/damagochi/` (`original_probe.log`, 원본에서 저장 작업 없는 probe 실행).
- 테스트 프로젝트: `C:/Users/syj_1/AppData/Local/Temp/damagochi-step22-43ddee3e216f4615aeeca6e3009b2b0d/`.
- 테스트 실제 `user://`: `C:/Users/syj_1/AppData/Roaming/damagochi-step22-43ddee3e216f4615aeeca6e3009b2b0d/`.
- 복사본 project.godot에만 custom user directory를 설정했다. 각 harness는 저장 작업 전에 엔진에서 해석한 경로를 출력하고 테스트용 이름이 없으면 종료한다. 원본 설정/SaveManager는 변경하지 않았다.
- 원본 해시 읽기는 최초 sandbox에서 거절되어 승인 후 수행했다. 따라서 before 해시는 **P1 종료 후, 수정 후 회귀 검사 전** 시점이다. P1 이전 해시 증거는 없으며, P1은 별도 경로에만 저장한 실행 로그로 격리를 입증한다.
- 회귀 검사 전후 원본 SHA256 동일: `E5F0C0FE37F6F110FEF2E3FDCC3DB12A73F8BB765A76E10DB0EE02E1E232037D`. `original_save_before.txt`, `original_save_after.txt` 참조.

## [선행 문제 처리]

- **BUG-002 신규 진입**: name_entry.gd의 기존 저장 성공 분기 끝에 Game.tscn 전환을 추가하고, 반환 오류는 기존 MessageLabel에 안내한다. STEP 22의 정상 신규 진입·알 육성·부화 검증에 필요한 최소 수정이다. 빈 이름 및 저장 실패 return 유지.
- **이름 입력/게임 화면 전환**: 수정 후 MainMenu 시작 버튼 → 이름 → 확인 → Game 및 저장 성공을 실제 Godot에서 확인했다. 빈 이름/저장 실패는 전환하지 않는다. 장면 전환 자체의 오류 반환 분기는 코드 확인만 했으며 오류 강제 주입은 미검증이다.
- **저장/복원**: 기존 팩토리, GameManager, SaveManager 코드 변경 없음. baby 저장 후 프로세스를 종료하고 새 프로세스의 직접 Game 복원에서 이미지/Idle 재개 확인.
- **이어하기 정책 영향**: 메뉴가 기존 데이터를 읽지만 시작 버튼은 계속 이름 입력으로 간다. 이름 확인 시 기존 create_new_game/save_game 동작으로 새 게임을 저장한다. 이어하기/덮어쓰기 정책은 추가하지 않았으며 BUG-002 전체 해결로 보고하지 않는다.
- **BUG-003**: 레벨 2·생성 직후 fixture에서 실제 60.2초 무입력 대기 시 egg 유지, 추가 입력 후 baby 전환 확인. 자동 판정 요구는 미정이며 Timer를 추가하지 않았다.
- BUG-004의 잘못된 0 임계값 데이터는 실행·수정하지 않았다.

## [STEP 22 구현 결과]

- R1: 현재 001 PNG 및 실제 로드로 확인한 UID를 기존 CreatureSprite.texture에 연결.
- R2/R3: _ready에서 로컬 기준 위치를 한 번 캡처. baby·표시·텍스처 조건에서 4픽셀 상하, 편도 1초, SINE/EASE_IN_OUT 무한 Tween 시작. 유효하고 실행 중인 Tween은 재생성하지 않는다.
- R4/R5: egg/다른 상태/빈 개체에서 정지 및 기준 위치 복원. 종료 시 노드 유효성을 확인해 정리. 기존 부화 완료/복원 화면 갱신 경로에서 자동 재개하며 hatch_in_progress로 시작을 막지 않는다.
- R6: 알 흔들림·빛 Tween·입력·부화 기준·데이터/저장 규칙을 유지. 다른 상태의 기존 non-egg 표시 분기도 유지.
- 이미지 연결과 Idle은 동일 수정 묶음으로 검증했다. 표시의 엔진 로드와 실제 화면 증거는 아래에 있다.

## [변경 파일]

제품 파일:

- `scenes/game/Game.tscn`: 외부 PNG 리소스 및 texture 연결만 추가.
- `scripts/game/game.gd`: Idle 상수·변수·시작/정지·초기화/종료와 기존 화면 갱신 연결.
- `scripts/main/name_entry.gd`: 저장 성공 후 장면 전환과 오류 안내.

검증/보고 파일:

- `tests/step_22/.gdignore`, `baseline.gd`, `verify.gd`, `probe.gd`, `run.ps1`, `runtime_path.txt`.
- `docs/reports/STEP_22_DEV_REPORT.md`, `docs/reports/step_22/` 로그·해시·PNG.
- tests는 .gdignore로 자동 import에서 제외하며 원본 자동 로드/시작 설정에 연결하지 않는다. baseline은 수정 전 기록용이며 현재 코드에서 같은 결과를 기대하는 회귀 테스트가 아니다.

MASTER.md, STEP_PLAN.md, BUG_LOG.md, DECISION_LOG.md, PROJECT_STATE.md, COMMON_OPERATIONS_TEMPLATE.md 및 진행표는 수정하지 않았다. 작업 시작 전부터 존재하던 Game.tscn 변경, 옛 이미지 삭제와 001 폴더 추가, 미추적 문서를 보존했다. 커밋/스테이징하지 않았다.

## [자체 테스트 결과]

| ID | 결과 | 실행 근거 / 제한 |
|---|---|---|
| T01 | PASS | import 재시도, 기본 시작, 게임 장면 및 PNG UID 로드. 정상 실행 파싱/런타임 오류 없음 |
| T02 | PASS / 일부 미검증 | 신규 UI 신호 흐름, 빈 이름, 격리 저장 경로를 디렉터리로 만든 저장 실패 처리 통과. 실제 마우스 GUI 조작·장면 전환 실패 주입 미검증 |
| T03 | PASS (합성 입력) | 첫 입력 +1, 10회 level2/affection0/목표13, 60초 전 미부화 |
| T04 | PASS | 0초/레벨1, 0초/레벨2, 120초/레벨1 미부화; 120초/레벨2만 기존 판정에서 부화 |
| T05 | PASS (현행 동작 관찰) | 실제 60.2초 대기 후 미부화, 추가 터치 부화. 자동 부화 기능 통과를 뜻하지 않음 |
| T06 | PASS (엔진 상태) | 효과 중 반복 입력 20회 친밀도 불변, 부화 시각 불변, baby 이미지/Idle 시작, 알 숨김/터치 비활성, 빛 알파 0 복귀 |
| T07 | PASS (직접 Game) | 별도 프로세스 복원 stage=baby, 이미지/Idle 실행, save_version=1. 일반 메뉴 이어하기는 BLOCKED |
| T08 | PASS | 10.1065초 측정: y=-3.999998~-0.000016, 2초 SINE 예측 최대 오차 0.000365px. 20회 갱신 후 동일 Tween·처리 Tween 1개. x/scale/rotation/메모리 데이터 불변 |
| T09 | PASS | baby→egg/기타/baby, 빈 화면/빈 load, stop 2회, 장면 교체 시 기존 Tween 무효/새 Tween 재개 |
| T10 | 부분 PASS / 미검증 | InputEventMouseButton 및 InputEventScreenTouch의 Area2D 신호 각각 +1. 물리 hit testing·OS 마우스 입력·실제 터치 기기 미검증 |

주 회귀: `verify.log` **38 PASS, RESULT failures=0**, 종료 코드 0. 별도 복원 렌더 실행도 종료 코드 0. 저장 실패와 빈 load 검사의 기존 push_error 2건은 예상 로그다. 기본 시작/복원 로그에는 오류가 없다.

화면 증거: [복원된 baby 실제 렌더](step_22/restored_baby.png). 표시된 캡처를 직접 확인했다. 405×720 창에서 캐릭터가 보이고 잘림이나 상단/하단 UI 겹침은 관찰되지 않았다. PNG의 흰 직사각형 배경은 유지했다. 부화 직후 렌더 캡처와 연속 동영상·움직임의 체감 품질은 확보하지 않았다.

재현: 프로젝트 루트 PowerShell에서 `./tests/step_22/run.ps1`. 새로운 고유 저장 경로의 복사본을 만들고 import → 약 72초 headless 회귀 → 새 프로세스 렌더 복원 순으로 실행한다. Godot가 사용자 데이터/캐시 및 렌더 창을 사용할 권한이 필요하다. run.ps1 래퍼 자체는 별도 재실행하지 않았으며 그에 대응하는 각 Godot 명령은 이번에 직접 실행했다. 전체 테스트 로그는 `docs/reports/step_22/`에 있다.

## [발견한 신규 문제]

- 이번 검사에서 신규 제품 BUG 후보는 확인되지 않았다. BUG-001 및 BUG-002 신규 진입 누락은 수정 근거를 확보했다. BUG-002 이어하기 부분과 BUG-003 관찰은 기존 문제다.
- missing file: `PROJECT_SPEC.md`는 여전히 없음. 지정된 여섯 문서와 구현에 필요한 코드/이미지는 모두 존재한다. 누락 명세를 가정해 새 정책을 만들지 않았다.

## [QA에 전달할 검증 항목]

- Q01: 실제 마우스로 MainMenu부터 신규 입력 → 알 육성 → 부화 → Idle 재현, 특히 클릭 영역과 UI 신호 연결을 독립 검증.
- Q02: 부화 빛 효과 직후 이미지 노출, 흰 배경 허용 여부, 연속 움직임의 자연스러움·끊김을 사용자 환경에서 확인.
- Q03: 이어하기 정책 및 후속 진입 복구 후 정상 재시작에서 baby/Idle 복원. 현재 BLOCKED.
- Q04: 실제 터치 기기 입력은 **사용자 환경 검증 필요**.
- Q05: AC1~6 대조. AC1은 복원 렌더/부화 노드 상태 증거, AC2/3은 수치 검사 통과, AC4는 합성 입력/엔진 검사 통과이며 실제 조작 확인이 남는다. AC5 BLOCKED, AC6 DEV 범위 검토/보존/보고 수행, 독립 QA와 관리자 반영 대기.

## [현재 BLOCKER]

- 전체 STEP 통합 완료: 기존 저장에 대한 시작/이어하기/덮어쓰기 정책 미정 및 정상 재시작 진입 경로 부재(AC5).
- 이미지/Idle 구현 자체의 BLOCKER는 없다. 사용자 실제 입력 및 부화 화면 QA는 미검증으로 남는다.

## [WORK-MANAGER에 전달할 내용]

S22-DEV-001의 이미지·baby Idle·중복 방지·정지/복원과 BUG-002 신규 진입 최소 수정을 구현했다. Godot 4.7.2에서 격리 저장으로 수정 전 재현, 38개 회귀 assertion, 별도 프로세스 baby 복원 및 실제 렌더를 확인했다. 코드/저장 규칙의 범위 밖 변경은 없다. 전체 STEP 완료는 선언하지 않는다. 다음은 QA 검증 및 이어하기 정책 결정/후속 선행 카드이며 STEP 23 착수는 권장하지 않는다.

MASTER/PROJECT_STATE 갱신용 요약: “STEP 22 DEV 구현 및 자체 실행 검증 수행. 기존 PNG 연결, 4px/2초 baby Idle 수명 관리, 신규 이름 저장 후 Game 진입 복구. 격리 Godot 회귀 실패 0, fresh-process 직접 Game 복원과 렌더 확인. 정상 메뉴 이어하기는 미해결이며 사용자 입력·부화 화면 독립 QA 필요. 전체 완료 판정은 관리자 대기.”
