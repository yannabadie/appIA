#!/usr/bin/env bash
set -e

echo "=== [JARVIS] Correction stack et frontend React ==="

# 1. Upgrade Node & npm si besoin
MIN_NODE_VERSION=20
NODEV=$(node --version | grep -oP '\d+' | head -1 || echo 0)
if [ "$NODEV" -lt "$MIN_NODE_VERSION" ]; then
  echo "➡️  Upgrade NodeJS (version > 20 recommandée)"
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt install -y nodejs
  npm install -g npm@latest
fi

# 2. Vérifie présence du frontend
FRONTEND_PATH="$PWD/frontend"
if [ ! -d "$FRONTEND_PATH" ] || [ ! -d "$FRONTEND_PATH/src" ]; then
  echo "➡️  Création du projet React/Vite dans $FRONTEND_PATH"
  npx create-vite@latest frontend --template react -- --skip-git
  cd frontend
  npm install axios
  cd ..
else
  echo "✅ Frontend déjà créé dans $FRONTEND_PATH"
fi

# 3. (Ré)écriture du composant UI custom
cat > frontend/src/JarvisApp.jsx <<'EOF'
import React, { useState } from "react";
import axios from "axios";

export default function JarvisApp() {
  const [input, setInput] = useState("");
  const [history, setHistory] = useState([]);
  const [output, setOutput] = useState("");
  const [agent, setAgent] = useState("ollama");

  const sendPrompt = async () => {
    const res = await axios.post("/api/ask", {
      prompt: input,
      history,
      agent,
    });
    setOutput(res.data.response);
    setHistory([...history, { role: "user", content: input }, { role: "assistant", content: res.data.response }]);
    setInput("");
  };

  return (
    <div className="p-8 max-w-xl mx-auto">
      <h1 className="text-3xl font-bold mb-4">🦾 Jarvis AI Console</h1>
      <div>
        <select value={agent} onChange={e => setAgent(e.target.value)} className="mb-4">
          <option value="ollama">🦙 Mistral (Ollama)</option>
          <option value="openai">🤖 GPT-4 (OpenAI)</option>
          <option value="gemini">🔷 Gemini (Google)</option>
        </select>
      </div>
      <textarea value={input} onChange={e => setInput(e.target.value)} className="w-full border p-2 mb-2" rows={3} />
      <button onClick={sendPrompt} className="bg-blue-600 text-white rounded px-4 py-2">Envoyer</button>
      <div className="mt-4 bg-gray-100 rounded p-3 min-h-[60px]">{output}</div>
    </div>
  );
}
EOF

cat > frontend/src/App.jsx <<'EOF'
import JarvisApp from "./JarvisApp";
export default JarvisApp;
EOF

sed -i "s/App/JarvisApp/g" frontend/src/main.jsx 2>/dev/null || true

echo "=== [JARVIS] Frontend prêt et UI corrigée ! ==="
echo "➡️  cd frontend && npm install && npm run dev"
echo "➡️  (Re)lance ./scripts/start_jarvis_stack.sh pour tout avoir !"
