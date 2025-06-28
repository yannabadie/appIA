#!/bin/bash
# Nettoyage avancé du projet JARVIS (exécute-le depuis ta racine projet !)

set -e

echo "=== [Backup optionnelle des fichiers obsolètes] ==="
mkdir -p ~/archive_jarvis
find ~/my-double-numerique -type f \( -name "*.bak" -o -name "*.db" \) -exec cp --parents {} ~/archive_jarvis/ \;

echo "=== [Suppression des environnements virtuels inutiles] ==="
find /root/ -type d \( -name ".venv" -o -name "venv" -o -name "jarvisenv*" \) ! -name "jarvisenv310" -prune -exec rm -rf {} +

echo "=== [Suppression des node_modules] ==="
rm -rf ~/my-double-numerique/frontend/node_modules

echo "=== [Suppression des fichiers .bak et .db inutiles] ==="
find ~/my-double-numerique -type f \( -name "*.bak" -o -name "*.db" \) -exec rm -f {} +

echo "=== [Nettoyage des caches Python/JS] ==="
rm -rf ~/my-double-numerique/jarvisenv310/lib/python3.10/site-packages/pip/_internal/operations/build

echo "Nettoyage terminé !"
echo "Vérifie que tout fonctionne bien, relance ton venv et réinstalle les node_modules si besoin."
