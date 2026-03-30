---
name: svn-merge
description: SVN 머지 어시스턴트. reintegrate/sync/cherry-pick 모드, dry-run 사전 검사, 충돌 해결 가이드.
trigger: "svn merge"
user-invocable: true
level: 3
---

# SVN Merge

SVN 머지의 복잡성을 단계별 가이드로 해소합니다. 3가지 머지 모드와 충돌 해결 어시스턴트를 제공합니다.

## 트리거

다음 문구가 포함되면 이 스킬을 자동 호출:
- "svn merge"
- "svn 머지"

## 머지 모드

### Mode A: reintegrate — 브랜치 → Trunk 머지

```
/svn-merge reintegrate [branch-name]
```

**실행 흐름**:
1. `svn info` → 현재 위치가 trunk인지 검증
2. 대상 브랜치 선택 (미지정 시 `branches/` 목록 제시)
3. `svn mergeinfo --show-revs eligible` → 미머지 리비전 확인
4. `svn merge --dry-run` → 충돌 사전 검사
   - 충돌 없음 → 실제 머지 실행
   - 충돌 있음 → 충돌 파일 목록 + 해결 가이드
5. 머지 결과 diff 요약
6. 커밋 메시지 생성 (머지 리비전 범위 포함)

### Mode B: sync — Trunk → Feature 동기화

```
/svn-merge sync
```

브랜치 작업 중 trunk 변경사항을 가져오는 패턴:
1. 현재 브랜치 확인
2. `svn mergeinfo --show-revs eligible ^/trunk` → 미반영 리비전 조회
3. dry-run → 실행 → 충돌 해결 → 커밋

### Mode C: cherry-pick — 특정 리비전 선택 머지

```
/svn-merge cherry-pick r1245
/svn-merge cherry-pick r1240:r1247
/svn-merge cherry-pick r1245,r1250,r1263
```

내부적으로 `svn merge -c <rev> <source-url>` 실행:
1. 대상 리비전의 변경 내용 요약 표시
2. 소스 URL 자동 추론 (trunk 또는 지정 브랜치)
3. dry-run → 적용
4. 커밋 메시지에 cherry-pick 리비전 기록

역방향(revert)도 지원: `svn merge -c -1245` (음수 리비전)

## Dry-run 출력 예시

```
🔀 Merge: branches/feature-login → trunk

미머지 리비전: r1230, r1235, r1240-r1247 (총 5 commits)

Dry-run 결과:
  ✅ src/auth/login.py        — clean merge
  ✅ src/auth/session.py      — clean merge
  ⚠️  config/settings.xml     — CONFLICT (양쪽 수정)
  ✅ src/auth/oauth.py        — added

충돌 1건:
  config/settings.xml
  ├─ trunk (r1229): timeout=30
  ├─ branch (r1247): timeout=60
  └─ 제안: branch 값(60) 채택

→ 머지를 진행하시겠습니까?
```

## 충돌 해결 어시스턴트

충돌 발생 시 파일별로 진입:

```
충돌 파일: config/settings.xml

<<<<<<< .mine (trunk)
  <timeout>30</timeout>
=======
  <timeout>60</timeout>
>>>>>>> .merge-right (branch)

분석:
- trunk 쪽: 기본값 유지 (변경 없음)
- branch 쪽: 의도적으로 60으로 변경 (커밋 메시지: "세션 타임아웃 연장")
- 권장: branch 값 채택
```

**핵심**: 단순 diff가 아니라 `svn log`로 양쪽 커밋 히스토리를 읽고 변경 의도를 분석하여 권장 해결 방향 제시.

해결 후 `svn resolved <file>` 자동 실행.

## 옵션

| 인자 | 설명 |
|------|------|
| `reintegrate [branch]` | 브랜치 → trunk 머지 |
| `sync` | trunk → 현재 브랜치 동기화 |
| `cherry-pick rN` | 특정 리비전 선택 머지 |
| `--dry-run` | 실행 없이 결과만 미리보기 |
| `--auto-resolve` | 단순 충돌 자동 해결 (한쪽만 변경된 경우) |

## 주의사항

- 머지 전 working copy가 clean 상태인지 확인 (미커밋 변경 있으면 경고)
- reintegrate 모드는 반드시 trunk에서 실행해야 함
- `svn:mergeinfo` 속성이 올바르게 기록되는지 확인
- 대규모 머지 시 파일별 결과를 단계적으로 표시
