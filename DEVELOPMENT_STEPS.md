# CreatureGame 개발 진행표

## 프로젝트 기준

- Engine: Godot 4.7.2 Stable Standard
- Language: GDScript
- Code Editor: Visual Studio Code
- Version Control: Git + GitHub
- Target: Windows EXE / Android APK
- Base Resolution: 720 × 1280
- Project Root: `D:\GitHub\CreatureGame`

## 개발 원칙

- 캐릭터별로 별도의 게임 로직을 만들지 않는다.
- 모든 캐릭터는 공통 코드를 사용한다.
- 캐릭터별 차이는 데이터와 이미지로 관리한다.
- 처음에는 캐릭터 1종으로 전체 시스템을 검증한다.
- 이후 3종, 10종 순으로 확장한 뒤 최종적으로 약 155종까지 늘린다.
- 하나의 STEP이 정상적으로 동작한 뒤 다음 STEP으로 이동한다.
- 각 STEP이 끝날 때 Git commit을 남긴다.
- 사용자에게 코드를 안내할 때는 파일 경로와 파일 전체 최종 내용을 함께 제공한다.

# PHASE 0 — 개발환경

- [X] STEP E01 — Git 및 VS Code 설치 확인
- [X] STEP E02 — Godot 4.7.2 Standard 설치
- [X] STEP E03 — `D:\GitHub\CreatureGame` Godot 프로젝트 생성
- [X] STEP E04 — VS Code에서 프로젝트 폴더 열기
- [X] STEP E05 — Git 저장소 초기화
- [X] STEP E06 — `.gitignore` 작성
- [X] STEP E07 — VS Code Godot Tools 설치
- [X] STEP E08 — Godot 외부 편집기를 VS Code로 설정
- [X] STEP E09 — 외부 변경 자동 Reload 설정
- [X] STEP E10 — Godot LSP 연결 확인
- [X] STEP E11 — `.vscode/extensions.json` 작성
- [X] STEP E12 — `.vscode/launch.json` 작성
- [X] STEP E13 — 프로젝트 해상도 720 × 1280 설정
- [X] STEP E14 — 프로젝트 기본 폴더 생성
- [X] STEP E15 — `MainTest.tscn` 생성
- [X] STEP E16 — `main_test.gd`를 VS Code에서 실행
- [X] STEP E17 — GDScript 자동완성 확인
- [X] STEP E18 — 첫 Git commit
- [X] STEP E19 — GitHub repository 연결 및 push

# PHASE 1 — 게임 골격

- [X] STEP 01 — MainMenu Scene 생성
- [X] STEP 02 — 게임 시작 / 도감 버튼 생성
- [X] STEP 03 — Scene 전환 시스템 구현
- [ ] STEP 04 — 이름 입력 화면 생성
- [ ] STEP 05 — 새 게임 데이터 생성
- [ ] STEP 06 — GameManager 생성
- [ ] STEP 07 — SaveManager 생성
- [ ] STEP 08 — JSON 저장 및 불러오기 구현

# PHASE 2 — 알 육성

- [ ] STEP 09 — Game Scene 기본 UI 구성
- [ ] STEP 10 — 테스트 알 이미지 표시
- [ ] STEP 11 — 알 클릭 및 모바일 터치 영역 구현
- [ ] STEP 12 — 친밀도 변수 구현
- [ ] STEP 13 — 친밀도 UI 구현
- [ ] STEP 14 — 알 터치 시 친밀도 증가
- [ ] STEP 15 — 친밀도에 따른 레벨업 구현
- [ ] STEP 16 — 알 생성 시간 저장
- [ ] STEP 17 — 부화 최소 시간 조건 구현
- [ ] STEP 18 — 레벨 + 시간 부화 조건 결합
- [ ] STEP 19 — 알 좌우 흔들림 애니메이션
- [ ] STEP 20 — 부화 빛 효과 구현
- [ ] STEP 21 — 알에서 캐릭터로 교체

# PHASE 3 — 기본 캐릭터 육성

- [ ] STEP 22 — 캐릭터 Idle 이미지 및 애니메이션
- [ ] STEP 23 — 캐릭터 랜덤 좌우 이동
- [ ] STEP 24 — 밥주기 버튼
- [ ] STEP 25 — 음식 이미지 생성 및 표시
- [ ] STEP 26 — 먹는 애니메이션
- [ ] STEP 27 — 밥주기 친밀도 처리
- [ ] STEP 28 — 놀아주기 버튼
- [ ] STEP 29 — 기뻐하는 애니메이션
- [ ] STEP 30 — 놀아주기 친밀도 처리
- [ ] STEP 31 — 랜덤 응가 Timer
- [ ] STEP 32 — 응가 이미지 생성
- [ ] STEP 33 — 응가 클릭/터치 제거
- [ ] STEP 34 — 응가 제거 친밀도 처리
- [ ] STEP 35 — 응가 제거 후 시원한 애니메이션

# PHASE 4 — 캐릭터 데이터 시스템

- [ ] STEP 36 — `creatures.json` 설계
- [ ] STEP 37 — 캐릭터 ID 시스템 구현
- [ ] STEP 38 — 테스트 캐릭터 001 등록
- [ ] STEP 39 — 이미지 경로를 데이터 기반으로 변경
- [ ] STEP 40 — 희귀도 Weight 데이터 추가
- [ ] STEP 41 — 랜덤 알 선택 시스템 구현
- [ ] STEP 42 — 테스트 캐릭터 002 추가
- [ ] STEP 43 — 테스트 캐릭터 003 추가
- [ ] STEP 44 — 3종 랜덤 지급 확률 테스트

# PHASE 5 — 진화

- [ ] STEP 45 — 캐릭터 Stage 데이터 추가
- [ ] STEP 46 — 진화 레벨 조건 구현
- [ ] STEP 47 — 진화 친밀도 조건 구현
- [ ] STEP 48 — 진화 빛 효과 구현
- [ ] STEP 49 — 진화 캐릭터 이미지 교체
- [ ] STEP 50 — 진화 상태 Save/Load 확인

# PHASE 6 — 도감

- [ ] STEP 51 — Encyclopedia Scene 생성
- [ ] STEP 52 — 전체 캐릭터 목록 읽기
- [ ] STEP 53 — 미발견 캐릭터 `???` 표시
- [ ] STEP 54 — 발견 캐릭터 표시
- [ ] STEP 55 — 조우 횟수 저장
- [ ] STEP 56 — 포획 횟수 저장
- [ ] STEP 57 — 도감 상세 화면 구현

# PHASE 7 — 랜덤 조우

- [ ] STEP 58 — 조우 이벤트 Manager 설계
- [ ] STEP 59 — 조우 최소 Cooldown 구현
- [ ] STEP 60 — 이동 중 조우 확률 판정
- [ ] STEP 61 — 야생 캐릭터 랜덤 선정
- [ ] STEP 62 — 신규 조우 도감 기록
- [ ] STEP 63 — Battle Scene으로 이동

# PHASE 8 — 전투

- [ ] STEP 64 — Battle Scene UI
- [ ] STEP 65 — 플레이어 캐릭터 표시
- [ ] STEP 66 — 야생 캐릭터 표시
- [ ] STEP 67 — HP 시스템
- [ ] STEP 68 — 공격 버튼
- [ ] STEP 69 — 공격 애니메이션
- [ ] STEP 70 — 야생 캐릭터 반격
- [ ] STEP 71 — 잡기 버튼
- [ ] STEP 72 — 포획 확률 계산
- [ ] STEP 73 — 포획 성공
- [ ] STEP 74 — 포획 실패
- [ ] STEP 75 — 도망 버튼
- [ ] STEP 76 — 전투 종료 후 Game Scene 복귀

# PHASE 9 — 최대 6마리

- [ ] STEP 77 — 보유 캐릭터 배열 정식 구현
- [ ] STEP 78 — 최대 6마리 제한
- [ ] STEP 79 — 포획한 캐릭터 추가
- [ ] STEP 80 — 여러 캐릭터 화면 배치
- [ ] STEP 81 — 캐릭터별 독립 이동
- [ ] STEP 82 — 캐릭터별 돌보기 선택
- [ ] STEP 83 — 캐릭터별 친밀도와 레벨
- [ ] STEP 84 — 방출 버튼
- [ ] STEP 85 — 1마리일 경우 방출 금지
- [ ] STEP 86 — 방출 확인 Dialog
- [ ] STEP 87 — 6마리 상태 Save/Load 테스트

# PHASE 10 — 안정화

- [ ] STEP 88 — 게임 종료 후 상태 복원
- [ ] STEP 89 — 오프라인 경과 시간 처리
- [ ] STEP 90 — 응가 Timer 저장/복원
- [ ] STEP 91 — 조우 Cooldown 저장/복원
- [ ] STEP 92 — 잘못된 Save 데이터 대응
- [ ] STEP 93 — UI 해상도 대응
- [ ] STEP 94 — 마우스와 터치 입력 통합
- [ ] STEP 95 — 효과음 시스템
- [ ] STEP 96 — 배경음악 시스템

# PHASE 11 — Windows EXE

- [ ] STEP 97 — Godot Export Templates 설치
- [ ] STEP 98 — Windows Export Preset 생성
- [ ] STEP 99 — 테스트 EXE 생성
- [ ] STEP 100 — 새 PC에서 EXE 실행 테스트
- [ ] STEP 101 — 아이콘 및 게임 정보 설정

# PHASE 12 — Android APK

- [ ] STEP 102 — OpenJDK 17 설치
- [ ] STEP 103 — Android Studio 설치
- [ ] STEP 104 — Android SDK 설치
- [ ] STEP 105 — Godot Java SDK Path 설정
- [ ] STEP 106 — Godot Android SDK Path 설정
- [ ] STEP 107 — Android Export Preset 생성
- [ ] STEP 108 — 테스트 APK 생성
- [ ] STEP 109 — 실제 Android 기기 설치
- [ ] STEP 110 — 터치 및 해상도 테스트

# PHASE 13 — 콘텐츠 확장

- [ ] STEP 111 — 캐릭터 10종까지 확장
- [ ] STEP 112 — 확률 밸런스 테스트
- [ ] STEP 113 — 진화 분기 추가
- [ ] STEP 114 — 캐릭터별 음식 선호도
- [ ] STEP 115 — 캐릭터별 행동 특성
- [ ] STEP 116 — 추가 랜덤 이벤트
- [ ] STEP 117 — 캐릭터 간 상호작용
- [ ] STEP 118 — 도감 UI 개선

# PHASE 14 — 155종 확장

- [ ] STEP 119 — 캐릭터 데이터 관리 방식 확정
- [ ] STEP 120 — 캐릭터 이미지 제작 규격 확정
- [ ] STEP 121 — Animation 규격 확정
- [ ] STEP 122 — 캐릭터 추가 검증 도구 작성
- [ ] STEP 123 — 캐릭터 데이터 일괄 추가
- [ ] STEP 124 — 희귀도 및 조우 확률 밸런싱
- [ ] STEP 125 — 155종 도감 테스트
- [ ] STEP 126 — 전체 Save 데이터 테스트
- [ ] STEP 127 — 성능 및 메모리 최적화

# 각 STEP 설명 요청 시 사용할 형식

각 STEP은 다음 순서로 설명한다.

1. 이번 STEP에서 만드는 것
2. 완료 후 어떤 동작을 해야 하는지
3. Godot Editor에서 클릭해야 할 위치
4. 생성해야 하는 Node와 Scene Tree
5. VS Code에서 생성해야 하는 파일
6. 해당 파일의 정확한 경로
7. 기존 파일이라면 변경 전 핵심 부분
8. 수정해야 하는 코드
9. 수정 완료 후 파일 전체 코드
10. 다른 파일도 변경된다면 각각 동일하게 전체 코드 제공
11. Godot Inspector에서 설정해야 할 값
12. 실행 방법
13. 정상 실행 시 예상 결과
14. 자주 발생하는 오류와 해결법
15. 해당 STEP 완료 후 예상 프로젝트 폴더 구조
16. Git `status` 확인
17. 권장 commit 메시지
18. `DEVELOPMENT_STEPS.md`의 해당 체크박스를 완료 상태로 변경

# 현재 진행 상태

현재 목표:

`PHASE 0 — 개발환경`

다음 개발 시작점:

`STEP E01 — Git 및 VS Code 설치 확인`

환경 설정이 모두 완료되면:

`STEP 01 — MainMenu Scene 생성`

부터 실제 CreatureGame 개발을 시작한다.