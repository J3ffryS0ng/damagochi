# STEP 32~35 DEV 통합 보고서

2026-10-02 / WORK-ORCHESTRATOR DEV / **DEV PASS WITH ISSUE**. 기능 AC는 통과했으며 기존 BUG005 native 종료 불안정 재관찰은 미해결이다. 최종 STEP 판정은 독립 QA와 MANAGER가 담당한다.

## 구현

- STEP32: 자체 SVG `assets/images/poop.svg`, 96×96, 중심 (540,900), 최대1개. 실제 baby Timer가 생성하고 존재 중 잔여시간 정지. 대상 무효/교체/이탈 제거. `assets/ASSET_INDEX.md` 신규 작성, 기존 파일 이동/삭제 없음.
- STEP33: viewport 입력을 통해 왼쪽 누름 또는 합성 ScreenTouch 누름만 영역 내 소비. 오른쪽/해제/취소터치/영역 밖 및 모든 행동 busy 입력 무시. 단일 busy 상태로 중복 차단.
- STEP34: 유효 수치 확인, GameManager 기존 +1/레벨업 및 SaveManager 즉시 저장. 명시 실패는 성장3필드 복구, 응가 유지와 재시도 안내. 성공 전 제거하지 않으며 저장 규격은 유지.
- STEP35: 원본 텍스처·scale·rotation 유지, 현재x 고정/위6px·복귀 각0.3초 SINE. 완료 후 Idle/이동 재개, 취소/교체/이탈 정리. 연출 추가 보상 없음.

## 실제 검증과 증거

Godot **4.7.2.stable.official.ed1daf0bf**, headless 및 OpenGL Compatibility. 원본 저장에 접근하지 않고 고유 TEMP 프로젝트 및 custom user dir을 사용했다.

1. 전체 DEV 사본 `6a6e0adc3d9e4b0290f4db6a3936300a`: 16검사 프로세스 native0, **301 PASS**. 기본 Timer 116.175048828125초를 단축하지 않고 실제 116.185초 뒤 생성. 핵심55/별도복원2/실제주기6/놀이46·복원3/급식38·복원3/이동19/메뉴52/알·baby·부화 seed·복원20/렌더57. 이 사본은 BUG006 안내 소유권 수정 전이다.
2. 최종 제품 사본 `27bde22d8c384127a968f74e8d95a8ba`: `dev.log` **60 PASS**, 별도프로세스 `clean_restore.log` **2 PASS**, `render.log` **62 PASS**와 PNG 생성 후 native **-1073741819**. 최초 로그/results 보존. 기능 단언을 native 정상종료로 잘못 집계하지 않는다. 동일사본 `render_retry.log` 재시도는 **62 PASS/native0**. 최초 실패 포함 최종사본 단언 총186 PASS이며 재시도 정상만으로 BUG005 해결을 주장하지 않는다.
3. 최초 입력 검사 좌표 오류 및 중복 실행 중단은 DEV_EXECUTION_NOTES에 기록. 최초 검사파일 `dev_verify_initial_coordinates.gd` 보존. 이들은 최종 완료 검사에 합산하지 않는다.

최종 렌더 PNG에서 응가 위치/크기 및 기존 캐릭터 외형, 청소 후 이미지 제거와 버튼 차단을 직접 확인했다. 실제 viewport routing의 합성 마우스/터치를 검증했으며 물리 터치 기기와 연출 체감은 비차단 사용자 품질 확인이다. 기존 BUG004 부분 디스크 쓰기 원자성 문제를 해결했다고 주장하지 않는다.

## QA 발견 수정

독립 QA 정적 검토에서 청소 실패→놀이 실패→청소 성공 연쇄가 새 놀이 안내를 지우는 BUG006을 발견했다. MANAGER 등록 후 DEV가 놀이 실패 시 clean 안내 소유권을 해제하도록 수정했다. 최종 핵심/렌더에서 연쇄 5단언 PASS. **QA→DEV 자동수정 1회**, 독립 QA 재검증으로 최종 해결 판정한다.

제품 변경: `scripts/game/game.gd`, `scenes/game/Game.tscn`, `assets/images/poop.svg`, `assets/ASSET_INDEX.md`. GameManager/SaveManager/캐릭터 원본/COMMON 및 이전 검사·보고서 변경 없음. 검증 스크립트는 tests/step_32_35 신규 파일만 사용한다. STEP36 미착수.

