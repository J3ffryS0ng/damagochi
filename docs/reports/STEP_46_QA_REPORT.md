# STEP 46 독립 QA 보고서 — 진화 레벨 조건 구현

2026-10-07 / QA / S46-QA-001 / **PASS**

## 기준과 독립성

사용자 A 승인 및 `docs/tasks/STEP_46_DEV.md` 실행 확정 계약을 기준으로 현재 제품 코드를 독립 검토했다. DEV의 PASS 결과를 전제하지 않고 `tests/step_46/qa_verify.gd`에 별도 입력·경계·부작용·프로세스 복원 검사를 작성했다. 제품 코드는 수정하지 않았다. 실제 Godot 실행은 root 오케스트레이터가 수행했고 QA는 생성된 로그, 종료 상태, 사본 및 보존 해시를 확인했다.

실행 전 정적 검토에서 stage의 명시적 String 타입 검사를 DEV에 요청했고 DEV가 자체 구현 단계에서 반영했다. 이는 QA 실행 FAIL 이후의 자동 수정 루프가 아니다. 실제 QA 첫 실행부터 모두 통과했으며 제품 자동 수정 0회다.

## 완료조건

| 조건 | 판정 | 독립 근거 |
|---|---|---|
| AC1 공통 레벨5 기준 | PASS | 001~004 각각 레벨4/5/6 및 4.0/5.0/6.0 경계, 실제 add_affection으로 4→5 도달 검사 |
| AC2 안전 거부·읽기 전용 | PASS | 누락/잘못된 container·entry·index·creature_id·stage·level, bool/string/null/음수/소수/INF/NAN 거부. 두 번째 유효 인덱스 확인. 반복 조회 전후 메모리·저장 SHA 동일, 독립 RNG와 100회 추첨 일치 |
| AC3 통합·회귀 | PASS | 4종×레벨4/5/6의 12개 저장/별도 프로세스 복원, baby 유지·이미지 유지·자동 진화 없음. 기존 레벨2 자연 부화와 feed/play/clean/메뉴/취소/저장 실패 복구·기존 egg/baby/hatch 복원 통과 |
| AC4 실행·보존 | PASS | Godot 4.7.2, 고유 TEMP 프로젝트와 custom user directory. 637 PASS, 40개 시험 실행 native exit0. 기존 기록 1420개/보호 파일3개 보존. 기존 제품30개 중 GM만 변경 |

## 실제 실행 결과

- 엔진: `4.7.2.stable.official.ed1daf0bf`.
- 독립 신규 suite 213 PASS, 12개 seed 24 PASS, 12개 restore 60 PASS.
- 먹이 83+복원7, 놀이83+복원6, 청소85+복원4, 메뉴52, 기존 egg/baby/hatch seed/restore20 PASS. 총 **637 PASS / FAIL0 / SCRIPT ERROR0**.
- headless 검사38개와 실제 렌더러 MainMenu/Game 종료 스모크2개 모두 native exit0. import도 성공했다. 엔진 import 실행은 위40개 시험 실행 수에 포함하지 않는다.
- 강제 저장 거부 회귀의 의도적인 저장 오류 출력은 rollback·복구 AC의 근거다. 제품의 예기치 않은 오류로 분류하지 않는다.
- BUG005 종료 오류는 이번 실행에서 재현되지 않았다. 기존 이슈가 해결됐다는 뜻은 아니다.

증거: `docs/reports/step_46/qa_paths.json`이 가리키는 `damagochi-step22-resume-step23-step27-step30-qa-step46-qa-5d5df2980d8745b2ba49ed0152fedbcf/`의 로그·status·version·source_hashes. 보존 검사: `docs/reports/step_46/qa_integrity.json`.

## 코드·보존 검토

`GameManager.BABY_TO_ADULT_MIN_LEVEL=5`를 단일 기준으로 `is_evolution_level_met(index: Variant=0)`만 추가했다. int 인덱스, 등록된 종, String baby 단계, int 또는 유한 정수 float 레벨을 확인한다. 저장/기본값 보정/부화/카탈로그 추첨을 호출하지 않으며 기존 게임 동작 함수 본문은 유지된다.

사본 제품 해시14개 중13개가 원본과 정확히 일치한다. `project.godot`은 고유 사용자 디렉터리 설정2줄만 다르며 예상 변경과 정규화 대조했다. 사용자 PNG4개, 카탈로그, 씬, 기존 돌봄 코드는 변경하지 않았다. 기존 tasks/reports/tests1420개와 COMMON/BUG/project 보호3개가 기준선과 일치한다. 원본 저장 파일에는 읽기·쓰기·해시 접근을 하지 않았다.

## 제한·후속

실제 성체 변환, 친밀도 조건, 진화 연출, 성체 이미지 교체는 이번 범위가 아니다. 화면 변경이 없으므로 새 전체 렌더 스크린샷 반복 검증은 수행하지 않았고 현재 이미지의 체감 품질/모바일 실기기 확인은 기존 후속 품질 항목으로 유지한다. 이번 STEP의 필수 AC 중 미검증·사용자 확인 필요 항목은 없다. 신규 BUG 없음. STEP47은 자동 시작하지 않는다.
