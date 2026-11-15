# 캐릭터 종 및 성장 단계 정의

STEP 45 / 2026-10-07 / catalog version 1 / save_version 1 유지.

data/creatures.json은 저장과 분리된다. 루트 version=1, 비어 있지 않은 creatures 배열. 종 필수 필드: 3자리 숫자 문자열 id(중복 불가), 공백 아닌 name/rarity, 유한 숫자 weight(0~1,000,000), res://assets/ 아래 Texture2D 경로 baby_image/egg_image, 양수 유한 숫자 두 개의 baby_scale/egg_scale(각 <=100). 전체 weight 합은 양수. 0은 추첨 제외. 잘못된 문서 전체는 내장001와 기본 성장 단계로 대체하며 경고한다. 조회는 깊은 복사다.

선택은 GameManager.create_new_game에서 전용 난수로 한 번 수행한다. ID만 기존 저장 필드에 기록하며 부화/이어하기/화면 재진입은 추첨하지 않는다. 미등록 저장ID는 그대로 보존하고 화면만 내장001을 표시한다.

## STEP 45 확정 등록과 이미지

사용자가 현재 001 이미지를 교체하고 002~004를 제공했다. 4종은 서로 다른 캐릭터이며 각각 weight1(25%)이다. 테스트 이름/희귀도 형식은 유지한다. 현재 원본 PNG 4장(976×1077)을 그대로 연결하고 공통 scale [0.2633197,0.24048276]로 약257×259px 표시한다. 방향·배경·원본 픽셀은 수정하지 않는다.

- 001: assets/creatures/001/creature_001_idle.png
- 002: assets/images/creatures/002/creature_002_idle.png
- 003: assets/images/creatures/003/creature_003_idle.png
- 004: assets/images/creatures/004/creature_004_idle.png

STEP 36~44의 임시002/003 SVG는 사용자 삭제 상태를 유지한다. 당시 원본 기록은 이전 카드/보고서에 보존한다. 이번 단계에 추가 성체 이미지는 필요하지 않다.

## 성장 단계 메타데이터

루트 stages는 정확히 다음 순서/허용 전이를 갖는다.

| id | name | next_stage |
|---|---|---|
| egg | 알 | baby |
| baby | 유아 | adult |
| adult | 성체 | 빈 문자열 |

각 필드는 문자열이며 name은 공백 불가. 중복/미등록 ID, 순서 변경, 미등록 대상, 순환, 단계 건너뛰기, 잘못된 종단과 타입은 거부한다. 잘못된 stages는 종 정의까지 전체 안전 대체한다. 구 version1 문서의 stages 필드 누락만 기본 단계로 메모리 보완하고, 명시적 null/빈 배열/다른 타입은 거부한다. 입력과 출력은 깊은 복사한다.

CreatureCatalog.get_stages()는 전체 배열, get_stage(id)는 개별 사전(미등록은 {}), get_next_stage(id)는 다음 ID(미등록/종단은 "")를 반환한다. 이 API는 저장·현재 stage·수치를 변경하지 않는다. adult는 후속 구현용 메타데이터이며 현재 부화는 baby까지만 수행한다. 실제 진화 조건·연출·이미지 교체는 STEP 46~49의 범위다.

## 검증 방법

tests/step_45/run_dev.ps1은 TEMP 프로젝트와 고유 userdir만 사용한다. 기존 회귀 원본은 보존하고 사본만 이전001 fixture로 고정한다. 고정 seed 40,000회 각25%±1%p, 별도 1:2:7:0과 0 제외 검증, 4종 알/유아 별도 프로세스 저장복원, 실제 부화/돌봄/렌더 및 구 회귀를 수행한다. 통계검증은 모든 가능한 seed의 수학적 보증이 아니다. 독립 QA의 결과와 실행 증거는 STEP_45 보고서를 따른다.

## STEP 46 진화 레벨 조건

GameManager.BABY_TO_ADULT_MIN_LEVEL=5가 네 종의 공통 기준이다. is_evolution_level_met(index=0)는 등록된 종의 baby이고 level이5이상인 경우만 true를 반환한다. 인덱스는 int여야 하며 누락/잘못된 배열·대상·ID·stage·레벨은 false다. JSON 정수의 float 표현은 허용하지만 문자열/bool/비유한/비정수 숫자는 거부한다. 조회는 기본값 보충·난수 소비·저장·stage·이미지 전환을 하지 않는다. 따라서 true는 레벨 선행조건만 뜻하며 진화 전체 승인이나 자동 성체 전환이 아니다. 친밀도·연출·이미지 통합은 STEP47~49 범위다. 미등록 저장ID의 기존 표시 fallback/원ID 보존은 유지하며 레벨 조건 조회만 false로 판정한다.
