#!/bin/bash
set -e

echo "=== [JARVIS PATCH] Injection UI Frontend React ==="
cd "$(dirname "$0")"

# 1. Vérifier le dossier frontend
if [ ! -d "frontend" ]; then
    echo "❌ Dossier frontend/ introuvable !"
    exit 1
fi

# 2. Nettoyage du template Vite par défaut
rm -f frontend/src/App.tsx frontend/src/App.jsx frontend/src/App.css
rm -f frontend/src/index.css
rm -rf frontend/src/assets

# 3. Télécharger ou copier le code UI Jarvis
# -- Ex: depuis un backup local ou distant, ou un repo, ou un modèle par défaut --
# Ici on copie d'un backup local, adapte ce chemin :
cp -a ./backups/jarvis_ui_default/* frontend/src/

# 4. Vérifie si le bon fichier principal existe
if [ ! -f frontend/src/JarvisApp.jsx ]; then
    echo "❌ Fichier UI principal JarvisApp.jsx manquant après copie !"
    exit 1
fi

# 5. Adapter le point d'entrée (index.jsx/tsx)
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

echo "✅ UI Jarvis React injectée !"
echo "➡️  Relance : cd frontend && npm run dev"
