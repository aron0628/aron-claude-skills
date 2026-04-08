# SunnyYK ERP 코드 리뷰 체크리스트

> code-reviewer 에이전트가 Step 4에서 사용하는 체크리스트.
> 마스터 규칙 문서(ykdev-rules.md)의 공통 규칙 + 리뷰 기준 섹션을 기반으로 검사한다.

## 심각도 기준

| 심각도 | 조치 | 리뷰 통과 |
|--------|------|----------|
| CRITICAL | 즉시 실패, executor 수정 후 재리뷰 필수 | 불가 |
| HIGH | 수정 필요, executor 수정 후 재리뷰 | 불가 |
| MEDIUM | 권고사항으로 기록 | 가능 |

## 체크리스트

### 보안 (CRITICAL/HIGH)

- [ ] **SEC-01** (CRITICAL): SQL은 `PreparedWhereMaker` 바인드 변수만 사용
  - `andEqual`, `andLike`, `andIn`, `andBetween`, `andGreaterThan` 등
  - 문자열 결합으로 SQL 생성 시 즉시 실패
- [ ] **SEC-02** (CRITICAL): 암호화 대상 컬럼은 `fnc_encrypt_var()` 사용
  - `BeanObject.isEncryptionField()` 해당 필드 확인
- [ ] **SEC-03** (HIGH): 파일 업로드 경로 검증
  - 경로 traversal 방지 확인

### 네이밍 (HIGH)

- [ ] **NAM-01** (HIGH): `{DOMAIN}{MENU}{PANEL}Controller` 패턴 준수
- [ ] **NAM-02** (HIGH): `@Service(value)` 소문자도메인 + 메뉴번호
  - 예: `@Service(value = "rent0301Service")`

### 코딩 패턴 (HIGH/MEDIUM)

- [ ] **COD-01** (HIGH): Controller는 `RequestDataSet` + `ResponseUtil` 패턴
  - `dataSet.requiredFieldCheck()` → 서비스 호출 → `dataSet.resultToJSON(ResponseUtil.successResult())`
- [ ] **COD-02** (HIGH): Service는 `DefaultService` 상속
- [ ] **COD-03** (MEDIUM): `requiredFieldCheck` 필수 파라미터 검증 적용
- [ ] **COD-04** (HIGH): `BeanObject` 신규 생성 시 `BeanDaoConfig` 등록 확인

### 프레임워크 안전성 (CRITICAL/HIGH)

- [ ] **FRM-01** (CRITICAL): `mobile.factory` 패키지 미수정 확인
  - 수정 시 전체 애플리케이션 영향
- [ ] **FRM-02** (CRITICAL): `BeanObject` 인터페이스 미변경 확인
  - 변경 시 200+ 엔티티 영향
- [ ] **FRM-03** (HIGH): `WEB-INF/jsp/common/` 공통 JSP 미수정 확인
  - 수정 시 전체 페이지 영향
- [ ] **FRM-04** (CRITICAL): `db.column.js` 직접 수정 금지
  - 자동생성 파일

### AOP 고려 (MEDIUM)

- [ ] **AOP-01** (MEDIUM): `_cd` 필드 사용 시 `_name` 자동 매핑 고려
  - `ServiceCodeNameAspect`가 자동 처리
- [ ] **AOP-02** (MEDIUM): 워크플로우 메서드의 `PaperAspect` 알림 고려
  - 서비스 메서드 리턴 후 자동 쪽지/알림 발송

### DB (HIGH/MEDIUM)

- [ ] **DB-01** (HIGH): `entityDao` 선택 올바른 분기
  - Oracle(메인): `entityDao`
  - SMS(Oracle): `entitySmsDao`
  - eBranch(Oracle): `entityEbranchDao`
  - Duzon(MSSQL): `entityDuzonDao`
- [ ] **DB-02** (MEDIUM): 트랜잭션 범위 적절성

## 리뷰 결과 출력 형식

```markdown
## 리뷰 결과

### 위반 사항
| # | 규칙 ID | 심각도 | 설명 | 파일 | 라인 | 상태 |
|---|---------|--------|------|------|------|------|

### 권고 사항
| # | 규칙 ID | 설명 | 파일 | 라인 |
|---|---------|------|------|------|

### 판정
- [ ] 모든 CRITICAL 해소
- [ ] 모든 HIGH 해소
- 최종 판정: PASS / FAIL

### 수정 이력
- Round N: 발견 내역 → 수정 결과
```
