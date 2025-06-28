#!/usr/bin/env bash
set -e

echo "=== [JARVIS] Reset complet de l'environnement Node.js + Frontend ==="

cd ~/my-double-numerique

# 1. Nettoyage éventuel des anciens Node/npm
echo "⏳ Suppression d'éventuelles anciennes versions de nodejs/npm (apt)..."
sudo apt purge -y nodejs npm || true
sudo apt autoremove -y

# 2. Installation NodeSource dernière version
echo "⏳ Installation Node.js LTS (22.x) depuis NodeSource..."
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs

echo "🆗 Node.js version : $(node -v)"
echo "🆗 npm version    : $(npm -v)"

# 3. Vérification npm, upgrade si besoin
if ! command -v npm >/dev/null; then
  echo "❌ npm n'est pas trouvé ! Installation..."
  sudo apt install -y npm
fi

# 4. Installation des packages frontend
cd frontend

echo "⏳ Suppression du node_modules + package-lock.json éventuels..."
rm -rf node_modules package-lock.json

echo "⏳ Installation des dépendances du frontend..."
npm install

echo "⏳ Installation globale de vite..."
sudo npm install -g vite

echo "=== [JARVIS] Lancement du frontend (npm run dev) ==="
npm run dev
