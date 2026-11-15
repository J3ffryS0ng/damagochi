# STEP 35 DEV 보고서 — 응가 제거 후 시원한 애니메이션

2026-10-02 / **DEV PASS WITH ISSUE** (기존 BUG005 종료 불안정).

AC1 원본 텍스처/scale/rotation 유지, x67고정 및 0.3초 시점 y-6·0.6초 복귀 확인. AC2 돌봄 입력/Idle/이동/Timer 차단. AC3 정상완료재개/교체/장면이탈정리/조기콜백거부. AC4 실제 렌더 이미지 관찰·기존 이동/메뉴/저장 회귀. 렌더 단언 후 native -1073741819 재관찰은 BUG005로 유지.

통합 근거·실행별 결과·한계: [STEP_32_35_DEV_REPORT.md](STEP_32_35_DEV_REPORT.md). 모든 증거는 step_32_35에 보존. 최종판정은 독립 QA와 MANAGER 담당. QA→DEV 자동수정 1회(BUG006); STEP36 미착수.

