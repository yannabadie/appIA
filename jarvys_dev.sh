#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# JARVYS-Dev v2.0 – Agent autonome (exécution horaire)
# - synchronise le Kanban Project v2
# - importe / (re)classe les issues
# - assigne Copilot & ouvre Codespace
# - lance Codex sur la feature la + prioritaire
# - pousse le patch + commente l'issue
# Dépendances dans l'image : git, gh, node 22, python3, bash, codex CLI
# ─────────────────────────────────────────────────────────────────────────────
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

log(){ printf "🕒 %s | %s\n" "$(date '+%F %T')" "$*"; }

### Secrets vérif
for v in GITHUB_TOKEN OPENAI_API_KEY SUPABASE_URL SUPABASE_KEY; do
  [[ -z "${!v:-}" ]] && { echo "❌  $v manquant" >&2; exit 1; }
done
export GH_TOKEN=$GITHUB_TOKEN

### Repo
if [[ ! -d .git ]]; then
  git init -q
  git remote add origin "https://$GITHUB_TOKEN@github.com/yannabadie/appIA.git"
fi
git pull --quiet origin main || true

### Prochaine issue backlog
NEXT=$(gh issue list --label backlog --json number,createdAt \
       --jq 'sort_by(.createdAt) | .[0].number // empty')
[[ -z $NEXT ]] && { log "👍  Pas d'issue backlog"; exit 0; }
TITLE=$(gh issue view "$NEXT" --json title --jq .title)
BODY=$(gh issue view "$NEXT" --json body  --jq .body)
log "🎯 Issue #$NEXT : $TITLE"

### RAG (Supabase) + GPT-4-o3 planner
CTX=$(python backend/rag_query.py "$TITLE"$'\n\n'"$BODY")
PLAN=$(python backend/ask_o3.py \
        --title "$TITLE" --body "$BODY" --context "$CTX")

CODEX_PROMPT=$(jq -r '.codex_prompt' <<<"$PLAN")
TEST_CMD=$(jq -r '.test_cmd'     <<<"$PLAN")
[[ -z $CODEX_PROMPT || $CODEX_PROMPT == "null" ]] && {
  log "🚫  Planner n’a rien produit"; exit 0; }

### Exec Codex
log "🛠️  Codex…"
codex -y -q "$CODEX_PROMPT"

### Tests
log "🧪  Tests : $TEST_CMD"
bash -c "$TEST_CMD"

### Commit & push
git add -A
git commit -m "feat(#$NEXT): impl auto via GPT-4-o3 + Codex" || true
git remote set-url origin "https://$GITHUB_TOKEN@github.com/yannabadie/appIA.git"
BRANCH="feat/issue-$NEXT-$(date +%s)"
git checkout -B "$BRANCH"
git push --set-upstream origin "$BRANCH"

### PR + issue comment
PR_URL=$(gh pr create --fill --head "$BRANCH" --base main)
gh issue edit "$NEXT" --add-label to-review
gh issue comment "$NEXT" -b "🤖  PR ouverte : $PR_URL"

log "✅  Cycle horaire terminé"
