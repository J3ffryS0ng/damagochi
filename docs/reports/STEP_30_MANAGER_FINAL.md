# STEP 30 MANAGER 최종 판정

2026-10-01 / WORK-ORCHESTRATOR / S30-DEV-001 / **PASS WITH ISSUE·개발 완료**.

## 구현·결정 수용

사용자 “A권장안으로해”에 따른 M015 A 및 공통 정책을 수용한다. 놀이3회점프 정상완료당 친밀도+1, 기존레벨업/잔여/UI/즉시저장을 연결했다. 조기/중복/취소/장면이탈/대상교체는 미지급. 명시적 처리/저장 실패 시 이번 친밀도·레벨·목표를 복구하고 놀이 안내 후 조작 복귀한다. 다음 유효 놀이는 이전 놀이 안내만 지우며 기존 급식 안내는 유지한다. 새 급식의 기존 안내 초기화도 유지한다.

game.gd만 제품변경. 원본 외형·연출·급식+1·행동상호차단·자산·장면·managers·저장규격 유지. STEP31 랜덤 응가 Timer 작업카드 준비 가능·미착수이며 자동 시작하지 않는다.

## 필수 AC 판정

| AC | 판정 | 수용 근거 |
|---|---|---|
| 1 보상 | PASS | 완료당+1·정확 임계값/잔여/연속사이클·UI·즉시저장, 별도 프로세스 정상메뉴 복원·새놀이 |
| 2 수명 | PASS | 10입력/100갱신·조기/중복/이전세대 방어,6구간취소·교체·장면이탈 미지급, 부적격/상호행동 차단 |
| 3 실패·회귀 | PASS | 무효수치 거부, add/save false 및 실제읽기전용 파일 쓰기거부 복구·바이트 보존, 안내수명. 급식·이동·알·부화·메뉴 회귀, 두해상도 실패/성공 화면 |
| 4 증거·범위 | PASS | Godot4.7.2 실제실행·DEV/QA사본hash 일치·고유TEMP/customuserdir·원본저장미접근. baseline708 중 game.gd만변경·707동일. 정상종료 재검증 통과; 최초 이상 별도 공개 |

DEV231 PASS, 독립QA359 PASS(환경반복·fixture 포함). 최신 기능검사/회귀/렌더 모두 native0·FAIL/SCRIPT ERROR0. 정상 제품 MainMenu/Game 종료 재검증도 각각 native0. 상세: STEP_30_DEV_REPORT.md, STEP_30_QA_REPORT.md 및 step_30/ 각 로그·status·PNG·dev_hashes.json·QA source_hashes.json·보존검사.

## ISSUE와 검사 이력

**BUG005 잠재 종료 이상을 비차단 ISSUE로 남긴다.** 검사스크립트 없는 MainMenu120frame 종료의 최초 실행에서 native -1073741819가 발생했다. 동일 제품·사본 재실행 MainMenu/Game은 모두0이었다. 원인미확정이며 재실행 정상만으로 해결 처리하지 않는다. 기능 AC의 실패나 저장 손상 근거는 없고 기존 메뉴 제품은 이번에 수정되지 않았다. 이전STEP28 fixture 종료 관찰과 동일원인인지도 미확인이다. 실제 사용자 환경 창닫기/재발 시 native기록 확인이 필요하다.

최초 QA의 연속사이클 검사1FAIL은 친밀도9→다음사이클이 레벨업0이어야 하는 기대값 오류였다. 검사만 수정하고 최초957a3660de6048288132c029f41a7b70 로그를 보존했다. 최신 f47ef0db1d5847b2bbf22a346dd69e5f 검증을 채택했다. 첫 메뉴종료 이상은 qa_native_menu_exit_first 로그/status에 보존했다.

제품 자동수정 루프 **0회**. BUG003/004 유지, 신규BUG005 관찰. 부분쓰기·원자복구는 기존BUG004 후속이며 이번명시적실패복구로 보장하지 않는다. 물리입력/실기기/체감·종료 안정성은 비차단후속확인. 추가 사용자 제품결정 없음.

## 문서·보존

MASTER/STEP_PLAN/PROJECT_STATE/DEVELOPMENT_STEPS 완료반영, DECISION M015 수용, 실제 관찰에 따라 BUG_LOG에BUG005 추가. COMMON_OPERATIONS_TEMPLATE 및 이전 카드/보고/검사·자산·managers는 그대로다. BUG_LOG 보호 해시는 시작시점 증거이며 이번 실제ISSUE 기록만 의도적으로 추가했다. 기존 미커밋 작업 보존, 커밋/역할작업정리 없음.

검증 game.gd SHA256:39C2EEA734139A6A32AC2196947D83A6DD59EE7689CB39253633B828BA321AD6. Game.tscn은32B206DB2265DAC84BAD9ED1220ADE4DDD7BE0066C49FDBC3A9DB3B27DC89995 유지.
