# STEP 31 DEV 보고서

2026-10-02 / S31-DEV-001 / M016 A 확정 / **DEV PASS**.

game.gd에 전용 난수원과 one-shot PoopTimer를 추가했다. 유효baby 부화빛종료부터60~120초 균등추첨·만료당poop_requested1회·재추첨. Timer의 별도 프레임 관찰로 Game 이동process가 꺼져도 상태를 확인한다. 먹기/놀이중 Timer.paused로 남은시간보존, 동일대상반복갱신유지, 자격상실/교체/장면이탈초기화. Tree pause 상속, 오프라인보충/저장없음. 재시작 후 신호를 보내 중복콜백·누적요청을 막는다. 제품변경은 game.gd만이며 생성 이미지/소비자는 후속이다.

## 실제 검증

Godot4.7.2.stable.official.ed1daf0bf headless 및 OpenGL Compatibility. 모든 프로세스native0, **235 PASS**(환경반복·fixture포함): 타이머23, 실제주기6, 놀이46/복원3, 급식38/복원3, 이동19, 메뉴52, 기존seed/복원20, 렌더25.

- 실제 기본첫간격63.632877초를 단축하지 않고 기다려63.631초 뒤 정확히1요청·다음60~120초재시작 확인. 메모리/저장SHA256불변. short검사 단축timeout과 별도 실행으로 구분했다.
- 2000간격표본 범위·양끝·평균,100갱신·단일연결·중복콜백, movement process중지독립성.
- 먹기/놀이중 남은시간정지 및 정상완료즉시동일잔여재개,Tree pause,알/지원외/빈대상/부화/교체정지 및 다시유효할때새간격,장면이탈해제·재진입초기화.
- 놀이/급식+1·취소0·실제파일열기거부복구,이동/알/부화/메뉴·별도복원회귀.405×720·720×1280기존화면렌더.

증거: step_31/dev_paths.json 및 damagochi-step22-resume-step23-step24-step27-step28-step29-step30-step31-dev-09710e3a6a0d4fd18402336589f39bb8/의 results.json/log/PNG. dev_hashes.json 원본·사본일치. baseline797중game.gd만변경·796보존. BUG_LOG/COMMON 별도보호해시기록. 원본사용자저장미접근·고유TEMP/customuserdir사용.

제품자동수정0회. DEV에서새FAIL없음. BUG003/004/005는기존후속유지하며이번정상종료만으로BUG005해결주장안함. 실기기/체감·종료안정성은비차단사용자확인. 최종판정은독립QA후MANAGER. STEP32미착수.
