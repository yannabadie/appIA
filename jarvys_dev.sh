#!/usr/bin/env bash
set -euo pipefail
log(){ printf '🕒 %(%F %T)T | %s\n' -1 "$*"; }

# 1.  Vérifie les secrets nécessaires
for v in GITHUB_TOKEN OPENAI_API_KEY SUPABASE_URL SUPABASE_KEY; do
  [[ -z "${!v:-}" ]] && { echo "❌  $v manquant" >&2; exit 1; }
done
export GH_TOKEN=$GITHUB_TOKEN

# 2.  Initialise ou met à jour le repo
if [[ ! -d .git ]]; then
  git init -q
  git remote add origin "https://$GITHUB_TOKEN@github.com/yannabadie/appIA.git"
fi
git pull --quiet origin main || true

# 3.  Installe Codex CLI si absent
command -v codex >/dev/null || npm install -g @openai/codex@latest

# 4.  Cherche la prochaine issue backlog
NEXT=$(gh issue list --label backlog --json number,createdAt \
       --jq 'sort_by(.createdAt) | .[0].number // empty')
if [[ -z $NEXT ]]; then
  log "🟡  Aucun backlog à traiter."
  exit 0
fi

TITLE=$(gh issue view "$NEXT" --json title --jq .title)
BODY=$(gh issue view "$NEXT" --json body --jq .body)
log "🎯 Issue #$NEXT : $TITLE"

# 5.  Appelle le planner (RAG + GPT-4o3)
CTX=$(python backend/rag_query.py "$TITLE"$'\n\n'"$BODY")
PLAN=$(python backend/ask_o3.py --title "$TITLE" --body "$BODY" --context "$CTX")

CODEX_PROMPT=$(jq -r '.codex_prompt' <<<"$PLAN")
TEST_CMD=$(jq -r '.test_cmd' <<<"$PLAN")
[[ -z $CODEX_PROMPT || $CODEX_PROMPT == null ]] && { log "🚫  Planner vide"; exit 0; }

# 6.  Exécute Codex
log "🛠️  Codex ..."
codex -y -q "$CODEX_PROMPT"

# 7.  Lancement des tests
log "🧪  Tests : $TEST_CMD"
bash -c "$TEST_CMD"

# 8.  Commit / push sur branche feat/issue-$NEXT-ts
BRANCH="feat/issue-$NEXT-$(date +%s)"
git add -A
git commit -m "feat(#$NEXT): impl auto via GPT-4o3 + Codex" || true
git checkout -B "$BRANCH"
git push -u origin "$BRANCH"

# 9.  Ouvre PR + commentaire
PR_URL=$(gh pr create --fill --head "$BRANCH" --base main)
gh issue edit "$NEXT" --add-label to-review
gh issue comment "$NEXT" -b "🤖  PR ouverte : $PR_URL"

log "✅  Cycle terminé"
