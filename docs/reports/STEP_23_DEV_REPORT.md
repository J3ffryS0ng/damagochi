# STEP 23 DEV 보고서

날짜: 2026-09-28 / 카드: S23-DEV-001 실행 확정 절 / 판정: **DEV PASS, 독립 QA 인계**.

## 구현

제품 변경은 scripts/game/game.gd 하나다. baby는 초기 중심에서 ±120px 내 무작위 목적지로 60px/초 이동하고 도착 후 1~3초 대기한다. 랜덤 생성기는 장면 인스턴스에 속한다. 이미지 반전·scale·rotation 변경 없음. 이동은 position.x, 기존 Idle Tween은 position.y만 제어한다. PetArea·알 입력 영역·UI는 이동하지 않는다.

단일 _process와 active 플래그로 중복 시작을 막고, egg/기타 stage/빈 데이터/장면 종료에서 정지 및 기준 x 복원한다. 재진입 시 장면 기준점에서 다시 시작한다. move_toward로 프레임 지연에도 목적지 초과를 막는다. 저장이나 게임 수치·부화 판정을 이동 처리에서 호출하지 않는다. Game.tscn·공용 저장 코드·데이터 계약은 그대로다.

## 자체검증

실행: tests/step_23/run_dev.ps1. Godot 4.7.2.stable.official.ed1daf0bf, headless 및 Windows OpenGL Compatibility(Intel Iris Xe) 실제 렌더. 프로젝트를 임시 경로에 복사하고 별도 custom_user_dir을 사용했다. 실제 사용자 savegame.json은 전후 SHA256 일치.

최종 실행 증거 폴더: docs/reports/step_23/damagochi-step22-resume-step23-dev-ceba8ff8236449668f7f5c7a494423ae/. 실행 경로: step_23/dev_paths.json. 집계: step_23/dev_summary.json. 제품 대조: step_23/dev_source_comparison.json(game.gd 포함 테스트 사본과 동일, 격리 경로를 추가한 project.godot만 의도적 차이).

| 조건 | 자체 판정 | 근거 |
|---|---|---|
| AC1 | PASS | 60px/초 계측, 20초 delta에서 목적지 초과 없음, 1~3초 대기, 10분 모의 시간의 양방향·다양한 목적지·경계·속도 검사, 텍스처 전체 화면 경계 검사 |
| AC2 | PASS | 실제 6.5초 x 이동과 y -4~0 진동, 원본 방향·크기·회전·알 영역 유지. dev_baby.png 및 dev_positions.csv |
| AC3 | PASS | egg 정지, 100회 갱신 단일 Tween·목적지 유지, stage/빈 데이터 정리, 장면 해제·재진입, 반복 정지 |
| AC4 | PASS (자동화 입력 범위) | 기존 회귀 38, 메뉴 suite 52, 별도 프로세스 egg/baby/hatch 복원 4/8/5, 기존 독립 검사 재실행 32 PASS. 이동 중 메모리·저장 해시 불변 |
| AC5 | DEV 증거 확보 | 사용자 저장 해시 보존, 로그·스크립트·제품 해시, 범위 준수. 최종 문서 통합과 QA 판정은 MANAGER 후속 |

신규 DEV 검사는 headless 19 PASS, 렌더 실행 19 PASS이며 같은 시나리오의 두 환경 재실행이다. seed 3건 포함 최종 집계 180 PASS, FAIL/스크립트 오류 0. 저장 실패·빈 데이터 등 회귀 주입의 예상 ERROR는 각 기대 PASS와 구분한다. 60.2초 실제 무입력 대기 후 egg 유지 및 추가 입력 부화로 BUG-003 현행 동작 유지 확인.

과거 verify.gd는 x 고정을 요구하므로 원본은 보존하고 격리 사본에서 해당 비교 1곳만 ±120px 범위 검사로 바꾸었다. 나머지 y 주기·scale·rotation·데이터·상태 회귀는 유지했다. 변경된 비교의 로그 라벨에 있는 x unchanged 문구는 과거 라벨이며 실제 기대값은 범위 유지다. QA는 이 적응과 별개로 카드 기준으로 독립 검증해야 한다.

## 초기 검사 보정·제한

첫 DEV 실행 a061d09c80644e7d8f09ea6b274facec에서 egg Tween을 kill한 동일 프레임에 트리 Tween 개수를 세어 1건 실패했다. 제품 중복이 아니라 엔진의 다음 프레임 제거 시점이었다. 검사에 2프레임 대기 후 동일 객체/목적지/개수 검증을 추가하고 전체 재실행했다. 제품 코드 수정 없이 통과했으며 초기 로그 보존. QA 이후 자동 수정 횟수는 0회다.

실제 마우스 전체 신규 이름→알 클릭→부화 플레이, 물리 터치·기기별 화면·체감 자연스러움은 사용자 환경 확인으로 유지한다. 자동화 입력은 실제 물리 입력 통과로 확대하지 않는다. 기존 BUG-003/004 및 쓰기 도중 장애 한계는 이번 범위 밖이다. STEP 24 구현 없음.
