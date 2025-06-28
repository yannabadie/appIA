#!/bin/bash
set -e

echo "=== [JARVIS PATCH] Injection UI Frontend React ==="
cd "$(dirname "$0")"

# Vérifier dossier frontend
if [ ! -d "frontend" ]; then
    echo "❌ Dossier frontend/ introuvable !"
    exit 1
fi

# Nettoyage du template Vite par défaut
rm -f frontend/src/App.tsx frontend/src/App.jsx frontend/src/App.css
rm -f frontend/src/index.css
rm -rf frontend/src/assets

# Injection du composant JarvisApp.jsx
cat > frontend/src/JarvisApp.jsx <<EOF
import React, { useState } from "react";

export default function JarvisApp() {
  const [msg, setMsg] = useState("");
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(false);

  async function askJarvis(e) {
    e.preventDefault();
    if (!msg.trim()) return;
    setLoading(true);
    setHistory(h => [...h, { role: "user", content: msg }]);
    try {
      const r = await fetch("http://localhost:8000/ask", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query: msg })
      });
      const data = await r.json();
      setHistory(h => [...h, { role: "jarvis", content: data.response || "..." }]);
    } catch (e) {
      setHistory(h => [...h, { role: "jarvis", content: "Erreur connexion backend." }]);
    }
    setMsg(""); setLoading(false);
  }

  return (
    <div style={{padding:40, maxWidth:700, margin:"auto", fontFamily:"Segoe UI, sans-serif"}}>
      <h1>🦾 Jarvis AI Console</h1>
      <form onSubmit={askJarvis} style={{display:"flex",gap:8,margin:"20px 0"}}>
        <input value={msg} onChange={e=>setMsg(e.target.value)} placeholder="Pose ta question à Jarvis..." style={{flex:1, padding:8, borderRadius:6, border:"1px solid #444"}} />
        <button type="submit" disabled={loading} style={{padding:"8px 18px", borderRadius:6, background:"#333", color:"#fff", border:"none"}}>{loading ? "..." : "Envoyer"}</button>
      </form>
      <div style={{marginTop:16}}>
        {history.map((m,i) =>
          <div key={i} style={{margin:"8px 0"}}>
            <b>{m.role==="user"?"👤":"🤖"}</b> {m.content}
          </div>
        )}
      </div>
    </div>
  );
}
EOF

# Adapter le point d’entrée main.jsx (pour React)
cat > frontend/src/main.jsx <<EOF
import React from 'react';
import ReactDOM from 'react-dom/client';
import JarvisApp from './JarvisApp.jsx';

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <JarvisApp />
  </React.StrictMode>
)
EOF

echo "✅ UI Jarvis React minimal injectée !"
echo "➡️  Lance le backend puis dans frontend/ : npm run dev"
