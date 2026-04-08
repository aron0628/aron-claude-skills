# aron-claude-skills

Claude Code 커스텀 스킬 저장소.

## Setup

### macOS / Linux

```bash
git clone https://github.com/aron0628/aron-claude-skills.git ~/aron-claude-skills && ~/aron-claude-skills/setup.sh
```

다른 경로에 저장하려면:

```bash
git clone https://github.com/aron0628/aron-claude-skills.git /원하는/경로 && /원하는/경로/setup.sh
```

### Windows

```cmd
git clone https://github.com/aron0628/aron-claude-skills.git %USERPROFILE%\aron-claude-skills && %USERPROFILE%\aron-claude-skills\setup.bat
```

다른 경로에 저장하려면:

```cmd
git clone https://github.com/aron0628/aron-claude-skills.git C:\원하는\경로 && C:\원하는\경로\setup.bat
```

> **Note:** `setup.bat`은 Junction(`mklink /J`)을 사용합니다. 관리자 권한 없이 실행 가능합니다.

## Prerequisites

| 스킬 | OMC 필요 여부 |
|------|:---:|
| `ykdev` | **필수** |
| `svn-*`, `obsidian-doc` | 불필요 |

`ykdev`는 OMC 에이전트(analyst, executor, code-reviewer, verifier)를 사용하므로, 사전에 OMC를 설치해야 합니다.

OMC 설치: Claude Code에서 `setup omc` 또는 `/oh-my-claudecode:omc-setup` 실행

## Skills

| 스킬 | 설명 |
|------|------|
| `ykdev` | SunnyYK ERP 전용 개발 파이프라인 (문서분석→계획→개발→리뷰→수정→검증→커밋) |
| `svn-status` | SVN working copy 상태를 git-style로 직관적 요약 |
| `svn-commit` | SVN diff 분석 기반 스마트 커밋 (메시지 자동 생성) |
| `svn-merge` | SVN 머지 어시스턴트 (reintegrate/sync/cherry-pick) |
| `svn-log` | SVN 히스토리를 읽기 좋게 포맷팅 |
| `svn-blame` | SVN blame + 커밋 맥락 분석 |
| `svn-flow` | SVN 원스톱 워크플로우 (status→merge→충돌해결→commit) |
| `svn-dev` | SVN 기반 기능 개발 전체 워크플로우 (분석→브랜치→개발→테스트→머지) |
| `obsidian-doc` | 대화 내용을 옵시디언 마크다운 문서로 생성 |

## Update

스킬 업데이트 시 pull만 하면 심볼릭 링크를 통해 즉시 반영됩니다.

```bash
cd ~/aron-claude-skills && git pull
```

## Customization

각 스킬의 `SKILL.md`를 수정하여 개인 환경에 맞게 커스터마이징할 수 있습니다.
경로, 하위 폴더, 문서 포맷 등을 자유롭게 변경 가능합니다.

자세한 설정 항목은 각 스킬 폴더의 `SKILL.md`를 참조하세요.
