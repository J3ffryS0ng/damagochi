# STEP 22 독립 QA 보고서

검증일: 2026-09-13 · 대상: S22-DEV-001, 현재 작업 폴더의 미커밋 구현 · 담당: QA

## [QA 판정]

**PASS WITH ISSUE**

캐릭터 이미지 연결, baby Idle, 중복 방지·정리·직접 Game 복원 및 BUG-002의 신규 저장 후 진입 수정은 실행 검증을 통과했다. STEP 22에서 도입한 제품 결함은 이번 검사에서 발견하지 못했다.

다만 **작업카드 AC5의 일반 재시작 → 기존 baby로 플레이 재개는 FAIL / BLOCKER**다. 기존 메뉴가 baby 데이터를 읽어도 시작 버튼은 NameEntry로 이동한다. 이는 기존 진입 경로·정책 문제이며 Idle 구현 자체의 FAIL 사유로 혼동하지 않는다. 이 판정은 STEP 전체 완료 선언이 아니다. 관리자 완료 처리는 보류를 권고한다.

MASTER.md, STEP_PLAN.md, BUG_LOG.md, DECISION_LOG.md, docs/tasks/STEP_22.md, docs/tasks/STEP_22_DEV.md, DEV 보고서를 읽고 실제 변경 코드와 대조했다. DEV의 과거 실행 결과를 그대로 인용하지 않고 DEV 테스트를 새 환경에서 재실행하고 별도 QA 테스트를 추가했다.

## [Godot 검증 환경]

| 항목 | QA 확인 결과 |
|---|---|
| 원본 프로젝트 | J:/2026/Github/damagochi |
| 실행 파일 | C:/Godot/Godot_console.exe |
| 독립 버전 조회 | 4.7.2.stable.official.ed1daf0bf |
| 프로젝트 호환성 | config/features 4.7, 기존 MainMenu UID·자동 로드 유지. 깨끗한 사본 import 성공, 정상 경로에 파싱·참조·리소스 오류 없음 |
| 실제 렌더러 | OpenGL API 3.3.0, Compatibility, Intel Iris Xe, 드라이버 32.0.101.5542 |
| 화면 | 논리 해상도 720×1280, 캡처 405×720 |
| 실행 방식 | headless 회귀 + 실제 OpenGL 렌더링 QA + 별도 프로세스 복원 + 테스트 스크립트 없는 기본 시작 실행 |
| 테스트 사본 | C:/Users/syj_1/AppData/Local/Temp/damagochi-step22-218f440bcc104c67be1d69b42d9937b9/ |
| 원본 user:// | C:/Users/syj_1/AppData/Roaming/Godot/app_userdata/damagochi/ |
| 테스트 user:// | C:/Users/syj_1/AppData/Roaming/damagochi-step22-218f440bcc104c67be1d69b42d9937b9/ |

저장 작업 전 원본 경로 probe와 테스트 엔진의 user:// 로그를 확인했다. 복사본의 custom user directory만 변경했으며 원본 project.godot와 모든 SaveManager 코드는 변경하지 않았다. Godot 캐시·격리 저장·렌더 창 실행은 실행 권한 승인 후 수행했다.

원본 savegame.json의 QA 실행 전후 SHA256은 모두 `E5F0C0FE37F6F110FEF2E3FDCC3DB12A73F8BB765A76E10DB0EE02E1E232037D`로 동일했다. 제품 코드·PNG 8개 파일은 원본과 실행 사본 SHA256 일치를 확인했다: [source_hashes.json](step_22_qa/source_hashes.json).

실행 및 증거:

1. 프로젝트 루트에서 `./tests/step_22/run.ps1` 실행. 새 사본 import → DEV verify.gd → 새 프로세스 렌더 복원 전체 종료 코드 0.
2. QA가 별도 작성한 `tests/step_22/qa_verify.gd`를 위 사본 루트에 복사하고 `C:/Godot/Godot_console.exe --path <사본> --script res://qa_verify.gd --log-file <QA 로그>` 실행. 종료 코드 0.
3. 동일 명령에 `-- restart`를 붙여 새 프로세스 검사. 종료 코드 0. 그 뒤 `--path <사본> --quit-after 90`으로 기본 시작 설정을 그대로 실행, 종료 코드 0.
4. QA 테스트는 기존 tests/step_22/.gdignore 아래에 보관하며 제품 시작 설정에 연결하지 않았다. 재실행은 고유한 테스트 사본에서만 한다. QA 테스트는 해당 사본의 저장을 초기화한다.

DEV 재실행 증거 디렉터리: [새 실행 로그](step_22/damagochi-step22-218f440bcc104c67be1d69b42d9937b9/verify.log). QA 증거: [렌더 검사](step_22_qa/independent_render.log), [새 프로세스 검사](step_22_qa/independent_restart.log), [기본 시작](step_22_qa/default_start.log).

## [STEP 22 완료 조건별 결과]

| ID | 상태 | 기대 / 실제 결과 및 제한 |
|---|---|---|
| AC1 PNG 로드·캐릭터 표시 | PASS | 현재 001 PNG와 UID가 연결됨. 부화 빛 효과 뒤 및 프로세스 종료 후 직접 Game 복원에서 실제 이미지 캡처·시각 확인 |
| AC2 baby 전용 2초 Idle | PASS | DEV 재실행 10.10초 수치 검사 + 독립 실제 렌더 10.217679초/615 샘플. y=-4.0~약 0, x/scale/rotation/PetArea 불변. egg에는 Idle 없음 |
| AC3 갱신·정지·재진입 | PASS | DEV 20회 갱신 및 QA 매 프레임 20회 갱신에서 같은 Tween 1개. baby→egg/기타/빈 개체 정리, 반복 stop, 장면 종료/재생성 통과. (11,17) 비영점 기준 위치 복원도 확인 |
| AC4 기존 알·레벨·부화·빛 효과 | PASS (엔진·합성 입력) | 친밀도, 네 시간/레벨 조합, 부화 중 입력 차단, 단일 전환·부화 시각·저장 및 빛 알파 복귀 통과. 실제 OS 마우스/터치 조작은 미검증 |
| AC5 정상 시작·재실행 전체 흐름 | FAIL / BLOCKER | 신규 진입 성공. 새 프로세스 MainMenu는 baby를 읽지만 시작 버튼은 NameEntry로 이동. 직접 Game 복원 성공을 AC5 통과로 대체하지 않음 |
| AC6 범위·저장 보존·보고 | PASS (QA 담당 범위) / 미검증 (관리자 반영) | 제품 변경 범위 확인, 원본 저장 해시 보존, QA 보고·증거 작성 완료. MASTER/STEP_PLAN 등 최종 상태 갱신은 WORK-MANAGER 담당 |

R1~R6 코드 대조: Game.tscn은 texture 경로·UID만 변경됐다. game.gd는 _ready에서 기준 위치를 한 번 저장하고 start_creature_idle에서 정확한 baby/visible/texture 및 유효·실행 중 Tween을 검사한다. position Tween은 기준→y-4→기준, 각 1초 SINE/EASE_IN_OUT다. 정지 시 참조를 비우고 유효 Sprite 위치를 복원한다. 부화 플래그로 시작을 막지 않아 부화 완료의 기존 화면 갱신에서 Idle이 시작된다. 다른 상태·빈 개체 및 _exit_tree 정리도 연결돼 있다.

기존 자동 로드, 데이터·저장 코드, 부화 조건·저장 순서, 알 흔들림, 입력 처리, scale/rotation, 장면 트리 및 UI 배치를 변경하지 않았다. 함수·변수·노드·UID 참조 오류 또는 import 누락은 검사 경로에서 발견되지 않았다. 후속 STEP 23이 PetArea를 이동하는 구조와 현재 자식 Sprite의 로컬 Idle은 함께 사용할 수 있다. 향후 동일 Sprite.position을 다른 연출이 변경한다면 정지/재개 조정이 필요하지만 현재 결함은 아니다.

## [BUG-002 검증 결과]

| 검사 | 상태 | 실제 결과 |
|---|---|---|
| 유효 이름·저장 성공·Game 이동 | PASS | MainMenu 시작 버튼 → NameEntry 확인 신호로 Game 진입. QA 별도 Enter 제출 신호도 성공 |
| 이름 저장 | PASS | 앞뒤 공백이 제거된 한글 이름 `QA 독립`이 메모리와 JSON에서 동일 |
| 빈 이름 | PASS | 공백 이름 제출 후 2프레임 기다려도 NameEntry 유지, 저장 없음 |
| 저장 실패 | PASS | 격리 savegame.json 위치에 디렉터리를 만들어 쓰기 실패 유도. 오류 안내 후 2프레임 지나도 NameEntry 유지. 실제 사용자 저장 권한은 변경하지 않음 |
| 기존 육성·부화 | PASS (합성 입력) | 신규 진입한 동일 Game에서 10회 입력으로 레벨업, 시간 fixture 이후 추가 입력으로 부화·Idle·저장 |
| 수정 범위 | PASS | name_entry.gd 저장 성공 이후 change_scene_to_file 및 반환 오류 안내만 추가. main_menu.gd와 기존 새 게임 생성/저장 규칙은 그대로 |
| 장면 전환 자체 실패 | 미검증 | 반환 Error 안내 분기는 코드상 존재. 이번 QA는 별도 장면 로드 실패를 강제하지 않음 |
| 기존 저장 이어하기 | FAIL / BLOCKER | 새 프로세스에서도 시작 버튼 목적지가 NameEntry. 이어하기·덮어쓰기 정책은 추가하거나 변경하지 않음 |

BUG-002는 **신규 진입 누락 부분만 수정 검증 통과**다. 전체 해결로 기록하면 안 된다.

## [회귀 테스트 결과]

DEV 테스트 재실행은 **38 PASS / failures=0**, 별도 restore 모드도 종료 코드 0. 독립 QA 렌더 검사는 **23 QA_PASS / failures=0**, 새 프로세스 검사는 **8 QA_PASS / failures=0**다. 이 수치는 장면 로드·캡처·기존 제약 재현 assertion도 포함하며 모든 제품 요구가 통과했다는 뜻이 아니다. 특히 `existing restart limitation reproduced`는 결함 재현 성공이지 AC5 통과가 아니다.

| 작업카드 테스트 | 상태 | QA에서 확인한 내용 |
|---|---|---|
| T01 | PASS | 버전, import, UID, 장면 로드, 실제 OpenGL 렌더, 기본 시작 |
| T02 | PASS (합성 UI 신호) | 정상/빈 이름/저장 실패, 확인 버튼 및 Enter 제출, 지연된 잘못된 전환 없음 |
| T03 | PASS (합성 입력) | 1회 +1, 총 10회 level=2/affection=0/목표=13, 60초 전 egg 유지 |
| T04 | PASS | age=0/level1, age=0/level2, age=120/level1은 미부화. age=120/level2만 부화 |
| T05 | PASS (기존 동작 관찰) | 실제 60.2초 무입력 후 egg·부화 미시작, 추가 입력 후 baby. 자동 부화 기능 통과가 아님 |
| T06 | PASS (엔진·렌더) | 부화 중 반복 입력 20회 무반영, 재판정 후 시각 불변, 알 숨김/터치 비활성/빛 소멸/Idle 시작 |
| T07 | PASS (직접 Game) / FAIL (일반 이어하기) | 별도 프로세스에서 baby 전체 개체 필드·이미지·Idle 복원. 일반 시작은 AC5 참조 |
| T08 | PASS | 4픽셀·2초 수치 검사 및 실제 렌더 장기 샘플링. 각 프레임 x/scale/rotation/PetArea·저장 데이터 보존 |
| T09 | PASS | 상태 변경, 빈 개체, 반복 정지, 장면 해제·재진입. 추가로 paused Tween 교체와 숨김/texture 없음 시작 차단 통과 |
| T10 | PASS (합성 입력) / 미검증 (실기기) | MouseButton 및 ScreenTouch 신호 처리 통과. 실제 포인터 hit testing·OS 마우스·기기 터치 미검증 |

DEV 로그의 저장 실패·빈 데이터 push_error 2건, QA 렌더 로그의 저장 실패 push_error 1건은 의도한 예외 테스트 결과다. 새 프로세스 복원·기본 시작의 정상 경로에는 해당 오류나 다른 스크립트 오류가 없었다. 잘못된 저장의 0 임계값 무한 반복 가능성(BUG-004)은 카드 지침대로 실행하지 않았다.

## [시각 검증 결과]

실제 Godot viewport가 렌더한 PNG를 QA가 열어서 확인했다. DEV의 기존 캡처를 대신 사용하지 않았다.

| 대상 | 상태 | 관찰 및 증거 |
|---|---|---|
| 신규 알 | PASS | [새 게임 알](step_22_qa/qa_new_egg.png), 캐릭터 미표시 |
| 부화 빛 효과 | PASS | [빛 효과](step_22_qa/qa_hatch_flash.png), 알 위 화면 밝아짐 |
| 부화 후 baby | PASS | [부화 직후](step_22_qa/qa_hatched_baby.png), 캐릭터 표시·알 숨김 |
| Idle 상하 움직임 | PASS (수치·프레임 비교) | [위 위치](step_22_qa/qa_idle_up.png), [기준 위치](step_22_qa/qa_idle_base.png). 논리 4px가 405px 창에서 약 2.25px 이동에 해당 |
| 화면 밖·위치 이상·잘림 | PASS (현재 크기) | 두 끝점 및 부화/복원 캡처에서 잘림·화면 이탈·상단/하단 UI 겹침 없음 |
| 프로세스 종료 후 표시 | PASS (직접 Game) | [QA 복원 화면](step_22_qa/qa_restored_baby.png), baby 표시와 Idle 자동 재개 |
| 연속 움직임의 체감 품질 | 사용자 확인 필요 | 연속 위치 데이터와 끝점 프레임은 검증했으나 사람이 실제 플레이하며 느끼는 자연스러움·OS 프레임 끊김 평가는 대체하지 않음 |

독립 측정: 10.217679초/615 프레임, y=-4.0~약 -0.00000004. 상단 근처(y<-3.99) 진입 간격은 2.015937, 2.003126, 1.995630, 1.998857초로 2초 주기와 일치하는 프레임 단위 측정이다. DEV 수식 검사의 최대 오차도 약 0.000564px였다. [원시 위치 CSV](step_22_qa/qa_positions.csv), [측정 요약](step_22_qa/measurements.json).

PNG의 흰 사각형 배경은 원본 자산 특성으로 남아 있다. 카드가 배경 제거를 금지했으므로 신규 결함으로 판정하지 않는다.

## [사용자 확인 필요 항목]

- **사용자 환경 검증 필요:** 실제 마우스로 MainMenu→이름 입력→알 클릭→부화까지 진행. 이번 입력은 버튼/Area2D 신호 및 text_submitted 신호로 실행했으며 물리 클릭 위치 판정을 검증하지 않았다.
- **사용자 환경 검증 필요:** 실제 모바일 터치 1회당 입력 횟수, 클릭/터치 영역, 기기 화면 크기 대응. 사용 가능한 실제 터치 기기 검증은 수행하지 않았다.
- **사용자 확인 필요:** Idle의 체감 자연스러움과 기존 흰 배경 표시의 디자인 수용 여부. 정해진 수치와 원본 자산 유지 조건은 통과했다.
- **사용자 확인 필요:** 기존 저장이 있는 시작 화면의 이어하기/새 게임 정책. QA는 어느 정책도 임의로 선택하지 않았다.

Q01은 합성 시작 흐름·렌더 증거 PASS/실제 마우스 미검증, Q02는 화면 배치·부화 뒤 표시 PASS/체감 품질 사용자 확인 필요, Q03은 일반 재시작 FAIL/BLOCKER, Q04는 실기기 미검증, Q05는 코드·AC/T 대조 PASS다.

## [기존 문제 / 신규 문제]

| 항목 | 분류 | 이번 판정 / 후속 |
|---|---|---|
| BUG-001 이미지 누락 | 기존 문제 수정 | 부화/복원에서 해결 검증 통과 |
| BUG-002 신규 진입 | 기존 문제 수정 | 저장 성공 후 Game 전환 검증 통과 |
| BUG-002 일반 이어하기 | 기존 미해결 | AC5 통합 완료 BLOCKER. 정책 결정과 별도 수정 후 재검증 필요 |
| BUG-003 무입력 자동 부화 부재 | 기존 동작·요구 미정 | 독립 실행으로 재확인. 카드가 현행 동작 유지와 Timer 추가 금지를 명시하므로 STEP 22 구현 BLOCKER 아님 |
| PROJECT_SPEC.md missing | 기존 문서 부재 | 실제 Test-Path 결과 False. M-004/R1~R6가 이번 한정 요구를 제공하므로 현재 Idle 검증 BLOCKER 아님. 명세 정리는 별도 후속 |
| BUG-004 잘못된 저장 | 기존 잠재 문제 | 이번 정상 fixture 검증 범위 밖, 강제 실행하지 않음 |
| 메뉴 버튼 미연결·부화 저장 실패 복구 부족 | 이전 QA 발견·기존 코드 유지 | 이번 Idle/신규 진입 수정으로 생긴 문제가 아님. 이번에는 별도 재현을 반복하지 않았으며 후속 검토 대상으로 유지 |
| STEP 22 신규 제품 결함 | 신규 문제 | 이번 검사 범위에서 발견 없음 |

## [STEP 22 완료를 막는 BLOCKER]

**B-01 — 일반 시작 경로에서 저장된 baby 플레이를 재개할 수 없음.**

재현: 정상 baby 저장 → 프로세스 종료 → 기본 MainMenu 시작 → GameManager에 baby 복원 확인 → 시작 버튼 → NameEntry로 이동. `scripts/main/main_menu.gd:64`의 목적지가 NameEntry로 고정돼 있다. 화면 진입을 우회한 직접 Game 테스트는 성공하지만 작업카드 AC5/Q03을 충족하지 못한다.

이는 현재 이미지·Idle 구현의 결함은 아니지만 사용자의 정상 재시작과 STEP 전체 통합 완료를 실제로 막는다. 정책 확정 후 WORK-MANAGER가 필요한 수정 범위를 별도 카드로 지정해야 한다. QA는 새 이어하기 버튼·덮어쓰기 정책·시작 장면 변경을 제안 구현하거나 적용하지 않았다.

실제 마우스/터치 검증은 실패가 아니라 검증 공백이다. 지원 환경의 필수 확인 범위를 관리자가 정하고 사용자 환경 증거를 확보해야 한다.

## [WORK-MANAGER에 전달할 최종 권고]

1. STEP 22의 이미지·Idle 구현 및 BUG-002 신규 진입 수정은 QA 통과 근거를 채택할 수 있다. 기존 전체 STEP 21 FAIL 결과의 이미지 누락은 이번 실행에서 해소됐다.
2. 최종 QA 의견은 **PASS WITH ISSUE**, 전체 완료 표시는 AC5 해결 및 필수 사용자 환경 검증 전까지 보류를 권고한다. 이어하기 정책을 확정하고 허용된 수정 후 일반 시작부터 baby 복원까지 재검증한다.
3. BUG-003과 PROJECT_SPEC 부재는 별도 후속으로 유지한다. 이를 근거로 현재 Idle 코드를 FAIL 처리하거나 임의로 게임 동작을 바꾸지 않는다.
4. MASTER.md, STEP_PLAN.md, BUG_LOG.md, DECISION_LOG.md, PROJECT_STATE.md 및 완료 체크는 QA가 갱신하지 않았다. COMMON_OPERATIONS_TEMPLATE.md도 변경하지 않았다. 최종 상태 확정과 관련 문서 반영은 WORK-MANAGER가 수행한다.

QA 추가 산출물은 이 보고서, `tests/step_22/qa_verify.gd`, `docs/reports/step_22_qa/` 증거와 DEV 테스트 재실행으로 생성된 고유 로그 디렉터리뿐이다. 제품 코드 수정·스테이징·커밋은 하지 않았다.
