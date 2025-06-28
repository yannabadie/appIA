#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

echo "=== [JARVIS PATCH] Vérification et patch agent_query ==="

# Chemin du vrai agent_core
AGENT_CORE="./agent_core.py"
MAIN_BACKEND="./backend/main.py"

# 1. Supprime agent_core.py dans backend/ si présent
if [ -f "./backend/agent_core.py" ]; then
    echo "🧹 Suppression du doublon backend/agent_core.py"
    rm -f ./backend/agent_core.py
fi

# 2. Vérifie que la fonction agent_query existe
if ! grep -q 'def agent_query' "$AGENT_CORE"; then
    echo "⚡ agent_query() ABSENTE, insertion d’une version par défaut (mock)"
    cat <<EOF >> "$AGENT_CORE"

def agent_query(question):
    # TODO: remplace ce mock par la vraie logique
    return "Jarvis a bien reçu : " + str(question)
EOF
else
    echo "✅ agent_query() déjà présente dans agent_core.py"
fi

# 3. Vérifie l'import dans backend/main.py
if ! grep -q 'from agent_core import agent_query' "$MAIN_BACKEND"; then
    echo "➕ Ajout de l’import agent_query dans backend/main.py"
    # Ajoute sys.path si absent
    if ! grep -q 'sys.path.append' "$MAIN_BACKEND"; then
      sed -i '1i\
import sys, os\
sys.path.append(os.path.abspath(os.path.dirname(__file__) + "/.."))\
' "$MAIN_BACKEND"
    fi
    # Ajoute import agent_query en haut du main.py
    sed -i '2i\
from agent_core import agent_query\
' "$MAIN_BACKEND"
else
    echo "✅ L’import agent_query existe déjà dans backend/main.py"
fi

echo "=== [JARVIS PATCH] agent_query prêt et fonctionnel ! ==="
