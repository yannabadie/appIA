#!/bin/bash
set -e

echo "=== [JARVIS] Correction automatisée du stack Frontend & Backend ==="

cd "$(dirname "$0")"

FRONT=frontend
BACK=backend

# Vérifie que Node.js et npm sont installés
if ! command -v node >/dev/null 2>&1; then
  echo "❌ Node.js non trouvé. Installe-le d'abord (sudo apt install nodejs npm)"
  exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
  echo "❌ npm non trouvé. Installe-le d'abord (sudo apt install npm)"
  exit 1
fi

# 1. Crée (ou écrase) le frontend React/Vite + TS si besoin
if [[ ! -d "$FRONT" || ! -f "$FRONT/package.json" ]]; then
  echo "➡️  Création du frontend React/Vite $FRONT"
  npm create vite@latest "$FRONT" -- --template react-ts --force
else
  echo "✅ Projet frontend déjà présent."
fi

cd "$FRONT"
echo "➡️  Nettoyage du template Vite"
rm -f src/App.* src/assets/* vite.svg react.svg 2>/dev/null || true

# 2. Injection UI Jarvis minimaliste
cat > src/JarvisApp.tsx <<'EOF'
import React, { useState } from "react";
const agents = [{ name: "Jarvis", id: "jarvis" }, { name: "Mistral (Ollama)", id: "mistral" }];
export default function JarvisApp() {
  const [messages, setMessages] = useState<{sender: string, text: string}[]>([]);
  const [input, setInput] = useState("");
  const [agent, setAgent] = useState(agents[0].id);
  async function sendMessage(e: React.FormEvent) {
    e.preventDefault();
    if (!input) return;
    setMessages([...messages, {sender: "user", text: input}]);
    setInput("");
    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({ message: input, agent })
      });
      const data = await res.json();
      setMessages(msgs => [...msgs, {sender: "ai", text: data.response}]);
    } catch {
      setMessages(msgs => [...msgs, {sender: "ai", text: "[ERREUR backend non dispo]"}]);
    }
  }
  return (
    <div style={{ maxWidth: 700, margin: "auto", color: "#eee" }}>
      <h1>🤖 Jarvis AI Console</h1>
      <select value={agent} onChange={e => setAgent(e.target.value)}>
        {agents.map(a => <option key={a.id} value={a.id}>{a.name}</option>)}
      </select>
      <div style={{ minHeight: 300, background: "#222", margin: 20, borderRadius: 10, padding: 16 }}>
        {messages.map((msg, i) =>
          <div key={i} style={{ textAlign: msg.sender === "user" ? "right" : "left" }}>
            <b>{msg.sender === "user" ? "Vous" : "Jarvis"}</b> : {msg.text}
          </div>
        )}
      </div>
      <form onSubmit={sendMessage} style={{ display: "flex" }}>
        <input value={input} onChange={e => setInput(e.target.value)} placeholder="Votre message…" style={{ flex: 1, padding: 10 }} />
        <button type="submit" style={{ marginLeft: 10 }}>Envoyer</button>
      </form>
    </div>
  );
}
EOF

# Patch main.tsx pour afficher JarvisApp
cat > src/main.tsx <<'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import JarvisApp from './JarvisApp'
import './index.css'
ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <JarvisApp />
  </React.StrictMode>,
)
EOF

echo "✅ UI Jarvis injectée dans le frontend React."
cd ..

# 3. Crée un backend FastAPI minimal
if [[ ! -d "$BACK" ]]; then
  mkdir "$BACK"
fi
cat > $BACK/main.py <<'EOF'
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.post("/api/chat")
async def chat(req: Request):
    data = await req.json()
    message, agent = data.get("message"), data.get("agent")
    # TODO: plug ton agent_core ici
    return {"response": f"[{agent}] → Réponse de test à: {message}"}
EOF

echo "✅ Backend FastAPI prêt dans $BACK/main.py"

# 4. Affiche les commandes de test
echo
echo "=== [JARVIS] Tout est prêt ! ==="
echo "➡️  1. Lance le backend : (dans ./backend)"
echo "     uvicorn main:app --reload --host 0.0.0.0 --port 8000"
echo "➡️  2. Lance le frontend : (dans ./frontend)"
echo "     npm install && npm run dev"
echo "➡️  3. Accède à http://localhost:5173"
echo
echo "💡 Pour brancher tes modèles : édite backend/main.py (plugin agent_core.py, .env etc)"
echo "💡 Pour la voix, les uploads, etc : je peux injecter tout le code nécessaire sur demande."
