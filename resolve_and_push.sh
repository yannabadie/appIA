#!/bin/bash

echo "=== [ JARVIS - Résolution de conflit Git ] ==="
echo ""
echo "Fichiers en conflit :"
git status --short

echo ""
echo "OUVREZ chaque fichier listé ci-dessus dans nano/vim/cat pour le corriger."
echo "Par exemple : nano README.md"
echo ""
read -p "Appuyez sur [Entrée] après avoir corrigé TOUS les fichiers…"

# Ajoute tous les fichiers résolus
git add .

# Tente de poursuivre le rebase
git rebase --continue

if [ $? -ne 0 ]; then
    echo "Erreur lors du rebase. Si besoin, vous pouvez annuler avec : git rebase --abort"
    exit 1
fi

echo "Rebase terminé, push sur GitHub…"
git push origin main

echo "✅ Conflits résolus, dépôt synchronisé !"
