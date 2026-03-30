---
name: svn-status
description: SVN working copy 상태를 git-style로 직관적 요약. 변경/추가/충돌/미추적 파일 분류 및 diff 요약.
trigger: "svn status"
user-invocable: true
level: 2
---

# SVN Status

SVN working copy의 현재 상태를 분석하여 git-style로 직관적으로 요약합니다.

## 트리거

다음 문구가 포함되면 이 스킬을 자동 호출:
- "svn status"
- "svn 상태"

## 실행 절차

1. `svn info`로 현재 저장소 URL, 리비전, 브랜치 경로 파악
2. `svn status`로 파일 상태 수집
3. `svn status -u`로 서버와의 차이 확인 (--remote 옵션 시)
4. `svn diff`로 변경 내용 수집 (--diff 옵션 시)
5. 카테고리별 분류 후 요약 출력

## 출력 포맷

```
📍 Branch: branches/feature-login (r1247)
   Remote: svn://repo.example.com/project

Modified (3):
  M  src/auth/login.py        (+42 -15)  인증 로직 리팩토링
  M  src/auth/session.py      (+8 -3)    세션 타임아웃 변경
  M  config/settings.xml      (+1 -1)    타임아웃 값 수정

Added (1):
  A  src/auth/oauth.py        (+120)     OAuth2 핸들러 신규

Unversioned (2):
  ?  build/output.jar          ← svn:ignore 추가 권장
  ?  .env.local                ← svn:ignore 추가 권장 (민감파일)

Conflicted (0): 없음
```

## 카테고리 분류 규칙

| SVN 상태코드 | 카테고리 | 설명 |
|-------------|---------|------|
| M | Modified | 수정된 파일 |
| A | Added | 새로 추가된 파일 |
| D | Deleted | 삭제된 파일 |
| C | Conflicted | 충돌 파일 (최상단 경고) |
| ? | Unversioned | 미추적 파일 |
| ! | Missing | 버전 관리 중이나 로컬에 없는 파일 |
| ~ | Obstructed | 타입 변경 (파일↔디렉토리) |

## 옵션

| 인자 | 설명 | 예시 |
|------|------|------|
| (없음) | 전체 상태 요약 | `/svn-status` |
| `path` | 특정 경로만 | `/svn-status src/auth/` |
| `--remote` | 서버 비교 포함 (`svn status -u`) | `/svn-status --remote` |
| `--diff` | 전체 diff 내용까지 분석 | `/svn-status --diff` |

## 추가 기능

- **ignore 미등록 경고**: unversioned 파일 중 `.env`, 빌드 산출물, IDE 설정 등을 자동 식별하여 `svn:ignore` 추가 권장
- **충돌 감지**: 충돌 파일이 있으면 최상단에 경고 표시 + `/svn-merge`로 안내
- **변경 요약**: --diff 옵션 시 각 파일의 변경 내용을 한 줄로 요약

## 주의사항

- SVN working copy가 아닌 경우 안내 메시지 출력
- `svn status -u`는 네트워크 접근이 필요하므로 --remote 옵션일 때만 실행
- 대량 파일 변경 시 상위 20개만 표시하고 나머지는 요약
