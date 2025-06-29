#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  JARVYS-Dev — boucle horaire lancée par le workflow GitHub
# ─────────────────────────────────────────────────────────────
set -Eeuo pipefail
IFS=$'\n\t'

log() { printf "🕒 %s | %s\n" "$(date '+%F %T')" "$*"; }

# 1️⃣ Vérification des secrets indispensables ────────────────
required=( GITHUB_TOKEN OPENAI_API_KEY SUPABASE_URL SUPABASE_KEY )
for v in "${required[@]}"; do
  [[ -z "${!v:-}" ]] && { echo "❌  $v manquant" >&2; exit 1; }
done
export GH_TOKEN="$GITHUB_TOKEN"      # gh CLI lit GH_TOKEN

# 2️⃣ Préparation du dépôt ───────────────────────────────────
if [[ ! -d .git ]]; then
  git init -q
  git remote add origin "https://${GITHUB_TOKEN}@github.com/yannabadie/appIA.git"
fi

# On se place toujours sur main ; si déjà en détaché → checkout
git checkout -qf main || git checkout -qB main
# Pull soft (sans échouer si rien à faire)
git pull --quiet --rebase origin main || true

# 3️⃣ Sélection de la prochaine issue « backlog » ─────────────
NEXT=$(gh issue list --label backlog --state open --json number,createdAt \
        --jq 'sort_by(.createdAt) | .[0].number // empty')

if [[ -z $NEXT ]]; then
  log "👍  Aucun backlog à traiter."
  exit 0
fi

TITLE=$(gh issue view "$NEXT" --json title   --jq .title)
BODY=$(gh  issue view "$NEXT" --json body    --jq .body)
log "🎯  Issue #$NEXT : $TITLE"

# 4️⃣ Récupération du contexte RAG + plan GPT-4o3 ─────────────
CTX=$(python -m backend.rag_query   "$TITLE"$'\n\n'"$BODY")
PLAN=$(python -m backend.ask_o3 \
        --title "$TITLE" --body "$BODY" --context "$CTX")

CODEX_PROMPT=$(jq -r '.codex_prompt // empty' <<<"$PLAN")
TEST_CMD    =$(jq -r '.test_cmd     // empty' <<<"$PLAN")

if [[ -z $CODEX_PROMPT ]]; then
  log "🚫  Le planner n’a rien produit — abandon."
  exit 0
fi

# 5️⃣ Exécution Codex CLI ────────────────────────────────────
log "🛠️  Codex en cours…"
codex -y -q "$CODEX_PROMPT"

# 6️⃣ Tests automatisés (facultatifs) ────────────────────────
if [[ -n $TEST_CMD ]]; then
  log "🧪  Tests : $TEST_CMD"
  bash -c "$TEST_CMD"
fi

# 7️⃣ Commit & branche PR ────────────────────────────────────
git add -A
git commit -m "feat(#$NEXT): auto-impl via GPT-4-o3 + Codex" || true

BRANCH="feat/issue-$NEXT-$(date +%s)"
git switch -C "$BRANCH"

git push --set-upstream "https://${GITHUB_TOKEN}@github.com/yannabadie/appIA.git" "$BRANCH"

# 8️⃣ Ouverture de la PR + mise à jour de l’issue ────────────
PR_URL=$(gh pr create --fill --head "$BRANCH" --base main)
gh issue edit "$NEXT" --add-label to-review
gh issue comment "$NEXT" -b "🤖  PR ouverte : $PR_URL"

log "✅  Cycle horaire terminé"
