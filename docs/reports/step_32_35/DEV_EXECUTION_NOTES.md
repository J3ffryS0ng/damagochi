# DEV 실행 이력 메모

- 최초 사본 `90d1a8e97ff24f51a652f1794798dd89`: 검사 입력이 window 좌표로 해석되어 cleanup 검사 실패 후 nil Tween 검사 예외. 최종 검사에는 root.push_input(event, true)로 viewport 좌표를 명시. 제품 결함 아님. 기존 사본과 로그를 보존. 대기 프로세스 session93282 Ctrl+C 종료(exit1).
- 두 번째 DEV agent 실행 session77391: 좌표 수정 후 핵심 및 별도 복원 PASS, 기본 Timer 대기 중 메인 에이전트 실행과 중복임 확인하여 Ctrl+C 종료(exit1). 완료 검증으로 집계하지 않음. 증거 폴더의 results.json으로 완료한 하위 검사 구분.
- 이후 실행은 메인 에이전트가 담당. 검사/제품 파일 변경을 마친 후 최종 사본 생성. 최신 run_dev.ps1 -CoreOnly는 핵심·별도복원·렌더 검사를 실행하고 이전 회귀/실시간 전체주기 반복은 생략한다.
- 독립 QA 정적 검토에서 발견하여 MANAGER가 BUG006으로 등록한 공유 안내 소유권 오류: 청소 실패→놀이 실패→청소 성공 순서에서 이전 clean flag가 남아 새 놀이 안내를 지우던 문제를, 놀이 실패가 안내를 소유할 때 clean flag를 비우도록 수정. 실제 연쇄 입력 자체검사 4개 추가. QA→DEV 자동수정 1회. 최종 재검증 대기.

- 메인 완료 전체사본 `6a6e0adc3d9e4b0290f4db6a3936300a` 301 PASS/native0. 중복 중단사본은 `a8436a9b7ffd41d58796a36525983749`이며 핵심55/복원2 완료 후 전체 미완료로 분리.
- 최종 `27bde22d8c384127a968f74e8d95a8ba`: 핵심60/복원2 native0, 최초 렌더62PASS 후 native -1073741819(BUG005), 동일사본 재시도62PASS/native0. 최초 실패를 유지하며 PASS WITH ISSUE로 DEV 보고.
- QA 정적 발견 BUG006 안내 소유권 수정 최종 자체검증 PASS. 독립QA 해결 판정은 별도 보고서 참조.
