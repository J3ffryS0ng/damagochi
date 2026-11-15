# STEP 30 독립 QA 보고서

2026-10-01 / S30-DEV-001 / 사용자 M015 A(+1) 확정 / WORK-ORCHESTRATOR 독립 QA / **PASS WITH ISSUE — 필수 AC1~4 PASS, 비차단 종료 관찰**.

작업카드와 실제 game.gd를 독립 검토하고 놀이 보상 전용 검사·실패 주입·실제 읽기전용 저장 거부 검사를 작성했다. DEV PASS를 검증 근거로 대신하지 않았다. 제품 코드는 수정하지 않았다. 실행 권한이 필요한 Godot 실행은 부모가 수행했고 QA가 실제 로그/status/hash/PNG를 직접 확인했다.

## AC 검증

| AC | 결과 | 근거 |
|---|---|---|
| 1 보상 | PASS | 0→1, 8→9, 9→레벨3/0/목표13, 기존10→레벨3/잔여1, 연속 사이클, UI·즉시 저장. 별도 프로세스 정상 메뉴 Continue로 전체 데이터/보상 복원 및 자동 재지급 없음, 다음 새 놀이+1 |
| 2 수명·중복 | PASS | 실제 viewport 입력으로 약1.2초 실행, 시작·중간·조기 완료에서 메모리/디스크 불변. 입력10회·같은 대상 갱신100회에 동일 세대 유지, 중복/이전 세대 완료 무시. 여섯 편도 구간마다 취소 후0, 장면이탈0, 알/미지원/빈대상/부화 중/동일내용 다른 Dictionary 교체 취소 및 재입력 거절. 두 행동 상호차단과 정상 Idle/이동 복귀 |
| 3 실패·회귀 | PASS | 음수/NaN/INF/소수/문자열/안전범위초과/비양수 목표·레벨을 실제 놀이 완료 경로로 거절. apply false에 세필드 변경 주입 및 save false에서 레벨업전 세필드 복구·기존 저장 바이트 보존. 실제 readonly 파일 open 거부도 같은 복구. 실패 안내·무효 입력 유지·새 유효 놀이에서 놀이 안내만 제거·급식 안내 보존·급식 시작 기존 초기화. 새 사이클 재시도1회 지급. 급식83+복원7, 이동19, 메뉴52, 알/baby/부화 seed·복원20 회귀 |
| 4 격리·보존 | PASS | 고유 TEMP/custom userdir, 원본 사용자 저장 미접근. 현재제품/사본5개 해시 일치. baseline708 중707 동일, 허용된 game.gd만 변경. 기존 scene/assets/managers/카드/보고/검사/BUG_LOG/COMMON_OPERATIONS_TEMPLATE 유지 |

Godot 4.7.2.stable.official.ed1daf0bf, Windows headless 및 OpenGL Compatibility. 최종 기능 검사 **359 PASS / FAIL0 / SCRIPT ERROR0**, 반복 fixture·renderer 단언 포함 수치. 신규 놀이83 + 별도복원6 + 렌더89 + 급식83/복원7 + 이동19 + 메뉴52 + seed/복원20. 13개 검사 native exit 모두0. 렌더 PNG6장(405×720,720×1280의 apply/save 실패와 성공)을 직접 확인했다. 두 줄 안내 잘림·버튼 중첩 없음, 레벨/친밀도 갱신 정상, 원본 흰 배경 포함 외형 유지. 실제 기기/물리입력/체감은 비차단 사용자 확인으로 남는다.

## 검사 수정과 종료 관찰

최초 QA `957a3660de6048288132c029f41a7b70`의 연속 보상 단언1건이 FAIL이었다. 8→9 다음 보상을10으로 기대했으나 기존 레벨업 규칙에 따라0이 정확하다. QA 기대값만 수정했으며 제품 수정은 없었다. 최초 로그/status를 보존하고 새 고유 사본에서 전체 검사·회귀를 다시 수행해 통과했다. 이 검사 수정은 제품 자동 수정 루프가 아니다.

추가 정상 제품 메뉴 종료 smoke에서 native -1073741819가 한 번 관찰되었다. 기능 검사 exit0와 구분한다. 최초 로그/status는 `qa_native_menu_exit_first`로 보존했다. 같은 사본·동일 제품을 수정 없이 재실행한 menu/Game 종료는 모두 native0이며 QA가 status를 직접 확인했다. 원인은 미확정이고 제품 변경 부재만으로 환경 문제로 확정하지 않는다. 일반 기능 사용 및 필수 AC 검증은 통과했으나 종료 관찰을 숨기지 않고 **PASS WITH ISSUE**로 판정한다. MANAGER는 BUG005에 잠재적 종료 문제로 기록하며 제품 결함 확정과 구분한다. 재발 시 로그/종료환경 조사 필요, 사용자 제품 결정은 불필요하다.

## 증거

- 최종 기능검사: `step_30/damagochi-step22-resume-step23-step27-step30-qa-f47ef0db1d5847b2bbf22a346dd69e5f/`
- `step_30/qa_paths.json`, `qa_summary.json`, `qa_preservation.json`, 실행 폴더의 version/source_hashes/로그/status/PNG.
- 검사: `tests/step_30/qa_verify.gd`, `qa_failure_game.gd`, `run_qa.ps1`. 기존 STEP27/23/22 검사는 격리 사본에서 실행했고 STEP27 userdir guard만 사본에서 조정했다.
- 검증 game.gd SHA256 `39C2EEA734139A6A32AC2196947D83A6DD59EE7689CB39253633B828BA321AD6`.

기대된 무효 데이터 및 실제 쓰기거부 ERROR는 SCRIPT ERROR와 구분한다. 원본 사용자 저장 파일의 해시를 읽거나 비교하지 않았다. 부분쓰기·원자 복구 보장은 기존 BUG004 후속이며, 이번 검증은 실제 쓰기 시작 거부와 메모리 복구에 한정한다. 신규 확정 제품 결함은 없으나 미확정 종료 관찰 BUG005 후속을 남긴다. BUG003/004 유지, 제품 수정 루프0회. STEP31은 이번 범위 밖이다.

