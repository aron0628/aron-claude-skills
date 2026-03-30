---
name: svn-blame
description: SVN blame + 커밋 맥락 분석. 라인별 변경 이력과 "왜 이렇게 됐는지" 설명 제공.
trigger: "svn blame"
user-invocable: true
level: 2
---

# SVN Blame

`svn blame` 결과에 커밋 맥락 분석을 더하여 "왜 이렇게 됐는지" 설명합니다.

## 트리거

다음 문구가 포함되면 이 스킬을 자동 호출:
- "svn blame"
- "svn 블레임"
- "이 코드 누가 썼어"

## 모드

### 파일 전체 요약

```
/svn-blame src/auth/login.py
```

`svn blame <file>`을 실행하고 분석:

```
src/auth/login.py blame 요약:

최근 수정자 분포:
  kim   — 65% (r1247, r1238, r1190...)
  lee   — 25% (r1201, r1180...)
  park  — 10% (r1150...)

최신 변경 구간 (r1247, kim):
  L42-L83: OAuth 호환 인증 로직 (신규)

오래된 코드 구간:
  L1-L20: 임포트 + 초기화 — r1050 이후 미변경 (6개월)
  L95-L110: 에러 핸들러 — r1150 이후 미변경
```

### 라인 범위 분석 (핵심 기능)

```
/svn-blame src/auth/login.py:42-50
```

해당 라인의 blame + 관련 커밋 메시지를 교차 분석:

```
L42-50 분석:

  r1247 kim  |  async def authenticate(self, token: str):
  r1247 kim  |      if self.oauth_enabled:
  r1247 kim  |          return await self._oauth_validate(token)
  r1190 kim  |      hashed = hash_password(token)
  r1190 kim  |      user = await self.db.find_user(hashed)
  r1201 lee  |      if not user:
  r1201 lee  |          logger.warning(f"Auth failed: {mask(token)}")
  r1201 lee  |          raise AuthError("Invalid credentials")
  r1190 kim  |      return user

변경 히스토리:
  - r1247 (kim, 2026-03-29): OAuth 분기 추가
    커밋 메시지: "feat: OAuth2 핸들러 추가 및 기존 인증 경로 보존"
  - r1201 (lee, 2026-03-15): 인증 실패 로깅 추가
    커밋 메시지: "fix: 인증 실패 시 로그 누락 수정 (보안팀 요청)"
  - r1190 (kim, 2026-03-10): 초기 인증 로직 구현
```

### 자연어 질의

```
/svn-blame "login.py에서 OAuth 관련 코드 누가 언제 넣었어?"
```

파일 + 키워드 기반으로 관련 라인 자동 탐색 후 blame + log 교차 분석.

## 실행 절차

1. `svn blame <file>` 실행
2. 라인 범위가 지정된 경우 해당 구간 추출
3. 등장하는 리비전 번호 수집
4. `svn log -r <revs> -v`로 각 리비전의 커밋 메시지 조회
5. blame 결과 + 커밋 맥락을 종합하여 설명 생성

## 옵션

| 인자 | 설명 | 예시 |
|------|------|------|
| `file` | 파일 전체 blame 요약 | `/svn-blame src/auth/login.py` |
| `file:L1-L2` | 특정 라인 범위 분석 | `/svn-blame src/auth/login.py:42-50` |
| `"자연어"` | 키워드 기반 자동 탐색 | `/svn-blame "OAuth 코드 누가?"` |
| `--raw` | 가공 없이 blame 원본 출력 | `/svn-blame src/auth/login.py --raw` |

## 주의사항

- 파일이 크면 blame 전체 출력 대신 요약 모드로 표시
- 라인 범위 분석 시 관련 커밋이 많으면 최근 5개까지만 상세, 나머지는 요약
- 바이너리 파일은 blame 불가 — 안내 메시지 출력
