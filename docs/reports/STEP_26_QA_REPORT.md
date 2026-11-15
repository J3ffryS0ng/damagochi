# STEP 26 독립 QA 보고서

2026-09-29 / S26-DEV-001 실행 확정 A안 / **QA PASS**.

## 기준과 독립성

MANAGER 카드, M-011 승인, 현재 game.gd·Game.tscn·매니저 코드를 읽고 독립 qa_verify.gd를 작성했다. 제품 코드는 수정하지 않았다. 실행은 부모 오케스트레이터가 승인된 권한으로 담당하고 QA가 로그·해시·화면을 판정한다. DEV PASS는 대체 근거로 사용하지 않는다.

고유 임시 프로젝트와 custom_user_dir에만 테스트 저장을 생성한다. 원본 사용자 저장은 읽기·쓰기 모두 하지 않는다. 기존 STEP 24/25의 임시 정책 검사는 보존하고 이번 승인 정책을 신규 검사로 검증한다.

## 최초 검사 이력

첫 qa-76c3a26a3c694d508f803b57d3bbda04 실행에 4 FAIL이 있었다. 양끝 접근 중 왼쪽만 단순0.5초 대기 뒤30px 비교에 실패했다. 검사에서 100회 갱신 처리 후 첫 프레임까지의 진행 시간을 누락한 문제를 제거하도록 엔진 Tween의 실제 경과시간과 관측 좌표로 속도를 계산하게 바꿨다.0.45~0.7초 실제 샘플 창과60±0.5px/초를 함께 확인한다. 최초 로그에는 좌표/시간 상세가 없어 최초 샘플값은 소급 추정하지 않는다.

나머지3FAIL은 새 장면에 부화 조건을 갖춘 알 데이터를 합성 주입하면서 기존 정상 부화가 시작된 뒤, 검사에서 즉시 stage를 baby로 되돌려 부화 실패 및 입력 잠금을 유발한 검사 격리 오류였다. 부적격 stage 행렬에서는 이미 앞에서 별도로 검증한 부화를 재발동하지 않도록 테스트 인스턴스의 hatch_effect_played를 true로 설정했다. 제품 수정 없이 검사만 보정했으며 최초 로그와 실패를 보존한다.

## 검증 범위

양끝/중앙부터 실제시간 관측, 순간이동 없음·60px/s 접근,3번6px 몸짓 및1.2초+0.2초 페이드, 음식숨김·알파복구, 원본scale/rotation/방향, Idle/이동 복귀. 연속10요청·100갱신, 실제 좌표클릭·Space, 알·부화빛·빈데이터·지원외stage 차단. 접근/몸짓/페이드 각각 자격상실 취소 및 장면해제·재진입, 이전Tween무효·지연콜백없음. 별도프로세스 정상 메뉴 이어하기, 전체메모리/저장SHA256불변. 기존 이동19·메뉴52·egg/baby/hatch별도복원20 회귀.

정적검토: 하나의 장면에 결속된Tween으로 단계가 연결되고 취소/exit에서 kill된다. busy 상태는 음식 표시 자격과 분리되고 데이터재로드가 먹는Tween이나 Idle을 중복 생성하지 않는다. 친밀도·저장 호출/데이터 필드 추가 없음. 제품변경은 game.gd에 제한된다.

실기기 터치·사람의 물리 입력·연출 체감은 비차단 사용자 확인으로 남긴다. 자동입력은 Godot UI 경로를 지나는 합성 이벤트이다.

## 최종 완료조건 판정

| AC | 판정 | 독립 검증 근거 |
|---|---|---|
| AC1 연출 순서·시간·원본 | PASS | 시작x -120/+120/0에서 최초 위치 동일, 양끝의 실제 경과시간/좌표로60px/s 확인. 중앙 도착 후 x고정, 실제 프레임에서3회하강반전·최대6px·몸짓+페이드1.4초 확인. 원본scale/rotation/flip 유지. 405×720·720×1280 연출중/완료후4PNG 직접 확인: 그릇중앙1개→없음, 버튼비활성→활성, 화면잘림·UI겹침없음 |
| AC2 유효1사이클·차단 | PASS | 10회직접요청+100회load후 동일Tween·단일연결, 별도로 Godot UI좌표클릭1회시작·busy10회무시·Space로다음사이클. egg/baby부화fade/empty/adult/unknown 차단 |
| AC3 복귀·취소·수명 | PASS | 음식숨김/alpha1·버튼복귀·Idle와랜덤이동재개. 접근/몸짓/페이드 각각 자격상실시Tweenkill 및1.5초후콜백없음. 각단계 장면해제후old객체소멸·재진입초기화. 별도프로세스 MainMenu실제좌표이어하기로baby복원후먹기사이클완료 |
| AC4 데이터·회귀 | PASS | 실제 격리부화save존재·SHA256비어있지않음확인, 전체메모리/파일hash가연속사이클·취소·재진입후동일. 복원디스크스냅샷과이후먹기도동일. 이동19·메뉴52·egg/baby/hatch seed/별도복원20PASS. 제품5종실행사본hash일치 |

최종 **227 PASS, FAIL 0, SCRIPT ERROR 0**, 모든11실행 native_exit=0. 신규headless63, 실제renderer67, 신규별도프로세스복원6, 기존이동19, 메뉴52, seed/restore20의 합이다. 같은 기능의 환경별 반복과fixture단언도 포함하며227개의서로다른기능을뜻하지않는다. 첫 실패실행은 최종성공집계에포함하지않는다. 메뉴손상저장·실패주입관련예상ERROR는기존회귀근거이며SCRIPT ERROR와구별했다.

Godot **4.7.2.stable.official.ed1daf0bf**, Windows OpenGL Compatibility / Intel Iris Xe. 화면의 기존 캐릭터 흰배경은 원본자산이며 이번STEP의변경이아니다. 연출감각에대한사용자검토는후속품질확인으로남긴다. DEV제품자동수정 **0회**, QA검사보정1회. 신규제품BUG·추가사용자결정·필수AC BLOCKER없음. STEP27은자동시작하지않는다.

## 최종 증거

- tests/step_26/qa_verify.gd 및 run_qa.ps1 (-RenderOnly).
- docs/reports/step_26/qa_paths.json, qa_summary.json.
- 최종폴더 docs/reports/step_26/damagochi-step22-resume-step23-step26-qa-32a502236d8a403f93466d2e718e768a/.
- qa.log, qa_render.log, qa_resume.log, qa_movement.log, qa_menu.log, qa_seed_*.log, qa_restore_*.log 및각 status.json.
- qa_eating_405.png, qa_finished_405.png, qa_eating_720.png, qa_finished_720.png 직접열람완료.
- source_hashes.json: game.gd `996374F13308A76C178833FA778FD97BE65C9BEF0580D8F6F606C87B54335083`, Game.tscn `8F7C139849159235285A4B66EAE9D47BAAFEEBB69C6EF387999AA6D1F5CFAC05`, rice_bowl.svg `EABF0BDDFBD8EB40469EAD3951B0C27B775A2D8BC4822FA649D6A68195081AA2` 및두매니저사본일치.

MANAGER 최종통합가능.
