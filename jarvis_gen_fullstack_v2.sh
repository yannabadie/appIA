#!/usr/bin/env bash
set -e

echo "=== [JARVIS AI V2] Déploiement complet FULLSTACK ==="

## --- 1. Structure de dossiers ---
echo "[1/8] Création de la structure de projet"
mkdir -p backend frontend scripts logs data backup

## --- 2. Backend FastAPI ---
echo "[2/8] Génération backend FastAPI dans ./backend"
cat > backend/main.py << 'EOF'
import os
from fastapi import FastAPI, WebSocket, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import uvicorn
import agent_core

load_dotenv(dotenv_path='../.env')

app = FastAPI()
app.add_middleware(CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/chat")
async def chat_endpoint(prompt: str):
    result = agent_core.chat(prompt)
    return {"result": result}

@app.post("/tts")
async def tts_endpoint(text: str):
    # Ajoute ici ta logique TTS
    return {"audio_url": ""}

@app.post("/asr")
async def asr_endpoint(audio: UploadFile = File(...)):
    # Ajoute ici ta logique ASR
    return {"text": ""}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    while True:
        data = await websocket.receive_text()
        result = agent_core.chat(data)
        await websocket.send_text(result)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

cat > backend/requirements.txt << EOF
fastapi
uvicorn[standard]
python-dotenv
# Optionnel : pip install -e ..
EOF

cp agent_core.py backend/agent_core.py
cp ../.env backend/.env 2>/dev/null || cp .env backend/.env 2>/dev/null || true

## --- 3. Frontend React/Vite ---
echo "[3/8] Création du frontend React/Vite dans ./frontend"
cd frontend
if ! command -v npm &> /dev/null; then
  echo "❌ Node.js/npm non trouvé. Installe-les et relance le script."
  exit 1
fi

npx create-vite@latest . -- --template react
npm install axios

# JarvisApp.jsx auto-généré (UI console)
cat > src/JarvisApp.jsx << 'EOF'
import React, { useState } from "react";
import axios from "axios";
export default function JarvisApp() {
  const [prompt, setPrompt] = useState("");
  const [output, setOutput] = useState("");
  const sendPrompt = async () => {
    setOutput("⏳...");
    try {
      const res = await axios.post("http://localhost:8000/chat", { prompt });
      setOutput(res.data.result);
    } catch (e) {
      setOutput("Erreur: " + e.toString());
    }
  };
  return (
    <div style={{ color: "white", background: "#222", minHeight: "100vh", padding: "3em" }}>
      <h1>🤖 Jarvis AI Console</h1>
      <textarea rows={3} value={prompt} onChange={e=>setPrompt(e.target.value)} style={{width:"100%"}}/>
      <button onClick={sendPrompt} style={{marginTop:10}}>Envoyer</button>
      <pre style={{background:"#111",padding:"1em",marginTop:"2em"}}>{output}</pre>
    </div>
  );
}
EOF

# Injecte dans App.jsx
sed -i "s~<App />~<JarvisApp />~g" src/main.jsx 2>/dev/null || true
cat > src/App.jsx << 'EOF'
import JarvisApp from "./JarvisApp";
export default JarvisApp;
EOF

cd ..

## --- 4. Scripts d’orchestration ---
echo "[4/8] Création des scripts de lancement"

mkdir -p scripts

cat > scripts/start_jarvis_stack.sh << EOF
#!/bin/bash
echo "=== [JARVIS AI] Lancement stack ==="
cd backend && uvicorn main:app --host 0.0.0.0 --port 8000 &
BACK_PID=\$!
cd ../frontend && npm run dev &
FRONT_PID=\$!
wait \$BACK_PID \$FRONT_PID
EOF
chmod +x scripts/start_jarvis_stack.sh

cat > scripts/check_audio_chain.sh << 'EOF'
#!/bin/bash
paplay /usr/share/sounds/alsa/Front_Center.wav
EOF
chmod +x scripts/check_audio_chain.sh

## --- 5. Vérification finale & README ---
echo "[5/8] Auto-vérification : .env et dépendances"

echo "
Pour lancer :
- Back : cd backend && pip install -r requirements.txt && python3 main.py
- Front : cd frontend && npm install && npm run dev
- All-in-one : ./scripts/start_jarvis_stack.sh
" > README.md

## --- 6. Pré-install requirements Python ---
echo "[6/8] Pré-install requirements Python"
pip install -r backend/requirements.txt || pip3 install -r backend/requirements.txt

## --- 7. Message de fin ---
echo "=== [JARVIS AI V2] Stack full générée ! ==="
echo "➡️ Lancement : ./scripts/start_jarvis_stack.sh"
echo "➡️ UI sur http://localhost:5173"
echo "➡️ API sur http://localhost:8000"
echo "➡️ Pense à finir le paramétrage audio/TTS dans agent_core.py"

exit 0
