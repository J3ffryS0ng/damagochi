# STEP 35 독립 QA 보고서

2026-10-02 / **PASS WITH ISSUE** / 작업카드 STEP_32_35_DEV.md / 독립 QA.

| AC | 결과·근거 |
|---|---|
|원본 외형/현재 위치/시간|PASS — x81 고정, y-6 각0.3초/총0.6초, 원본 texture·scale·rotation 유지|
|입력/Idle/이동/Timer 충돌|PASS — 동시 중지·버튼 비활성·조기완료 거부|
|정상 복귀·교체/이탈|PASS — Idle/이동 재개, 대상 교체·이탈 tween 정리 및 재진입 초기화|
|실제 렌더·이동/메뉴/저장|PASS 기능/시각 — 두 해상도4장, 이동/메뉴/저장 회귀. native 종료 BUG005 잔여|

통합 최종 제품에서 해당 STEP 필수 AC를 독립 검증했다. 상세 실제 로그·해시·완료조건·실행 방식은 [STEP_32_35_QA_REPORT.md](STEP_32_35_QA_REPORT.md) 참조. DEV 판정을 대신 인용하지 않았고 QA 제품 코드 수정 없음.

통합 370 PASS / FAIL0 / SCRIPT ERROR0. 기능·회귀·렌더16프로세스 native0. 실제 MainMenu 최초 종료 native -1073741819, 동일사본 1회 재실행 MainMenu/Game native0. BUG005 원인 미확정·미해결로 PASS WITH ISSUE이며 재실행 성공을 해결로 표시하지 않는다.

자동 수정1회: BUG006 안내 소유권을 DEV 수정한 뒤 독립 두 연쇄 통과. BUG003/004 기존 후속 유지. 실제기기 터치·연출 체감·사용자 환경 정상 종료는 비차단 품질 후속. 원본 사용자 저장 미접근, STEP36 미실행.

