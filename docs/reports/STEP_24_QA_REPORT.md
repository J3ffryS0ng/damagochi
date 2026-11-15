# STEP 24 독립 QA 보고서

검증 완료: 2026-09-29 / 구현·DEV: 2026-09-28 / S24-DEV-001 실행 확정 절 / **QA PASS**.

## 기준과 독립성

사용자 M-009 A안, 작업카드 AC1~4, MASTER 12절 역할 경계를 기준으로 실제 game.gd·Game.tscn·GameManager·SaveManager를 읽고 독립 qa_verify.gd를 작성했다. DEV PASS를 대신 인용하지 않고 Godot 4.7.2.stable.official.ed1daf0bf에서 좌표·키보드 UI 경로, 상태 전환, 저장·재진입, 기존 이동·메뉴 회귀를 실행했다. QA는 제품 코드나 기준 문서를 수정하지 않았다. 부모 오케스트레이터가 정식 승인된 실행을 담당하고 QA가 코드·로그·화면·해시를 독립 판정했다.

## 완료조건 판정

| AC | 판정 | 독립 근거 |
|---|---|---|
| AC1 표시 | PASS | 알의 한글 버튼 표시·비활성, baby 활성. 부화 시작 및 baby로 바뀐 뒤 빛이 남는 0.48초 시점에도 차단, 빛 종료 후 추가 갱신 없이 활성. egg/adult/빈 stage/unknown/빈 데이터·활성 캐릭터 없음 차단. 405×720 egg/baby와 720×1280 baby 렌더 직접 확인: 글자 잘림·메뉴 겹침·화면 이탈 없음 |
| AC2 입력 | PASS | Viewport 실제 UI 좌표 mouse press/release 5회 각각 요청 1회, focus+Space 1회. 알·빛 연출 중 좌표 입력 0회. 37회 갱신 뒤 단일 연결 유지, 장면 재진입 3회 각각 1요청, 디스크 복원 후 1요청. 직접 핸들러 검사는 빈 데이터 방어의 보조 검사로만 사용 |
| AC3 기존 동작 | PASS | 입력 전후 전체 메모리·저장 SHA-256 동일, 기존 Idle 객체·이동 활성·원본 방향 유지. STEP 23 이동 19 PASS, STEP 22 메뉴 52 PASS, 별도 프로세스 egg/baby/hatch seed·복원 20 PASS. 복원된 메모리는 디스크 스냅샷과 일치하고 이후 버튼 입력으로 변하지 않음 |
| AC4 범위·증거 | PASS | 두 제품 파일과 양 매니저의 실행 사본 해시 일치. 버튼 handler는 조건 검사와 feed_requested.emit만 수행하며 음식·먹기·친밀도·저장 필드·이동 중단 구현 없음. 사용자 원본 저장 전후 해시 동일. QA 보고·로그·화면·검사기 보존. 최종 기준 문서 통합은 MANAGER 책임 |

최종 집계는 **171 PASS, FAIL 0, SCRIPT ERROR 0**이다. 신규 headless 38, 최신 렌더 42, 이동 19, 메뉴 52, 별도 프로세스 seed·복원 20이다. 동일 시나리오의 환경별 단언과 fixture를 포함한 수치이며 서로 다른 기능 171개를 의미하지 않는다. 렌더 재검증 42개는 최초 렌더 42개를 대체하여 중복 합산하지 않았다. 최종 렌더 native exit 0, 전체 headless·회귀 각각 failures=0을 확인했다. 빈 데이터·손상 저장 등의 ERROR는 실패 주입에 따른 예상 출력이며 스크립트 오류와 구분했다.

## 검사 이력과 한계

첫 sandbox 실행은 원본 APPDATA 저장의 읽기 해시 권한 거부로 엔진 실행 전에 중단됐다. 이후 정식 승인으로 원본은 읽기 해시만 수행하고 격리된 custom_user_dir에서 실행했다.

최초 QA 실행의 복원 단언 1건은 검사 기대값 오류였다. SaveManager.save_game()은 메모리를 복제한 저장 사본의 last_played_at만 갱신한다. 그러므로 저장 전 메모리와 복원 후 메모리를 통째로 비교하면 실패한다. 제품 변경 없이 검사만 수정하여 복원 직후 디스크 스냅샷 일치, 요청 수, 입력 전후 복원 메모리, 저장 해시를 각각 검증했다. 재실행 RESTORE_BASELINE 로그의 서로 다른 시각과 개별 PASS로 원인을 확인했다. 최초 실패 증거 qa-40b50e55adc9437db5c17272b9ced0a8을 보존한다.

최초 렌더는 42 PASS·failures=0 뒤 runner가 native 비정상 종료를 감지했다. 당시 raw 종료 코드가 기록되지 않아 원인은 미확정이다. 같은 제품·검사 사본으로 렌더만 재실행하여 42 PASS와 native_exit=0을 확인했고 재현되지 않았다. 첫 로그를 지우지 않았으며 qa_render_retry_status.json에 재실행 원본 저장 해시와 종료 코드를 기록했다. 제품 결함으로 확정할 근거는 없고 반복 발생 시 실행환경·종료 경로를 조사할 관찰 항목으로 남긴다.

좌표·키보드는 Godot UI 경로를 통과한 합성 입력이다. 사람이 마우스로 누른 전체 플레이, 실기기 터치, 기기별 화면·체감 품질은 미검증이며 비차단 사용자 후속 확인이다. 기존 BUG-003/004 후속과 저장 안정성 범위는 유지한다. 신규 제품 BUG 없음. **DEV 자동 수정 0회**이며 검사 기대값 보정 1회·렌더 재확인 1회는 제품 수정 루프가 아니다. STEP 25는 착수하지 않았다.

## 증거

- 실행: tests/step_24/qa_verify.gd, run_qa.ps1. 렌더만 재검증 옵션: -RenderOnly.
- 경로·집계·사본: step_24/qa_paths.json, qa_summary.json, qa_source_comparison.json, qa_render_retry_status.json.
- 최종 폴더: step_24/damagochi-step22-resume-step23-step24-qa-356611800d974877a528b29572c346ac/.
- 화면: qa_egg_405.png, qa_baby_405.png, qa_baby_720.png. 원본 사이즈에서 한글·활성 시각·배치 직접 확인.
- game.gd SHA-256: 56CC9AEA601ACCF13A52A17B4C9E5645A3B565D5C25BCA66B7225BB0066EF858.
- Game.tscn SHA-256: 223144F09FE2CF8EFCE862F60723C9C7C683E6333A8493935106F8D56B640E90.
- 사용자 원본 저장 전후 SHA-256: E5F0C0FE37F6F110FEF2E3FDCC3DB12A73F8BB765A76E10DB0EE02E1E232037D.

MANAGER는 필수 AC PASS와 위 잔여 품질 확인·실행 관찰 항목을 구분하여 최종 통합할 수 있다. 추가 제품 정책 결정이나 필수 AC BLOCKER는 없다.
