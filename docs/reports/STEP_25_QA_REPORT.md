# STEP 25 독립 QA 보고서

2026-09-29 / S25-DEV-001 실행 확정 A안 / **QA PASS**.

## 기준과 독립성

MANAGER 작업카드와 실제 game.gd, Game.tscn, rice_bowl.svg, GameManager, SaveManager를 읽고 별도 qa_verify.gd를 작성했다. DEV 검사나 PASS를 판정 근거로 대신 사용하지 않았다. QA는 제품 코드와 정책 문서를 변경하지 않았다. 실행은 부모 오케스트레이터가 승인된 권한으로 담당하고 QA가 로그·사본 해시·실제 렌더 화면을 독립 확인했다.

Godot 4.7.2.stable.official.ed1daf0bf, Windows OpenGL Compatibility / Intel Iris Xe에서 검증했다. 임시 프로젝트 사본과 고유 custom_user_dir를 사용했다. 원본 사용자 저장은 읽기·쓰기 모두 수행하지 않았으며 원본 해시 검증을 했다고 주장하지 않는다. 실행 로그의 TEST_USER_DIR와 qa_paths.json으로 테스트 저장 경로의 분리를 확인했다.

## 완료조건

| AC | 판정 | 독립 검증 근거 |
|---|---|---|
| AC1 자산·위치·크기 | PASS | SVG가 96×96 텍스처로 로드되고 모서리 알파가 0. 논리 위치 (360,900), Game 직속 Sprite로 PetArea 이동과 독립. 상태창·버튼·캐릭터 경계와 비중첩. 405×720 알/음식 및 720×1280 음식 PNG를 직접 확인: 그릇 1개, 투명 배경, 화면 내 표시·한글 버튼 정상 |
| AC2 입력·중복·차단 | PASS | 실제 Godot UI 좌표 press/release 10회에서 각각 요청 1개·동일 FoodSprite 유지. 100회 데이터 갱신 후 단일 버튼 연결과 음식 연결 수 유지. Space 입력 정상. 알·부화 시작·baby 빛 fade 중·adult·unknown·빈 데이터는 숨김·차단. 직접 signal/handler 호출은 자격 재검사의 보조 검증 |
| AC3 수명·회귀 | PASS | 입력 후 이동·Idle·원본 방향 유지, 음식 위치 고정. 자격 상실 시 숨김, 다시 baby가 되어도 자동 재표시 없음. 장면 재진입 후 이전 이미지 객체 소멸·새 이미지 숨김, 다시 요청 가능. 별도 프로세스 정상 MainMenu 좌표 이어하기로 baby 복원 시 음식 숨김. 이동 19·메뉴 52·egg/baby/hatch seed 및 복원 20 PASS |
| AC4 데이터·근거 | PASS | 격리 부화 저장 파일의 존재·비어 있지 않은 SHA-256을 먼저 확인. 음식 입력·10회 반복·100회 갱신·상태 전환·장면 재진입 전후 전체 메모리와 저장 파일 SHA-256 동일. 프로세스 복원은 디스크 스냅샷과 비교하고 이후 음식 표시도 메모리·파일 불변. 제품 3종과 매니저 2종 실행 사본 해시 일치 |

최종 **183 PASS, FAIL 0, SCRIPT ERROR 0**. 신규 headless 41, 렌더 44, 신규 별도 프로세스 복원 7, 기존 이동 19, 기존 메뉴 52, 기존 별도 프로세스 seed/복원 20이다. 동일 검사의 실행 환경별 단언 및 fixture를 포함한 집계이며 183개의 서로 다른 기능을 뜻하지 않는다. 모든 최종 실행의 native_exit=0을 별도 status.json에서 확인했다. 메뉴의 손상 저장·실패 주입 관련 ERROR 출력은 예상 회귀 근거이며 스크립트 오류와 구분했다.

## 이력·한계

첫 일반 권한 실행(qa-2244c5caa50342779db058bc2db541f7)은 Godot editor 경로 및 격리 사용자 저장 쓰기가 권한 거부되어 검증 무효였다. 마지막 fixture 검사도 저장이 없어 스크립트 오류가 났다. 원본 접근이나 권한 우회 없이 승인된 실행으로 다시 검증했다. QA 검사에는 저장 존재·비어 있지 않은 해시를 명시적으로 확인하고 비어 있는 fixture 접근을 방어하는 보강을 넣었다. 첫 로그는 보존한다. 이는 환경 실패와 검사 보강이며 제품 수정 루프가 아니다. 최종 실행에는 저장 실패·스크립트 오류가 없다.

사람의 물리 마우스 입력·실기기 터치·화면 체감은 미검증 비차단 후속 확인이다. 좌표와 키보드는 Godot UI 경로를 통과하는 합성 입력이다. 음식은 표시만 구현했으며 먹기·소멸 연출·친밀도·이동 정지·저장 필드 변경을 하지 않았다. 기존 캐릭터/알 이미지의 흰 배경은 이번 음식 자산 변경과 무관한 기존 외형이다.

신규 제품 BUG 없음. 기존 BUG-003/004 유지. **DEV 자동 수정 0회**. 추가 제품 결정·필수 AC BLOCKER 없음. STEP 26은 자동 착수하지 않는다.

## 증거

- 검사: tests/step_25/qa_verify.gd, run_qa.ps1 (-RenderOnly).
- 경로 및 집계: docs/reports/step_25/qa_paths.json, qa_summary.json.
- 최종 증거 폴더: docs/reports/step_25/damagochi-step22-resume-step23-step25-qa-faf2cb0f8e264fedb28731976e383f2a/.
- 로그: qa.log, qa_render.log, qa_resume.log, qa_movement.log, qa_menu.log, qa_seed_*.log, qa_restore_*.log 및 각 status.json.
- 화면: qa_egg_405.png, qa_food_405.png, qa_food_720.png.
- 사본: source_hashes.json. game.gd B9D64737E70D418C457B610446CD6EA8A27EA106887401F0825815B27BF04EC5, Game.tscn 8F7C139849159235285A4B66EAE9D47BAAFEEBB69C6EF387999AA6D1F5CFAC05, rice_bowl.svg EABF0BDDFBD8EB40469EAD3951B0C27B775A2D8BC4822FA649D6A68195081AA2.

MANAGER가 필수 완료조건 PASS와 사용자 후속 품질 확인을 구분해 최종 통합할 수 있다.
