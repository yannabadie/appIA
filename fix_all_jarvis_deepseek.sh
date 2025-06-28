#!/bin/bash

echo "=== [JARVIS AUTO-FIX] Stack complète avec Deepseek ==="

# 1. Vérif/Install Ollama
if ! command -v ollama &> /dev/null; then
    echo "➡️  Ollama non trouvé, installation en cours..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "✅ Ollama déjà installé."
fi

# 2. Lancer Ollama en tâche de fond si pas déjà actif
if ! nc -z localhost 11434; then
    echo "➡️  Lancement du serveur Ollama en tâche de fond..."
    nohup ollama serve > /dev/null 2>&1 &
    sleep 3
else
    echo "✅ Serveur Ollama déjà actif."
fi

# 3. Vérif/Pull Deepseek LLM (dernière version)
if ! ollama list | grep -iq deepseek; then
    echo "➡️  Téléchargement du modèle Deepseek LLM..."
    ollama pull deepseek-llm:latest
else
    echo "✅ Modèle Deepseek déjà présent."
fi

# 4. Vérif module Python openai
if ! pip freeze | grep -q 'openai'; then
    echo "➡️  Installation du module Python openai..."
    pip install openai
else
    echo "✅ Module openai déjà présent."
fi

# 5. Vérif module httpx (souvent utile)
if ! pip freeze | grep -q 'httpx'; then
    echo "➡️  Installation du module Python httpx..."
    pip install httpx
else
    echo "✅ Module httpx déjà présent."
fi

# 6. Vérif présence .env
if [ ! -f .env ]; then
    echo "❌ Fichier .env manquant ! Place-le à la racine avant de continuer."
    exit 1
else
    echo "✅ Fichier .env présent."
fi

# 7. Synthèse, instructions relance
echo ""
echo "=== [JARVIS AUTO-FIX TERMINÉ] ==="
echo "Deepseek LLM installé, Ollama prêt, dépendances Python OK."
echo "➡️ Lance dans 2 terminaux :"
echo "   1. cd backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000"
echo "   2. cd frontend && npm run dev"
echo ""
echo "Test : sélectionne Deepseek comme moteur, pose une question en français."
echo "Dis-moi le comportement ou tout blocage éventuel."
