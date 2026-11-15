# STEP 46 MANAGER 최종 판정 — 진화 레벨 조건 구현

2026-10-07 / WORK-ORCHESTRATOR / **PASS · 개발 완료**

사용자의 M-023 A안 승인에 따라 현재 4종 공통 레벨5 이상인 baby의 레벨 조건 판정을 구현했다. MANAGER 카드 → DEV 구현·자체검증 → 독립 QA → MANAGER 통합을 수행했다. 실제 성체 전환은 후속 STEP47~49에서 친밀도 조건·연출·이미지와 통합한다. STEP47은 시작하지 않았다.

## 완료조건

| AC | 판정 | 근거 |
|---|---|---|
| AC1 공통 레벨 조건 | PASS | 001~004 모두 레벨4=false,5/6=true. JSON 정수 float 허용. 실제 친밀도 보상으로 레벨4→5 도달 시 판정 변경 |
| AC2 안전한 읽기 전용 조회 | PASS | baby만 대상. 잘못된 인덱스·배열·대상·미등록ID·stage·level 및 누락값 안전 거부. 조회 전후 메모리·저장 바이트·카탈로그·추첨열 동일 |
| AC3 저장·기존 기능 | PASS | 4종×레벨4/5/6 별도 프로세스 복원, 기존 알 부화·돌봄·취소·실패 복구·메뉴 회귀. 레벨5 baby도 현재 이미지와 돌봄을 유지하며 자동 진화하지 않음 |
| AC4 실제 검증·보존 | PASS | Godot4.7.2 DEV326/독립QA637 PASS. 격리 프로젝트와 고유 userdir 사용, 원본 저장 미접근. 코드·원본 이미지·기존 기록 보존 대조 |

## 구현 및 실행 근거

제품 변경은 `scripts/managers/game_manager.gd`에 추가한 `BABY_TO_ADULT_MIN_LEVEL=5`와 `is_evolution_level_met(index: Variant=0) -> bool`뿐이다. 기존 함수 본문·카탈로그·이미지·씬·save_version1은 유지했다. true는 레벨 선행조건만 뜻하며 전체 진화 승인으로 사용하지 않는다. API 설명은 `docs/CREATURE_CATALOG.md`, 신규 검사는 `tests/step_46`에 기록했다.

Godot 4.7.2.stable.official.ed1daf0bf를 root가 실행했고, DEV/QA는 각자 작성한 검사와 별도 사본의 실제 로그를 분석했다. QA는 제품 코드를 수정하지 않았다.

- DEV: 326 PASS, 7개 검사 프로세스 모두 종료0. core104·저장/복원26·청소60·놀이46·먹기38·메뉴52.
- 독립 QA: 637 PASS, FAIL/SCRIPT ERROR 0, 38개 기능·복원·회귀와 실제 메뉴/Game 종료2개를 합친40개 프로세스 모두 종료0. core213·4종 경계 저장/복원84·돌봄268·메뉴52·기존 부화단계 복원20.
- 최초 실행 실패·재시도 없음. 실행 전 정적 검토에서 stage 문자열 타입 가드를 명시했다. QA 실행 FAIL에 따른 제품 수정 루프는 **0/3회**다.
- UI와 원본 이미지 변경이 없어 STEP45의 화면 검증을 불필요하게 반복하지 않았다. 이번에는 실제 Game 동작·현재 이미지 경로·돌봄 활성과 메뉴/Game 종료를 확인했다.

상세: `STEP_46_DEV_REPORT.md`, `STEP_46_QA_REPORT.md`. 실행 사본/로그: `step_46/dev_paths.json`, `step_46/qa_paths.json`. 실제 권한 실행은 root 담당이고 independent QA 검사·코드/근거 분석은 별도 QA 역할이 담당했다.

## 보존 및 잔여 항목

`step_46/manager_preservation.json` 기준 과거 카드·보고서·검사1,420개 불변. 제품 기준30개 중 GameManager만 변경. COMMON_OPERATIONS_TEMPLATE/BUG_LOG/project.godot 3개 불변. PNG4장·카탈로그·기존 씬·SaveManager 보존. QA 실행 사본의 제품13개는 현재와 동일하고 project.godot은 격리 userdir 설정만 의도적으로 다르다. 기존 미커밋 변경을 되돌리거나 커밋하지 않았다.

신규 버그 없음. BUG003/004/005는 기존 후속 상태를 유지한다. BUG005 종료 오류는 이번 실행에서 재현되지 않았으며 해결 판정하지 않는다. BUG006 돌봄 실패 안내 회귀도 통과했다. BUG_LOG와 공통 템플릿은 수정하지 않았다.

이번 STEP 필수 미검증·추가 사용자 결정·추가 이미지 요청 없음. 기존 실기기/아트 체감 확인은 비차단 후속으로 유지한다. 다음은 **STEP47 — 진화 친밀도 조건 구현**, 작업카드 준비 가능·미착수다.
