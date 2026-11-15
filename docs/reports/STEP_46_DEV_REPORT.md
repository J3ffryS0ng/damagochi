# STEP 46 DEV 보고서 — 진화 레벨 조건 구현

2026-10-07 / DEV / S46-DEV-001 / M-023 A안 / 판정 PASS

## 구현

제품 변경은 scripts/managers/game_manager.gd의 BABY_TO_ADULT_MIN_LEVEL=5 및 is_evolution_level_met(index: Variant=0) -> bool 추가뿐이다. 네 등록 종 모두 동일 기준을 적용하며 int 인덱스, 정상 배열/사전, 등록 문자열ID, 문자열 baby, int 또는 유한한 정수float 레벨을 확인한다. 조건을 충족하면 true, 그 외는 false다. 누락 데이터 보충/친밀도 조건/실제 성체 전환/저장/추첨을 수행하지 않는다. 기존 egg 부화 및 돌봄 경로는 수정하지 않았다.

사용법과 미등록 저장ID의 표시 fallback 유지 설명은 docs/CREATURE_CATALOG.md에 추가했다. 테스트는 tests/step_46 신규 파일로만 추가했다. 과거 테스트 원본은 보존하며 필요한 돌봄/메뉴 회귀를 실행 사본에서만 고정종 fixture에 맞춰 사용했다.

## 실제 실행 근거

root가 tests/step_46/run_dev.ps1로 Godot 4.7.2.stable.official.ed1daf0bf를 실행했다. docs/reports/step_46/dev_paths.json이 고유 TEMP 프로젝트, 격리 userdir, 증거 디렉터리를 가리킨다. 사용자 원본 저장은 접근하지 않았다. 고유 사본에 스크립트/장면/이미지/카탈로그를 복사했으며 제품 해시 목록은 product_hashes.json, 주요 실행/작업사본 일치는 dev_product_match.json에 기록했다.

| 실행 | PASS | 종료 |
|---|---:|---:|
| 신규 조건 core | 104 | 0 |
| 4종×레벨4/5/6 저장 seed | 1 | 0 |
| 별도 프로세스 restore | 25 | 0 |
| 청소·실패복구 회귀 | 60 | 0 |
| 놀기·실패복구 회귀 | 46 | 0 |
| 먹이·실패복구 회귀 | 38 | 0 |
| 메뉴·이어하기·취소 회귀 | 52 | 0 |
| 합계 | 326 | 7개 모두0 |

각 로그와 results.json에 근거가 있다. FAIL/SCRIPT ERROR/timeout 없음. 예상된 강제 저장 실패 오류는 회귀 시나리오이며 제품 결함이 아니다. BUG005 native 종료 오류는 이번 DEV 실행에서 재현되지 않았으며 해결 판정하지 않는다.

## 완료조건별 자체검증

- AC1 PASS: 4종 각각 level4/5/6 및 JSON용5.0/6.0, 실제 친밀도 보상으로 level4→5 경계 도달.
- AC2 PASS: 잘못된 배열/대상/ID/stage/index/level, 누락필드, bool/string/nonfinite/fraction 입력 안전 false. 반복조회 전후 메모리 사전·저장 바이트·카탈로그/성장 메타데이터 동일. 동일seed 다음64개 추첨열 동일. egg/adult 제외 및 성체 자동 전환 없음.
- AC3 PASS: 네 종 경계12개 레코드를 저장한 뒤 별도 프로세스에서 판정/현재 baby 복원. 기존 부화 egg→baby·반복 부화 거부, 돌봄/취소/저장 실패 복구/메뉴 회귀 통과.
- AC4 DEV PASS: 실제 Godot 실행 및 고유 환경 근거 확보. QA 독립 검증과 최종 원본기록/PNG 보호 감사는 MANAGER/QA 담당.

UI/이미지 변경이 없으므로 신규 렌더 재촬영은 하지 않았다. 레벨 조건은 전체 진화 가능 여부가 아니며 친밀도·연출·성체이미지 연결은 STEP47~49 후속 범위다. 기존 BUG003/004/005의 전체 해결은 주장하지 않는다.

자동 제품 수정 루프0회. 구현 전후 정적검토에서 stage 문자열 타입 검사를 명시했고 실행 FAIL은 없었다. 신규 BUG 없음, 사용자 결정 필요 없음. STEP47 미착수.
