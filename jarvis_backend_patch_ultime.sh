#!/bin/bash
echo "=== [JARVIS BACKEND PATCH ULTIME] ==="
echo "→ Tu dois être DANS le venv !"
echo "  source ~/my-double-numerique/jarvisenv310/bin/activate"
echo ""

# 1. Installer d'abord les packages critiques, pour court-circuiter le resolver
pip install --upgrade pip

# Install manuellement les dépendances cœur dont tu as besoin :
pip install 'openai>=1.30.0' 'httpx>=0.23.0' fastapi uvicorn python-dotenv google-generativeai supabase

# 2. Puis requirements complet avec legacy resolver (ignore les cycles non critiques)
pip install --use-deprecated=legacy-resolver -r requirements.txt || true

# 3. Vérification des imports essentiels
echo ""
echo "→ Vérification de l'import openai / httpx..."
python3 -c "import openai; import httpx; print('✅ Imports openai/httpx OK')" || echo '❌ Problème d’import openai/httpx !'

echo "→ Si erreur, relance juste : pip install openai httpx"
