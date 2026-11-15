# STEP 26 DEV 보고서

2026-09-29 / S26-DEV-001 / 사용자 M-011 A안 / **DEV PASS**.

## 구현

제품 변경은 scripts/game/game.gd 하나다. 유효 요청에서 feeding_busy와 단일 Tween을 시작한다. 기존 x를 유지한 채 랜덤 이동만 일시정지하고 중앙까지60px/초로 이동, 접근 중 기존 Idle 유지, 도착 시 Idle 중지 후 y기준+6px/복귀 각0.2초3회, 음식0.2초 페이드아웃 후 숨김·알파복원·평소 이동/Idle 재개한다. 연출 중 요청은 무시하며 버튼도 비활성이다. 자격 검사와 busy를 분리하여 먹는 동안 음식이 숨겨지는 문제를 방지했다.

자격 상실 갱신 및 진행 중 프레임 검사, 장면 종료에서 Tween을 kill하고 상태·위치·음식을 정리한다. 비동기 대기 함수를 두지 않아 취소된 연출의 대기 완료가 새 상태를 덮어쓰지 않는다. 기존 원본 이미지·방향·scale·rotation과 고정 그릇은 그대로이며 친밀도/저장 호출은 추가하지 않았다.

## 검증

Godot 4.7.2.stable.official.ed1daf0bf / Windows headless 및 OpenGL Compatibility Intel Iris Xe. tests/step_26/run_dev.ps1을 정식 실행 권한으로 실행. temp 프로젝트·고유 custom_user_dir 사용, 사용자 원본 저장 미접근. 저장 fixture 성공/비어 있지 않은 hash를 확인한 후 불변 검사.

| 검사 | PASS |
|---|---:|
| 신규 headless | 63 |
| 별도 프로세스 정상 메뉴 복원 | 4 |
| 평소 이동 회귀 | 19 |
| 기존 메뉴 회귀 | 52 |
| egg/baby/hatch seed·별도프로세스 복원 | 20 |
| 렌더 기능 반복·4PNG 캡처 | 67 |
| 합계 (환경 반복·fixture 포함) | **225** |

전 실행 native exit0, FAIL·SCRIPT ERROR0. 메뉴의 오류 주입 로그는 기대한 회귀 동작이다.

- AC1: 엔진 Tween.custom_step으로 양끝/중앙 접근 속도·시간,3회6px 왕복, 페이드 중간값0.5·종료0.2초 확인. 실제 시간의 접근/먹기/완료 및 원본 외형 보존 확인. 405 접근/먹기,720 먹기/완료 PNG4장 직접 시각 확인, UI와 겹침 없음.
- AC2: egg/부화fade/빈 데이터 거부,10회 중복·100회 갱신 동일Tween, 실제 UI좌표·Space 시작 확인.
- AC3: 접근/몸짓/페이드 취소·transform복구, 장면종료Tween해제·재진입숨김, 기존 사이클 최대시간 이상 대기 후 부활 없음, 평소 이동/Idle 복귀. 별도프로세스 정상 메뉴 복원 시 음식/먹기 상태 초기화.
- AC4: 요청·완료·취소 전후 메모리와 저장hash 불변, 사본5파일 해시 일치. 신규 테스트는 승인 정책을 사용하며 이전24/25기대값 파일은 수정하지 않았다.

증거: step_26/dev_paths.json, dev_summary.json, dev_source_comparison.json, dev-d34781c484ba457cafb2328433d2a043 실행 폴더의 results.json·로그·PNG. DEV 단계 제품수정 재시도 없음. 독립 QA 판정은 별도 보고서에 남긴다.

물리 입력·실기기터치·체감 자연스러움은 비차단 사용자 확인이며 합성 UI입력/엔진수치/렌더와 구분한다. 기존 BUG-003/004 후속 유지. STEP27 친밀도는 미구현·미착수.
