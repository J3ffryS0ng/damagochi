# STEP 30 MANAGER 조사 보고

2026-10-01 / S30-DEV-001 / **M-015 사용자 결정 대기**.

사용자 “step 30 시작해줘” 수용. MASTER/STEP_PLAN/BUG_LOG/DECISION_LOG/COMMON_OPERATIONS_TEMPLATE, STEP29 카드·최종/DEV/독립QA보고, 실제 game.gd/Game.tscn·GameManager/SaveManager를 확인했다. STEP29 최종PASS 유지·현재 수용해시 일치:

- game.gd: 42FDA13656F357C16F0A53D91C959407B886B21075931D57C5A3E9D7C66560EE
- Game.tscn: 32B206DB2265DAC84BAD9ED1220ADE4DDD7BE0066C49FDBC3A9DB3B27DC89995

현재 _finish_playing은1.2초 및 시작 대상/generation 확인 후 움직임을 복원하며 보상/저장이 없다. 급식은 기존 GameManager.add_affection·SaveManager.save_game과 세 필드 복구·오류 안내를 사용한다. 놀이 완료에도 대응하는 지급·실패 검증을 추가할 수 있다. M012의+1은 급식에만 확정되었고 M014는 놀이 보상을STEP30으로 유보했다.

M015 제안: A 완료당+1(급식과 같은 단위), B 완료당+3(놀이 성장 강화). 놀이1.2초가 급식1.4~3.4초보다 짧아 A도 시간당 보상이 같지는 않다. 공통으로3점프 완료 후1회·취소/교체0·기존 레벨업/UI/즉시저장·명시적실패 메모리복구/안내·자동재지급없음을 제안한다. 기존 급식 안내 보존, 이전 놀이 안내만 다음 놀이 시작 시 제거. 카드에 구체 범위·AC1~4 기록.

사용자의 최초 운영 지시 ‘제품 정책 결정’ 중단 기준에 따라 수치를 임의 결정하지 않는다. STEP29의 A 승인은 연출 정책이며 보상 수치 승인으로 확대하지 않는다. 영향은 game.gd·필요시Game.tscn 및 신규검증/문서, managers/저장규격/자산/급식보상/기존 연출 유지. 부분쓰기 원자 복구는 BUG004 후속이다.

제품변경·DEV/QA실행없음·자동수정0회. 신규BUG없음, BUG003/004 유지. 기존 카드/보고·공통템플릿·BUG_LOG 보존. 사용자선택 후 DEV부터 이어가며 STEP31 자동착수금지.
