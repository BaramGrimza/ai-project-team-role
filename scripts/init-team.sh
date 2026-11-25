#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "사용법: $0 <대상_프로젝트_저장소_경로> [프로젝트명]"
  exit 1
fi

TEAM_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$(cd "$1" && pwd)"
PROJECT_NAME="${2:-$(basename "$TARGET_DIR")}"
NOW_TS="$(date '+%Y-%m-%d %H:%M')"

cp "$TEAM_REPO_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
mkdir -p "$TARGET_DIR/.claude/agents"
cp -R "$TEAM_REPO_DIR/.claude/agents/." "$TARGET_DIR/.claude/agents/"

mkdir -p "$TARGET_DIR/docs/templates"
cp -R "$TEAM_REPO_DIR/docs/templates/." "$TARGET_DIR/docs/templates/"

for dir in \
  "docs/01-analysis" \
  "docs/02-design" \
  "docs/03-dev" \
  "docs/04-test" \
  "docs/05-qa" \
  "docs/logs"
do
  mkdir -p "$TARGET_DIR/$dir"
  touch "$TARGET_DIR/$dir/.gitkeep"
done

ACTIVITY_LOG="$TARGET_DIR/docs/logs/activity-log.md"
if [ -f "$TEAM_REPO_DIR/docs/templates/07_활동로그_activity-log_템플릿.md" ]; then
  cp "$TEAM_REPO_DIR/docs/templates/07_활동로그_activity-log_템플릿.md" "$ACTIVITY_LOG"
  printf "\n| %s | 초기화 | 시스템(init-team.sh) | 저장소 초기화 | [%s] 팀 규약·에이전트·템플릿 복사 및 폴더 구조 생성 완료 | 완료 |\n" \
    "$NOW_TS" "$PROJECT_NAME" >> "$ACTIVITY_LOG"
fi

echo "초기화 완료: $TARGET_DIR"