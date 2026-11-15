# STEP 32~35 독립 QA 통합 보고서

2026-10-02 / WORK-ORCHESTRATOR 독립 QA / 작업카드 STEP_32_35_DEV.md / M017~M020 / **PASS WITH ISSUE**.

카드와 실제 제품 코드를 독립 검토하고 새로운 QA 검사·실패 주입을 작성했다. DEV PASS를 검증 근거로 대체하지 않았다. 권한이 필요한 실행은 메인 오케스트레이터가 수행했고 QA가 로그·native status·6개 제품 해시·렌더 4장을 직접 확인했다. QA는 제품 코드를 수정하지 않았다.

## 완료조건 판정

| STEP | AC | 판정 및 근거 |
|---|---|---|
|32|1 이미지/위치/인덱스|PASS. 자체 SVG AST-004 경로 assets/images/poop.svg, 96×96, 전역 Rect2(492,852,96,96), 중심(540,900). ASSET_INDEX 출처/권리/버전/용도 확인. 실제 렌더에서 표시 확인.|
|32|2 실제 Timer/최대1개|PASS. 가속 자연 timeout과 기본범위 실제 Timer 모두 생성. 기본 간격90.761016846초, fixture 준비 뒤 관찰대기90.661초에 생성. 중복 요청은 추가 오브젝트/보상 없음.|
|32|3 정지/청소 후 새 간격|PASS. 존재 중 0.2초 잔여시간 정확 보존. 성공 청소 직후 새60~120초 시작·연출 중 정지·완료 후 감소.|
|32|4 대상/진입/저장규격|PASS. 동일값 다른 Dictionary 교체와 stage 무효화 시 제거. 같은/별도 프로세스 재진입은 응가 없음·전체 새주기. 성장필드 외 저장키 추가 없음, GameManager/SaveManager 해시 기존과 동일.|
|33|1 마우스/터치|PASS. 실제 viewport 입력 전달. 왼쪽 누름 및 터치로 제거, 좌상단 포함·우하단 내부 좌표 통과.|
|33|2 잘못된 입력|PASS. 사각형 밖 네 경계, 오른쪽 버튼, 마우스/터치 해제, 취소 터치 무시. Tree pause 중 입력도 무시.|
|33|3 상호차단/중복|PASS. 먹기·놀이 중 청소 무시 후 예약 없음. 연출 중 feed/play/생성 요청 차단. 연속 mouse+touch로 정확히 한 번만 처리.|
|33|4 취소/교체/기존 버튼|PASS. 오래된 대상 입력 무시, 새 대상 교체 후 이전 연출 취소 및 늦은 완료 콜백 무보상. 기존 feed/play 179개 단언, 별도 복원 포함 통과.|
|34|1 성공당+1|PASS. 입력 순간 한 번 반영, 연출 완료/중복/늦은 콜백 추가 반영 없음.|
|34|2 레벨/UI/복원|PASS. 9/10→0/13, LV2→3. UI label/bar 갱신. 별도 프로세스로 실제 격리 저장 복원해 성장값 확인.|
|34|3 실패/무효 복구|PASS. add가 3필드를 변경하고 false를 반환한 경우 및 save false 주입에서 3필드 복구·응가 유지·안내·재시도. 실제 격리 파일 read-only 오류12에서도 원래 저장 SHA256 보존, writable 복원 후 재시도 성공. null/string/bool/음수/소수/INF/NAN/1e15 및 level/목표0 거부.|
|34|4 중복/취소/회귀|PASS. 취소·완료 추가 보상 없음. feed/play 자체 보상/실패/복원 회귀 통과. BUG006 수정 후 청소 실패→놀이 실패→청소 성공 및 청소 실패→먹기 실패→청소 성공에서 최신 타 행동 오류 안내 보존.|
|35|1 외형/위치/시간|PASS. 시작 x81 고정, 0.3초 부근 y-6, 총0.6초 뒤 종료. 원본 texture/scale/rotation 유지.|
|35|2 충돌 없음|PASS. Idle/이동 중지, 두 버튼 비활성, Timer 정지. 조기 완료 콜백 무시.|
|35|3 복귀/취소|PASS. 정상 완료 Idle/이동 재개. 대상 교체 시 tween 정리, 장면 이탈 시 tween 무효화, 재진입 busy 초기화.|
|35|4 렌더/회귀|PASS 기능 및 시각. 405×720·720×1280 응가/청소 4 PNG 직접 확인: 제거·비활성 버튼·원본 외형 유지, 잘림/겹침 없음. 이동19·메뉴52·알/baby/부화 seed·복원20 단언 통과. native 종료 BUG005는 아래 별도 잔여.|

## 실제 실행 결과

**370 PASS / FAIL 0 / SCRIPT ERROR 0.** 신규 핵심85 + 별도 복원4 + 실제주기3 + 렌더8 + 기존 회귀270. 반복 fixture 단언 포함이며 단언 수를 독립 시나리오 수로 주장하지 않는다. 가속 timeout은 경계/수명 검사이며 기본범위 실제 대기 검사를 대체하지 않는다.

Godot 4.7.2.stable.official.ed1daf0bf. Windows headless 및 OpenGL Compatibility/Intel Iris Xe. 고유 TEMP 프로젝트와 고유 custom user dir 사용. 원본 사용자 저장에 접근하거나 해시를 읽지 않았다. 읽기 전용 변경은 검증된 격리 사용자 경로만 대상으로 하고 finally에서 복구한다. 기대된 SaveManager ERROR 12는 저장 거부 검증이며 SCRIPT ERROR와 구분한다.

기능·복원·회귀15개 및 렌더1개 프로세스 native0. 별도 실제 MainMenu --quit-after120 최초 종료는 **-1073741819**로 실패했고 GDScript 오류는 없었다. 최초 log/status를 qa_native_menu_exit_first.*로 보존했다. 같은 제품·같은 사본·동일 명령 1회 재실행에서 MainMenu와 Game 모두 native0. 이번 DEV 렌더에서도 유사 종료 재발을 보고받았으며 이를 해결로 간주하지 않는다. **BUG005 미해결·비차단 종료 안정성 잔여 때문에 최종 PASS WITH ISSUE**다.

## 자동 수정과 잔여 항목

자동 수정 **1회**: 독립 정적 QA에서 발견한 BUG006 안내 소유권 잔류를 DEV가 수정했다. 수정 전 경로의 정적 원인과 수정 후 독립 실제 연쇄 검증을 구분한다. 수정된 제품에서 두 연쇄 모두 PASS. QA는 제품 수정 없이 검증했다. 최종 QA 검사 자체 오류나 실패 단언은 없다.

BUG003 자동 부화 요구 및 BUG004 전체 로더 검증/부분 쓰기 원자성은 기존 후속 유지. BUG005 종료 실패 원인은 엔진/드라이버/제품 어느 쪽으로도 확정하지 않았다. 저장 손상 근거는 없다. 실제 기기의 물리 터치, 원본 흰 배경을 포함한 외형·0.6초 시원한 연출 체감, 사용자 환경 정상 창 닫기는 비차단 품질 확인 항목이다. 합성 터치/실제 렌더/명령 기반 종료 결과를 실제기기 확인으로 표시하지 않는다. STEP36은 수행하지 않았다.

## 증거

- docs/reports/step_32_35/qa_paths.json 및 qa_summary.json
- docs/reports/step_32_35/damagochi-step22-resume-step23-step27-step30-qa-step32-35-qa-831d63e2ecf4476d8d9585101bbeedd7/: qa*.log, *.status.json, version.txt, source_hashes.json, PNG4장.
- tests/step_32_35/qa_verify.gd, qa_failure.gd, run_qa.ps1. 기존 STEP30/27/23/22 원본 검사를 보존하고 격리 사본에서 실행(STEP27 userdir guard만 사본에서 조정).
- 최종 game.gd SHA256: 35522AE6B2C380490934A77B3BC433383AE319A678BA50C82F1736AB36EEE042.
- Game.tscn: 2DB3163E2A36A6F6C4C00C61FADDF413FC027D5397E8E4774FF5E8B701204091.
- poop.svg: ADE1076E50285508C0D9AD1989E5ACCC9B33FA95456817C79543E64B0E6945F6.
- 검증 사본과 현재 제품 6해시 일치 확인. 기존 카드·보고서·COMMON 템플릿을 QA가 변경하지 않았다.
