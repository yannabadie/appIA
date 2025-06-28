#!/bin/bash
set -e

echo "=== [JARVIS PATCH] Correction stack Backend/Frontend & fonctionnalités UI ==="

# 1. Correction backend FastAPI (main.py)
BACKEND_PATH="./backend"
MAIN_PY="$BACKEND_PATH/main.py"

# Ajoute la route /ask si elle n'existe pas déjà
if ! grep -q "@app.post(\"/ask\")" "$MAIN_PY"; then
cat << 'EOF' >> "$MAIN_PY"

# [AUTO PATCH] /ask alias (pour compatibilité frontend legacy)
from fastapi import Request
@app.post("/ask")
async def ask_jarvis_alias(req: Request):
    return await ask_jarvis(req)
EOF
echo "✅ Ajout de la route /ask à $MAIN_PY"
fi

# 2. Correction frontend React
FRONTEND_PATH="./frontend"
SRC_PATH="$FRONTEND_PATH/src"

# Crée index.css s'il manque
if [ ! -f "$SRC_PATH/index.css" ]; then
cat << EOF > "$SRC_PATH/index.css"
body { background: #232323; color: #fafafa; margin: 0; font-family: Inter, sans-serif; }
input, button { font-size: 1rem; }
.time { color: #AAA; font-size: 0.9em; margin-right: 8px; }
.ai-label { font-weight: bold; color: #73eaff; margin-right: 8px; }
.me-label { font-weight: bold; color: #ffa773; margin-right: 8px; }
EOF
echo "✅ Création de src/index.css"
fi

# Patch src/main.tsx pour s'assurer que le CSS est importé
if ! grep -q 'import "./index.css"' "$SRC_PATH/main.tsx"; then
sed -i '1i import "./index.css";' "$SRC_PATH/main.tsx"
echo "✅ Patch import CSS dans main.tsx"
fi

# Patch UI principale pour historique, heure, IA interrogée, user info
APP_TSX="$SRC_PATH/JarvisApp.tsx"
if [ -f "$APP_TSX" ]; then
cat << 'EOF' > "$APP_TSX"
/*
 * JarvisApp.tsx - UI principale améliorée (historique, IA, user, timestamp)
 */
import React, { useState } from "react";

const AI_NAME = process.env.VITE_AI_NAME || "Jarvis";
const USER_NAME = process.env.VITE_USER_NAME || "Yann";

function formatTime(date: Date) {
  return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });
}

export default function JarvisApp() {
  const [input, setInput] = useState("");
  const [history, setHistory] = useState([
    { role: "ai", text: `Bienvenue, ${USER_NAME} ! Pose ta question à ${AI_NAME}.`, time: new Date(), ia: AI_NAME }
  ]);
  const [ai, setAI] = useState("Mistral");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function askJarvis(e) {
    e.preventDefault();
    if (!input.trim()) return;
    const now = new Date();
    setHistory([...history, { role: "user", text: input, time: now }]);
    setLoading(true); setError("");
    try {
      const res = await fetch("http://localhost:8000/ask", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ question: input, ia: ai, user: USER_NAME }),
      });
      if (!res.ok) throw new Error(`[${res.status}] ${await res.text()}`);
      const data = await res.json();
      setHistory(h =>
        [...h, { role: "ai", text: data.answer || "(pas de réponse)", time: new Date(), ia }]
      );
    } catch (e) {
      setHistory(h =>
        [...h, { role: "ai", text: "(Erreur API : " + e.message + ")", time: new Date(), ia }]
      );
      setError(e.message);
    }
    setInput(""); setLoading(false);
  }

  return (
    <div style={{ margin: "auto", maxWidth: 900, paddingTop: 70 }}>
      <div style={{ display: "flex", alignItems: "center", marginBottom: 20 }}>
        <span style={{ fontSize: 40, marginRight: 12 }}>🤖</span>
        <span style={{ fontSize: 32, fontWeight: "bold" }}>{AI_NAME} <span style={{fontSize:18}}>(powered by {ai})</span></span>
        <span style={{ marginLeft: "auto", fontSize: 16, color: "#aaa" }}>Utilisateur: <b>{USER_NAME}</b></span>
      </div>
      <form onSubmit={askJarvis} style={{ marginBottom: 30, display: "flex" }}>
        <input autoFocus disabled={loading} type="text" placeholder={`Pose ta question à ${AI_NAME}...`}
          value={input} onChange={e => setInput(e.target.value)} style={{ flex: 1, padding: 12, borderRadius: 6, border: "1px solid #333" }} />
        <button disabled={loading} style={{ marginLeft: 12, padding: "10px 26px", borderRadius: 7, background: "#5ad1d1", color: "#232323", fontWeight: 700, border: 0 }}>
          {loading ? "..." : "Envoyer"}
        </button>
      </form>
      {error && <div style={{ color: "red", marginBottom: 20 }}>Erreur réseau: {error}</div>}
      <div>
        {history.map((msg, i) => (
          <div key={i} style={{ marginBottom: 12 }}>
            <span className={msg.role === "ai" ? "ai-label" : "me-label"}>
              {msg.role === "ai" ? msg.ia + " (IA)" : USER_NAME}
            </span>
            <span className="time">{formatTime(msg.time)}</span>
            <span>{msg.text}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
EOF
echo "✅ UI JarvisApp.tsx patchée avec historique, IA, utilisateur et heure"
fi

# Patch .env frontend pour variables IA/USER si inexistant
ENV_FRONT="$FRONTEND_PATH/.env"
if ! grep -q "VITE_AI_NAME" "$ENV_FRONT" 2>/dev/null; then
  echo "VITE_AI_NAME=Jarvis" >> "$ENV_FRONT"
  echo "VITE_USER_NAME=Yann" >> "$ENV_FRONT"
  echo "✅ Ajout des variables .env frontend (IA et User)"
fi

echo "=== [JARVIS PATCH] Stack corrigée et enrichie. Relance backend & frontend ==="
echo "------------------------------------------"
echo "Backend: cd backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000"
echo "Frontend: cd frontend && npm run dev"
echo "------------------------------------------"
