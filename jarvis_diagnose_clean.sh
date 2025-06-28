#!/bin/bash
# jarvis_diagnose_clean.sh - Audit & clean multi-environnement Jarvis AI

set -e
PROJDIR="$PWD"
LOG="diagnostic_jarvis_$(date +%Y%m%d_%H%M%S).log"

echo "=== [JARVIS AI DIAGNOSTIC & CLEAN] ===" | tee "$LOG"
echo "Dossier analysé : $PROJDIR" | tee -a "$LOG"
echo "" | tee -a "$LOG"

# 1. Taille dossier principale
du -sh "$PROJDIR" 2>/dev/null | tee -a "$LOG"
echo "" | tee -a "$LOG"

# 2. Détection des env virtuels inutiles
echo "Recherche de dossiers venv inutiles (.venv, venv, .env)..." | tee -a "$LOG"
find "$PROJDIR" -type d \( -name ".venv" -o -name "venv" -o -name "__pycache__" \) | tee -a "$LOG"
echo "" | tee -a "$LOG"

# 3. Taille de chaque sous-dossier critique
echo "Taille des dossiers backend, frontend, models, etc. :" | tee -a "$LOG"
for d in backend frontend models notebooks logs; do
  if [ -d "$PROJDIR/$d" ]; then
    du -sh "$PROJDIR/$d" 2>/dev/null | tee -a "$LOG"
  fi
done
echo "" | tee -a "$LOG"

# 4. Fichiers de config importants
for f in requirements.txt requirements_dev.txt .env pyproject.toml package.json package-lock.json yarn.lock; do
  if [ -f "$PROJDIR/$f" ]; then
    echo "==== Contenu $f ====" | tee -a "$LOG"
    cat "$PROJDIR/$f" | tee -a "$LOG"
    echo "" | tee -a "$LOG"
  fi
done

# 5. Taille des modèles Ollama
if command -v ollama >/dev/null; then
  echo "Modèles Ollama téléchargés et leur taille :" | tee -a "$LOG"
  ollama list | tee -a "$LOG"
  ls -lh ~/.ollama/models/ 2>/dev/null | tee -a "$LOG"
else
  echo "Ollama non détecté dans le PATH." | tee -a "$LOG"
fi
echo "" | tee -a "$LOG"

# 6. Dossier node_modules
find "$PROJDIR" -type d -name "node_modules" -exec du -sh {} \; 2>/dev/null | tee -a "$LOG"

echo "" | tee -a "$LOG"
echo "------" | tee -a "$LOG"

# 7. Option de suppression interactive
read -p "Supprimer tous les dossiers .venv/venv/__pycache__ inutiles ? [y/N] " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Suppression en cours..." | tee -a "$LOG"
  find "$PROJDIR" -type d \( -name ".venv" -o -name "venv" -o -name "__pycache__" \) -exec rm -rf {} +
  echo "Suppression terminée." | tee -a "$LOG"
else
  echo "Aucun dossier supprimé. (Réexécute et répond 'y' pour nettoyer)" | tee -a "$LOG"
fi

echo "" | tee -a "$LOG"
echo "=== Fin de l’audit. Rapport dans $LOG ==="
