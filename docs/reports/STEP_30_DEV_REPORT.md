# STEP 30 DEV 보고서

2026-10-01 / S30-DEV-001 / M-015 A 확정 / **DEV PASS**.

## 구현

game.gd의 정상 놀이 완료에 친밀도+1을 연결했다. busy/generation/1.2초 경과/시작대상 identity 확인 후 수명 상태를 소비하고 기존 GameManager 레벨업·UI·즉시저장을 수행한다. 취소·중복·조기·대상교체는 미지급이다. 기존 수치 유효성 검사를 재사용하며 명시적 add/save 실패는 affection/level/목표를 복구한다.

실패는 기존 안내 영역에 놀이 메시지를 표시한다. 놀이 안내 태그로 다음 유효 놀이 시작 시 자기 안내만 지우며 급식 안내는 유지한다. 새 급식은 기존처럼 안내를 초기화한다. 원본 외형·점프·행동 상호차단·managers·저장 규격·장면·자산 변화 없음.

## 실제 자체검증

Godot4.7.2.stable.official.ed1daf0bf headless 및 OpenGL Compatibility 실제 실행. 전체 **231 PASS**(환경반복·fixture 포함), 채택 프로세스 모두 native0: 자체46, 놀이 별도복원3, 급식38+별도복원3, 이동19, 메뉴52, 기존 egg/baby/hatch seed·복원20, 렌더50.

- AC1: 완료당+1·즉시저장/UI, 정확 임계값 레벨업·잔여·다음목표, 실제 UI완료, 별도프로세스 정상 메뉴 전체데이터 복원.
- AC2: 10입력·100동일갱신, 조기/중복 완료,6구간 취소·다른 Dictionary교체·장면이탈/이전세대 미지급, 급식중 놀이 차단.
- AC3: add/save false 주입·레벨업 세필드복구·실제 파일열기 거부·격리저장 바이트보존, 무효목표 거부. 안내표시/부적격입력유지/새놀이초기화/급식안내보존. 급식/이동/알/부화/메뉴 회귀 통과.
- AC4: 고유TEMP/customuserdir로 원본저장 미접근. dev_hashes.json 원본·실행사본 일치, baseline708 중 game.gd만 변경. BUG_LOG/COMMON은 별도 보호 해시 기록. 두해상도 놀이실패안내 캡처·405 한글/비중첩 직접확인.

증거: step_30/dev_paths.json 및 damagochi-step22-resume-step23-step24-step27-step28-step29-step30-dev-0d1fca1edab64ac188d1886e380b3155/의 results.json·각로그·PNG. 의도한 파일열기 실패 ERROR는 fixture이며 SCRIPT ERROR/FAIL 없음.

제품 자동수정0회. 신규 잔여BUG없음. 원자적 부분쓰기 복구는 기존BUG004 후속. 실기기 입력·기기별화면·체감은 비차단 사용자확인. 최종판정은 독립QA 후 MANAGER가 수행한다. STEP31 미착수.
