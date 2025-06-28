#!/bin/bash

set -e

echo "=== [JARVIS PROJECT INIT - ALL IN ONE] ==="
echo "⚡️ Lancement du script complet d'initialisation du projet JARVIS IA"

## 1. Nettoyage des vieux venv, fichiers temporaires, dossiers inutiles
echo "🧹 Suppression des anciens environnements virtuels et fichiers inutiles..."
find ~ -type d \( -name ".venv" -o -name "venv" -o -name "__pycache__" \) -prune -exec rm -rf {} +
find ~/my-double-numerique -type d \( -name ".venv" -o -name "venv" \) -prune -exec rm -rf {} +
find ~/my-double-numerique -type d -name "__pycache__" -exec rm -rf {} +

## 2. Upgrade pip et outils de build
echo "⬆️ Upgrade pip, setuptools et wheel..."
pip install --upgrade pip setuptools wheel

## 3. Correction du problème pip “resolution-too-deep” (mode legacy, désactive le nouveau resolver pip)
echo "🐍 Correction de pip (mode legacy resolver pour installation massive)..."
pip install --use-deprecated=legacy-resolver -r requirements.txt || true

## 4. (Optionnel) Réinstalle OpenAI et httpx à la main si besoin
pip install openai httpx

## 5. Installe/Upgrade backend FastAPI, uvicorn, python-dotenv, supabase etc.
pip install fastapi uvicorn python-dotenv google-generativeai supabase

## 6. Installe/Upgrade le frontend (npm) si présent
if [ -d "frontend" ]; then
    cd frontend
    npm install
    cd ..
fi

## 7. Installe/Upgrade Ollama (et Deepseek)
if command -v ollama >/dev/null 2>&1; then
    echo "✅ Ollama déjà installé"
else
    echo "🚀 Installation d'Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
fi

echo "⬇️ Installation/Pull du modèle Deepseek LLM..."
ollama pull deepseek-llm:latest

## 8. Génère le README.md et OBJECTIFS.md
cat <<EOF > README.md
# Jarvis IA

Assistant IA personnel local, multimodal (chat, vocal), multi-LLM (Deepseek via Ollama, OpenAI, Gemini).  
Projet auto-hébergé, modulaire et évolutif.

## Stack :
- Backend : Python 3.10 / FastAPI
- Frontend : React + ViteJS (npm)
- LLM : Ollama (Deepseek), OpenAI, Gemini (Google)
- Supabase (pour la mémoire persistante)
- TTS/STT : Whisper, Google TTS

---

Lancement rapide :
\`\`\`
# Backend (dans venv)
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Frontend
cd frontend
npm run dev

# Ollama local
ollama serve
\`\`\`
EOF

cat <<EOF > OBJECTIFS.md
# Objectifs Jarvis IA

Voir README.md pour la roadmap détaillée.  
- Routing LLM intelligent (OpenAI, Gemini, Deepseek)
- Mémoire persistante utilisateur (Supabase)
- Plugins (email, calendrier, fichiers…)
- Proactivité (Jarvis peut notifier ou proposer des actions à l’utilisateur)
- Interface moderne, ergonomique, personnalisable
EOF

## 9. Génère le .gitignore classique Python/JS
cat <<EOF > .gitignore
# Python
__pycache__/
*.py[cod]
*.egg-info/
venv/
.venv/
env/
*.sqlite3
# Node
node_modules/
dist/
build/
# VSCode
.vscode/
# Mac/Unix
.DS_Store
# Ollama
ollama.db
EOF

## 10. Prépare le dépôt git (init/commit)
git init
git add .
git commit -m "Initial Jarvis IA setup: backend, frontend, README, objectifs, .gitignore"

echo "🎉 Tout est prêt pour GitHub et Codex. Tu peux pousser ton dépôt !"
echo "Exécute : git remote add origin <URL> && git push -u origin main"

echo "=== [FIN JARVIS PROJECT INIT] ==="

