#!/usr/bin/env bash
set -e
echo "=== [JARVIS AI] Setup Fullstack Ultra-Auto ==="

### [1/6] CHECK ENV
if [ ! -f .env ]; then
    echo "❌ Fichier .env absent ! Place-le à la racine avant de lancer ce script."
    exit 1
fi

### [2/6] BACKEND : FastAPI
mkdir -p backend
cat > backend/main.py <<EOF
import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv("../.env")

import sys
sys.path.append("..")
from agent_core import agent_query  # Ton core d'agent IA

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/api/jarvis")
async def ask_jarvis(request: Request):
    data = await request.json()
    question = data.get("prompt", "")
    # Appelle ton agent IA :
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
# Si besoin, ajoute ici les dépendances de ton agent_core.py (openai, etc.)
EOF

### [3/6] FRONTEND : React/Vite
if [ ! -d frontend ]; then
    npm create vite@latest frontend -- --template react
    cd frontend && npm install && cd ..
fi

# Ajout du composant Jarvis (frontend/src/JarvisApp.jsx)
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

# Patch App.jsx pour afficher JarvisApp
sed -i 's/import .\/App.css/import .\/App.css"\;\nimport JarvisApp from ".\/JarvisApp"/' frontend/src/App.jsx
sed -i 's/function App()/function App() {\n  return <JarvisApp \/>;\n}/' frontend/src/App.jsx

### [4/6] INSTALL backend & test venv
cd backend
pip install --upgrade pip
pip install -r requirements.txt
cd ..

### [5/6] MESSAGE FINAL + TEST
echo
echo "=== [JARVIS] Fullstack prêt ! ==="
echo "1️⃣  Lance le backend :"
echo "   cd backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000"
echo "2️⃣  Lance le frontend :"
echo "   cd frontend && npm install && npm run dev"
echo "3️⃣  Accède à http://localhost:5173 pour dialoguer avec ton agent IA"
echo "Tout est relié : le front envoie à FastAPI qui appelle ton agent IA."

exit 0
