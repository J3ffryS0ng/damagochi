# STEP 27 독립 QA 보고서

2026-10-01 / S27-DEV-001 · M-012 사용자 확정 A +1 / **QA PASS**.

## 독립성 및 실행 경계

작업카드와 현재 game.gd, Game.tscn, GameManager, SaveManager를 직접 검토하고 tests/step_27/qa_verify.gd를 독립 작성했다. 제품 코드는 수정하지 않았다. 부모 오케스트레이터가 승인된 권한으로 runner를 실행하고 QA가 로그·화면·소스 해시를 별도로 판정한다. DEV의 PASS를 검증 대체 근거로 사용하지 않는다.

고유 임시 프로젝트와 custom_user_dir에만 저장한다. 원본 사용자 저장은 읽거나 쓰지 않는다. 실패 주입용 qa_failure_game.gd는 테스트 사본에서만 제품 스크립트를 상속한다. 처리 false는 세 보상 필드를 변경한 뒤 실패하도록 하여 복구를 검증하고, 저장 false는 기존 GameManager의 실제 레벨업 후 저장만 거부한다. 별도로 임시 저장파일을 Windows 읽기 전용으로 설정하여 실제 SaveManager의 FileAccess.WRITE 시작 거부·파일 바이트 보존을 검증하며 종료 시 속성을 복구한다.

## 최초 실행과 검사 보정

첫 qa-414f97687a674ffcaa2e78ba4e936297 실행은 신규 headless 83 PASS 후 별도 프로세스 복원 검사 1 FAIL이 발생했다. 화면은 LV.3/친밀도1로 복원되고 다음 급식이 [2,3,13]에 도달했으나, 검사에서 JSON 복원 수치 배열을 정수 배열과 엄격 비교했다. JSON은 숫자를 float로 읽는다. 보정한 검사는 각 수치 값 비교와 전체 저장 Dictionary 일치 검사를 분리하고 TYPE 진단을 남긴다. 재실행 qa_resume.log에서 RESTORED_VALUES=[1.0, 3.0, 13.0], TYPES=3,3,3으로 float 복원을 확인했고 수치·전체 Dictionary 일치가 모두 PASS하여 검사 결함으로 확정했다. 최초 로그는 삭제하지 않는다. 이 보정은 제품 수정 루프와 구별한다.

## 정적 검토

먹기 시작 시 Dictionary 정체성과 generation을 기록하고, 완료 시 현재 활성 대상과 동일한지 다시 검사한다. busy를 먼저 소비하므로 완료 중복 호출은 추가 지급하지 않는다. 유효성은 유한 정수 값·양수 임계값으로 제한되어 기존 add_affection의 0임계값 무한반복을 급식 진입부에서 피한다. 레벨업 계산은 기존 GameManager를 재사용하며 저장 규격/매니저는 변경하지 않는다. 실패 시 친밀도/레벨/다음 목표를 원복하고 UI를 갱신한다. 고장난 디스크의 부분 기록이나 원자적 저장 복구를 보장하지 않으며 이는 기존 BUG-004 범위다.

실제 기기 터치, 사람의 물리 입력, 연출 체감은 비차단 사용자 확인으로 남긴다. 합성 좌표 입력은 실제 Godot 버튼 경로를 통과한다.


## 완료조건 판정

| AC | 판정 | 독립 검증 근거 |
|---|---|---|
| 1 완료당+1·레벨업·화면 | PASS | 접근/몸짓/페이드 중 수치 불변, 완료+1·즉시 디스크 반영. 8→9, 9→레벨3/0/13, 10→레벨3/1/13으로 기존 증가·임계값 도달·잔여 이월 확인. 두 해상도 실제 UI |
| 2 사이클/대상별 정확1회 | PASS | 10요청·100갱신 동일 generation, 이른 완료·완료 중복·stale callback 무지급. 접근/몸짓/페이드 취소와 장면 해제 무지급, egg/adult/empty/hatch/동일내용 다른Dictionary 교체 및 stale idle 신규입력 차단 |
| 3 저장·복원·실패 | PASS | 정상 메뉴 좌표 클릭 별도 프로세스 이어하기에서 전체 저장 일치, 복원 후 다음 완료+1. 처리 false(필드 변이 후 실패)/저장 false/실제 Windows 읽기전용 WRITE 시작 거부에서 세 필드·UI 복구, 파일SHA256 유지, 재시도 새 사이클만 1회 보상 |
| 4 회귀·안전·범위 | PASS | 신규 검사에서 접근60px/s, 정상 이동/Idle/버튼 복귀. 기존 이동19·메뉴52·egg/baby/hatch seed/별도복원20 PASS. 0/음수/NaN/INF/소수/문자/과대수치 진입 방어와 실제0임계값 완료가 무한반복 없이 실패 안내. 매니저/저장/자산 변경 없음 |

최종 **272 PASS, FAIL 0, SCRIPT ERROR 0**, 11실행 native_exit 모두0. 신규 headless83, renderer91, 별도프로세스복원7, 이동19, 메뉴52, seed/restore20의 합이다. 환경별 반복·fixture 단언을 포함하며272개 서로 다른 기능을 뜻하지 않는다. 최초 실패실행은 최종성공 합계에서 제외했다. 의도한 파일열기거부 ERROR12 및 기존 손상저장회귀의 예상ERROR는 SCRIPT ERROR와 구별한다.

Godot **4.7.2.stable.official.ed1daf0bf**. OpenGL Compatibility 실제 렌더 405×720·720×1280의 실패(처리/저장)4장, 먹기2장, 성공2장을 QA가 직접 열람했다. 두 줄 실패 안내가 버튼/캐릭터와 겹치지 않고 잘리지 않으며 성공 시 안내가 사라진다. 연출 중 그릇1개·버튼비활성, 완료 후 음식제거·레벨/친밀도/게이지 갱신·버튼활성을 확인했다. 캐릭터의 흰 배경은 기존 자산이다.

DEV 제품 자동 수정 **0회**, QA 검사 보정1회. 신규 제품 BUG·추가 사용자 결정·필수 AC BLOCKER 없음. 물리 입력/터치/체감은 사용자 환경의 비차단 품질 확인이다. STEP28은 시작하지 않는다.

## 증거

- tests/step_27/qa_verify.gd, qa_failure_game.gd, run_qa.ps1.
- docs/reports/step_27/qa_paths.json, qa_summary.json.
- 최종폴더 docs/reports/step_27/damagochi-step22-resume-step23-step27-qa-94a44c4df27540dfad58eece8ad6c188/의11로그·상태 JSON·8PNG·source_hashes.json.
- 최초 qa-414f97687a674ffcaa2e78ba4e936297의 qa.log와 qa_resume.log 보존.
- 제품 실행사본 해시: game.gd `4CEF236002023D1E2257383F1C56022CE6F6CBDC4DDABCB204B4BA54987236D9`, Game.tscn `560F47CD9AB9167F3DC604392F88D322012606269F895B9FDBA20FB96C199DD5`; rice_bowl.svg 및 양 매니저도 원본과 동일하다. 원본 사용자 저장 미접근.
