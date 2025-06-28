#!/bin/bash
echo "=== [JARVIS PATCH] Correction et patch backend FastAPI ==="

BACKEND_DIR="backend"
MAIN_PY="$BACKEND_DIR/main.py"
AGENT_CORE="$BACKEND_DIR/agent_core.py"

# 1. S'assure que FastAPI est installée
pip install fastapi uvicorn

# 2. Crée/patch main.py avec l'endpoint compatible
cat > $MAIN_PY <<'EOF'
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import os
import sys

# Ajoute agent_core.py du projet parent si dispo
sys.path.append(os.path.abspath(os.path.dirname(__file__)))

try:
    from agent_core import agent_query
    agent_loaded = True
except ImportError:
    agent_loaded = False

app = FastAPI()

# CORS pour front local
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)

@app.post("/api/jarvis")
async def ask_jarvis(req: Request):
    data = await req.json()
    query = data.get("query", "")
    engine = data.get("engine", "openai")
    if not query.strip():
        return {"response": "Pose-moi une vraie question..."}
    # Appelle ton core IA si dispo, sinon dummy
    if agent_loaded:
        try:
            result = agent_query(query, engine=engine)
            return {"response": result}
        except Exception as e:
            return {"response": f"Erreur agent_core: {e}"}
    # Dummy fallback
    return {"response": f"(Mock) Tu as demandé '{query}' à l'IA '{engine}'."}
EOF

# 3. Informe l'utilisateur
echo "✅ backend/main.py patché pour gérer POST /api/jarvis"
echo "➡️ Lance-le avec :"
echo "   cd backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000"
echo
echo "Si tu veux que l'agent_core.py soit pris en compte :"
echo " - Il doit contenir une fonction 'agent_query(question, engine)'"
echo "Sinon la réponse sera simulée."
