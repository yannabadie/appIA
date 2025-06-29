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
set -euo pipefail
IFS=$'\n\t'

log(){ printf "🕒  %s | %s\n" "$(date '+%F %T')" "$*"; }

### 1. Vérif des secrets obligatoires
for v in GITHUB_TOKEN OPENAI_API_KEY; do
  [[ -z "${!v:-}" ]] && { echo "❌  $v manquant" >&2; exit 1; }
done

### 2. Repo Git
if [[ ! -d .git ]]; then
  git init -q
  git remote add origin "https://$GITHUB_TOKEN@github.com/yannabadie/appIA.git"
fi
git pull --quiet origin main || true

### 3. Authentification gh CLI (silencieuse)
export GH_TOKEN=$GITHUB_TOKEN
gh auth setup-git --hostname github.com >/dev/null 2>&1 || true

### 4. Fonctions utilitaires ---------------------------------------------------
codex_run(){   # $1 = prompt
  log "Codex ▶︎ $1"
  codex -y -q "$1"
}

create_codespace(){
  log "⛺  Création Codespace pour la branche $1"
  gh api -X POST \
     repos/:owner/:repo/codespaces \
     -f ref="$1" >/dev/null
}

assign_copilot(){
  local issue="$1"
  gh issue edit "$issue" --add-assignee github-copilot --add-label to-copilot
}

### 5. Import / triage backlog -------------------------------------------------
PROJECT_URL="https://github.com/users/yannabadie/projects/2"
log "Sync Project board"
gh project item-list "$PROJECT_URL" --format json >/dev/null 2>&1 || \
  gh project create "$PROJECT_URL" --title "Jarvis AI" >/dev/null

# Exemple : tagger toute issue ouverte sans label
for id in $(gh issue list --json number,labels,state --jq '.[] | select(.labels==[]) | .number'); do
  log "🔖 Label issue #$id → backlog"
  gh issue edit "$id" --add-label backlog
done

### 6. Sélection de la next-best issue ----------------------------------------
NEXT=$(gh issue list --label backlog --json number,createdAt \
       --jq 'sort_by(.createdAt) | .[0].number // empty')
if [[ -z "$NEXT" ]]; then
  log "👍  Aucun backlog en attente. Fin."
  exit 0
fi
log "🎯 Prochaine feature : issue #$NEXT"

assign_copilot "$NEXT"

### 7. Branche de travail + Codespace -----------------------------------------
BRANCH="feat/issue-$NEXT-$(date +%H%M)"
git checkout -b "$BRANCH"
create_codespace "$BRANCH" || true

### 8. Génération Codex --------------------------------------------------------
PROMPT=$(gh issue view "$NEXT" --json title,body \
         --jq '.title + "\n\n" + .body')
codex_run "$PROMPT"

### 9. Commit / push -----------------------------------------------------------
git add -A
git commit -m "feat(#$NEXT): auto-implementation via Codex" || \
  log "ℹ️ Aucun changement à committer"

git remote set-url origin "https://$GITHUB_TOKEN@github.com/yannabadie/appIA.git"
git push --set-upstream origin "$BRANCH"

### 10. Ouvre un PR + commentaire issue ---------------------------------------
PR_URL=$(gh pr create --fill --head "$BRANCH" --base main)
gh issue comment "$NEXT" -b "🤖 PR ouverte : $PR_URL"

log "✅  Cycle horaire terminé"
