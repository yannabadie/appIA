#!/bin/bash
# ---- 0. Prérequis ----
# - Place-toi bien dans le dossier racine de ton projet (my-double-numerique ou appIA)
# - Lance dans le venv Python (source ~/my-double-numerique/jarvisenv310/bin/activate)

set -e

# ---- 1. Initialisation git si besoin ----
if [ ! -d .git ]; then
  git init
fi

# ---- 2. Ajout du remote et branche principale ----
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/yannabadie/appIA.git
git checkout -B main

# ---- 3. Premier commit si vide ----
if [ -z "$(git status --porcelain)" ]; then
  echo "Aucun changement à commiter."
else
  git add .
  git commit -m "Initial commit: full project structure, auto-setup"
fi

# ---- 4. Push automatisé avec token ----
git config --global credential.helper store
echo "https://yannabadie:$TOKEN@github.com" > ~/.git-credentials

git push -u origin main

echo "✅ Projet synchronisé avec Github !"

# ---- 5. Log et état du projet ----
git status
git log --oneline --graph | head -10
