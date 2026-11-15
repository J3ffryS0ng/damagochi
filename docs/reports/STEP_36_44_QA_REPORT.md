# STEP 36~44 독립 QA 보고서

실행·판정: 2026-10-03 / WORK-ORCHESTRATOR QA / Godot 4.7.2.stable.official.ed1daf0bf.

**PASS WITH ISSUE.** 작업카드의 STEP별 AC1~3 및 공통 AC4 기능 검증 통과. 최신 독립 QA 598 PASS, FAIL 0, SCRIPT ERROR 0. 실행 상태 기록 32개 모두 native exit 0. DEV 렌더 종료에서 기존 BUG005가 재발했고 동일 사본 1회 재실행은 정상이나 원인 미확정이므로 전체 종료 안정성 문제를 해결로 판정하지 않는다. 제품 자동 수정 루프 0회.

## 독립성·격리·증거

DEV PASS를 그대로 채택하지 않고 QA가 별도 qa_verify.gd, 고정 seed, 데이터 오류 사례, 실제 메뉴·부화·돌봄·복원·저장 실패·장면 실패 경로를 작성해 별도 TEMP 프로젝트와 고유 custom user directory에서 검증했다. 실제 Godot 실행은 메인 오케스트레이터가 담당하고 QA는 로그·해시·3종 PNG를 직접 열어 분석했다. 제품 코드를 수정하지 않았다. 원본 사용자 저장 파일은 접근하지 않았다.

- 최신 실행: [qa_paths.json](step_36_44/qa_paths.json)
- 최신 증거 폴더: `step_36_44/damagochi-step22-resume-step23-step27-step30-qa-step36-44-qa-afdbacd52374472da77b0d55171933a0/`
- 최초 검사 경로: [qa_paths_initial.json](step_36_44/qa_paths_initial.json)
- 최초 unknown-ID 단언 실패 로그와 `qa_verify_initial.gd`는 `...9910fe38efb442b9bd72092893f330f6/`에 보존했다. 기존 SaveManager는 저장할 사본의 last_played_at만 갱신하는데 QA가 저장 전 메모리를 복원 기대값으로 사용한 검사 오류였다. 제품 변경 없이 저장 후 실제 디스크 데이터 기준으로 보정하고, 001 표시 / 원 ID 및 로드값 보존 / 파일 무변경을 분리해 최신 새 격리 사본에서 전부 재실행했다. 이 최초 FAIL을 제품 버그나 수정 루프로 계산하지 않는다.

## 완료조건별 판정

|STEP|AC1|AC2|AC3|근거|
|---|---|---|---|---|
|36 JSON 설계|PASS: 정의·저장 분리와 규격 문서|PASS: 3종·무효 문서 전체001 대체|PASS: save_version1 및 필드 불변|qa.log 구조/필수/JSON 오류/저장 키 단언, CREATURE_CATALOG.md, 6쌍 복원|
|37 ID 시스템|PASS: 001/002/003 조회|PASS: 중복·형식·미등록·누락 거부/표시 대체|PASS: 깊은 복사·저장 ID 무변경|qa.log ID 및 deep-copy, unknown 3개 독립 단언; 기존 메뉴 누락 ID 거부 유지|
|38 001 등록|PASS: 기존 PNG 경로 등록|PASS: 원본 scale·방향·돌봄 유지|PASS: egg/baby 프로세스 복원|qa.log, qa_restore_001_*.log, 원본 해시, qa_species_001.png|
|39 이미지 연결|PASS: 종별 texture/scale|PASS: 3종 자연 부화·재진입·복원|PASS: 잘못된 이미지/scale 전체 대체|qa.log, 6개 restore 로그, 3종 PNG|
|40 Weight|PASS: test/weight1 세 종|PASS: 0제외·음수/비수치/비유한/과대/모두0 거부|PASS: 1:2:7 데이터 반영|qa.log 검증 및 각30,000회 분포|
|41 랜덤 알|PASS: 실제 메뉴 신규 생성 3종 선택·저장|PASS: 자연 부화·이어하기·실패 후 재시도 재추첨 없음|PASS: 취소/저장 거부 보존·난수 분리|qa.log, qa_retry.log, qa_menu_write_denied.log, qa_restore_*.log|
|42 002 추가|PASS: 임시 SVG·인덱스·교체 가이드|PASS: 알/부화/표시/먹기/놀이/청소|PASS: 저장·별도 프로세스 복원|qa.log, qa_restore_002_*.log, qa_species_002.png|
|43 003 추가|PASS: 임시 SVG·인덱스·교체 가이드|PASS: 알/부화/표시/먹기/놀이/청소|PASS: 저장·별도 프로세스 복원|qa.log, qa_restore_003_*.log, qa_species_003.png|
|44 확률 검증|PASS: 30,000회 균등 각1/3±1%p|PASS: 1:2:7·0제외·동일 seed 재현|PASS: 실제 신규 게임 3종 도달·회귀|qa.log 통계와 실제 메뉴 단언, 회귀 로그|

공통 AC4: 기능·실행·회귀·렌더·복원·증거 보존 **PASS**. 종료 안정성은 별도 기존 BUG005 **남은 문제**. 임시 이미지의 최종 미술 품질은 **사용자 확인 필요**, 이번 기능 STEP 완료를 막지 않는다.

## 확률 결과

|조건/seed|횟수|001|002|003|판정|
|---|---:|---:|---:|---:|---|
|1:1:1 / 736441|30,000|10,051 (33.5033%)|10,047 (33.49%)|9,902 (33.0067%)|각33.3333%±1%p PASS|
|1:2:7 / 964431|30,000|2,995 (9.9833%)|5,960 (19.8667%)|21,045 (70.15%)|각10/20/70%±1%p PASS|
|0:0:7|30,000|0|0|30,000|weight0 제외 PASS|

균등 seed를 초기화한 추가 30,000회가 같은 집계를 재현했다. 이동/응가 RNG를 각각 100회 호출해도 카탈로그의 다음 선택은 독립 seed 기대값과 같았다. 실제 MainMenu→NameEntry→신규 저장 경로로 세 종 도달을 별도 확인했다. 이 통계는 모든 seed에 대한 수학적 보증이 아니다.

## 실행·회귀 집계

- 신규 통합 suite 186 PASS; 종별 egg/baby 6쌍 seed/복원 42 PASS.
- 장면 실패 후 재시도 6 PASS, 실제 저장 쓰기 거부 1 PASS.
- 놀이 83+복원6, 먹기83+복원7, 청소85+복원4 PASS. 실제 격리 저장 파일을 readonly로 만들어 오류 후 메모리·파일 복원도 확인했다.
- 이동19, 메뉴52, 선행 egg/baby/hatch seed·복원20 PASS.
- 실제 렌더4 PASS(격리 확인+3종 PNG). 001 원본과 흰 배경 유지, 002 민트색/003 보라색 임시 도형 및 번호가 서로 구별되며 돌봄 버튼과 겹치지 않음을 직접 시각 확인했다.
- 최신 QA 일반/복원/회귀/렌더/메뉴 종료/Game 종료 기록 32개 모두 native0, FAIL/SCRIPT ERROR0. 기대한 잘못된 입력·파일 접근 실패 로그는 오류 주입 근거이며 정상 실행 오류와 구분했다.

## 제품·자료 보존

`source_hashes.json`의 제품/데이터/asset 12개는 source=격리copy=최종workspace 해시가 일치한다. project.godot은 원본 해시 유지, 사본만 고유 userdir 설정 때문에 의도적으로 다르다. 001 원본 PNG SHA256 `CCDCBDE4C48455B6ECE794AD64CD45293CFDA60C7D3B3F95C2F6592389497FB6`. 기존 회귀 검사 원본은 유지했고 QA 사본에는 격리 경로 검사 문자열만 반영했다. 최종 대조는 `step_36_44/final_product_hashes.json`에도 기록했다. 기존 작업카드/보고서/COMMON 보존 최종 통합은 MANAGER의 history/protected 대조 대상이다.

## 남은 항목

신규 제품 결함 없음. BUG003/004 기존 범위 밖 상태 유지, BUG005 DEV 종료 재발·QA에서는 미재현, BUG006 회귀 통과. 002·003 실제 이미지를 사용자가 제공하고 JSON 연결 및 ASSET_INDEX 상태를 갱신해야 한다. 경로와 방법은 [이미지 교체 가이드](../CREATURE_CATALOG.md) 참조. STEP45는 수행하지 않았다.

