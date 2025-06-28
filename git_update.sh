#!/bin/bash
set -e

# Variables
REPO_DIR=~/my-double-numerique
BRANCH=main

cd "$REPO_DIR"

echo "===> Synchronisation avec le repo distant..."
while ! git pull --rebase origin $BRANCH; do
  echo "!!! Conflit détecté. Corrige les conflits ci-dessus puis valide avec :"
  echo "    git add <fichiers_resolus> && git rebase --continue"
  echo "Puis relance ce script."
  read -p "Appuie sur [Entrée] quand c'est résolu."
done

echo "===> Push final vers GitHub..."
if ! git push origin $BRANCH; then
  echo "!!! Push rejeté (upstream a encore bougé)."
  echo "Corrige ou refais un pull puis push, ou force avec :"
  echo "    git push --force-with-lease origin $BRANCH"
  echo "⚠️ Force push uniquement si tu es sûr (pas d’autre contrib en parallèle) !"
else
  echo "✅ Dépôt GitHub synchronisé avec succès."
fi
