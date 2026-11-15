# STEP 25 DEV 보고서

2026-09-29 / S25-DEV-001 / M-010 A안 / **DEV PASS, 독립 QA로 전달**.

## 구현

Game의 FoodSprite는 투명 배경 96×96 밥그릇 SVG를 논리 좌표 (360,900)에 표시한다. 장면 초기값은 숨김이며 기존 feed_requested 신호를 1회 연결하고 baby·부화 빛 종료 자격을 재검사하여 표시한다. 재입력은 같은 노드의 표시만 유지하며 타이머·토글·누적 생성이 없다. 자격 상실 갱신 시 숨기고 장면 소유 노드이므로 종료 시 함께 해제된다. 재진입·별도 프로세스 복원은 숨김으로 시작한다.

변경: scripts/game/game.gd, scenes/game/Game.tscn, 신규 assets/food/rice_bowl.svg. 기존 SVG 자산 로드 방식 사용. 원본 캐릭터·이동/Idle·버튼 활성/요청·메뉴·부화·저장 계약 유지. 음식 접근/먹기/소멸 연출 및 친밀도 증가는 구현하지 않았다.

## 자체검증 결과

Godot 4.7.2.stable.official.ed1daf0bf, Windows headless 및 OpenGL Compatibility Intel Iris Xe. `tests/step_25/run_dev.ps1`로 격리 프로젝트·고유 user 디렉터리 사용. 기존 사용자 저장 파일에 접근하지 않았다. 경로는 step_25/dev_paths.json, 실제 테스트 로그에 기록했다.

| 검사 | PASS |
|---|---:|
| 신규 음식 기능 headless | 28 |
| 별도 프로세스 정상 메뉴 baby 복원 | 5 |
| STEP 24 버튼 회귀 | 21 |
| STEP 23 이동 회귀 | 19 |
| STEP 22 메뉴 회귀 | 52 |
| egg/baby/hatch 별도 프로세스 seed·복원 | 20 |
| 실제 렌더 기능 반복 및 화면 캡처 | 30 |
| 합계 (반복·fixture 포함 단언 수) | **175** |

모든 정식 실행 native exit 0, FAIL·SCRIPT ERROR 0. 메뉴의 잘못된 저장·빈 데이터 의도적 오류 로그는 기존 음성 테스트이며 실패 판정과 구분한다. 두 해상도 PNG 직접 시각 확인: 음식은 캐릭터·상태창·하단 버튼과 겹치지 않고 투명 배경·밥그릇 모양으로 표시된다.

- AC1 PASS: 실제 자산 로드, 크기·위치·투명도 및 405×720/720×1280 렌더 확인.
- AC2 PASS: 좌표 클릭·키보드 Space, 부적격 요청 거부, 10회 요청·100회 갱신에도 동일 노드/단일 신호 연결.
- AC3 PASS: 이동·Idle 병행, stage/빈 데이터 전환, 장면 소멸·재진입, 별도 프로세스 정상 메뉴 복원 후 숨김 및 재표시, 알/부화/버튼 회귀.
- AC4 PASS(DEV 범위): 음식 입력 전후 메모리·저장 바이트 불변, 저장 fixture 생성 성공, 테스트 사본과 제품5파일 해시 일치. 최종 문서 통합은 MANAGER 담당.

증거: docs/reports/step_25/dev_paths.json, dev_summary.json, dev_source_comparison.json 및 dev-24a86f89130a4200bb73a5745d379ab9 실행 폴더의 results.json·로그·PNG.

## 실행 이력·한계

최초 sandbox 실행 dev-4894820c306b47e9a5d4d6af4303837a는 Godot editor/user 폴더 접근 거부로 저장 fixture 2 FAIL. 제품 결함으로 판정하거나 통과 수에 합산하지 않고 원 로그를 보존했다. 정식 권한 승인 후 새 격리 사본에서 전체 실행이 통과했다. 제품 수정 없이 재실행, DEV 자동 수정 루프 0회.

사용자 물리 입력·실기기 터치·디자인 및 체감 수용은 별도 비차단 확인. 자동 입력과 실제 렌더를 사람의 전체 플레이/실기기 검증으로 확대하지 않는다. 신규 제품 BUG 없음, 기존 BUG-003/004 후속 유지. 원본 저장 해시를 읽어 비교한 것은 아니며, 모든 실행의 고유 격리 경로와 원본 미접근으로 보호했다.
