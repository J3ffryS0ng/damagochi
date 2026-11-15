# STEP 36~44 DEV 통합 보고서

실행일: 2026-10-03 / Godot 4.7.2.stable.official.ed1daf0bf / WORK-ORCHESTRATOR DEV

## 판정

**PASS WITH ISSUE**. 필수 기능검사 통과. 최초 렌더 기능69 PASS/RESULT failures=0 이후 native 종료 -1073741819가 발생하여 기존 BUG005 재발로 분류한다. 최초 로그/결과를 보존했고 동일 TEMP 프로젝트·동일 스크립트 1회 재검증은 69 PASS/native0이었다. 원인은 미확정이며 해결로 처리하지 않는다. 제품 수정이나 검사 완화를 하지 않았다. QA→DEV 제품 수정 루프는 아직 0회.

## 구현

- STEP36: 저장과 독립된 data/creatures.json 및 CreatureCatalog. 구조/version/필수필드/ID/이미지/scale/weight 검증, 무효 문서 전체 내장001 대체.
- STEP37: 기존3자리 문자열 ID를 유지, 깊은 복사 조회. 미등록 저장ID는 변경·저장 없이 표시만001로 대체.
- STEP38~39: 원본001 PNG/방향/scale 유지, 종 정의에서 알/baby texture와 scale 적용. 부화·장면 재진입에서 현재ID 사용.
- STEP40~41: 별도 RNG의 데이터 가중 추첨. GameManager.create_new_game에서 선택 후 기존 save_version1 creature_id에 저장. factory 기본001 호출 호환. 기존 NameEntry의 저장 성공 후 화면 재시도 경로는 그대로 보존한다.
- STEP42~43: 직접 작성한256×256 SVG002/003 임시이미지·등록·인덱스·실제이미지 교체가이드. 최종 외형 제작 완료로 주장하지 않는다.
- STEP44: 고정seed 확률통계와 실제 메뉴→이름→저장→Game 신규생성 경로를 별개로 검증.

## 실제 실행 증거

runner: tests/step_36_44/run_dev.ps1. 최초 전체실행과 -RetryRender 1회. TEMP 사본에 data/assets/scripts/scenes를 복사하고 별도 userdir을 사용했다. 원본 사용자 저장은 접근하지 않았다. 경로는 step_36_44/dev_paths.json, 해시는 실행폴더 product_hashes.json, 엔진은 version.txt.

|검사|PASS|native|
|---|---:|---:|
|신규 핵심/무효정의/확률/실제메뉴/3종부화·돌봄|66|0|
|3종 각 seed/별도프로세스복원|9|모두0|
|청소 회귀|60|0|
|놀이 회귀|46|0|
|먹기 회귀|38|0|
|이동/Idle 회귀|19|0|
|메뉴/취소/저장 회귀|52|0|
|기존001 egg/baby/hatch seed+별도복원|20|모두0|
|최초 실제렌더+통합검사|69|-1073741819|
|동일사본 렌더 재검증|69|0|

총448 PASS 출력, FAIL/SCRIPT ERROR 0. 반복 검사의 수를 독립 AC 수로 해석하지 않는다. 최초20개 실행결과(재검증 포함)는 results.json에 보존. import 별도 성공. 기존 회귀파일 원본은 변경하지 않았으며 격리사본에서 과거 단일종 fixture를 factory001로 고정했다.

## 확률 결과

|모드|seed|시행수|001|002|003|기준|
|---|---:|---:|---:|---:|---:|---|
|1:1:1|3644|30,000|9,822 (32.74%)|9,991 (33.3033%)|10,187 (33.9567%)|각1/3±1%p PASS|
|1:2:7|4144|30,000|2,969 (9.8967%)|6,126 (20.42%)|20,905 (69.6833%)|각목표±1%p PASS|
|0:0:7|동일 RNG연속|30,000|0|0|30,000|0가중 제외 PASS|

동일seed 재현성도 통과. probabilities.json에 집계 보존. 통계검사가 모든seed/확률의 수학적 보증을 의미하지 않는다. 실제 신규 UI 경로는 세 종 모두 도달했으며 저장ID와 화면의 연결을 검사했다.

## 이미지 직접검토

DEV가 dev_species_001/002/003.png 3개를 직접 열람했다. 원본001 방향·크기 유지,002 녹색귀형+002와003 보라별형+003 식별, 중앙표시·UI비겹침 확인. 임시모양의 최종품질/아트방향 승인은 검증범위가 아니다.

## 한계·후속

- BUG005 재발, 동일사본 재검증 정상이나 원인 미확정. 기존 BUG003/004 범위를 확대해 수정하지 않았다.
- 저장성공 후 장면전환실패 재시도의 ID/해시 보존은 기존 구현을 유지하며 독립 QA 전용검사로 별도 확인한다.
- 사용자 실제기기 터치감·최종이미지 외형은 후속 확인. 002/003 실제 PNG 추가 및 JSON경로 변경 필요: docs/CREATURE_CATALOG.md 참조.
- 독립 QA 및 최종 MANAGER 판정은 별도 보고서. STEP45 미착수.
실행 증거 폴더: J:\2026\Github\damagochi/docs/reports/step_36_44/damagochi-step22-resume-step23-step27-step30-step32-35-dev-step36-44-dev-9c5e35be74914c4e9899553f0a2c870c

