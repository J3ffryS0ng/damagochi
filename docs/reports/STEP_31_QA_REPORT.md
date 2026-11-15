# STEP 31 독립 QA 보고서

2026-10-02 / S31-DEV-001 / M-016 사용자 A 확정 / WORK-ORCHESTRATOR 독립 QA / **PASS**.

작업카드와 실제 game.gd를 독립 검토하고 별도 Timer 검사를 작성했다. DEV 판정을 근거로 대신하지 않았으며 제품 코드를 수정하지 않았다. 권한이 필요한 Godot 실행은 부모가 수행했고 QA가 로그·native status·제품해시·두 PNG를 직접 확인했다.

## 필수 완료조건

| AC | 결과 | 독립 검증 근거 |
|---|---|---|
| 1 주기 | PASS | 실제 one-shot Timer, baby 첫60~120초·즉시요청없음. 전용 RNG1000표본 모두범위내, 낮은절반506/높은절반494, 평균90.075325초. 이동RNG상태 불변. 기본범위 실시간73.589515686초 간격을73.619초 벽시계 대기해 요청1회 및 전체새간격 재시작. 빠른 수명검사에서는0.001초 자연timeout을 별도로사용하며 실제주기검사를 대체하지않음. 중복callback2회 억제, 긴프레임150ms 후 요청1회·몰아발생없음 |
| 2 상태·수명 | PASS | 알·미지원·빈대상·부화진행·부화빛동안 정지, 빛완료후 새주기. 같은대상100갱신에 남은시간/간격/연결1개 유지. feed/play 각각 busy0.35초동안남은시간보존·취소재개. 별도 보완검사에서 두행동 정상완료후남은시간오차0.1초미만·이후0.2초동안재개·각+1. Tree pause0.3초 보존. 갱신없이 동일내용 다른Dictionary로활성대상교체시정지 및 명시갱신시 새주기. 장면종료시 Timer 해제·같은프로세스재진입전체간격·별도프로세스실제저장복원후전체간격. 오프라인누적/Timer저장필드없음 |
| 3 회귀·범위 | PASS | 내부요청전후 전체게임Dictionary와 격리저장SHA256 불변. 이동/Idle 공존. STEP30 독립놀이83+복원6, STEP27 독립급식83+복원7(실제readonly저장실패·rollback포함), 이동19, 메뉴52, 알/baby/부화seed·복원20 통과. 응가이미지/청소/친밀도변경/저장규격추가없음. 405×720·720×1280 실제render2장을 직접확인, 기존원본외형·버튼·상태표시유지, 겹침/잘림없음 |
| 4 증거 | PASS | Godot4.7.2.stable.official.ed1daf0bf, Windows headless/OpenGL Compatibility. 고유TEMP/customuserdir, 원본사용자저장미접근. 현재제품과검사사본5해시일치. 기존797파일중796보존, 허용game.gd만변경. 기존자산/scene/managers/보고/카드/검사/BUG_LOG/COMMON템플릿보존. 기능16프로세스와추가메뉴/Game종료smoke2개 모두native0 |

**319 PASS / FAIL0 / SCRIPT ERROR0.** Timer기본34+별도복원4+정상완료보완7+렌더4+회귀270 단언이다. 반복fixture단언을포함하며1000난수표본을1000PASS로부풀리지않았다. BUG005 종료오류는 이번에 재현되지 않았지만 해결/종결 근거로 보지 않는다. BUG003/004/005 후속유지, 신규확정결함없음·제품자동수정0회. 실제기기 물리입력과 체감은 비차단사용자확인으로남긴다.

## 실행 코드와 보완검사 이력

최초 full검사 실행사본을 만든직후 정상완료검사를 추가한 저장소QA스크립트와차이가발견되었다. 실행중사본을수정하지않고 `qa_verify_initial.gd`를증거폴더에보존했으며 최초full/복원/회귀는 해당사본으로완료했다. 추가정상완료검사는 독립 `completion`모드7단언으로후속실행했다. 보완검사실행전Sprite local중심을global360으로설정한검사코드오류를고쳤다. 제품변경·실패한제품검사·자동수정루프에해당하지않는다. 초기busy취소검사는Sprite위치와무관하게남은시간보존/취소를검증하므로유효하다. 최종저장소스크립트full경로는 이보완내용도포함하지만 최종집계는 실제실행된초기full34+후속completion7로한정한다.

## 증거 위치

- `docs/reports/step_31/damagochi-step22-resume-step23-step27-step30-qa-step31-qa-0bb7c54c515c4f0b9101b4b2265f244b/`: 실제로그·status·version·source_hashes·PNG·초기검사코드.
- `docs/reports/step_31/qa_paths.json`, `qa_summary.json`, `qa_preservation.json`.
- `tests/step_31/qa_verify.gd`, `run_qa.ps1`; 기존30/27/23/22검사는격리사본에서실행, STEP27userdirguard만사본에서조정.
- 검증game.gd SHA256 `6D2B62D73DBFAE3ED35072FA5613FCDFC12D7B87625AA62BC153D2AB109BDFE3`.

기대된무효데이터및읽기전용쓰기거부 ERROR는 SCRIPT ERROR와구분한다. 원본사용자저장해시를읽거나비교하지않았다. STEP32는범위밖이며착수하지않았다.
