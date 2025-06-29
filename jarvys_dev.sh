#!/usr/bin/env bash
set -euo pipefail
echo '🏗️  Orchestration JARVYS-Dev start'

[[ -z \"\\" || -z \"\\" ]] && {
  echo '❌  GITHUB_TOKEN et/ou OPENAI_API_KEY manquants' >&2 ; exit 1 ; }

if [[ ! -d .git ]]; then
  git init -q
  git remote add origin https://\@github.com/yannabadie/appIA.git
fi

command -v codex >/dev/null 2>&1 || npm install -g @openai/codex

codex --approval-mode full-auto -q \
  'Scaffold Dockerfile, jarvys_dev.sh, GitHub workflow for JARVYS-Dev'

git add -A
git commit -m 'chore: scaffold JARVYS-Dev' 2>/dev/null || true
git push origin HEAD:main

echo '✅  Orchestration completed'
