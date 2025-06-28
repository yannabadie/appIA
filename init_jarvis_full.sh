#!/bin/bash

PROJECT_PATH=~/my-double-numerique
REPO_URL="https://github.com/yannabadie/appIA"
BRANCH="main"

cd $PROJECT_PATH

# 1. Git init si besoin
if [ ! -d ".git" ]; then
  git init
fi

git remote remove origin 2>/dev/null || true
git remote add origin $REPO_URL
git checkout -B $BRANCH

# 2. README.md pour humains ET Copilot/Codex
cat > README.md <<EOF
# Jarvis IA – Agent personnel local

## Objectif
Créer un agent IA personnel et professionnel, **exécuté en local** (sous WSL), combinant :
- Modèles de langage locaux puissants (Ollama + Deepseek)
- Accès cloud optionnel (OpenAI, Gemini, autres)
- Humanisation avancée : agent capable d’interactions spontanées, mémoire longue, routines, autonomie

## Fonctionnalités attendues
- Interface utilisateur moderne (React ou équivalent)
- Backend Python (FastAPI, gestion du routing)
- Interaction vocale et texte (micro/haut-parleur + chat)
- Gestion contextuelle et persistante de l’utilisateur (habitudes, préférences, profil)
- Routage intelligent des requêtes (Ollama/Deepseek, OpenAI, Gemini)
- Possibilité pour l’IA de “prendre la parole” si information/action urgente ou pertinente
- Automatisation, scripts shell et APIs (pour orchestrer/contrôler l’OS, etc.)

## Stack technique
- **Backend** : Python 3.10+ (FastAPI, openai, httpx…)
- **Frontend** : React (vite), npm, tailwind, shadcn/ui
- **IA locale** : Ollama (Deepseek LLM)
- **Cloud** : OpenAI, Gemini, Supabase (pour la persistance), autres APIs
- **Venv principal** : \`jarvisenv310\`
- **GitHub Repo** : $REPO_URL (branche $BRANCH)

## Directives de développement
- **Code évolutif, maintenable, documenté**
- Toute modification importante doit être documentée dans le README ou en commentaire
- Scripts de maintenance/cleaning/déploiement doivent toujours être inclus (`.sh`)
- **Aucun venv inutile** : n’utiliser que \`jarvisenv310\`
- Nettoyer le projet régulièrement avec les scripts d’audit fournis
- Penser à l’ergonomie et à l’expérience utilisateur “chatGPT-like”

## Mode d’emploi rapide
- Lancer \`ollama serve\` dans un terminal dédié WSL avant d’utiliser l’agent IA
- Activer le venv principal pour tout ce qui touche au backend Python :  
  \`source ~/my-double-numerique/jarvisenv310/bin/activate\`
- Pour toute modification, commit/push sur la branche $BRANCH du repo GitHub

---

## Pour Copilot/Codex

### Rôle attendu de l’IA (Jarvis)
- **Être un véritable assistant numérique, proactif, qui connaît l’utilisateur**
- Savoir router les requêtes au bon modèle selon le besoin (Ollama/Deepseek pour local, OpenAI/Gemini pour le cloud)
- Proposer des actions ou interruptions intelligentes, si contexte le justifie
- Permettre une personnalisation avancée via scripts/API
- Maintenir la simplicité et la fiabilité de l’ensemble (éviter l’usine à gaz)

### Exigences UX/UI
- Interface claire, moderne, sobre, “type chatGPT” (Dark mode par défaut, tailwind, shadcn/ui)
- Affichage instantané des réponses et de l’historique
- Paramétrage rapide des moteurs (local/cloud)
- Personnalisation avancée (profils, routines, mémoire persistante)
EOF

# 3. (Optionnel) Génère un prompt pour Copilot Chat ou Workspace
mkdir -p .copilot
cat > .copilot/README.md <<EOF
# Pour Copilot/Codex

- Ce projet est un **agent IA personnel local “Jarvis”**, basé sur Deepseek (ollama), Python (FastAPI), React, OpenAI/Gemini pour fallback.
- Objectif : créer un assistant intelligent, humain, proactif, ultra-connecté (APIs, scripts).
- Le code doit être propre, scalable, bien documenté.
- Toutes optimisations de stack, suggestions UX ou refacto sont bienvenues si elles gardent la simplicité.
- Toujours prioriser la stabilité de la stack, la simplicité d’installation, la clarté du code.
- Pour toute modification de dépendances, bien vérifier la compatibilité avec le venv principal (\`jarvisenv310\`).
EOF

# 4. Ajoute tout, commit & push
git add .
git commit -m "Init repo + doc pour Copilot/Codex"
git push -u origin $BRANCH

echo "✅ Projet initialisé, synchronisé sur $REPO_URL et prêt pour Copilot/Codex !"
echo "README.md et .copilot/README.md générés avec toutes les directives."

