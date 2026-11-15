# STEP 29 독립 QA 보고서

2026-10-01 / S29-DEV-001 / WORK-ORCHESTRATOR 독립 QA / **필수 AC1~4 PASS**.

사용자 A 확정 카드와 실제 제품을 독립 검토하고 별도 검사 코드를 작성했다. DEV PASS 판정을 대신 근거로 사용하지 않았다. QA는 제품 코드를 수정하지 않았다. 권한이 필요한 Godot 실행은 부모가 수행했고 QA가 로그·status·PNG를 직접 확인했다.

## 판정과 근거

Godot 4.7.2.stable.official.ed1daf0bf, Windows headless 및 OpenGL Compatibility. **748 PASS, FAIL 0, SCRIPT ERROR 0**. fixture/환경 반복 단언 포함 수치이며 18개 실행 status 모두 native exit 0. STEP28에서 관찰했던 검사 종료 오류는 이번 실행에서 재현되지 않았다. 별도 정상 제품 메뉴/Game 진입·종료도 exit 0.

| AC | 판정 | 독립 증거 |
|---|---|---|
| 1 연출 | PASS | 좌/중/우 x=-120/0/120에서 Idle 중 시작, 기본 y 정렬·현재 x 유지. 수동 Tween 단계로 각 편도0.2초·SINE 중간점9px·정점18px·3회 기본 y복귀·총1.2초 확인. 실제 프레임 경과도1.2초 허용 오차 내. texture/scale/rotation/flip_h/modulate 불변, 완료 후 Idle·이동 재개 |
| 2 입력·수명 | PASS | viewport 좌클릭·focus+Space 새 사이클, 우클릭 무시. 놀이 중 두 버튼 비활성 및 직접 handler/pressed 신호10회 차단·급식 방해 없음·예약 없음. 같은 대상100회 갱신에 Tween/세대 동일·연결1개. 조기/중복 finish 무해. 6개 구간×empty/adult/egg/동일내용 다른 Dictionary/hatch 조건으로 취소·Tween 해제·기본 위치·보상0·버튼 차단 확인. 장면 종료 중 Tween 해제 및 재진입 초기화 |
| 3 회귀 | PASS | 놀이 후 전체 메모리와 격리 저장 SHA256 불변, 실패 안내 유지. 놀이 후 급식+1, 급식 중 놀이 차단. 기존27 QA의 취소0·중복콜백·경계보상·false주입·실제 read-only 쓰기거부 rollback 및 저장 바이트 보존. 기존 이동·메뉴·알·부화 회귀. 별도 프로세스 정상 메뉴 egg/baby복원과 놀이 상태 미복원·새 입력 확인 |
| 4 증거·보존 | PASS | 고유 TEMP/custom userdir, 원본 저장 미접근. 실행사본5파일 해시 일치. 보존baseline616 중615 동일, 허용 game.gd만 변경. 기존 검사/카드/보고/장면/자산/managers/BUG_LOG/COMMON_OPERATIONS_TEMPLATE 유지 |

405×720 및720×1280 PNG8장(좌/중/우 정점과 안내 유지)을 QA가 직접 확인했다. 원본 흰 배경 포함 외형 유지, 캐릭터와 버튼 화면 이탈/잘림 없음, 놀이 중 버튼 비활성 표현과 기존 메뉴 유지, 안내문 비중첩. 실제 기기/물리 입력/점프 체감은 비차단 사용자 후속 확인이다.

검사 집계: 신규놀이271 + 렌더279 + 급식83/별도복원7 + 놀이 seed/복원17 + 이동19 + 메뉴52 + 기존 egg/baby/hatch seed/복원20 =748. 정상 제품 종료 smoke2개는 PASS단언수에 더하지 않았다. 이전STEP28의 즉시 연속요청 검사는 보존하고 M014에 맞는 새 검사를 사용했다.

## 증거 위치

- `step_29/damagochi-step22-resume-step23-step27-step29-qa-3b8b1a50863642ea89f7b076337dd63a/`: 로그/status/PNG/source_hashes.json/version.txt.
- `step_29/qa_paths.json`, `qa_summary.json`, `qa_preservation.json`.
- 검사: `tests/step_29/qa_verify.gd`, `run_qa.ps1`. STEP27 QA는 사본에서 고유 경로 guard만 치환해 실행; 원본 검사 보존.
- 최종 game.gd SHA256 `42FDA13656F357C16F0A53D91C959407B886B21075931D57C5A3E9D7C66560EE`로 현재 제품과 검증사본 일치.

QA 이후 제품 자동 수정0회. QA 실행 자체는 첫 실행부터 모든 단언 통과했다. DEV 자체검증 중 finished 시점 is_valid 판정으로 정상 완료를 막았던1건을 수정한 최신코드를 QA가 검증했으며 DEV 최초 실패 로그는 별도 보존했다. QA 보고 집계 도구의 PowerShell 인수 순서 오류는 명시 인수로 고쳤고 실제 게임 검사나 판정에 영향이 없다.

기대된 malformed/empty fixture와 실제 저장 쓰기거부 ERROR는 오류경로 검증이며 SCRIPT ERROR와 구분했다. 원본 사용자 저장 해시를 비교했다는 뜻은 아니다. 데이터/쓰기거부 검증은 고유 격리 파일에 한정했다. 물리적 부분쓰기·원자 복구 보장은 기존 BUG004 범위로 남는다.

신규 확정 BUG 없음, 기존 BUG003/004 유지. 추가 사용자 결정 없음. STEP30은 미착수이며 이번 놀이로 친밀도·저장을 변경하지 않는다.
