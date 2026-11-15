# STEP 28 DEV 보고서

2026-10-01 / S28-DEV-001 / M-013 A 승인 / DEV PASS.

## 구현

Game.tscn 하단 중앙에 160×80 놀아주기 버튼 추가. game.gd가 준비 시 pressed를 한 번 연결하고 play_requested를 발행한다. 기존 현재 대상·baby·부화 종료 조건과 feeding_busy를 검사하며 상태 갱신마다 버튼 활성도 갱신한다. 유효 누름만 요청하며 연출·보상·저장·대기열을 추가하지 않는다. 외형·기존 버튼 위치·자산·managers 변경 없음.

## 실제 자체검증

Godot 4.7.2.stable.official.ed1daf0bf, headless 및 OpenGL Compatibility 실제 실행. tests/step_28/run_dev.ps1 전체 exit0, 180 PASS(반복·fixture 포함): STEP28 headless22 / render26, STEP27 급식38 / 별도 복원3, 이동19, 메뉴52, egg/baby/hatch 별도 프로세스 seed·복원20.

- AC1: 알 표시·비활성, baby 활성, 부화 중/먹기 중/빈 데이터/미지원 stage 차단. 두 크기에서 중앙 배치와 버튼·오류 안내 비중첩. 405×720 화면에서 한글 라벨과 기존 외형 확인.
- AC2: 실제 viewport 좌표 입력10회→10신호, Space1회, 우클릭0회, 100갱신 단일연결. 먹기 중 요청0, 완료 후 예약 없이 활성.
- AC3: 놀이 전후 메모리 및 격리 저장 SHA256 불변, Idle·이동 유지. 급식+1·중복/취소 미지급·대상교체·레벨업·주입된 실패 및 실제 파일열기 실패 복구 회귀 PASS. 오류 안내 유지.
- AC4: dev_paths.json에 고유 TEMP 실행사본 및 custom userdir 기록. 원본 사용자 저장은 접근하지 않음. preserved_before.json 대비 변경은 game.gd·Game.tscn만 있음(이전 카드·보고·테스트·자산·BUG_LOG·COMMON 템플릿 보존).

실행 증거: step_28/damagochi-step22-resume-step23-step24-step27-step28-dev-68d00727dab14c9680dafa20320bb345/results.json 및 각 log·PNG. 빈 대상/파일열기 거부의 ERROR는 의도한 fixture이며 SCRIPT ERROR/FAIL 없음.

제품 SHA256: game.gd 2E1FE86B0ACF3837F92B01071CA7B81E58B07FF10E9FA7A0267139ACC0E60E6A, Game.tscn 32B206DB2265DAC84BAD9ED1220ADE4DDD7BE0066C49FDBC3A9DB3B27DC89995. 실행사본 대조는 최종 관리자 증거에 기록한다.

제품 자동 수정0회. 신규 BUG 없음. 물리 키/마우스·실기기 터치·체감은 비차단 사용자 확인이며 합성 입력 PASS와 구분한다. 최종 판정은 독립 QA 후 MANAGER가 수행한다.
