#!/bin/bash
set -e

echo "=== [JARVIS RESET STACK] Nettoyage structure et relink fullstack ==="

# 1. Suppression des backend mal placés, node_modules inutiles
rm -rf frontend/backend frontend/frontend
find . -type d -name "node_modules" -exec rm -rf {} +

# 2. Vérification présence des fichiers clés
for file in .env agent_core.py; do
  [[ ! -f $file ]] && echo "❌ $file absent !" && exit 1
done

# 3. Backend FastAPI propre
if [[ ! -d backend ]]; then
  mkdir backend
  cat > backend/main.py <<EOF
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import sys
import os
sys.path.append(os.path.abspath(os.path.dirname(__file__) + "/.."))
from agent_core import agent_query

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

@app.post("/ask")
async def ask(request: Request):
    data = await request.json()
    question = data.get("question", "")
    response = agent_query(question)
    return {"response": response}
EOF
  echo "✅ Backend réinitialisé dans backend/main.py"
fi

# 4. Frontend React clean
if [[ ! -d frontend ]]; then
  npm create vite@latest frontend -- --template react-ts --force
  cd frontend
  npm install
  # Injecte l’UI de base
  cat > src/JarvisApp.jsx <<'EOF'
import React, { useState } from "react";

export default function JarvisApp() {
  const [question, setQuestion] = useState("");
  const [response, setResponse] = useState("");
  const [loading, setLoading] = useState(false);

  const askJarvis = async (e) => {
    e.preventDefault();
    setLoading(true);
    setResponse("");
    try {
      const r = await fetch("http://localhost:8000/ask", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ question }),
      });
      const data = await r.json();
      setResponse(data.response);
    } catch {
      setResponse("Erreur de connexion au backend !");
    }
    setLoading(false);
  };

  return (
    <div style={{ margin: "2em auto", maxWidth: 600 }}>
      <h1>🤖 Jarvis AI Console</h1>
      <form onSubmit={askJarvis}>
        <input
          style={{ width: "70%", fontSize: 18 }}
          value={question}
          onChange={(e) => setQuestion(e.target.value)}
          placeholder="Pose ta question à Jarvis"
        />
        <button type="submit" style={{ fontSize: 18 }}>Envoyer</button>
      </form>
      {loading && <p>Chargement...</p>}
      {response && <div style={{ marginTop: "2em", background: "#222", padding: 16, borderRadius: 8 }}>
        <b>Réponse :</b>
        <div>{response}</div>
      </div>}
    </div>
  );
}
EOF
  # Patch App.tsx pour lancer JarvisApp
  echo "import JarvisApp from './JarvisApp.jsx'; export default function App() { return <JarvisApp />; }" > src/App.tsx
  cd ..
  echo "✅ Frontend réinitialisé dans frontend/"
fi

echo "=== [JARVIS RESET STACK] Terminé ==="
echo "➡️  1. Démarre le backend:  cd backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000"
echo "➡️  2. Démarre le frontend: cd frontend && npm install && npm run dev"
echo "➡️  3. Accède à http://localhost:5173"
