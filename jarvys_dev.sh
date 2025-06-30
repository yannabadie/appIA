#!/usr/bin/env bash
set -euo pipefail
echo '🏗️  Orchestration JARVYS-Dev start'

# 1. Vérif secrets
[[ -z "${GITHUB_TOKEN:-}" || -z "${OPENAI_API_KEY:-}" ]] && {
  echo '❌  GITHUB_TOKEN / OPENAI_API_KEY manquants' >&2; exit 1; }

# 2. (Ré)initialise le dépôt si besoin
if [[ ! -d .git ]]; then
  git init -q
  git remote add origin "https://$GITHUB_TOKEN@github.com/yannabadie/appIA.git"
fi

# 3. Installe Codex CLI s’il manque
command -v codex >/dev/null || npm install -g @openai/codex@latest

# 4. Laisse Codex travailler
codex -y -q 'Scaffold Dockerfile, jarvys_dev.sh, GitHub workflow for JARVYS-Dev'

# 5. Commit local des modifs
git add -A
git commit -m 'chore: scaffold JARVYS-Dev' 2>/dev/null || true

# 6. Toujours garantir l’URL avec PAT
git remote set-url origin "https://$GITHUB_TOKEN@github.com/yannabadie/appIA.git"

# 7. Synchronise (pull --rebase --autostash) puis push
git pull --rebase --autostash origin main || {
  echo '⚠️  Pull rebase impossible – passage en force-push'; }
git push --force-with-lease origin HEAD:main

echo '✅ Orchestration completed'
