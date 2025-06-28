#!/bin/bash
echo "=== Diagnostic Stack Jarvis AI ==="

echo "1. [PYTHON] Version et modules..."
python3 --version
pip freeze | grep -E 'openai|ollama|google'

echo "2. [OLLAMA] Ping serveur local (http://localhost:11434/api/tags)..."
curl --max-time 3 -s http://localhost:11434/api/tags && echo " [OK]" || echo " [KO - Ollama down !]"

echo "3. [.env] Clés API détectées :"
grep -i 'key\|token' .env 2>/dev/null || echo "   (aucune clé détectée)"

echo "4. [FRONTEND] Vérif npm/vite"
cd frontend
npm --version
npx vite --version

echo "5. [BACKEND] Présence des fichiers critiques"
cd ../backend
ls -l main.py agent_core.py 2>/dev/null || echo "   (Certains fichiers manquent !)"

echo "=== Fin diagnostic ==="
