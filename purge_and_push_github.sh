#!/bin/bash
set -e

# --- CONFIG ---
REMOTE_URL="https://github.com/yannabadie/appIA.git"
GIT_BRANCH="main"
MAX_SIZE_MB=50

echo "===[ Purge auto GROS FICHIERS + Clean & Push GitHub ]==="
echo "Repo: $REMOTE_URL | Branche: $GIT_BRANCH"
echo "Attention: l'historique git va être réécrit !"

# 1. Liste les fichiers > 50Mo et les ajoute au .gitignore
echo "📦 Recherche de fichiers > ${MAX_SIZE_MB}Mo..."
find . -type f -size +${MAX_SIZE_MB}M > .purge_large_files.txt
cat .purge_large_files.txt

if [ ! -s .purge_large_files.txt ]; then
  echo "✅ Aucun gros fichier à purger."
else
  echo "📝 Ajout au .gitignore..."
  while read -r FILE; do
    # Ajoute chaque fichier/extension au .gitignore si absent
    FILE_EXT=$(echo "$FILE" | grep -o '\.[^.]*$')
    if ! grep -q "$FILE_EXT" .gitignore 2>/dev/null; then
      echo "*$FILE_EXT" >> .gitignore
    fi
  done < .purge_large_files.txt

  echo "==> .gitignore mis à jour:"
  tail .gitignore
fi

# 2. Commit du .gitignore
git add .gitignore
git commit -m "chore: ajout des extensions lourdes au .gitignore (purge auto)"

# 3. Installe BFG si pas présent
if ! [ -f ./bfg.jar ]; then
  echo "⬇️  Téléchargement de BFG Repo-Cleaner..."
  wget -q https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar -O bfg.jar
fi

# 4. Clone le repo en mode miroir (obligatoire pour BFG)
cd ..
MIRROR_NAME="repo_mirror_purge"
rm -rf $MIRROR_NAME
git clone --mirror "$REMOTE_URL" $MIRROR_NAME
cd $MIRROR_NAME

echo "🧹 Purge des gros fichiers de l'historique avec BFG..."
java -jar ../my-double-numerique/bfg.jar --delete-files '*.[zZ][iI][pP]' --delete-files '*.[bB][iI][nN]' --delete-files '*.[pP][tT]' --delete-files '*.[wW][aA][vV]' --delete-files '*.[mM][pP]4' --delete-files '*.ckpt' --delete-files '*.tar' --delete-files '*.pkl' --delete-folders data --no-blob-protection

echo "🧽 Garbage collection git..."
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo "🚀 Force push du repo propre..."
git push --force --all
git push --force --tags

echo "===[ Purge et push terminés ]==="
echo "✅ Ton repo est clean, prêt pour Codex, Copilot, etc."

# 5. Log des fichiers supprimés
echo "===[ LOG: fichiers purgés ]==="
cat ../my-double-numerique/.purge_large_files.txt

echo "===[ FIN ]==="
