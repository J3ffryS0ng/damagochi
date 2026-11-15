# STEP 33 독립 QA 보고서

2026-10-02 / **PASS WITH ISSUE** / 작업카드 STEP_32_35_DEV.md / 독립 QA.

| AC | 결과·근거 |
|---|---|
|마우스/터치 유효 영역|PASS — viewport 실제 전달, 좌상단 포함·우하단 내부 클릭/터치|
|오른쪽/해제/영역 밖|PASS — 네 경계 밖·오른쪽·해제·취소 터치·Tree pause 무시|
|먹기/놀이/청소 차단·중복|PASS — 입력 예약 없음, 연속 mouse/touch 정확히 한 번|
|취소/교체·기존 버튼|PASS — stale identity 무시, 취소와 늦은 콜백 무보상, feed/play 회귀|

통합 최종 제품에서 해당 STEP 필수 AC를 독립 검증했다. 상세 실제 로그·해시·완료조건·실행 방식은 [STEP_32_35_QA_REPORT.md](STEP_32_35_QA_REPORT.md) 참조. DEV 판정을 대신 인용하지 않았고 QA 제품 코드 수정 없음.

통합 370 PASS / FAIL0 / SCRIPT ERROR0. 기능·회귀·렌더16프로세스 native0. 실제 MainMenu 최초 종료 native -1073741819, 동일사본 1회 재실행 MainMenu/Game native0. BUG005 원인 미확정·미해결로 PASS WITH ISSUE이며 재실행 성공을 해결로 표시하지 않는다.

자동 수정1회: BUG006 안내 소유권을 DEV 수정한 뒤 독립 두 연쇄 통과. BUG003/004 기존 후속 유지. 실제기기 터치·연출 체감·사용자 환경 정상 종료는 비차단 품질 후속. 원본 사용자 저장 미접근, STEP36 미실행.

