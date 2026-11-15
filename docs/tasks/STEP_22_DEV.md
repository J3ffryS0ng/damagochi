# STEP 22 DEV 작업카드

## 작업 ID / STEP 번호와 제목

- 작업 ID: S22-DEV-001
- STEP: 22 — 캐릭터 Idle 이미지 및 애니메이션
- 작성일: 2026-09-13 / 버전: 1.0 / 작성: WORK-MANAGER / 실행 담당: DEV / 독립 확인: QA
- 기준: STEP_PLAN.md 4절 및 22-A~D 완료 조건. 이 카드는 docs/tasks/STEP_22.md의 개요를 구체화한다.

## 현재 상태

작업카드 작성 완료. **22-P1은 준비 완료**, STEP 22 전체는 **선행 검증 대기**다. 22-A/B의 구현 지침은 M-004로 확정했으나 선행 실행 증거는 없다. 이번 관리자 작업에서는 구현 코드 수정·게임 실행 테스트를 하지 않았다.

## 목표

부화 직후와 baby 저장 복원 후 캐릭터 001의 기존 이미지가 표시되고 미세한 상하 Idle이 반복된다. 알 입력·흔들림·부화 빛 효과·레벨·친밀도·저장 계약을 유지한다. 게임 시작부터 재실행까지의 전체 검증이 끝나야 STEP 22를 완료할 수 있다.

## 현재 코드 상태 및 계획과의 대조

| 파일 / 함수·노드 | 실제 상태 | STEP_PLAN과 비교 / 영향 |
|---|---|---|
| project.godot | MainMenu UID로 시작, GameManager/SaveManager 자동 로드, 720 × 1280 | 계획과 일치. 시작 장면을 Game으로 변경해 검증을 우회하지 않음 |
| scripts/main/main_menu.gd / _on_start_button_pressed | 저장을 읽는 코드는 있으나 시작 버튼은 항상 NameEntry로 이동 | 계획에 기록된 BUG-002와 일치. 사용자 재시작 복원 경로는 미완성 |
| scripts/main/name_entry.gd / validate_name | 이름 검사·새 데이터 생성·저장·메시지 출력까지만 수행 | 게임 장면 전환 없음. STEP 03 완료 이력과 정상 시작 흐름은 다름. 선행 복구 대상 |
| scripts/managers/game_data_factory.gd | 버전 1, active_creatures[0], creature_id=001, stage=egg, level=1, affection=0, 목표=10 및 시간 필드 | 계획과 일치. 테스트 데이터를 이 팩토리로 만들고 스키마 변경 금지 |
| scripts/managers/game_manager.gd | 친밀도 증가·레벨업·egg→baby 변경·기본값 보완 | 구현 존재만 확인. 저장 복원·부화 회귀 테스트 필요 |
| scripts/managers/save_manager.gd | user://savegame.json 읽기/쓰기, JSON Dictionary 확인 | 계획과 일치. 실제 파일 보존·저장 격리 확인 필요 |
| scenes/game/Game.tscn / PetArea/CreatureSprite | Sprite2D, visible=false, texture 없음. position 미지정(기본 0,0), scale=(0.2633197,0.24048276) | BUG-001과 일치. STEP 21 완료 이력과 표시 조건 충돌 |
| assets/creatures/001/creature_001_idle.png | 실제 열어 본 결과 단일 캐릭터 이미지. 프레임 격자 없음. 밝은 배경 영역이 보임 | 파일명 추정에서 실제 시각 확인으로 보완. 원본 배경 제거·크롭은 이번 범위 밖 |
| game.gd / update_creature_visual | egg와 그 외 상태의 visible/input_pickable 전환 및 알 Tween 처리. Idle 없음 | STEP 22 미구현 상태와 일치. 기존 비-egg 표시 분기는 유지하고 Idle만 baby에 제한 |
| game.gd / _ready, load_current_creature | 데이터 복원 → 현재 개체 → UI/화면 갱신 | 기존 진입점에서 Idle 시작. 별도 로더를 만들지 않음 |
| game.gd / _finish_hatch | baby 변경 → 저장 → 화면 갱신 → hatch_in_progress=false | 계획에 없던 구현 주의점. 이 플래그로 Idle 시작을 막지 말 것 |
| game.gd / can_hatch, check_hatch_effect | 60초와 레벨 2 조건, 로드·터치 후 판정. 무입력 Timer 없음 | BUG-003과 일치. 자동 부화 요구가 확정됐다고 가정하지 않음 |

현재 계획의 정적 사실과 코드는 일치한다. 차이는 과거 완료 체크 대비 실제 시작·캐릭터 표시 누락이다. 이 차이를 복구 완료로 맞춰 적지 않는다. 부화 플래그 순서와 비-egg 분기는 위 표처럼 세부 지침을 보완한 것이며 기존 동작을 변경할 근거가 아니다.

## 입력 파일 및 관련 파일

모든 경로는 프로젝트 루트 J:\2026\Github\damagochi 기준이다.

- 기준 문서: MASTER.md, STEP_PLAN.md, COMMON_OPERATIONS_TEMPLATE.md, BUG_LOG.md, DECISION_LOG.md, PROJECT_STATE.md, docs/tasks/STEP_22.md.
- 직접 구현 대상: scenes/game/Game.tscn, scripts/game/game.gd.
- 선행 확인: project.godot, scenes/main/MainMenu.tscn, scenes/main/NameEntry.tscn, scripts/main/main_menu.gd, scripts/main/name_entry.gd.
- 데이터·저장 회귀 확인: scripts/managers/game_data_factory.gd, scripts/managers/game_manager.gd, scripts/managers/save_manager.gd.
- 리소스: assets/creatures/001/creature_001_idle.png 및 .import, assets/eggs/egg_001.svg.
- 결과물 예정: docs/reports/STEP_22_DEV_REPORT.md, docs/reports/STEP_22_QA_REPORT.md, 관련 로그·화면 증거.

## 수정 가능 범위

| 단위 | 허용 파일 | 허용 내용 |
|---|---|---|
| 22-P1/P3 | 테스트 전용 파일·보고서 | 재현용 fixture/harness 및 로그. 실행 설정 격리는 테스트 복사본에서만 수행 |
| 22-P2 신규 진입 복구 | scripts/main/name_entry.gd | P1에서 재현한 뒤 기존 저장 성공 분기 끝에 Game.tscn 전환. 반환 오류 시 기존 MessageLabel로 실패 안내. 빈 이름·저장 실패의 return 유지 |
| 22-A | scenes/game/Game.tscn | 현재 PNG 외부 리소스 선언 및 CreatureSprite.texture 지정 |
| 22-B | scripts/game/game.gd | R2~R6의 Idle 변수·상수·시작/정지·초기화·정리 및 기존 화면 갱신 연결 |
| 22-C/D | tests/step_22/ 아래 테스트 전용 파일(필요 시 신규), docs/reports/, 관리 문서 결과 기록 | 테스트가 런타임 자동 로드나 배포 동작에 들어가지 않도록 분리. 완료 표시는 QA 결과 검토 후 관리자 처리 |

STEP_PLAN의 22-P2에 main_menu.gd 변경 가능성이 있으나 이어하기 정책이 미정이므로 이 카드에서는 해당 파일을 읽기 전용으로 좁힌다. 재시작 전체 경로는 정책 결정과 후속 선행 카드가 필요하다. 이를 이유로 직접 장면 로드 검사를 전체 흐름 통과로 간주하지 않는다.

## 수정하면 안 되는 범위

- COMMON_OPERATIONS_TEMPLATE.md, 기존 사용자 변경의 원복·정리·일괄 스테이징.
- 원본 PNG/SVG 및 .import 수동 변경, Sprite 노드 교체, 새 프레임 이미지 생성, 배경 제거.
- project.godot의 시작 장면·자동 로드·입력·해상도, 장면 트리 이름·부모 관계, UI 배치, 기존 scale·rotation.
- game_manager.gd, game_data_factory.gd, save_manager.gd의 데이터·저장 규칙, active_creatures·save_version·시간·레벨·친밀도 필드.
- game.gd의 부화 조건, 플래그 설정 순서, 부화 저장 호출, 알 흔들림, 입력당 친밀도, 판정 주기. Idle 추가에 필요한 호출 외 기존 로직을 재작성하지 않음.
- 새 이어하기 버튼·자동 덮어쓰기 정책, 부화 Timer, 랜덤 이동(STEP 23), 밥주기·도감·전투·새 캐릭터 시스템.
- 허용 범위 밖 오류가 드러나면 원인·영향·필요 파일을 보고하고 해당 복구 단위를 분리한다.

## 선행 STEP 및 의존 기능 / 실행 순서

1. **22-P1**: E02 엔진·STEP 03 장면 전환·05~08 데이터/저장·09~21 알/부화를 재현한다. 처음에는 수정 전 상태를 기록한다. 일반 시작이 막히면 BUG-002를 실패로 기록하고, 별도 테스트 경로의 알·baby 검증을 분리해서 계속할 수 있다.
2. **22-P2**: BUG-002의 신규 진입 누락이 재현되면 위 허용 범위로 복구한다. 기존 저장으로 재시작하는 사용자 흐름은 정책 대기로 남긴다.
3. **22-P3**: 게임 진입 후 아래 시간/레벨 조건표로 알 로직을 확인한다. 오류 수정이 필요한 경우 Idle 변경과 구분한다.
4. **22-A**: P1의 이미지 누락 근거 확보 후 PNG 연결을 복구하고 baby 표시를 확인한다.
5. **22-B**: A의 표시 검증 통과 후 M-004에 따라 Idle을 추가한다. P2의 미정 정책이 남아도 격리된 개체 표시 테스트로 A/B 자체 구현·검증은 가능하다. STEP 전체 완료는 차단된다.
6. **22-C/D**: DEV 보고 → QA 검증 → 관리자 완료 판정. 정상 재시작 흐름 또는 필수 선행 테스트가 미완료면 STEP 상태를 완료로 바꾸지 않는다.

## 구현 요구사항

### R1 — 이미지 연결

Game.tscn에 res://assets/creatures/001/creature_001_idle.png를 Texture2D 외부 리소스로 선언하고 PetArea/CreatureSprite.texture에 연결한다. 외부 리소스 ID는 장면 내 미사용 ID를 쓰며 삭제된 옛 경로·옛 UID를 재사용하지 않는다. 현재 .import의 UID는 uid://bvxbd2giroe7m이나 실제 엔진 로드에서 확인한다. Scene의 나머지 노드·속성은 유지한다. PNG 전체를 사용하며 hframes/vframes나 AnimatedSprite2D를 도입하지 않는다.

### R2 — Idle 상태와 수치

game.gd에 전용 Tween 참조(예: creature_idle_tween), 기준 로컬 위치(예: creature_idle_base_position), 진폭 4.0 및 편도 시간 1.0초 상수를 둔다. _ready에서 기존 데이터 복원·화면 갱신 전에 CreatureSprite.position을 한 번 캡처한다. 반복 시작 때 현재 애니메이션 위치를 기준으로 다시 저장하지 않는다.

기준 위치 → Vector2(기준 x, 기준 y-4.0) 1.0초 → 기준 위치 1.0초, 두 구간 모두 SINE/EASE_IN_OUT, 무한 반복이다. 한 주기는 2.0초이며 PetArea 전체를 움직이지 않는다. scale·rotation·x·저장 데이터에 쓰지 않는다.

### R3 — 시작 조건과 중복 방지

start_creature_idle()은 현재 개체가 비어 있지 않고 stage가 정확히 baby이며 CreatureSprite가 표시되고 texture가 있을 때만 시작한다. 실행 중인 유효 Idle Tween이 있으면 즉시 반환한다. 종료되거나 무효한 참조는 정리하고 기준 위치에서 새 루프를 만든다. game.gd의 create_tween()으로 장면 수명에 묶는다.

update_creature_visual()에서 기존 non-egg 표시·알 Tween 정지 후 baby에만 이 함수를 호출한다. _finish_hatch의 화면 갱신 시점은 아직 hatch_in_progress=true이므로 이 플래그를 Idle 시작 차단 조건에 넣지 않는다. baby 전환 후 빛 효과가 사라지는 동안 Idle이 시작되는 것이 이 카드의 기대 동작이다.

### R4 — 정지 및 상태 복원

stop_creature_idle()은 유효한 Tween을 kill하고 참조를 null로 비우며 CreatureSprite.position을 캡처한 기준으로 복원한다. 반복 호출해도 안전해야 한다. egg 화면 분기에서는 기존 알 로직을 실행하기 전에 정지한다. 비어 있는 개체 또는 baby가 아닌 기타 상태에도 정지한다. 기타 non-egg 상태의 기존 표시 동작은 그대로 둔다.

load_current_creature()의 기존 빈 데이터 return 경로에도 Idle 정리만 추가한다. 기존 오류 메시지·UI 정책은 바꾸지 않는다. _exit_tree()에서 전용 Tween을 정리하되 노드 유효성 확인 후 접근한다. 다른 알/빛 Tween을 Idle 정리 함수에서 조작하지 않는다.

### R5 — 복원과 반복 갱신

기존 _ready → restore_game_data_if_needed → load_current_creature → update_creature_visual 경로로 baby 복원 시 바로 시작되게 한다. 별도 저장 값이나 Idle 진행률을 저장하지 않는다. 화면 갱신을 20회 호출해도 실행 중인 Tween은 한 개이고, 중간 위치가 새 기준이 되지 않아야 한다.

### R6 — 기존 동작 보존

부화는 기존 GameManager.hatch_creature(0)와 SaveManager 호출을 유지한다. 입력·레벨업·egg_created_at·hatched_at 값을 Idle 때문에 바꾸지 않는다. 60초/레벨 2 상수를 테스트 편의로 수정하지 않는다. 별도 테스트 fixture에서 시간·레벨 조합을 만들고 원본 게임 규칙으로 검사한다.

## 완료 조건

| ID | 조건 | 판정 근거 |
|---|---|---|
| AC1 | PNG 로드와 캐릭터 표시 | 부화 직후·baby 복원 화면, 리소스 오류 없음 |
| AC2 | baby Idle이 2초 주기로 반복, egg에는 없음 | 10초 이상 관찰 및 로컬 위치 측정, x/scale/rotation 불변 |
| AC3 | 반복 갱신·정지·재진입에 중복/위치 누적 없음 | 20회 갱신, 상태 전환, 장면 재생성 검사 |
| AC4 | 기존 알 입력·레벨·부화 조건·빛 효과 유지 | 조건표와 입력 회귀 결과, 전환 1회 및 저장 확인 |
| AC5 | 정상 시작·재실행 복원 전체 흐름 통과 | 시작 장면부터 QA 재현. 직접 Game 장면 실행 결과로 대체 불가 |
| AC6 | 수정 범위·저장 보존·보고 완료 | 변경 파일 검토, 원본 저장 보존 증거, DEV/QA 결과 및 관리 문서 반영 |

AC1~4 통과는 부분 구현 결과다. AC5가 BUG-002 또는 정책 미정으로 막히면 STEP 22 전체를 완료하지 않는다.

## DEV 자체 테스트 항목

테스트 전에 별도 복사본/테스트 전용 환경을 만들고, 그 환경에서 해석한 user://의 절대 위치가 원본 게임 저장 위치와 다른지 로그로 확인한다. 복사본 경로만 다르면 저장도 격리됐다고 가정하지 않는다. 경로 격리 방법과 결과를 DEV 보고에 남긴 뒤 저장 테스트를 시작한다. 원본 project.godot와 SaveManager는 수정하지 않는다.

| ID | 실행 입력·시나리오 | 기대 결과 |
|---|---|---|
| T01 | 실제 Godot 버전 및 테스트 프로젝트 import/로드 | GDScript 파싱·리소스 로드 오류 없음. 헤드리스만 통과하면 화면은 미검증 |
| T02 | 원본과 다른 user:// 확인 후, 저장 없는 상태로 MainMenu → 이름 입력 → 확인 | 수정 전 전환 누락 기록, P2 복구 후 Game 진입. 빈 이름은 유지, 저장 실패는 전환하지 않음 |
| T03 | 팩토리 기반 정상 egg, 친밀도 0/목표 10, 마우스 입력 1회 및 총 10회 | 1회당 +1, 10회 후 레벨 2·친밀도 0·다음 목표 13. 60초 미만이면 미부화 |
| T04 | egg 시간 0초/레벨1, 0초/레벨2, 120초/레벨1, 120초/레벨2 네 fixture | 앞 세 개 미부화, 마지막만 기존 판정 호출에서 부화. 시간과 레벨 각각의 조건 검증 |
| T05 | 레벨 2를 먼저 만든 뒤 무입력으로 60초 경과 후 추가 터치 | 무입력 자동 판정 부재를 BUG-003 관찰로 기록. 추가 터치 후 기존 판정 실행. Timer 추가 금지 |
| T06 | 실제 부화 전환 및 효과 중 반복 입력 | egg 숨김·baby 표시·알 터치 비활성, 부화 처리 1회, Idle 시작 누락 없음 |
| T07 | 정상 baby를 저장 후 종료, 테스트에서 Game 복원 경로 실행 | 이미지와 Idle 자동 시작, 저장 version/필드 보존. 사용자 시작 경로 검사와 구분 |
| T08 | baby Idle 10초 관찰, 20회 화면 갱신 | y는 기준-4~기준 범위, 주기 2초, Tween 중복 없음; x/scale/rotation 불변 |
| T09 | 테스트 메모리에서 baby→egg 및 빈 데이터로 갱신, 정지 2회, 새 장면 재진입 | Idle 종료·기준 위치 복구·해제 후 접근 오류 없음. 원본 저장에는 fixture를 쓰지 않음 |
| T10 | 마우스와 가능한 ScreenTouch 입력 비교, 게임 종료 로그 | 기존 입력 횟수 유지, 관련 오류 없음. 실제 터치 기기 미사용이면 QA에 미검증 전달 |

부화 데이터는 팩토리 결과를 복제해 stage/level/egg_created_at만 시나리오에 맞게 바꾸고, 목표 친밀도는 양수로 유지한다. BUG-004의 0 임계값 무한 반복 가능성 테스트는 이 카드에서 실행하지 않는다. save 실패 검증은 격리 환경에서만 수행하며 실제 저장 폴더 권한을 변경하지 않는다.

## QA 검증이 필요한 항목

- Q01: DEV와 별도로 시작 화면부터 신규 게임·친밀도·부화·Idle을 재현하고 화면 증거를 확보한다.
- Q02: 캐릭터가 빛 효과 뒤 실제로 보이며 원본 이미지가 잘리거나 다른 UI를 가리지 않는지, 움직임이 끊기지 않는지 확인한다. 원본 배경 영역은 기존 자산 특성으로 구분한다.
- Q03: 정상 재시작 경로에서 baby 상태가 복원되고 Idle이 즉시 시작되는지 확인한다. 이어하기 정책/진입 경로 미해결 시 BLOCKED로 기록한다.
- Q04: 마우스 입력과 사용 가능한 실제 터치 환경을 검증한다. 미제공 기기의 결과를 통과로 쓰지 않는다.
- Q05: AC1~6 및 T01~10 증거를 대조하고, 코드 차이에서 입력·저장·알 연출 변경이나 허용 범위 이탈 여부를 확인한다.

## 예상 영향 범위

직접 영향은 캐릭터 이미지 연결과 baby의 시각적 위치뿐이다. 기존 화면 갱신·부화 완료·복원 진입점에 연결하므로 이 경로들의 회귀 검증이 필요하다. P2 신규 장면 전환은 별도 선행 흐름 변경이다. 저장 형식, 친밀도, 레벨, 부화 시각, 다른 STEP 기능에는 변경을 주지 않는다.

## 알려진 문제 또는 주의사항 / BLOCKER

| 항목 | 영향 / 처리 |
|---|---|
| BUG-001 | 표시 누락, 22-A에서 복구·검증 대상. 이번 준비 작업에서 해결 처리하지 않음 |
| BUG-002 | 신규 게임 진입 및 재시작 통합 검증 차단. 신규 진입 수정 지침은 위에 정의, 이어하기 정책 결정은 관리자/사용자에게 남김 |
| BUG-003 | 자동 부화 여부 미정. 현행 조건표를 검증하고 동작 변경 금지. 자동 부화가 필수로 확정되면 선행 복구 카드 필요 |
| BUG-004 | 잘못된 저장에서 멈춤 가능성. 정상 fixture 사용, 발견 시 저장 안정화 복구 단위로 분리 |
| M-001/M-002 | 과거 완료 이력·문서 부재·범위 차이 유지. PROJECT_SPEC 부재가 현재 한정된 이미지/Idle 지침을 막지는 않지만 미정 게임 규칙은 결정 금지 |
| M-003/M-004 | 연출 선택은 M-004로 구체화됨. DEV에게 연출 방식 선택을 다시 맡기지 않음 |
| 선행 실행 증거 없음 | P1부터 시작. 코드가 있다는 이유로 이전 STEP 전체 통과 선언 금지 |
| 기존 사용자 변경 | Game.tscn 편집, 이전 이미지 경로 삭제 및 001 폴더 추가가 준비 전부터 존재. 의도를 추정해 되돌리지 않음 |

## 결과 보고 방법

DEV는 docs/reports/STEP_22_DEV_REPORT.md, QA는 docs/reports/STEP_22_QA_REPORT.md에 아래 항목으로 보고한다. 환경·테스트 저장 절대 경로·명령/조작·기대/실제 결과·증거 경로·AC/T/Q ID별 통과/실패/미검증/BLOCKED를 포함한다. 기존 문제와 새 회귀 문제를 구분한다.

```text
[현재 STEP]
[수행한 작업]
[수정한 파일]
[테스트 결과]
[발견된 문제]
[보류 사항]
[다음 STEP]
[MASTER 갱신 내용]
```

관리자용 PROJECT_STATE 갱신 문안: “STEP 22 구현 준비와 S22-DEV-001 카드 작성 완료. 22-P1 준비 완료, 전체 STEP은 선행 검증 대기. M-004로 기존 PNG/Sprite2D/Tween의 상하 Idle 지침을 기록했다. BUG-001/002 해결 및 통합 실행 증거는 아직 없다. 다음 DEV 작업은 docs/tasks/STEP_22_DEV.md의 P1이며, 이번에 구현 코드는 수정하지 않았다.”
