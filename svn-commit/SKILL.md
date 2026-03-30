---
name: svn-commit
description: SVN diff 분석 기반 스마트 커밋. 커밋 메시지 자동 생성, 파일 선택, 민감파일 경고.
trigger: "svn commit"
user-invocable: true
level: 2
---

# SVN Commit

변경 내용을 분석하여 커밋 메시지를 자동 생성하고, 파일 선택 커밋을 지원합니다.

## 트리거

다음 문구가 포함되면 이 스킬을 자동 호출:
- "svn commit"
- "svn 커밋"

## 실행 절차

1. `svn status`로 변경 파일 목록 수집
2. `svn diff`로 변경 내용 수집
3. 변경 분석 → 커밋 메시지 초안 생성
4. 파일 선택 (전체 or 부분 커밋)
5. 사용자 확인/수정
6. `svn commit` 실행
7. 결과 출력 (커밋 리비전 번호)

## 파일 선택 모드

SVN은 git의 staging area가 없으므로 스킬이 이를 보완:

```
변경된 파일 (4):
  [1] M  src/auth/login.py       인증 로직 리팩토링
  [2] M  src/auth/session.py     세션 타임아웃 변경
  [3] M  config/settings.xml     타임아웃 값 수정
  [4] A  src/auth/oauth.py       OAuth2 핸들러 신규

→ 전체 커밋 (기본)
→ 번호 지정: "1,2,4" — 선택 파일만 커밋
→ 논리적 분리: 자동으로 관련 파일 그룹핑 제안
```

부분 커밋 시 `svn commit file1 file2 ...` 형태로 실행.

## 커밋 메시지 생성 전략

1. diff 내용 분석하여 변경 유형 분류 (feat/fix/refactor/docs/config)
2. 프로젝트의 기존 `svn log --limit 10` 메시지 스타일 감지 → 동일 포맷으로 생성
3. 여러 관심사가 섞인 경우 분리 커밋 제안

### 메시지 예시

```
feat: OAuth2 인증 핸들러 추가 및 세션 관리 개선

- OAuth2 핸들러 신규 구현 (oauth.py)
- 기존 로그인 로직을 OAuth 호환 구조로 리팩토링
- 세션 타임아웃 30분 → 60분으로 변경
```

## 안전장치

- **업데이트 체크**: 커밋 전 `svn status -u`로 서버와 비교, 업데이트 필요 시 먼저 권유
- **충돌 차단**: 충돌 파일이 포함되면 커밋 차단
- **민감파일 경고**: `.env`, `credentials`, `*.key`, `*.pem` 등 커밋 시 경고
- **바이너리/빌드 경고**: `svn:ignore`에 없는 바이너리/빌드 파일 커밋 시 경고
- **빈 커밋 방지**: 변경 파일이 없으면 안내 후 종료

## 옵션

| 인자 | 설명 | 예시 |
|------|------|------|
| (없음) | 인터랙티브 모드 | `/svn-commit` |
| `"message"` | 메시지 직접 지정 | `/svn-commit "fix: 버그 수정"` |
| `--all` | 전체 파일, 확인 생략 | `/svn-commit --all` |
| `--dry-run` | 커밋 미실행, 메시지만 생성 | `/svn-commit --dry-run` |

## 주의사항

- SVN은 커밋이 즉시 서버에 반영됨 (git push와 동일) — 커밋 전 반드시 사용자 확인
- 커밋 실패 시 에러 메시지 분석 후 해결 방안 제시 (out-of-date → update 필요 등)
