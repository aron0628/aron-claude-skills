---
name: ykdev
description: SunnyYK ERP 전용 개발 파이프라인 (문서분석→계획→개발→리뷰→수정→검증→커밋)
triggers:
  - ykdev
  - 개발진행
argument-hint: "<문서경로 또는 요구사항> [--step analyze|plan|dev|review|verify|commit] [--skip-review] [--skip-commit] [--consensus] [--deliberate] [--all] [--restart]"
level: 4
---

# ykdev — SunnyYK ERP 개발 파이프라인

<Purpose>
SunnyYK ERP 프로젝트의 개발 프로세스를 표준화하는 파이프라인 스킬.
요구사항 문서(PDF/이미지/텍스트) 분석부터 구현 계획, 개발, 코드리뷰, 검증까지 5단계를 자동 실행한다.
기존 OMC 에이전트(analyst, planner, executor, code-reviewer, verifier)를 SunnyYK 규칙과 순서로 조합한다.
</Purpose>

<Use_When>
- "ykdev" 또는 "개발진행" 키워드 사용 시
- PDF/이미지 기반 개발 요구사항 문서를 분석하여 구현할 때
- SunnyYK ERP의 표준 개발 프로세스를 따라야 할 때
</Use_When>

<Do_Not_Use_When>
- ERP 외 프로젝트 작업 시 (범용 devpipe 스킬 사용)
- 단순 질문이나 코드 설명 요청 시
- CLAUDE.md 또는 설정 파일 수정 같은 비개발 작업 시
</Do_Not_Use_When>

<Configuration>
rules_file: "/Users/aron/Library/Mobile Documents/iCloud~md~obsidian/Documents/01. Projects/SunnyYK-ERP/ykdev-rules.md"
obsidian_base: "/Users/aron/Library/Mobile Documents/iCloud~md~obsidian/Documents/01. Projects/SunnyYK-ERP"
omc_plans: ".omc/plans"
build_cmd: "./gradlew compileGroovy"
test_cmd: "./gradlew test"
templates_dir: "~/.claude/skills/ykdev/templates"
metrics_file: "{obsidian_base}/_metrics.md"
static_analysis_rules: "~/.claude/skills/ykdev/templates/static-analysis-rules.yml"

domains:
  acnt: 회계
  sale: 영업
  part: 부품
  rent: 렌탈
  serv: 서비스/A/S
  cust: 고객관리
  comp: 회사/조직
  mmyy: 인사/총무
  comm: 공통
  mobi: 모바일
  bat: 배치
  tax: 세금

naming:
  controller: "{DOMAIN}{MENU}{PANEL}Controller"
  service: "{domain}{menu}Service / {domain}{menu}ServiceImpl"
  service_value: "@Service(value = \"{domain}{menu}Service\")"
  jsp: "{domain}{menu}.jsp"
  jsp_popup: "{domain}{menu}p{seq}.jsp"
  entity: "Bean{TableName}"

templates:
  controller: "templates/controller.java.tmpl"
  service_impl: "templates/service-impl.java.tmpl"
  service_interface: "templates/service-interface.java.tmpl"
  jsp_grid: "templates/jsp-grid.jsp.tmpl"
  jsp_popup: "templates/jsp-popup.jsp.tmpl"
</Configuration>

<Steps>

## 파이프라인 실행

### 0. 초기화

1. 인자 파싱: `--step`, `--skip-review`, `--skip-commit`, `--consensus`, `--deliberate`, `--all`, `--files`, `--restart` 옵션 확인
2. **규칙 로드 (메인 오케스트레이터가 직접 수행)**:
   - ykdev-rules.md를 Read하여 **전체 내용**을 변수 `${RULES_CONTENT}`에 보관
   - 이후 모든 서브에이전트 프롬프트에 `<ykdev-rules>` 태그로 통째 주입
3. **작업 유형 판별 + REF 문서 로드 (메인 오케스트레이터가 직접 수행)**:
   입력 분석 후 작업 유형을 판별하고, 해당 REF 문서를 Read하여 `${REF_CONTENT}`에 보관:
   - 백엔드(Service/Controller): REF-01, REF-03, REF-05
   - 프론트엔드(JSP/JS): REF-01, REF-02, REF-04, REF-06, REF-07
   - DB 작업: REF-01, REF-03
   - 풀스택(백엔드+프론트엔드): REF-01~07 전부
   REF 문서는 `<ref-documents>` 태그로 서브에이전트 프롬프트에 주입
4. **[필수] 메트릭 & 자동 튜닝 로드 (메인 오케스트레이터가 직접 수행 — 이 단계를 건너뛰지 마라)**:
   - 메트릭 파일 경로: `/Users/aron/Library/Mobile Documents/iCloud~md~obsidian/Documents/01. Projects/SunnyYK-ERP/_metrics.md`
   - 위 경로의 파일을 Read 시도한다.
   - **파일이 존재하면**: "자동 튜닝 현황" 섹션에서 **강조 주입 대상 규칙**을 추출하여 `${TUNING_RULES}`에 보관
   - **파일이 존재하지 않으면 (Read 실패 시)**: `~/.claude/skills/ykdev/templates/metrics.md.tmpl`을 Read한 뒤, 그 내용을 위 메트릭 파일 경로에 Write하여 초기 생성한다. 생성 후 `${TUNING_RULES}`는 빈 값으로 설정한다.
   - 이후 executor/code-reviewer 프롬프트에 `<tuning-emphasis>` 태그로 `${TUNING_RULES}` 주입
5. 기능 폴더 결정 (3뎁스 기준 분리):
   PDF/이미지 문서의 헤더에서 **3뎁스(x.x.x) 번호**를 기능 분리 기준으로 사용한다.
   - 문서 헤더 형식: `{1뎁스}. {모듈} > {1뎁스}.{2뎁스}.{3뎁스} {분류} > {기능명}`
     예: `2. 렌탈 > 2.3.1 기능개선 > 렌탈기준정보-어태치먼트`
   - **3뎁스(x.x.x) 번호가 바뀌면 별도 기능 폴더**로 분리한다:
     - `2.3.1-렌탈기준정보-어태치먼트` → 폴더 1
     - `2.3.2-렌탈장비대장상세` → 폴더 2
   - 같은 3뎁스 번호의 연속 페이지는 하나의 기능으로 묶는다 (예: 2.3.2가 2~3페이지에 걸쳐 있으면 하나의 폴더)
   - 폴더명 형식: `{3뎁스번호}-{기능명}` (예: `2.3.1-렌탈기준정보-어태치먼트`)
   - 텍스트 요구사항(PDF 없음)이면: `{YYYYMMDD}-{기능명}` (예: `20260403-장착옵션추가`)
   - `--all` 옵션 시: PDF 전체를 스캔하여 3뎁스 단위로 모든 기능 폴더를 한번에 생성하고 순차 실행
6. 옵시디언 기능 폴더 생성: `{obsidian_base}/{기능폴더}/` (3뎁스별 각각 생성)
7. **`00-input.md` 생성** (최초 실행 시): 원본 입력 정보 저장
   ```markdown
   # 입력 정보
   - 문서: @document_for_dev.pdf
   - 페이지: 2~3
   - 기능명: 2.3.2 렌탈장비대장상세-장착옵션
   - 실행일: 2026-04-03
   ```
8. `--restart` 지정 시 → **재시작 처리** (아래 참조)
9. `--step` 지정 시 해당 단계만 실행, 미지정 시 전체 파이프라인 실행
10. `--step X..Y` 형태면 X부터 Y까지 범위 실행

### 0-1. 재시작 (`--restart`)

기존 기능 폴더가 존재할 때만 동작한다.

**입력 방식:**

| 방식 | 예시 | 동작 |
|------|------|------|
| 폴더명만 | `ykdev 2.3.2-렌탈장비대장상세-장착옵션 --restart` | `00-input.md`에서 원본 입력 읽어 재실행 |
| PDF 재지정 | `ykdev @document_for_dev.pdf 2~3페이지 개발 --restart` | `00-input.md` 덮어쓰기 후 재실행 |

**처리 순서:**
1. 기능 폴더 내 산출물 삭제 (`01-analysis.md`, `02-plan-draft.md`, `02-plan.md`, `03-review.md`, `04-verify.md`, `05-commit.md`, `summary.md`, `context-chain.md`)
2. `00-input.md`는 유지 (PDF 재지정 시에만 덮어쓰기)
3. `.omc/plans/` 내 해당 기능 관련 파일 삭제
4. `_index.md` 상태를 `📋 Step 1 분석 (restart)`으로 리셋
5. Step 1부터 자동 실행

### Step 1: 문서 분석

**에이전트**: `analyst` (opus)
**산출물**: `{obsidian_base}/{기능폴더}/01-analysis.md`

1. **과거 구현 검색 (Experience Replay)**:
   메인 오케스트레이터가 직접 수행한다.
   - `_index.md`에서 완료된 기능 목록을 읽는다
   - 현재 기능과 유사한 과거 기능을 검색한다 (도메인 일치, 키워드 유사도):
     - 같은 도메인의 기능 폴더를 우선 탐색
     - 기능명에서 핵심 키워드를 추출하여 매칭 (예: "어태치먼트", "팝업", "그리드", "조회", "등록")
   - 유사 기능이 발견되면 해당 폴더의 `03-review.md`를 읽어 **과거 위반 사항**을 추출:
     - CRITICAL/HIGH 위반 규칙 ID와 설명
     - 수정에 걸린 라운드 수
   - 추출 결과를 `${EXPERIENCE_CONTEXT}`에 보관
   - 유사 기능의 `02-plan.md`에서 **구현 패턴 요약**도 추출 (어떤 테이블, 어떤 패턴 사용했는지)
   - 결과를 analyst 프롬프트에 `<experience-replay>` 태그로 주입

2. `analyst` 에이전트 호출 (opus):

```
Agent(subagent_type="oh-my-claudecode:analyst", model="opus", prompt="
**[필수 규칙 — 아래 규칙을 모두 준수하라. common + planner 섹션 적용]**

<ykdev-rules>
${RULES_CONTENT}
</ykdev-rules>

<ref-documents>
${REF_CONTENT}
</ref-documents>

<experience-replay>
${EXPERIENCE_CONTEXT}
(과거 유사 기능의 위반 이력 및 구현 패턴. 없으면 '유사 기능 없음')
</experience-replay>

---
SunnyYK ERP 개발 요구사항을 분석하라.

[입력 문서/요구사항 내용]

분석 항목:
1. 요구사항 추출
   - 빨간 글씨 = 핵심 요구사항
   - 파란 주석 = 구현 힌트
   - '개발진행' 마커 = 구현 대상
2. 화면 경로 식별 (ERP > 도메인 > 메뉴)
3. 도메인 매핑: {domains 설정 참조}
4. 컨트롤러/서비스/JSP 파일명 추정: {naming 설정 참조}
5. 영향도 분석:
   - explore 에이전트로 관련 파일 탐색
   - **조회 대상 테이블의 데이터 관리 화면(CRUD) 탐색 및 쿼리 패턴 분석 (ANL-01~03)**
   - mobile.factory 영향 여부
   - DB 테이블/뷰 변경 필요 여부
   - 외부 시스템 연동 여부
6. 복잡도 판단: 단순/복잡/고위험
7. 과거 유사 기능 참고사항 (experience-replay 기반)

출력 형식: 마크다운
")
```

3. 분석 결과를 `01-analysis.md`로 저장
4. `.omc/plans/`에도 병행 저장
5. **컨텍스트 체인 시작**: `context-chain.md` 생성

```markdown
# 컨텍스트 체인 — {기능명}
> 각 Step의 핵심 판단/결정을 누적 기록. 다음 Step에 전달.

## Step 1: 분석 (${날짜})
- 복잡도: {단순/복잡/고위험}
- 핵심 요구사항: {1~2줄 요약}
- 주요 영향 파일: {파일 목록}
- 과거 유사 기능: {있으면 폴더명 + 주의사항}
- 판단 근거: {왜 이 복잡도로 판단했는지}
```

6. **산출물 자동 검증** (사용자에게 제출 전 자동 실행):
   - 01-analysis.md를 읽고 아래 규칙을 대조한다. 미통과 시 자동 수정 후 재검증:
   - [ ] NAM-01~04: 추정 파일명이 네이밍 규칙에 맞는가? 신규 팝업이면 **호출 위치 기준**으로 1차(p{seq}) vs 서브팝업(p{부모seq}{자식seq})을 구분했는가? (NAM-03/REF-04)
   - [ ] DB 변경이 식별되었으면 복잡도가 "복잡" 이상으로 판단되었는가?
   - [ ] 외부 시스템 연동이 있으면 해당 Manager 클래스가 명시되었는가? (EXT-01)

### Step 2: 구현 계획

**산출물**: `{obsidian_base}/{기능폴더}/02-plan-draft.md` → 승인 후 `02-plan.md`

1. `01-analysis.md` 로드하여 복잡도 확인
2. 복잡도 기반 자동 분기 (오버라이드 옵션 우선):

| 조건 | 모드 |
|------|------|
| `--consensus` 지정 | 강제 ralplan 합의 |
| `--deliberate` 지정 | 강제 ralplan deliberate |
| 복잡도 = 단순 | planner 직접 (omc-plan) |
| 복잡도 = 복잡 | ralplan 합의 |
| 복잡도 = 고위험 | ralplan deliberate |

**고위험 자동 감지 조건** (ERP 맥락):
- DB 스키마 변경 (테이블/컬럼 추가, 뷰 수정)
- 금액/정산 로직
- 보안/인증 (`CustomAuthenticationProvider`)
- 암호화 컬럼 (`fnc_encrypt_var()`)
- 외부 시스템 연동 (Duzon, John Deere 등 13개)
- 프레임워크 영향 (`mobile.factory`, `BeanObject`)

3. 계획 수립 시 SunnyYK 컨텍스트 주입:
   - Step 1 분석 결과
   - CLAUDE.md 코드 패턴 (Controller/Service/JSP 작성법)
   - PreparedWhereMaker 패턴
   - AOP 자동실행 규칙
   - **과거 유사 기능 경험** (`${EXPERIENCE_CONTEXT}`) — 과거 위반 사항을 계획에 선제 반영
   - **코드 템플릿 참조 지시**: 신규 파일 생성 시 `templates/` 디렉토리의 템플릿을 기반으로 구현하도록 계획에 명시
   - **planner/architect/critic 에이전트 프롬프트에 규칙 + REF를 직접 주입한다:**

```
**[필수 규칙 — 아래 규칙을 모두 준수하라. common + planner 섹션 적용]**

<ykdev-rules>
${RULES_CONTENT}
</ykdev-rules>

<ref-documents>
${REF_CONTENT}
</ref-documents>

<experience-replay>
${EXPERIENCE_CONTEXT}
</experience-replay>
```

4. **모드 A (단순)**: `planner` (opus)로 직접 계획

5. **모드 B (합의)**: `Skill("oh-my-claudecode:ralplan")` 호출
   - Planner → Architect → Critic 순차 합의
   - RALPLAN-DR 요약 포함 (원칙, 의사결정 요인, 옵션)

6. 계획 수립 즉시 **`02-plan-draft.md`**로 저장 (옵시디언 + `.omc/plans/`):
   - 사용자가 옵시디언에서 편하게 확인 가능
   - 콘솔에는 파일 경로와 핵심 요약만 출력

7. **산출물 자동 검증** (사용자에게 제출 전 자동 실행):
   - 02-plan-draft.md를 읽고 아래 규칙을 대조한다. 미통과 시 자동 수정 후 재검증:
   - [ ] WRK-01: DDL SQL이 계획서 본문에 인라인으로 포함되어 있지 않은가? (DB 변경이 있으면 ddl/ 폴더에 .md 파일로 분리되어 있어야 함)
   - [ ] WRK-02: 뷰 수정이 있으면 ddl/ 폴더에 원본.md + 수정본.md가 존재하는가? 수정본에 ★★★ 표시가 있는가? 파생 필드 영향 범위가 문서화되었는가?
   - [ ] CHK-01~02: 사용자 수동 작업이 시점별(선행/후행)로 분류되어 문서 상단에 체크리스트로 있는가?
   - [ ] CHK-03: 선행 작업이 식별되었으면 "완료 후 다음 단계 진행" 조건이 명시되었는가?
   - [ ] BTN-01~03: 버튼 추가가 있으면 (A)/(B) 처리 방식 확인을 사용자에게 요청했는가? A방식 시 pos 사용 현황 + 등록 가이드가 포함되었는가?
   - [ ] NAM-01~04: 신규 파일 네이밍이 규칙에 맞는가? 팝업 JSP는 **호출 위치 기준** 1차/서브팝업 구분 확인 (NAM-03/REF-04)
   - [ ] DB-04: 테이블/컬럼 DDL에 COMMENT ON이 포함되었는가?
   - [ ] DB-08: CREATE INDEX에 TABLESPACE YK_ERP_IDX_TS가 명시되었는가?
   - [ ] COD-06A: 계획서 내 코드 스니펫의 `<script>` 영역에서 `${item.xxx}` EL을 사용하지 않았는가? (hidden input + `$M.getValue()` 패턴 사용)
   - [ ] 롤백 계획이 포함되었는가? (변경 파일, DB 롤백 SQL, 롤백 순서, 검증 방법)
   - [ ] **TMPL-01**: 신규 파일 생성 계획에 사용할 템플릿이 명시되었는가?

8. **컨텍스트 체인 업데이트**: `context-chain.md`에 Step 2 기록 추가

```markdown
## Step 2: 계획 (${날짜})
- 계획 모드: {단순/합의/deliberate}
- 작업 항목 수: {N}건 (독립 {M}건, 의존 {K}건)
- 신규 파일: {목록}
- DB 변경: {있으면 요약, 없으면 '없음'}
- 핵심 결정: {아키텍처 결정 또는 설계 판단 1~2줄}
- 과거 경험 반영: {experience-replay에서 선제 반영한 사항}
```

9. **사용자 승인 대기** (여기서 반드시 멈춤):
   - 승인 → `02-plan-draft.md`를 `02-plan.md`로 이름 변경, draft 삭제 → Step 3 진행
   - 수정 요청 → 계획 재수립 → `02-plan-draft.md` 덮어쓰기 → 다시 승인 대기
   - 거부 → `02-plan-draft.md` 삭제 → 파이프라인 중단

### Step 3: 개발

**에이전트**: `executor` (opus/sonnet/haiku)
**실행 모드**: `ultrawork` (자동 활성화)

1. `02-plan.md` 로드
2. **컨텍스트 체인 로드**: `context-chain.md`를 읽어 이전 Step의 핵심 판단을 확인
3. 계획의 작업 항목을 독립성 기준으로 분류:
   - **독립 작업**: 서로 다른 파일/모듈을 수정하는 작업 → 병렬 실행
   - **의존 작업**: 이전 작업 결과가 필요한 작업 → 순차 실행
4. **독립 작업이 2개 이상이면 ultrawork 모드 자동 활성화**:
   - `docs/shared/agent-tiers.md` 참조하여 작업별 모델 티어 결정
   - 모든 독립 작업을 동시에 Agent 호출 (단일 메시지에서 병렬 발사)
   - 30초 이상 소요 예상 작업은 `run_in_background: true`
5. 독립 작업이 1개이면 ultrawork 없이 executor 직접 호출

**모델 티어 라우팅**:
| 작업 유형 | 모델 | 예시 |
|-----------|------|------|
| 복잡한 비즈니스 로직, 금액/정산 | opus | 서비스 핵심 로직 구현 |
| 일반 CRUD, 화면 개발 | sonnet | Controller/JSP/JS 구현 |
| 단순 설정, SQL 스크립트 | haiku | INSERT 문, 코드 테이블 추가 |

**코드 템플릿 활용**:
신규 파일 생성 시 `templates/` 디렉토리의 템플릿을 기반으로 시작한다.
executor 프롬프트에 해당 템플릿 내용을 `<code-template>` 태그로 주입한다.

| 신규 파일 유형 | 템플릿 | 치환 변수 |
|---------------|--------|-----------|
| Controller | `templates/controller.java.tmpl` | `${DOMAIN}`, `${MENU}`, `${domain_lower}`, `${menu}` |
| Service Interface | `templates/service-interface.java.tmpl` | 위와 동일 |
| ServiceImpl | `templates/service-impl.java.tmpl` | 위와 동일 |
| JSP (그리드 화면) | `templates/jsp-grid.jsp.tmpl` | `${domain_lower}`, `${menu}` |
| JSP (팝업) | `templates/jsp-popup.jsp.tmpl` | `${domain_lower}`, `${menu}` |

```
# 병렬 실행 예시 — 독립 작업 3건을 동시 발사
# 모든 executor 프롬프트에 규칙 + REF + 컨텍스트 체인 + 템플릿 + 자동 튜닝을 주입한다.

Agent(subagent_type="oh-my-claudecode:executor", model="opus", prompt="
**[필수 규칙 — 아래 규칙을 모두 준수하라. common + executor 섹션 적용]**

<ykdev-rules>
${RULES_CONTENT}
</ykdev-rules>

<ref-documents>
${REF_CONTENT}
</ref-documents>

<context-chain>
${CONTEXT_CHAIN_CONTENT}
(이전 Step의 핵심 판단 — 설계 의도와 이유를 이해하고 따를 것)
</context-chain>

<code-template>
(신규 파일 생성 시 아래 템플릿을 기반으로 시작하라. TODO 주석을 실제 구현으로 교체.)
${TEMPLATE_CONTENT}
</code-template>

<tuning-emphasis>
${TUNING_RULES}
(아래 규칙은 최근 반복 위반된 규칙이다. 특별히 주의하라.)
</tuning-emphasis>

---
[백엔드 구현 작업]
승인된 계획: [02-plan.md 내용 중 해당 작업 슬라이스]
")

Agent(subagent_type="oh-my-claudecode:executor", model="sonnet", prompt="
**[필수 규칙 — 위와 동일한 규칙 + REF + 컨텍스트 체인 + 템플릿 + 자동 튜닝 주입]**
...
[프론트엔드 구현 작업]
...")

Agent(subagent_type="oh-my-claudecode:executor", model="haiku", prompt="
**[필수 규칙 — 위와 동일한 규칙 + REF + 자동 튜닝 주입]**
...
[SQL 스크립트 작업]
...")
```

6. 모든 executor 완료 대기
7. **컨텍스트 체인 업데이트**: `context-chain.md`에 Step 3 기록 추가

```markdown
## Step 3: 개발 (${날짜})
- 실행 모드: {단일/ultrawork 병렬 N건}
- 생성 파일: {목록}
- 수정 파일: {목록}
- 사용 템플릿: {목록, 없으면 '없음'}
- 특이사항: {구현 중 발견한 이슈나 계획 변경}
```

8. **산출물 자동 검증** (코드 리뷰 전 자동 실행):
   - 변경/생성된 파일을 읽고 아래 규칙을 대조한다. 미통과 시 executor가 자동 수정 후 재검증:
   - [ ] SEC-01: SQL에 문자열 결합이 없고 PreparedWhereMaker 바인드 변수만 사용하는가?
   - [ ] COD-01: Controller가 RequestDataSet + ResponseUtil.successResult() 패턴인가?
   - [ ] COD-03: Controller 메서드에 requiredFieldCheck()가 있는가?
   - [ ] COD-05~06: Service에서 makePrepareWhereMaker(false) + appendWithCR() 패턴인가?
   - [ ] COD-06A: JSP script 내에서 폼 필드 값 참조 시 $M.getValue() 사용하고 ${item.xxx} EL을 사용하지 않았는가?
   - [ ] COD-18~20: Ajax 통신에 $M.goNextPageAjax() 계열만 사용하는가?
   - [ ] COD-26~27: 신규 JSP에 auiHeader.jsp 포함, header.jsp/commonForAll.jsp 미사용인가?
   - [ ] FRM-01~10: 프레임워크 금지 파일을 수정하지 않았는가?
   - [ ] DB-05: use_yn 조건에 `<> 'N'` 패턴만 사용하는가?
   - [ ] COD-28: 그리드 데이터 저장이 있으면 fnChangeGridDataToForm/fnGridDataToForm + BeanUtil.createListOfBean 패턴을 사용하는가? (수동 # join/split 사용하지 않았는가?)
   - [ ] NAM-01~04: 신규 파일명이 네이밍 규칙에 맞는가? 팝업은 호출 계층(1차/서브) 확인 (NAM-03/REF-04)

### Step 4: 코드 리뷰

**에이전트**: `code-reviewer` (opus)
**산출물**: `{obsidian_base}/{기능폴더}/03-review.md`
**조건**: `--skip-review` 시 이 단계 건너뜀

1. 변경된 파일 목록 수집 (`--files` 지정 시 해당 파일만)
2. `code-reviewer` 호출:

```
Agent(subagent_type="oh-my-claudecode:code-reviewer", model="opus", prompt="
**[필수 규칙 — 아래 규칙을 모두 준수하라. common + reviewer 섹션 적용]**

<ykdev-rules>
${RULES_CONTENT}
</ykdev-rules>

<ref-documents>
${REF_CONTENT}
</ref-documents>

<tuning-emphasis>
${TUNING_RULES}
(아래 규칙은 최근 반복 위반된 규칙이다. 특별히 주의 깊게 검사하라.)
</tuning-emphasis>

리뷰 체크리스트도 참조하라: ~/.claude/skills/ykdev/templates/review-checklist.md

---
변경된 코드를 리뷰하라.

변경 파일: [파일 목록]

각 위반 사항에 규칙 ID를 기록하라 (예: SEC-01, NAM-01).
심각도별 판정:
- CRITICAL: 리뷰 즉시 실패
- HIGH: 리뷰 통과 불가
- MEDIUM: 권고사항으로 기록

리뷰 결과는 반드시 사용자에게 보고 후 수정 방향을 확인받는다. 자동 수정 금지 (REV-01).
")
```

3. 리뷰 → 수정 루프:
   - CRITICAL/HIGH 이슈 발견 → executor가 수정 → code-reviewer 재리뷰 (최대 3회)
   - MEDIUM 이하만 → 권고 기록 후 통과

4. 리뷰 결과를 `03-review.md`로 저장
5. **컨텍스트 체인 업데이트**: `context-chain.md`에 Step 4 기록 추가

```markdown
## Step 4: 리뷰 (${날짜})
- 리뷰 라운드: {N}회
- CRITICAL: {N}건 (해소 여부)
- HIGH: {N}건 (해소 여부)
- MEDIUM: {N}건 (권고)
- 주요 위반 규칙: {규칙 ID 목록}
- 판정: PASS / FAIL
```

### Step 5: 검증

**에이전트**: `verifier` (sonnet)
**산출물**: `{obsidian_base}/{기능폴더}/04-verify.md`

1. **정적 분석 실행** (verifier 호출 전 메인 오케스트레이터가 직접 수행):
   `templates/static-analysis-rules.yml`의 규칙을 순차 실행한다.

   **5-1. Grep 기반 패턴 탐지** (변경된 파일만 대상):
   ```
   # SEC-01: SQL 문자열 결합 탐지
   Grep(pattern='"\s*\+\s*(?:param|map|req|dataSet|get\w+)', glob="**/*ServiceImpl.java")

   # COD-06A: JSP script 내 EL 표현식
   Grep(pattern='\$\{(?:item|row|data|param)\.\w+\}', glob="**/*.jsp")
   → 결과를 <script> 태그 내부인지 확인 (multiline 검사)

   # COD-18: jQuery 직접 Ajax 호출
   Grep(pattern='\$\.(ajax|get|post|getJSON)\s*\(', glob="**/*.jsp")

   # COD-26: 잘못된 JSP include
   Grep(pattern='include\s+file\s*=\s*"[^"]*(?:header\.jsp|commonForAll\.jsp)"', glob="**/*.jsp")

   # COD-28: 수동 # join/split
   Grep(pattern='\.split\s*\(\s*"#"\s*\)', glob="**/*ServiceImpl.java")

   # DB-05: use_yn = 'Y' 패턴
   Grep(pattern="use_yn\s*=\s*['\"]Y['\"]", glob="**/*ServiceImpl.java")
   ```

   **5-2. ast-grep 기반 구조 탐지** (가능한 경우):
   ```
   # Controller에서 HttpServletRequest 직접 사용 탐지
   mcp__plugin_oh-my-claudecode_t__ast_grep_search(
     pattern="public $_ $_(HttpServletRequest $_, $$$) { $$$ }",
     lang="java"
   )
   ```

   **5-3. 프레임워크 금지 파일 수정 검사**:
   ```
   # svn status 또는 변경 파일 목록에서 금지 경로 포함 여부 확인
   금지 경로: mobile/factory/, BeanObject.java, RequestDataSet.java,
              WEB-INF/jsp/common/, db.column.js, style.css,
              AUIGrid.extend.js, jquery.mfactory
   ```

   **5-4. 영향 범위 교차 검증**:
   ```
   1. 01-analysis.md에서 "영향 파일" 목록 추출
   2. 실제 변경 파일 목록 추출
   3. 교차 검증:
      - 예측했지만 미변경 → WARNING: "분석 시 예측한 {파일}이 변경되지 않음 — 의도적인지 확인 필요"
      - 예측 못 했지만 변경 → WARNING: "분석 시 미예측 {파일}이 변경됨 — 영향 범위 재검토 필요"
   ```

   정적 분석 결과를 `${STATIC_ANALYSIS_RESULT}`에 보관.
   CRITICAL 발견 시 → Step 3로 회귀하여 수정 후 재검증.

2. `verifier` 호출:

```
Agent(subagent_type="oh-my-claudecode:verifier", model="sonnet", prompt="
변경사항을 검증하라.

<static-analysis-result>
${STATIC_ANALYSIS_RESULT}
(메인 오케스트레이터가 사전 실행한 정적 분석 결과)
</static-analysis-result>

1. 컴파일 확인: ./gradlew compileGroovy
2. 테스트 통과: ./gradlew test
3. 변경 파일 목록 최종 확인
4. 영향 범위 재검증 (01-analysis.md의 영향도와 비교)
5. 정적 분석 결과 중 WARNING 항목에 대한 판단
")
```

3. 검증 실패 시:
   - 컴파일 에러 → Step 3로 돌아가 수정
   - 테스트 실패 → 실패 원인 분석 후 수정
   - 영향 범위 이상 → 사용자에게 알림
   - 정적 분석 CRITICAL → Step 3로 돌아가 수정

4. 검증 결과를 `04-verify.md`로 저장
5. **컨텍스트 체인 업데이트**: `context-chain.md`에 Step 5 기록 추가

```markdown
## Step 5: 검증 (${날짜})
- 정적 분석: {통과/위반 N건}
- 컴파일: {PASS/FAIL}
- 테스트: {PASS/FAIL}
- 영향 범위 교차 검증: {일치/불일치 N건}
- 최종 판정: {PASS/FAIL}
```

### Step 6: SVN 커밋

**조건**: `--skip-commit` 시 이 단계 건너뜀
**산출물**: `{obsidian_base}/{기능폴더}/05-commit.md`

Step 5 검증 통과 후 svn-commit 워크플로우를 실행한다.

1. `svn status`로 변경 파일 목록 수집
2. `svn diff`로 변경 내용 분석
3. `svn status -u`로 서버와 동기화 상태 확인 (업데이트 필요 시 사용자에게 권유)
4. 안전 검사:
   - 충돌 파일 포함 시 → 커밋 차단, 사용자에게 충돌 해결 안내
   - 민감파일 (`.env`, `*.key`, `*.pem`, `application-prod.properties`) 포함 시 → 경고
   - `svn:ignore`에 없는 바이너리/빌드 파일 포함 시 → 경고
5. 커밋 메시지 자동 생성:
   - `svn log --limit 10`으로 기존 메시지 스타일 감지
   - diff 내용 기반 변경 유형 분류 (feat/fix/refactor 등)
   - 기능 폴더명과 분석 결과(01-analysis.md)를 참조하여 의미 있는 메시지 작성
   - **커밋 메시지에 AI/Claude/자동생성 관련 문구 절대 포함 금지**
6. 파일 선택 모드 제시:
   ```
   변경된 파일 (N):
     [1] M  src/.../SomeServiceImpl.java    서비스 로직 구현
     [2] A  src/.../some.jsp                화면 추가
     ...

   → 전체 커밋 (기본)
   → 번호 지정: "1,2,4" — 선택 파일만 커밋
   ```
7. **사용자 확인 대기** (커밋 메시지 + 파일 목록 승인)
   - 승인 → `svn commit` 실행
   - 메시지 수정 요청 → 수정 후 재확인
   - 거부 → 커밋 미실행, 파이프라인 완료 처리
8. 커밋 결과 기록:
   - 커밋 리비전 번호를 `05-commit.md`에 저장
   - 커밋 실패 시 에러 분석 후 해결 방안 제시 (out-of-date → update 필요 등)

### 완료 처리

1. `summary.md` 자동 생성: 전체 프로세스 요약, 최종 변경사항
2. `_index.md` 업데이트: 기능 상태를 "완료"로 변경, 완료일 기입
3. **메트릭 업데이트**: `_metrics.md`에 이번 파이프라인 결과를 자동 기록

   **기록 항목:**
   - 기능 폴더명, 완료일
   - 리뷰 라운드 수 (03-review.md에서 추출)
   - 위반 규칙 목록 (03-review.md + 04-verify.md에서 추출)
   - 컴파일/테스트 통과 여부 (04-verify.md에서 추출)
   - 정적 분석 결과 요약

   **자동 튜닝 업데이트:**
   - "빈출 위반 규칙 Top 10" 재계산
   - 동일 규칙이 **최근 3건 연속** 발생하면 "자동 튜닝 현황"에 추가
   - 3건 연속 미발생이면 "자동 튜닝 현황"에서 제거

### _index.md 관리

`_index.md`는 개발 기능이 누적되는 파일이다. 각 단계에서 자동 업데이트한다.

**업데이트 시점:**

| 시점 | _index.md 동작 |
|------|---------------|
| Step 1 시작 | 새 행 추가 (상태: 📋 Step 1 분석) |
| 각 Step 진행 | 상태 업데이트 (🔄 Step N 진행중) |
| Step 5 완료 | 상태 업데이트 (🔄 Step 6 커밋 대기) |
| Step 6 완료 | 상태를 ✅ 완료, 완료일 + 커밋 리비전 기입 |
| Step 6 건너뜀 (--skip-commit) | 상태를 ✅ 완료 (미커밋), 완료일 기입 |
| `--archive` 실행 | 완료 항목을 _archive-{N}차.md로 이동 |

**아카이브:**

항목이 20건 이상 누적되거나 개발 차수가 종료되면 아카이브한다.

```
# 아카이브 명령어
ykdev --archive 7차
```

동작:
1. `_index.md`에서 해당 차수의 완료 항목을 추출
2. `_archive-7차.md` 파일 생성 (기간, 총 기능 수, 항목 테이블 포함)
3. `_index.md`에서 이동한 항목 제거

디렉토리 구조:
```
SunnyYK-ERP/
├── _index.md              ← 현재 진행중 + 최근 완료 항목만
├── _metrics.md            ← 품질 메트릭 누적 기록 (NEW)
├── _archive-7차.md        ← 7차 추가개발 완료 이력
├── _archive-6차.md        ← 6차 추가개발 완료 이력
└── {기능폴더들}/
    ├── 00-input.md        ← 원본 입력 정보
    ├── 01-analysis.md     ← 문서 분석 결과
    ├── 02-plan-draft.md   ← 구현 계획 초안 (승인 전)
    ├── 02-plan.md         ← 구현 계획 (승인 후)
    ├── 03-review.md       ← 코드 리뷰 결과
    ├── 04-verify.md       ← 검증 결과
    ├── 05-commit.md       ← 커밋 결과
    ├── context-chain.md   ← 컨텍스트 체인 (NEW)
    ├── summary.md         ← 완료 요약
    └── ddl/               ← DB 변경 스크립트
```

</Steps>

<Execution_Policy>
- **산출물 자동 검증 의무화**: 각 Step의 산출물을 사용자에게 제출하거나 다음 단계로 넘기기 전에, 해당 Step에 정의된 "산출물 자동 검증" 체크리스트를 반드시 실행한다. 미통과 항목이 있으면 자동 수정 후 재검증한다. 검증을 건너뛰고 제출하지 않는다. 이 규칙은 메인 오케스트레이터가 직접 작성하든, 서브에이전트가 작성하든 동일하게 적용된다.
- Step 1, 3, 4, 5는 자동 진행. Step 2, 6 후 반드시 사용자 승인 대기.
- Step 3에서 독립 작업은 ultrawork로 병렬 실행.
- Step 4 → Step 3 수정 루프는 최대 3회.
- Step 5 실패 시 Step 3으로 회귀.
- 규칙 주입: **메인 오케스트레이터가 Step 0에서 ykdev-rules.md를 Read하여 전체 내용을 보관**하고, 모든 서브에이전트 프롬프트에 `<ykdev-rules>` 태그로 통째 주입한다. 서브에이전트가 직접 Read하지 않는다.
- REF 문서: 메인 오케스트레이터가 작업 유형(백엔드/프론트엔드/DB/풀스택)에 따라 필요한 REF를 Read하고, `<ref-documents>` 태그로 서브에이전트 프롬프트에 주입한다.
- **컨텍스트 체인**: 매 Step 완료 시 `context-chain.md`에 핵심 판단/결정을 누적 기록한다. 다음 Step의 서브에이전트에 `<context-chain>` 태그로 주입하여 이전 판단의 맥락을 전달한다.
- **코드 템플릿**: 신규 파일 생성 시 `templates/` 디렉토리의 스켈레톤 템플릿을 기반으로 시작한다. executor 프롬프트에 `<code-template>` 태그로 주입한다.
- **Experience Replay**: Step 1에서 유사 과거 기능을 검색하여 위반 이력과 구현 패턴을 추출하고, 이후 Step에 `<experience-replay>` 태그로 주입한다.
- **메트릭 & 자동 튜닝**: 파이프라인 완료 시 `_metrics.md`에 결과를 기록한다. 빈출 위반 규칙은 다음 파이프라인의 executor/code-reviewer 프롬프트에 `<tuning-emphasis>` 태그로 강조 주입한다.
- **정적 분석**: Step 5에서 verifier 호출 전에 Grep/ast-grep 기반 정적 분석을 선행 실행한다. CRITICAL 발견 시 Step 3으로 회귀한다.
- 산출물은 옵시디언 기능 폴더 + .omc/plans/ 병행 저장.
- `--step` 옵션으로 단계별 독립 실행 가능. 이전 단계 산출물은 옵시디언에서 자동 참조.
- `_index.md`는 각 Step 시작/완료 시 자동 업데이트. 20건 이상 또는 차수 종료 시 아카이브.
</Execution_Policy>

<Agent_Rule_Mapping>
| 에이전트 | 모델 | ykdev-rules.md 참조 섹션 | 추가 주입 태그 |
|---------|------|------------------------|--------------|
| analyst | opus | common + planner | experience-replay |
| planner | opus | common + planner | experience-replay |
| architect | opus | common + planner | experience-replay |
| critic | opus | common + planner + reviewer | experience-replay |
| executor | opus/sonnet/haiku | common + executor | context-chain, code-template, tuning-emphasis |
| code-reviewer | opus | common + reviewer | tuning-emphasis |
| verifier | sonnet | (규칙 참조 없음, 빌드/테스트만) | static-analysis-result |
</Agent_Rule_Mapping>

<Tag_Injection_Reference>
서브에이전트 프롬프트에 주입하는 태그 목록과 출처:

| 태그 | 내용 | 생성 시점 | 주입 대상 |
|------|------|-----------|-----------|
| `<ykdev-rules>` | ykdev-rules.md 전체 | Step 0 | 전체 (verifier 제외) |
| `<ref-documents>` | REF 문서 내용 | Step 0 | 전체 (verifier 제외) |
| `<experience-replay>` | 유사 기능 위반 이력 + 구현 패턴 | Step 1 | analyst, planner, architect, critic |
| `<context-chain>` | 이전 Step 핵심 판단 누적 | 매 Step | executor |
| `<code-template>` | 신규 파일 스켈레톤 템플릿 | Step 3 | executor (신규 파일 생성 시) |
| `<tuning-emphasis>` | 빈출 위반 규칙 강조 | Step 0 | executor, code-reviewer |
| `<static-analysis-result>` | 정적 분석 결과 | Step 5 | verifier |
</Tag_Injection_Reference>

<Examples>
<Good>
전체 파이프라인 실행:
```
ykdev @document_for_dev.pdf 2.3.1 렌탈기준정보-어태치먼트
```
→ Step 1~6 순차 실행, Step 2, 6 후 사용자 승인 대기

단계별 실행:
```
ykdev 2.3.1-렌탈기준정보-어태치먼트 --step plan
```
→ 01-analysis.md 기반 복잡도 자동 판단 후 계획 수립

범위 실행:
```
ykdev 2.3.1-렌탈기준정보-어태치먼트 --step dev..verify
```
→ Step 3~5 실행

재시작 (기존 입력 재사용):
```
ykdev 2.3.2-렌탈장비대장상세-장착옵션 --restart
```
→ 산출물 삭제, 00-input.md의 원본 PDF/페이지 정보로 Step 1부터 재시작

재시작 (요구사항 변경):
```
ykdev @document_for_dev.pdf 2~3페이지 개발 --restart
```
→ 00-input.md 덮어쓰기 후 Step 1부터 재시작
</Good>

<Bad>
Step 2에서 사용자 승인 없이 Step 3으로 넘어감.
Why bad: 잘못된 계획으로 개발하면 전부 다시 해야 함.

code-reviewer와 executor를 같은 컨텍스트에서 실행.
Why bad: 자기가 쓴 코드를 자기가 리뷰하면 객관성이 없음.

메트릭을 기록하지 않고 파이프라인 완료 처리.
Why bad: 자동 튜닝 데이터가 누적되지 않아 반복 위반이 계속됨.

context-chain.md를 업데이트하지 않고 다음 Step으로 넘어감.
Why bad: 다음 Step의 에이전트가 이전 판단의 맥락을 잃어 불일치 발생.
</Bad>
</Examples>

<Final_Checklist>
- [ ] Step 0에서 ykdev-rules.md 전체 Read 완료 (${RULES_CONTENT} 보관)
- [ ] 작업 유형별 REF 문서 Read 완료 (${REF_CONTENT} 보관)
- [ ] _metrics.md 로드 및 자동 튜닝 규칙 추출 완료 (${TUNING_RULES} 보관)
- [ ] 각 서브에이전트 프롬프트에 <ykdev-rules> + <ref-documents> 태그로 내용 직접 주입
- [ ] Step 1에서 과거 유사 기능 검색 (Experience Replay) 실행
- [ ] 기능 폴더 생성 완료
- [ ] context-chain.md 생성 및 매 Step 업데이트
- [ ] 각 단계별 산출물 저장 완료 (옵시디언 + .omc/plans/)
- [ ] 신규 파일 생성 시 templates/ 스켈레톤 활용
- [ ] Step 2 후 사용자 승인 획득
- [ ] Step 4 리뷰에서 CRITICAL/HIGH 모두 해소
- [ ] Step 5 정적 분석 통과 (Grep/ast-grep 기반)
- [ ] Step 5 빌드/테스트 통과
- [ ] Step 5 영향 범위 교차 검증 완료
- [ ] Step 6 SVN 커밋 완료 (--skip-commit 시 제외) — 05-commit.md에 리비전 기록
- [ ] summary.md 생성 완료
- [ ] _index.md 업데이트 완료
- [ ] _metrics.md 업데이트 완료 (메트릭 기록 + 자동 튜닝 재계산)
</Final_Checklist>
