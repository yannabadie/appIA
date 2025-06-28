#!/usr/bin/env bash
set -e

echo "=== [JARVIS AI] Setup Fullstack Ultra-Auto ==="

# 0️⃣ Chercher/corriger le .env automatiquement
if [ ! -f ".env" ]; then
    echo "🔍 .env non trouvé à la racine, recherche…"
    found_env=$(find . -type f -name ".env" | head -1)
    if [ -n "$found_env" ]; then
        cp "$found_env" .env
        echo "✅ Copié $found_env → .env"
    else
        echo "❌ Aucun fichier .env trouvé. Place-le à la racine ou fournis-en un."
        exit 1
    fi
else
    echo "✅ .env déjà présent à la racine."
fi

# 1️⃣ Générer/patcher agent_core.py pour avoir agent_query
if [ ! -f agent_core.py ]; then
    echo "⚙️  Génération minimale de agent_core.py…"
    cat > agent_core.py <<EOF
def agent_query(prompt):
    return f"Jarvis a reçu : {prompt}"
EOF
else
    # Patch si fonction absente
    if ! grep -q "def agent_query" agent_core.py; then
        echo "⚠️  agent_core.py sans agent_query, patch auto."
        echo -e "\ndef agent_query(prompt):\n    return f'Jarvis a reçu : {prompt}'" >> agent_core.py
    fi
fi

# 2️⃣ BACKEND (FastAPI)
mkdir -p backend
cat > backend/main.py <<EOF
import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
load_dotenv("../.env")
import sys
sys.path.append("..")
from agent_core import agent_query
app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
@app.post("/api/jarvis")
async def ask_jarvis(request: Request):
    data = await request.json()
    question = data.get("prompt", "")
    try:
        answer = agent_query(question)
        return {"response": answer}
    except Exception as e:
        return {"response": "Erreur : " + str(e)}
EOF

cat > backend/requirements.txt <<EOF
fastapi
uvicorn
python-dotenv
EOF

# 3️⃣ FRONTEND (React/Vite)
if [ ! -d frontend ]; then
    npm create vite@latest frontend -- --template react
    cd frontend && npm install && cd ..
else
    echo "✅ Dossier frontend déjà présent."
fi

# Ajout du composant Jarvis
cat > frontend/src/JarvisApp.jsx <<EOF
import React, { useState } from 'react';
function JarvisApp() {
  const [prompt, setPrompt] = useState("");
  const [response, setResponse] = useState("");
  const [loading, setLoading] = useState(false);
  const askJarvis = async () => {
    setLoading(true);
    setResponse("");
    const res = await fetch("http://localhost:8000/api/jarvis", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt }),
    });
    const data = await res.json();
    setResponse(data.response);
    setLoading(false);
  };
  return (
    <div style={{ padding: 30, fontFamily: 'sans-serif' }}>
      <h1>🤖 Jarvis AI Console</h1>
      <textarea
        style={{ width: "90%", minHeight: 50 }}
        value={prompt}
        onChange={e => setPrompt(e.target.value)}
        placeholder="Pose ta question à Jarvis…"
      />
      <br />
      <button onClick={askJarvis} disabled={loading}>
        {loading ? "Attente..." : "Envoyer"}
      </button>
      <div style={{ marginTop: 20, background: "#222", color: "#0f0", padding: 10, borderRadius: 10, minHeight: 30 }}>
        {response}
      </div>
    </div>
  );
}
export default JarvisApp;
EOF

# Patch App.jsx pour afficher JarvisApp (remplace le contenu)
cat > frontend/src/App.jsx <<EOF
import JarvisApp from './JarvisApp';
function App() { return <JarvisApp />; }
export default App;
EOF

# 4️⃣ Installer les dépendances backend (dans le venv)
cd backend
pip install --upgrade pip
pip install -r requirements.txt
cd ..

# 5️⃣ Message final
echo ""
echo "=== [JARVIS] Fullstack prêt ! ==="
echo "1️⃣  Lance le backend :"
echo "   cd backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000"
echo "2️⃣  Lance le frontend :"
echo "   cd frontend && npm install && npm run dev"
echo "3️⃣  Accède à http://localhost:5173"
echo ""
echo "Tout est relié. UI prête, backend prêt, agent_core patché automatiquement."
