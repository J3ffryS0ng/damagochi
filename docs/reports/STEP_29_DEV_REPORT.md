# STEP 29 DEV 보고서

2026-10-01 / S29-DEV-001 / M-014 A 확정 / **DEV PASS**.

## 구현

game.gd에서 play_requested를 연출에 연결했다. 시작 x를 보존하고 이동·Idle을 멈춘 뒤 기본 y 기준18px 상승/복귀 각0.2초를3회 수행한다(SINE/EASE_IN_OUT). 완료 시 시작 x·기본 y 복귀, 평소 움직임 및 자격에 맞는 버튼 활성으로 돌아간다. 놀이 중 두 행동을 차단하며 직접 신호 소비 경로도 방어한다. 현재 대상 identity·generation 및 경과 시간을 검사하고 자격 상실/대상 교체/장면 이탈 시 취소·정리한다. 동일 대상 갱신은 연출을 중복 생성하지 않는다.

새 놀이 보상·저장·자산·소리 없음. 기존 실패 안내와 원본 외형 유지. Game.tscn·managers·이전 기록/검사는 변경하지 않았다.

## 실제 자체검증

Godot4.7.2.stable.official.ed1daf0bf, headless 및 OpenGL Compatibility 실제 실행. 최종 run_dev.ps1 모든 프로세스 exit0, **241 PASS**(환경 반복·fixture 포함): 자체51, 렌더58, 급식38, 별도 급식복원3, 이동19, 메뉴52, egg/baby/hatch seed·별도복원20.

- AC1: 좌/중/우 x 고정,3회 높이18px·기본 y 복귀,1.2초 후 이동·Idle 복구, 텍스처/크기/회전 불변. 두 화면의 점프·복귀 렌더 캡처.
- AC2: 실제 클릭·10회 반복/직접 신호·100회 동일 대상 갱신, 조기/오래된 완료 방어, 먹기 중 놀이 및 놀이 중 먹기 차단. 대상 교체 3구간·adult/empty/hatch 취소, 장면 이탈 Tween 정리·재진입 단일 연결.
- AC3: 놀이 전후 전체 메모리/격리 저장 SHA256 불변. 오류 안내 유지. 먹기+1·취소0·레벨업·중복 방어·실제 쓰기 시작 거부 복구 회귀, 이동/알/부화/메뉴/별도 복원 통과.
- AC4: 고유 TEMP 프로젝트/custom userdir 사용, 원본 사용자 저장 미접근. dev_hashes.json 원본/사본 일치, baseline616 중 game.gd만 변경. protected_before.json의 BUG_LOG/COMMON 템플릿도 유지.

증거: step_29/dev_paths.json 및 damagochi-step22-resume-step23-step24-step27-step28-step29-dev-a029d257dd6642ffa050e7c532cdde3f/ 의 results.json·로그·PNG. 기대한 빈 데이터/저장 거부 fixture 출력 외 SCRIPT ERROR/FAIL 없음.

## 자체 수정 이력

초기 DEV 실행(동일 prefix의63e026beae2d477c9ec02814a86bd817)은 finished 신호 안에서도 Tween.is_valid가 true여서 완료 복귀를 막는 오류를 발견했다. 최초 FAIL 및 이후 검사 null 오류 로그 보존, 멈춘 검사 프로세스 중단. 완료 가드를 전체1.2초 경과 검사로 수정 후 전체 재실행 통과. **DEV 자체 수정1건, QA FAIL 이후 자동 수정 루프0회**(QA 결과는 별도 보고). 정상 종료 검증에 fixture 명시 해제를 사용했다.

신규 잔여 BUG 없음. 실기기 입력/기기별 렌더/점프 체감은 비차단 사용자 품질 확인. 최종 판정은 독립 QA 후 MANAGER가 수행한다. STEP30 미착수.
