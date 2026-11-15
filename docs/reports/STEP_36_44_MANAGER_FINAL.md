# STEP 36~44 MANAGER 최종 판정

2026-10-03 / WORK-ORCHESTRATOR / **PASS WITH ISSUE·개발 완료**.

사용자의 STEP36~44 실행 요청을 조사한 뒤 부족한002/003 이미지를 사전 안내했고, 임시 테스트 이미지 사용 승인을 받아 M021을 확정했다. MANAGER 작업카드→DEV 구현/실제 자체검증→독립 QA→MANAGER 통합을 완료했다. STEP45는 시작하지 않았다.

## 필수 AC 통합

각 STEP의 AC1~3과 공통 기능AC4는 독립QA PASS다. 종료 안정성 BUG005가 미해결이므로 모든 STEP의 최종은 PASS WITH ISSUE로 구분한다.

| STEP | 결과 및 근거 |
|---|---|
|36 creatures.json 설계|저장과 분리된 version1 종 정의, 필수값/ID/이미지/scale/weight 검증, 문서 전체 오류의 내장001 대체. save_version1 유지|
|37 캐릭터 ID 시스템|기존3자리 ID 조회·깊은 복사·중복거부. 미등록 저장ID는 보존하고 화면만001 대체, 임의 저장/재추첨 없음|
|38 테스트 캐릭터001 등록|원본 PNG/방향/scale 그대로 데이터 등록, 기존001 egg/baby 별도프로세스 복원·돌봄 회귀|
|39 이미지 경로 데이터화|종ID로 알/baby texture와 scale 적용,3종 부화/갱신/재진입·무효경로 안전대체|
|40 희귀도 Weight|test 희귀도/weight1:1:1, 유한범위검증·0제외·음수/비수치/모두0거부·다른가중치 적용|
|41 랜덤 알 선택|실제 메뉴→이름→새게임에서1회추첨·저장. 부화/이어하기/장면전환실패 재시도에서ID유지, 취소/쓰기거부보존·난수분리|
|42 테스트 캐릭터002 추가|민트색 자체SVG 임시이미지·정의/인덱스 등록,알/부화/돌봄 및egg/baby별도복원|
|43 테스트 캐릭터003 추가|보라색 자체SVG 임시이미지·정의/인덱스 등록,알/부화/돌봄 및egg/baby별도복원|
|44 3종 랜덤 지급 확률|고정seed 균등·1:2:7·0가중제외 각각30,000회,실제신규메뉴3종도달·기존기능회귀|

## 검증

Godot4.7.2.stable.official.ed1daf0bf / Windows headless 및 OpenGL Compatibility. DEV/QA는 서로 다른 검사와고유TEMP프로젝트/customuserdir로 실행, 원본사용자저장 미접근. 실제권한실행은메인에서담당하고독립QA는검사작성·코드/로그/해시/PNG분석을수행했다. 제품코드는DEV만수정했다.

- DEV 총448 PASS(반복렌더 포함), 기능FAIL/SCRIPT ERROR0. 최초렌더69단언PASS 후native -1073741819, 동일사본단1회재검증69PASS/native0. 최초기록보존.
- 최종 독립QA **598 PASS / FAIL0 / SCRIPT ERROR0**,32개기능·복원·회귀·렌더·메뉴/Game종료프로세스 모두native0. PNG3개직접열람:001원본·002/003식별·화면/버튼겹침없음.
- 독립QA 균등30,000회:001=10,051(33.5033%),002=10,047(33.49%),003=9,902(33.0067%). 각1/3±1%p통과. 가중1:2:7:2,995/5,960/21,045로각목표±1%p통과. 0가중은지급없음. 고정seed재현·이동/응가RNG분리통과. 확률시험은모든seed에대한수학적보증과구분.
- 기존먹기/놀이/청소/친밀도·실패복구·이동/Idle·메뉴·부화/이어하기회귀통과. 실제새게임쓰기거부는격리save만읽기전용으로검증하고복구했다.

첫QA는미등록ID복원비교에서저장전메모리와저장후디스크의last_played_at차이를오류로판정한검사문제1건. 기준을실제저장된데이터로보정하고texture/ID/파일불변을분리해새사본전체재검증통과했다. 초기qa_paths_initial.json·검사원본·로그보존. **제품수정루프0/3회**, 신규제품BUG없음.

## 보존·남은 문제

12개검증제품파일의현재/QA사본SHA256일치. project.godot은원본불변이며격리사본의customuserdir설정2줄만다름을별도검증했다(final_product_hashes.json). 기존카드/보고서/검사975파일불변(history_preservation.json). COMMON·001원본·SaveManager·Game장면·project.godot보존(protected_result.json). 기존Git변경되돌림/커밋없음.

BUG005는DEV렌더에서재발했고QA정상종료만으로해결하지않는다. 원인미확정·비차단종료안정성후속. BUG003/004후속유지, BUG006해결회귀유지. 실제기기터치·최종아트품질은비차단품질확인. 공통데이터파일추가는M021확정범위이며기존저장스키마변경은없다.

## 사용자가 넣을 실제 이미지

002/003은임시테스트이미지다. 다음PNG를추가한뒤연결/크기검증이필요하다.

- assets/images/creatures/002/creature_002_idle.png
- assets/images/creatures/003/creature_003_idle.png

투명배경정지PNG권장. 파일추가만으로자동교체되지않으며data/creatures.json의해당baby_image와크기설정을연결한다. 임시SVG·001원본은보존. 상세 docs/CREATURE_CATALOG.md, 자산이력 assets/ASSET_INDEX.md. 최종대화에서사용자에게이미지추가를안내한다. 임시이미지승인에따라이번STEP완료를막지않는다.

## 근거 및 다음 단계

STEP_36_44_DEV_REPORT.md / STEP_36_44_QA_REPORT.md 및각STEP보고서, step_36_44/의dev_paths/qa_paths·로그·native결과·해시·PNG·확률집계. MASTER/STEP_PLAN/PROJECT_STATE/DEVELOPMENT_STEPS/M021/BUG005관찰을갱신했다.

다음은 STEP45 — 캐릭터 Stage 데이터 추가. 작업카드 준비가능·미착수이며이번자동실행범위는44까지다.
