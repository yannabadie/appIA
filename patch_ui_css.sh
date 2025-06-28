#!/bin/bash
cd "$(dirname "$0")/frontend/src"

# Supprime tout import de ./index.css dans main.* (tsx/jsx)
for file in main.tsx main.jsx; do
    [ -f "$file" ] && sed -i '/import ".\/index\.css";/d' "$file"
done

# Vérifie le bon composant React
for file in main.tsx main.jsx; do
    if [ -f "$file" ]; then
        sed -i 's/import App from ".\/App.*";/import JarvisApp from ".\/JarvisApp.jsx";/' "$file"
        sed -i 's/<App \/>/<JarvisApp \/>/' "$file"
        sed -i 's/<App\/>/<JarvisApp\/>/' "$file"
        sed -i 's/App/JarvisApp/g' "$file"
    fi
done

echo "✅ Patch CSS et point d'entrée appliqué !"
