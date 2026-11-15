# STEP 45 DEV 보고서

2026-10-07 / DEV 자체검증 PASS / MANAGER 최종판정 및 독립 QA는 별도.

## 구현

확정 카드 STEP_45_DEV.md에 따라 CreatureCatalog와 data/creatures.json만 제품 수정했다. egg→baby→adult 단계 메타데이터와 읽기 전용 조회 API(get_stages/get_stage/get_next_stage)를 추가했다. 단계 순서·중복·필수 필드·유효 문자열·전이·종단을 검증하고, 불량 문서 전체는 내장001+기본3단계로 안전 대체한다. stages 없는 구version1 카탈로그만 기본 단계를 메모리 보완한다. 조회/입력은 깊은 복사하며 저장과 현재단계는 변경하지 않는다.

001은 사용자가 교체한 현재 원본을 보존하고, 002/003/004 사용자 PNG를 연결했다. 4종 weight1, 각25%, 976×1077 원본에 공통scale[0.2633197,0.24048276]. 임시SVG 삭제 상태를 존중하고 복원하지 않았다. ASSET_INDEX와 CREATURE_CATALOG 안내를 갱신했다.

Game, GameManager, GameDataFactory, SaveManager, 씬, 원본PNG와 과거 카드/보고서/검사는 수정하지 않았다. 자동 adult 전환·진화 조건·성체 연출/이미지 구현은 하지 않았다. STEP46 미착수.

## 실행 및 증거

root가 권한 승인된 실행을 담당했고 DEV는 검사 작성/증거 분석을 수행했다. Godot 4.7.2.stable.official.ed1daf0bf, 독립 TEMP 프로젝트/고유 userdir. 원본 사용자 저장 접근 없음.

- 실행기: tests/step_45/run_dev.ps1
- 경로 기록: docs/reports/step_45/dev_paths.json
- 증거 디렉터리: docs/reports/step_45/damagochi-step22-resume-step23-step27-step30-step32-35-dev-step45-dev-d83f1175d85f4880b595f6f366685ad8
- 실행 결과: results.json / 29개 검사 프로세스 모두 종료0 / 총539 PASS / SCRIPT ERROR 또는 FAIL 없음. 별도 import 성공.
- core134, render138, 4종×egg/baby seed/restore32, 청소60, 놀이46, 밥38, 이동19, 메뉴52, 구저장 egg/baby/hatch20 PASS.
- 과거검사 원본 보존. 기존 단일종 회귀는 격리 사본에서만 create_new_game 호출을 이전001 factory fixture로 고정. 제품 테스트 범위는 신규 검사에서 실제 4종 추첨으로 별도 검증.

## AC 결과

| AC | DEV 판정 | 근거 |
|---|---|---|
| AC1 단계 데이터/호환 | PASS | 정확순서/전이, 필드누락/잘못된타입/null/빈값, 순환/미등록/건너뛰기/중복 거부, unknown 안전조회, deepcopy, legacy 기본값 |
| AC2 이미지/확률 | PASS | 4종실제 새게임 도달, PNG경로/scale/표시크기, 40,000회 고정seed 균등·가중·0제외, 렌더4장 |
| AC3 기존행동/저장 | PASS | 4종별 egg/baby 다른 프로세스 복원, 부화ID유지/밥·놀이·청소각+1/이동Idle재개, 단계조회 전후 메모리와 저장해시 동일, 메뉴/취소/실패모사 회귀 |
| AC4 실행근거 | DEV PASS | 위 실제실행/로그·PNG·해시, 독립QA는 STEP_45_QA_REPORT 참고 |

균등 seed3644 / N=40,000: 001=9,967(24.9175%), 002=9,855(24.6375%), 003=10,038(25.095%), 004=10,140(25.35%). 모두25%±1%p.
가중 seed4144 / 1:2:7:0 / N=40,000: 3,987 / 8,102 / 27,911 / 0. 추가0:0:7:0은40,000회 모두003.

dev_species_001~004.png를 직접 검토했다. 서로 다른 사용자 이미지가 화면 중앙에 표시되며 가장자리나 UI에 잘리지 않고 원래 방향을 유지한다. 원본 투명영역/선의 모양은 그대로 보존했다. PNG표시 약257×259px와 좌우공통이동범위가 화면에 들어간다.

## 해시

- creature_catalog.gd: 6D3806F36E38409F0F1307E4606FEE3D50D3217252982F5C39E703B04DC68B0D
- data/creatures.json: ACFF607ABF8CE0F3F315D43DB0D118807BB6EB09117BEE505A0BE12C2E835CF7
- 001 PNG: 8F555F64F7EAD7C2891FF055D1A450DF1CAA4E40F9381F416D024C33B1DB2E4C
- 002 PNG: 6F80A71E5D3C4E4B9D5FCDA2413848B012300CBFBC84B672A1082F2C50CC0B04
- 003 PNG: 1A4841263559754A3143546D228EF5BE5DBC7E361C5B2A2D9314BCC68A0A884A
- 004 PNG: 7D772761B827689CA384A5CFA534DDCC3BB379E4EB9F5C94385F0FF567FCA999

실행시점 product_hashes.json과 일치. 실제 사용자 저장의 해시를 읽었다는 의미가 아니다.

## 이슈/범위

제품 자동수정 0회, 실행검사 실패 0회, 재실행 0회. DEV 이번 실행에서 BUG-005 종료오류는 재현되지 않았지만 원인 미확정인 기존 문제를 해결 판정하지 않는다. 신규 제품 버그 없음. 실제 쓰기거부 및 독립 fixture 검증은 QA 결과와 통합한다. 성체는 데이터 정의만 완료이며 실제 진화와 성체 외형은 후속 STEP 46~49 범위다.
