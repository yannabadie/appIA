#!/usr/bin/env bash
set -e

echo "=== [JARVIS AI] Génération auto fullstack projet & scripts ==="

# 1. Structure
mkdir -p scripts frontend backend backup config

# 2. Backup .env si présent
[ -f .env ] && cp .env backup/.env.bak.$(date +"%Y-%m-%d_%H-%M-%S") || true

# 3. Script PulseAudio init pour WSL
cat > scripts/pulse_wsl_init.sh <<'EOF'
# Usage : source scripts/pulse_wsl_init.sh
export PULSE_SERVER="tcp:$(grep nameserver /etc/resolv.conf | awk '{print $2}')"
echo "[Jarvis] PULSE_SERVER défini à $PULSE_SERVER"
EOF

# 4. Script de démarrage de la stack
cat > scripts/start_jarvis_stack.sh <<'EOF'
#!/usr/bin/env bash
set -e
source "$(dirname $0)/pulse_wsl_init.sh"
echo "=== [JARVIS AI] Initialisation complète ==="
echo "[Jarvis] PULSE_SERVER défini à $PULSE_SERVER"
# Lancement FastAPI backend (en daemon)
nohup uvicorn backend.main:app --host 0.0.0.0 --port 8000 > backend/backend.log 2>&1 &
# Lancement React frontend (en daemon)
cd frontend && nohup npm start > ../frontend.log 2>&1 &
cd ..
echo "=== [JARVIS AI] Tout est lancé ! ==="
EOF
chmod +x scripts/start_jarvis_stack.sh

# 5. Script test audio
cat > scripts/check_audio_chain.sh <<'EOF'
#!/usr/bin/env bash
set -e
paplay /usr/share/sounds/alsa/Front_Center.wav && echo "🔊 Audio OK (WSL → Windows)" || echo "❌ Audio KO !"
EOF
chmod +x scripts/check_audio_chain.sh

# 6. Backend Python (FastAPI)
mkdir -p backend
cat > backend/main.py <<'EOF'
import os
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from agent_core import ask_agent

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/api/ask")
async def api_ask(req: Request):
    body = await req.json()
    prompt = body.get("prompt")
    history = body.get("history", [])
    agent = body.get("agent", "ollama")
    response = ask_agent(prompt, history, agent)
    return {"response": response}
EOF

cat > backend/__init__.py <<'EOF'
# (vide)
EOF

# 7. Génération frontend React (vite.js)
if [ ! -d frontend/node_modules ]; then
  npx create-vite@latest frontend --template react -- --skip-git || true
  cd frontend
  npm install axios
  cd ..
fi

# 8. UI React custom
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

# Corrige l'entrée main.jsx pour appeler JarvisApp
sed -i "s/App/JarvisApp/g" frontend/src/main.jsx 2>/dev/null || true

# 9. requirements.txt moderne
cat > config/requirements.txt <<'EOF'
fastapi
uvicorn
python-dotenv
requests
openai
google-generativeai
EOF

echo "=== [JARVIS AI] Structure complète générée ! ==="
echo "➡️  Lancement : ./scripts/start_jarvis_stack.sh"
echo "➡️  Test audio : ./scripts/check_audio_chain.sh"
echo "➡️  Front React prêt dans frontend/ !"
echo "➡️  Backend Python FastAPI : backend/main.py"
echo ""
echo "Pour finaliser :"
echo "- pip install -r config/requirements.txt"
echo "- cd frontend && npm install"
echo "- ./scripts/start_jarvis_stack.sh"
echo ""
echo "Bonne chance, Tony ! 🤖"

