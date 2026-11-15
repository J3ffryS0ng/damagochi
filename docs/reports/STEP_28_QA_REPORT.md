# STEP 28 독립 QA 보고서

2026-10-01 / S28-DEV-001 / WORK-ORCHESTRATOR 독립 QA / **필수 AC1~4 PASS**.

사용자 A안과 실행 확정 카드, 실제 game.gd/Game.tscn을 기준으로 별도 QA가 검사 코드를 작성하고 실제 로그·렌더를 판정했다. DEV PASS를 근거로 대신 판정하지 않았다. QA 제품 코드 수정 없음. 엔진 권한 실행은 부모가 수행했으며 QA가 증거를 직접 검토했다.

## 실행과 판정

Godot 4.7.2.stable.official.ed1daf0bf, Windows headless 및 OpenGL Compatibility(Intel Iris Xe). 채택한 실행 **355 PASS, FAIL 0, SCRIPT ERROR 0**, 모두 native exit 0. 환경 반복·fixture 단언을 포함한 수치다. 추가 정상 제품 진입/종료 smoke 2건도 exit 0이다.

| AC | 판정 | 독립 검증 근거 |
|---|---|---|
| 1 표시·활성·배치 | PASS | egg 표시·비활성, 부화 시작/이미 baby로 바뀐 fade 중 차단, 완전 종료 후 활성. adult/empty/stale/hatch 방어, 먹기 완료·취소 후 상태 복귀. 논리 rect(280,1160,160,80), 기존 feed/menu/실패안내와 비중첩. 405×720·720×1280 각각 egg/hatch/baby/feeding/notice PNG10장 직접 확인: 한글 라벨 정상, 화면 이탈·잘림 없음 |
| 2 입력 | PASS | 실제 viewport 좌표의 좌클릭 1회, 우클릭 0회, focus+Space 1회. 실제 클릭 10회=10요청, 100회 갱신 및 장면 재진입 단일 pressed 연결. 부적격 직접 handler/합성 signal/좌표 입력 차단. 급식 중10회 신호 차단·세대 유지, 완료 후 대기 요청 없음·새 클릭1회 |
| 3 회귀·불변성 | PASS | 놀이 입력 전후 전체 메모리 및 격리 저장 SHA256 불변. 기존 Idle Tween 동일·실행 유지, 이동 유지. 급식 정상완료+1·취소0, threshold/재시도/중복 콜백 방어, 저장 false 주입 및 실제 read-only 파일 열기 거부 복구·기존 저장 바이트 유지. 실패 안내를 놀이 입력이 지우지 않음. 별도 프로세스 정상 메뉴 egg/baby 놀이 복원 및 기존 이동·알/부화/메뉴 회귀 |
| 4 범위·증거·보존 | PASS | 고유 TEMP 프로젝트·별도 custom userdir 사용. 제품·자산5파일 원본/실행사본 해시 일치. baseline523 중521파일 동일, 예상 game.gd/Game.tscn만 변경. 이전 카드/보고·검사·자산·managers·BUG_LOG·COMMON_OPERATIONS_TEMPLATE 보존. 원본 사용자 저장 미접근 |

검사 집계: 놀이 자체76, 렌더86, 급식83+급식 별도복원7, 놀이 별도 seed/복원12, 이동19, 메뉴52, 기존 egg/baby/hatch seed/복원20 =355. 놀이 consumer/애니메이션/보상·저장·새 busy/쿨다운이 추가되지 않은 것도 실제 코드에서 확인했다. STEP29/30 범위를 앞당기지 않았다.

## 격리·증거

- 최신 실행: `step_28/damagochi-step22-resume-step23-step27-step28-qa-39c58c3117974f048c878e0cbad0656e/`의 로그·status·PNG·source_hashes.json.
- 경로: `step_28/qa_paths.json`, 집계: `qa_summary.json`, 별도 보존검사: `qa_preservation.json`.
- 실행 코드는 `tests/step_28/qa_verify.gd`, runner는 `run_qa.ps1`. STEP27 QA는 사본에서 이름과 고유 userdir guard만 조정하여 재사용; 원본 이전 검사는 수정하지 않았다.
- game.gd SHA256: `2E1FE86B0ACF3837F92B01071CA7B81E58B07FF10E9FA7A0267139ACC0E60E6A`.
- Game.tscn SHA256: `32B206DB2265DAC84BAD9ED1220ADE4DDD7BE0066C49FDBC3A9DB3B27DC89995`.

원본 저장의 해시 전후 비교를 했다는 의미는 아니다. 고유 격리 user 경로로 원본을 접근하지 않았고, 데이터 불변/쓰기거부 검사는 격리 파일에서 수행했다. 의도한 손상 fixture·저장 쓰기거부 ERROR 출력은 기대한 실패 경로이며 SCRIPT ERROR와 구분했다.

## 검사 수정·관찰 이력

제품 자동 수정 **0회**. 최초 QA fixture helper `seed(String)`가 Godot 전역 `seed(int)`와 충돌하여 parse 실패했다. `create_fixture`로 이름만 수정했고 최초 `qa-4027581e5a954d46b7714484d4119621` 로그를 보존했다. 이 실패 실행은 집계에서 제외했다.

첫 렌더와 동일 사본 재실행은 각각86 PASS·failures=0 이후 native exit **-1073741819**였다. 두 원본 로그/status를 `qa_render_first`, `qa_render_second`로 보존했으며 이를 정상 종료로 간주하지 않았다. 다수의 합성 입력·장면 교체를 하는 QA fixture 종료부에 현재 장면 명시 해제, 세 프레임 및 렌더 완료 대기를 추가한 뒤 동일 제품으로86 PASS·native exit0을 확인했다. 원인은 확정하지 못했으며, STEP24의 유사 종료 관찰과 함께 후속 실행환경/종료 경로 관찰 항목으로 남긴다.

제품 영향 분리를 위해 QA script 없이 실제 MainMenu 및 Game.tscn을 각각 실행하고120프레임 뒤 종료했다. `qa_native_menu_exit`, `qa_native_game_exit` 모두 native exit0·SCRIPT ERROR0이며 Game은 격리 저장 불러오기를 확인했다. DEV 렌더도 정상 종료다. 현재 제품 결함으로 확정할 근거는 없고 필수 AC를 막지 않는다. 위 관찰을 숨기거나 제품 수정 완료로 주장하지 않는다.

## 남은 확인

신규 확정 BUG 없음. 기존 BUG003/004 후속 유지. 저장기의 물리 부분 쓰기·원자 복구는 기존 범위 밖이며 이번 검증은 명시적 실패 반환과 쓰기 시작 거부를 다룬다. 물리 키보드/마우스·실기기 터치·화면 체감은 비차단 사용자 확인으로 남긴다. 추가 제품 결정 필요 없음. STEP29 미착수.
