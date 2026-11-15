# STEP 24 DEV 보고서

2026-09-28 / 카드 S24-DEV-001 실행 확정 절 / **DEV PASS, 독립 QA 인계**.

## 구현과 범위

Game.tscn의 UI/FeedPanel/FeedButton을 좌측 하단 (30,1160)~(190,1240)에 추가했다. 기존 메뉴와 동일한 160×80 논리 크기·기본 스타일이다. 알 상태에서도 ‘밥주기’ 표시·비활성, baby 활성이다. game.gd에서 ready 때 pressed를 한 번 연결하고, 허용 입력을 feed_requested 신호 1회로 전달한다. 부화 빛 Tween 실행 중·hatch_in_progress·빈 데이터·미지원 stage는 버튼과 핸들러 모두에서 차단한다. 기존 부화 플래그 해제 시점은 유지하고 빛 Tween finished에서 버튼을 갱신한다.

음식·먹기·친밀도·레벨·저장·쿨다운·이동 중단을 추가하지 않았다. STEP 25가 요청 신호를 받아 음식 표시를 연결할 수 있는 입력 준비 단계이며 실제 밥주기 효과 완성이 아니다. 제품 변경은 Game.tscn, game.gd 두 파일이다.

## 실행·증거

tests/step_24/run_dev.ps1: Godot 4.7.2.stable.official.ed1daf0bf, headless와 Windows OpenGL Compatibility(Intel Iris Xe) 렌더. 실제 프로젝트/저장 대신 별도 임시 프로젝트·custom_user_dir을 사용한다. 사용자 원본 저장은 읽기 해시만 수행했고 전후 일치. 최초 sandbox의 해시 읽기 거부 후 정식 escalation으로 실행했다. 제품/테스트 실패로 세지 않는다.

증거: step_24/dev_paths.json, dev_summary.json, dev_source_comparison.json. 로그·PNG 폴더: step_24/damagochi-step22-resume-step23-dev-step24-dev-c146ecbd5abb43159ba3812984e4da3d/. 제품 사본 해시 동일, project.godot 사본만 격리 저장 설정의 의도적 차이.

| AC | 판정 | 자체검증 |
|---|---|---|
| AC1 | PASS | egg 표시·비활성, 부화 0.5초의 baby+빛 잔존 시 비활성, 1초 후 활성, adult/빈 데이터·빈 load 비활성. 기존 메뉴와 같은 크기·비중첩. 405×720 egg/baby 및 720×1280 baby 실제 렌더 캡처 확인 |
| AC2 | PASS (Godot 합성 UI 입력) | Viewport 좌표 mouse press/release로 요청 1회, 우클릭 0회, focus+Space 요청 1회. 알/빛 중 직접 신호도 차단. 100회 갱신 연결 1개, 10회 누름 10요청, 재진입 단일 연결 |
| AC3 | PASS | 입력 전후 전체 메모리/저장 바이트 동일, 이동 목표·Idle 객체 보존. STEP 23 이동 19, 기존 핵심 38, 메뉴 52, 기존 독립 검사 32 PASS. 별도 프로세스 정상 메뉴 egg/baby/hatch 및 급식 버튼 상태/입력 복원 확인 |
| AC4 | DEV 범위 PASS | 실제 저장 보존, 저장 규격·후속 STEP 미구현 유지, 제품 해시·로그·화면 기록. QA 및 MANAGER 최종 통합 후속 |

신규 headless 21 PASS, 렌더 24 PASS(동일 시나리오+PNG 3건), 버튼 별도 프로세스 seed/복원 10 PASS. 이동·기존 회귀와 fixture 포함 전체 216 PASS, FAIL/스크립트 오류 0, 종료 코드 0. 반복 환경과 fixture를 포함한 단언 수다. 기존 verify.gd의 과거 정지 x 기대 1곳만 격리 사본에서 ±120px 범위 기대로 적응하며 원본은 보존했다. 관련 STEP 23 검사 원본도 수정하지 않았다.

기존 회귀의 저장 실패·빈 데이터·손상 JSON 주입 ERROR는 예상 처리 검사이며 SCRIPT ERROR와 구분한다. BUG-003의 실제 60.2초 무입력 egg 유지·추가 입력 부화도 유지됐다. QA 이후 수정 루프 0회, 자체검증 제품 수정도 없었다.

## 남은 확인

좌표·키보드는 실제 Godot UI 경로를 통과한 합성 입력이며 사람이 물리 장치를 누른 검증은 아니다. 실기기 터치·기기별 화면·전체 물리 플레이·체감 품질은 별도 사용자 확인으로 유지한다. 기존 BUG-003/004 후속과 저장 중 디스크 장애 한계는 이번 범위 밖이다. STEP 25 미착수.
