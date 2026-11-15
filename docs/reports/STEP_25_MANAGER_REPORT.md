# STEP 25 MANAGER 조사 — 결정 대기

2026-09-29 / WORK-ORCHESTRATOR / S25-DEV-001 / 구현 전 중단.

사용자 “step 25 시작해”로 실행 상한을 STEP 25까지 연장했다. MASTER·STEP_PLAN·BUG_LOG·DECISION_LOG·공통 템플릿, docs/tasks·reports, 실제 game.gd·Game.tscn·GameManager·SaveManager·project.godot·assets를 조사했다. 프로젝트 및 상위 경로에서 적용할 AGENTS.md는 발견하지 못했다.

## 선행 근거

STEP 24 최종 보고는 PASS이며 DEV 216·독립 QA 171 PASS는 그 STEP의 기존 근거다. 이번 STEP 25에서 새 실행한 수치가 아니다. 현재 파일 해시가 STEP 24 qa_source_comparison.json과 일치한다.

- game.gd: 56CC9AEA601ACCF13A52A17B4C9E5645A3B565D5C25BCA66B7225BB0066EF858
- Game.tscn: 223144F09FE2CF8EFCE862F60723C9C7C683E6333A8493935106F8D56B640E90

현재 feed_requested 신호는 연결 지점만 있고 음식 표시 구현은 없다. assets에는 알·캐릭터 이미지가 있으며 음식 자산은 없다. 논리 화면은 720×1280, PetArea 중심 (360,650), M-008 가로 이동 ±120px, 하단 버튼 y1160~1240이다. 저장 매니저는 전체 게임 데이터를 기록하며 음식 필드는 없다.

## 중단 이유·선택지

계획은 STEP 25 음식 생성/표시, 26 먹기, 27 친밀도로 나누지만 음식 형태·위치·연속 입력·수명 정책이 없다. 사용자 요청의 ‘사용자 경험에 영향을 주는 여러 설계 선택지’ 중단 기준에 해당하므로 M-010과 실행 카드 초안을 작성했다. 구현 오류나 QA FAIL이 아니다.

A 권장: 밥그릇 1개를 (360,900), 최대96×96으로 고정. 캐릭터가 이동해도 그릇은 제자리에 남는다. B: 같은 그릇이 캐릭터 아래에서 가로 이동을 따라간다. 항상 가까이 보이지만 음식도 캐릭터와 함께 이동한다.

공통 제안: 반복 입력에도 1개 유지, 자동 소멸 없음, baby 자격 상실/장면 종료 시 정리, 재진입 시 초기화·저장하지 않음. 이동/Idle 유지, 먹기·친밀도는 후속이다. 원본 캐릭터·저장 형식·부화·버튼 대상 정책에는 변경이 없다. 후속 STEP 26에서 먹기/소멸/이동 관계는 별도 구체화한다.

## 산출물·재개

docs/tasks/STEP_25_DEV.md에 범위·AC1~4·DEV/QA/회귀 검증안을 작성했다. MASTER·STEP_PLAN·PROJECT_STATE·진행표를 시작 요청 수용/결정 대기로 맞추며 DECISION_LOG M-010은 제안으로 기록했다. 제품 코드·기존 자산·저장·기존 작업카드/보고서·COMMON_OPERATIONS_TEMPLATE·BUG_LOG는 수정하지 않았다. STEP 25 DEV/QA 실행 없음, 자동 수정 0회, 신규 BUG 없음.

사용자 결정 후 M-010과 카드 실행 확정 절 갱신 → DEV 구현/검증 → 독립 QA → MANAGER 통합으로 재개한다. STEP 26은 시작하지 않는다. M-007 시험 종료 평가와 기존 역할 작업 정리는 STEP 25 완료 이후의 별도 결정이다.
