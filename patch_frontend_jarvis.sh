#!/bin/bash

set -e

FRONT=~/my-double-numerique/frontend
SRC="$FRONT/src"
echo "=== [JARVIS PATCH] Reconstruction et patch complet du frontend React/Vite ==="

# 1. S'assure que le dossier frontend/src existe
mkdir -p "$SRC"

# 2. Corrige l'import CSS absent
if grep -q 'import "./index.css";' "$SRC/main.tsx"; then
  sed -i '/import ".\/index\.css";/d' "$SRC/main.tsx"
  echo "🧹 Import CSS fautif supprimé de main.tsx"
fi

# 3. Crée un fichier CSS stylé si absent
cat > "$SRC/index.css" <<'EOF'
body {
  margin: 0;
  padding: 0;
  font-family: 'Segoe UI', Roboto, Arial, sans-serif;
  background: linear-gradient(120deg,#232526,#414345);
  color: #f5f6fa;
  min-height: 100vh;
}
#jarvis-app {
  max-width: 560px;
  margin: 40px auto;
  background: rgba(30,30,40,0.98);
  border-radius: 18px;
  box-shadow: 0 8px 40px #2228  ;
  padding: 36px 28px 24px 28px;
  min-height: 420px;
}
.header {
  text-align: center;
  margin-bottom: 16px;
}
.jarvis-logo {
  width: 64px; height: 64px; border-radius: 100%;
  background: linear-gradient(145deg,#2088fe,#00ffe7 80%);
  display: inline-flex; align-items: center; justify-content: center;
  margin-bottom: 10px;
  font-size: 42px;
}
.jarvis-title {
  font-weight: bold;
  font-size: 2.1rem;
  letter-spacing: 2px;
}
.chat-window {
  height: 270px; overflow-y: auto;
  background: #20222b;
  border-radius: 14px;
  padding: 12px;
  margin-bottom: 20px;
}
.message {
  padding: 7px 12px; margin-bottom: 8px; border-radius: 7px;
  max-width: 85%; word-break: break-word;
}
.message.user { background: #2088fe44; align-self: flex-end; margin-left: auto;}
.message.jarvis { background: #00ffe755; align-self: flex-start; margin-right: auto;}
.input-area {
  display: flex; gap: 10px;
}
.input-area input {
  flex: 1; border-radius: 8px; border: none; padding: 10px 12px; font-size: 1rem;
  background: #232435; color: #fff; outline: none;
}
.input-area button {
  background: linear-gradient(120deg,#2088fe,#00ffe7 70%);
  border: none; border-radius: 8px; color: #222; font-weight: bold;
  font-size: 1.1rem; padding: 0 18px; cursor: pointer; transition: 0.1s;
}
.input-area button:hover {
  filter: brightness(1.15);
}
::-webkit-scrollbar {width:8px;background:#292c38;}
::-webkit-scrollbar-thumb {background:#2088fe88;border-radius:5px;}
@media(max-width:680px){
  #jarvis-app{max-width:99vw;padding:12px;}
}
EOF

echo "🎨 index.css prêt."

# 4. Ajoute/Appelle index.css dans main.tsx s'il n'est pas déjà présent
if ! grep -q 'import "./index.css";' "$SRC/main.tsx"; then
  sed -i '1i import "./index.css";' "$SRC/main.tsx" || true
  echo "✅ Import CSS ajouté en tête de main.tsx"
fi

# 5. Crée JarvisApp.tsx (UI principale)
cat > "$SRC/JarvisApp.tsx" <<'EOF'
import React, { useState, useRef, useEffect } from "react";

type Message = { sender: "user" | "jarvis"; text: string };

const demoWelcome = "Bonjour, je suis Jarvis 🤖. Que puis-je faire pour toi ?";

export default function JarvisApp() {
  const [messages, setMessages] = useState<Message[]>([
    { sender: "jarvis", text: demoWelcome }
  ]);
  const [input, setInput] = useState("");
  const chatRef = useRef<HTMLDivElement>(null);

  // Auto-scroll
  useEffect(() => {
    chatRef.current?.scrollTo(0, chatRef.current.scrollHeight);
  }, [messages]);

  async function handleSend() {
    const question = input.trim();
    if (!question) return;
    setMessages((msgs) => [...msgs, { sender: "user", text: question }]);
    setInput("");
    // Envoi au backend (adapte l'URL selon conf)
    try {
      const res = await fetch("/api/jarvis", {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({ query: question })
      });
      const data = await res.json();
      setMessages((msgs) => [...msgs, { sender: "jarvis", text: data.response ?? "(Aucune réponse...)" }]);
    } catch (e) {
      setMessages((msgs) => [...msgs, { sender: "jarvis", text: "Erreur de connexion au backend." }]);
    }
  }

  return (
    <div id="jarvis-app">
      <div className="header">
        <div className="jarvis-logo">🤖</div>
        <div className="jarvis-title">JARVIS AI</div>
      </div>
      <div className="chat-window" ref={chatRef}>
        {messages.map((msg, i) => (
          <div key={i} className={"message " + msg.sender}>{msg.text}</div>
        ))}
      </div>
      <div className="input-area">
        <input
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === "Enter" && handleSend()}
          placeholder="Tape ta question à Jarvis..."
        />
        <button onClick={handleSend}>Envoyer</button>
      </div>
    </div>
  );
}
EOF
echo "🧩 JarvisApp.tsx généré."

# 6. Patch main.tsx pour qu’il charge JarvisApp
cat > "$SRC/main.tsx" <<'EOF'
import "./index.css";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import JarvisApp from "./JarvisApp";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <JarvisApp />
  </StrictMode>
);
EOF
echo "🛠 main.tsx (React entry) régénéré."

# 7. Crée App.tsx pour éviter toute confusion (facultatif)
cat > "$SRC/App.tsx" <<'EOF'
export default function App() {
  return null;
}
EOF

# 8. Crée index.html si absent (vite attend un <div id="root"></div>)
cat > "$FRONT/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="fr">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1.0" />
    <title>Jarvis AI</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF
echo "📄 index.html prêt."

echo "=== [JARVIS PATCH] Frontend prêt ! ==="
echo "➡️  Lance dans frontend : npm run dev"
