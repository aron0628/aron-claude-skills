---
name: svn-log
description: SVN 히스토리를 읽기 좋게 포맷팅. 파일/디렉토리 이력, 리비전 범위 비교, 자연어 질의 지원.
trigger: "svn log"
user-invocable: true
level: 2
---

# SVN Log

`svn log` 출력을 읽기 좋게 가공하고 AI 기반 요약을 제공합니다.

## 트리거

다음 문구가 포함되면 이 스킬을 자동 호출:
- "svn log"
- "svn 로그"
- "svn 히스토리"

## 모드

### 기본 모드 — 최근 히스토리

```
/svn-log
```

`svn log --limit 10 -v`를 실행하여 포맷팅:

```
최근 10 commits (trunk, r1247~r1238):

r1247  2026-03-29  kim   feat: OAuth2 핸들러 추가
r1246  2026-03-28  lee   fix: 세션 만료 시 리다이렉트 오류
r1245  2026-03-28  kim   refactor: 인증 미들웨어 분리
r1244  2026-03-27  park  docs: API 문서 업데이트
...

이 기간 요약: 인증 시스템 개선 작업이 주로 진행됨
```

### 파일/디렉토리 히스토리

```
/svn-log src/auth/login.py
```

`svn log -v <path>`로 특정 파일의 변경 이력 추적:

```
src/auth/login.py 변경 이력 (총 23 commits):

r1247  kim   OAuth 호환 구조로 리팩토링 (+42 -15)
r1238  kim   로그인 실패 시 재시도 로직 추가 (+18 -2)
r1201  lee   비밀번호 해싱 알고리즘 변경 (+5 -5)
...

주요 기여자: kim (15), lee (5), park (3)
```

### 리비전 범위 비교

```
/svn-log r1200:r1247
```

`svn log -r 1200:1247 -v`로 범위 내 변경 요약:

```
r1200 → r1247 변경 요약 (47 commits, 3 authors):

주요 변경:
- OAuth2 인증 시스템 도입 (r1240-r1247, kim)
- 세션 관리 버그 수정 3건 (r1220-r1238, lee)
- API 문서 전면 재작성 (r1210-r1215, park)

파일 변경 통계:
  src/auth/     — 28 commits, 가장 활발
  config/       — 8 commits
  docs/         — 11 commits
```

### 자연어 질의

```
/svn-log "지난주에 auth 관련 뭐가 바뀌었어?"
```

자연어에서 날짜 범위 + 경로 필터 추출:
- `svn log -r {날짜범위} <경로>` 자동 구성
- 결과를 요약하여 답변

## 옵션

| 인자 | 설명 | 예시 |
|------|------|------|
| (없음) | 최근 10 commits | `/svn-log` |
| `path` | 특정 파일/디렉토리 이력 | `/svn-log src/auth/` |
| `rN:rM` | 리비전 범위 | `/svn-log r1200:r1247` |
| `--author name` | 특정 작성자 필터 | `/svn-log --author kim` |
| `--since date` | 날짜 기반 필터 | `/svn-log --since 2026-03-01` |
| `--limit N` | 표시 개수 제한 (기본 10) | `/svn-log --limit 30` |
| `"자연어"` | AI가 조건 추출 | `/svn-log "이번 달 변경사항"` |

## 주의사항

- `svn log -v` 옵션으로 변경 파일 목록도 함께 수집
- 대량 로그 시 `--limit`로 제한하여 성능 확보
- 자연어 질의 시 상대 날짜("지난주", "이번 달")를 절대 날짜로 변환
