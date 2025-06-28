#!/bin/bash

# =============== [JARVIS AUDIT & CLEANUP PROFOND] ===============
# A exécuter depuis le dossier racine du projet sous WSL

LOG="audit_jarvis_deepclean_$(date +%Y%m%d_%H%M%S).log"
EXCLUDE_VENV="jarvisenv310"
EXCLUDE_NODE="frontend/node_modules"

echo "[AUDIT] Lancement audit approfondi" | tee $LOG

# 1. Liste tous les venv hors jarvisenv310
echo -e "\n[ENV PYTHON INUTILES]" | tee -a $LOG
find ~ -type d -name ".venv*" ! -path "*$EXCLUDE_VENV*" 2>/dev/null | tee -a $LOG
find ~ -type d -name "env*" ! -path "*$EXCLUDE_VENV*" 2>/dev/null | tee -a $LOG

# 2. Recherche caches Python & Node
echo -e "\n[CACHES PYTHON/JS]" | tee -a $LOG
find ~/my-double-numerique -type d -name "__pycache__" | tee -a $LOG
find ~/my-double-numerique -type d -name ".pytest_cache" | tee -a $LOG
find ~/my-double-numerique -type d -name ".mypy_cache" | tee -a $LOG
find ~/my-double-numerique -type d -name "dist" | tee -a $LOG
find ~/my-double-numerique -type d -name "build" | tee -a $LOG
find ~/my-double-numerique -type d -name "*.egg-info" | tee -a $LOG
find ~/my-double-numerique -type d -name ".ipynb_checkpoints" | tee -a $LOG
find ~/my-double-numerique -type d -name ".cache" | tee -a $LOG

# 3. Grosse volumétrie hors dossiers à conserver
echo -e "\n[GROS FICHIERS/HORS VENV/NODE]" | tee -a $LOG
find ~/my-double-numerique -type f -size +100M ! -path "*/$EXCLUDE_VENV/*" ! -path "*/$EXCLUDE_NODE/*" | tee -a $LOG

# 4. Liste fichiers & dossiers potentiellement obsolètes (.sqlite, .db, .bak)
echo -e "\n[FICHIERS POTENTIELS OBSOLETES]" | tee -a $LOG
find ~/my-double-numerique -type f \( -name "*.bak" -o -name "*.db" -o -name "*.sqlite" \) | tee -a $LOG

echo -e "\n[FIN AUDIT] Rapport généré: $LOG"
echo -e "⚠️  Aucune suppression automatique dans ce mode. Vérifie le log avant toute action destructive."
