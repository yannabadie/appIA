#!/usr/bin/env bash
set -e

echo -e "\033[1;36m=== [JARVIS AI] Génération fullstack FastAPI + Next.js ===\033[0m"

# 1. Création des dossiers de base
mkdir -p scripts logs config frontend app

# 2. Génération du backend FastAPI
cat > app/main.py <<'EOF'
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os

app = FastAPI(title="Jarvis AI", description="API Backend Jarvis", version="1.0")

# Autoriser l’accès à l’API depuis le front local (port 3000 par défaut Next.js)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # À restreindre en prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health():
    return {"status": "ok", "detail": "Jarvis backend ready"}

@app.post("/api/voice")
async def process_voice(req: Request):
    data = await req.json()
    # Placeholder: on retourne le texte reçu
    return {"received_text": data.get("text", ""), "response": "Hello from Jarvis backend!"}

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
EOF

cat > scripts/start_jarvis_stack.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
source ./scripts/pulse_wsl_init.sh || true
mkdir -p logs
echo "=== [JARVIS AI] Lancement backend FastAPI ==="
(python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 > logs/backend.log 2>&1 &) || echo "Erreur FastAPI"
echo "=== [JARVIS AI] Backend lancé sur :8000 ==="
EOF
chmod +x scripts/start_jarvis_stack.sh

# 3. Génération de scripts utilitaires
cat > scripts/check_audio_chain.sh <<'EOF'
#!/usr/bin/env bash
set -e
echo "[Test Audio] - lecture Front_Center"
paplay /usr/share/sounds/alsa/Front_Center.wav || echo "Erreur PulseAudio/Alsa"
EOF
chmod +x scripts/check_audio_chain.sh

cat > scripts/pulse_wsl_init.sh <<'EOF'
export PULSE_SERVER="tcp:$(grep nameserver /etc/resolv.conf | awk '{print $2}')"
echo "[Jarvis] PULSE_SERVER défini à \$PULSE_SERVER"
EOF
chmod +x scripts/pulse_wsl_init.sh

# 4. .env modèle
cat > .env <<'EOF'
API_KEY=change-me
EOF

# 5. requirements.txt adapté FastAPI
cat > config/requirements.txt <<'EOF'
fastapi
uvicorn[standard]
python-dotenv
sounddevice
TTS
EOF

# 6. Installation des requirements (avec test auto)
echo -e "\n\033[1;34m[Setup] Vérification des modules Python…\033[0m"
pip install -r config/requirements.txt || {
    echo -e "\033[1;31m❌ Problème installation requirements.txt, vérifie ta version Python ou pip.\033[0m"
}

# 7. Génération frontend Next.js/React minimal
cd frontend
npx create-next-app@latest . --use-npm --ts --no-tailwindcss --eslint --src-dir --app --no-git <<EOF



EOF

cat > src/pages/index.tsx <<'EOF'
import { useEffect, useState } from "react";
export default function Home() {
  const [ping, setPing] = useState("…");
  useEffect(() => {
    fetch("http://localhost:8000/health").then(r => r.json()).then(d => setPing(d.detail));
  }, []);
  return (
    <main style={{padding:32,fontFamily:"sans-serif"}}>
      <h1>🤖 Jarvis UI (Next.js/React)</h1>
      <p>Status backend: <b>{ping}</b></p>
    </main>
  );
}
EOF
cd ..

# 8. README synthétique
cat > README.md <<'EOF'
# JARVIS AI - Fullstack Généré

## Lancer backend FastAPI
  ./scripts/start_jarvis_stack.sh

## Tester audio (WSL)
  ./scripts/check_audio_chain.sh

## Setup Frontend (Next.js)
  cd frontend
  npm run dev

## À intégrer dans ~/.bashrc pour PulseAudio WSL :
  source $PWD/scripts/pulse_wsl_init.sh

## Backend API docs (Swagger)
  http://localhost:8000/docs
EOF

echo -e "\033[1;36m=== [JARVIS AI] Stack FastAPI+Next.js prêt !\033[0m"
echo -e "➡️  Lancer backend : ./scripts/start_jarvis_stack.sh"
echo -e "➡️  Lancer front   : cd frontend && npm run dev"
echo -e "➡️  Tester audio   : ./scripts/check_audio_chain.sh"
echo -e "➡️  API Docs       : http://localhost:8000/docs"
