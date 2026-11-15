# STEP 31 MANAGER 최종 판정

2026-10-02 / WORK-ORCHESTRATOR / S31-DEV-001 / **PASS·개발 완료**.

## 구현·결정 수용

사용자 “a안으로 진행해”에 따른 M016 A 및 공통정책 수용. baby부화빛종료 후60~120초 균등무작위간격에서 one-shot Timer를 시작하고 만료마다내부poop_requested1회 및 재추첨한다. 먹기/놀이중 남은시간보존 일시정지, 같은대상복귀시재개. 같은대상갱신유지·자격상실/교체/장면이탈초기화·재진입새간격·오프라인누적/저장없음. 타이머용난수원과 프레임상태관찰을 이동process와 분리했다.

제품변경은 game.gd만. 화면생성물·청소·보상소비자는 추가하지 않았다. 기존 외형·급식/놀이보상·저장규격·자산·managers 유지. STEP32 응가 이미지 생성 작업카드 준비가능·미착수, 자동시작하지 않는다.

## 필수 AC 판정

| AC | 판정 | 근거 |
|---|---|---|
| 1 주기 | PASS | 실제기본주기 DEV63.632877초설정→63.631초, 독립QA73.589516초설정→73.619초. 각1요청·다음전체간격. 표본범위/평균·이동난수분리·긴프레임/중복콜백비보충 |
| 2 상태·수명 | PASS | 알/부화/빈대상/지원외/같은내용다른대상차단,100동일갱신보존,먹기/놀이중정지·취소/정상완료잔여재개,Tree pause,재진입/별도프로세스복원초기화 |
| 3 회귀·범위 | PASS | 타이머요청전후메모리/저장SHA256불변. 급식/놀이+1·취소0·실제쓰기거부복구·이동/부화/메뉴회귀. 두해상도화면유지 |
| 4 증거·보존 | PASS | 실제Godot4.7.2·고유TEMP/customuserdir·원본저장미접근·사본hash일치. baseline797중game.gd만변경·796보존,BUG_LOG/COMMON별도동일. 상세DEV/독립QA·실행로그 |

DEV235 PASS, 독립QA319 PASS(환경반복·fixture포함). QA18개실행status는모두native0, 기능/회귀/렌더FAIL·SCRIPT ERROR0. 실제메뉴/Game정상종료2건도통과. 기본주기를단축한시험과실제60~120초대기는별도기록했다.

## 검증 이력·제한

제품자동수정루프0회·신규BUG없음. QA 최초full실행개시와 보완검사작성시점이겹쳐 초기실행검사코드를evidence/qa_verify_initial.gd로보존했다. 정상행동완료검사는별도CompletionOnly7PASS로추가검증,렌더는4PASS. 보완검사좌표를실행전에로컬기준으로바로잡았으며실행FAIL이나제품수정은없다. 최종검사사본hash도별도보존했다.

BUG003/004/005후속유지. 이번native종료는정상이지만BUG005를해결처리하지 않는다. 사용자환경물리입력·돌봄간격체감·기기별화면·종료안정성은비차단후속확인. 추가제품결정없음. Timer저장/복원은STEP90, 생성물개수/배치·제거수명은후속STEP32/33결정으로남긴다.

## 근거·문서

STEP_31_DEV_REPORT.md, STEP_31_QA_REPORT.md 및 step_31/의 dev_paths/qa_paths·results/status/log/PNG·dev_hashes·source_hashes·preservation_result·protected_result·manager_qa_counts 참조. MASTER/STEP_PLAN/PROJECT_STATE/DEVELOPMENT_STEPS/M016수용반영. 기존카드/보고/검사·공통템플릿·BUG_LOG보존,커밋/역할작업정리없음.

검증game.gd SHA256:6D2B62D73DBFAE3ED35072FA5613FCDFC12D7B87625AA62BC153D2AB109BDFE3. Game.tscn:32B206DB2265DAC84BAD9ED1220ADE4DDD7BE0066C49FDBC3A9DB3B27DC89995 유지.
