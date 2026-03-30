#!/bin/bash
# aron-claude-skills setup script
# Usage: git clone https://github.com/aron0628/aron-claude-skills.git ~/aron-claude-skills && ~/aron-claude-skills/setup.sh

SKILLS_DIR="$HOME/.claude/skills"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$SKILLS_DIR"

count=0
for skill in "$REPO_DIR"/*/; do
  name=$(basename "$skill")
  # skip hidden dirs and non-skill files
  [[ "$name" == .* ]] && continue

  if [ -L "$SKILLS_DIR/$name" ]; then
    echo "  skip: $name (already linked)"
  elif [ -e "$SKILLS_DIR/$name" ]; then
    echo "  skip: $name (already exists, not a symlink)"
  else
    ln -s "$skill" "$SKILLS_DIR/$name"
    echo "  linked: $name"
    count=$((count + 1))
  fi
done

echo ""
echo "Done. $count skill(s) linked to $SKILLS_DIR"
