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

## Skills

| 스킬 | 설명 |
|------|------|
| `obsidian-doc` | 대화 내용을 옵시디언 마크다운 문서로 생성 |

## Customization

각 스킬의 `SKILL.md`를 수정하여 개인 환경에 맞게 커스터마이징할 수 있습니다.
경로, 하위 폴더, 문서 포맷 등을 자유롭게 변경 가능합니다.

자세한 설정 항목은 각 스킬 폴더의 `SKILL.md`를 참조하세요.
