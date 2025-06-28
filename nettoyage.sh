#!/bin/bash

echo "=== [JARVIS CLEANUP SÉCURISÉ] ==="

LOG_CLEANUP="jarvis_cleanup_$(date +%Y%m%d_%H%M%S).log"

echo "[Sauvegarde] Sauvegarde des paths supprimés dans $LOG_CLEANUP"
touch $LOG_CLEANUP

# 1. Suppression des anciens venv (sauf jarvisenv310)
echo "[VENV] Suppression des anciens environnements virtuels..."
find /root/my-double-numerique -maxdepth 2 -type d -name ".venv*" ! -path "*jarvisenv310*" -exec bash -c 'echo "[SUPPRIME] $1" >> '"$LOG_CLEANUP"' && rm -rf "$1"' _ {} \;

# 2. Suppression gros fichiers inutiles
echo "[ARCHIVES] Suppression des .zip inutiles..."
if [ -f "1.zip" ]; then
  echo "[SUPPRIME] $(pwd)/1.zip" >> $LOG_CLEANUP
  rm -f 1.zip
fi

# 3. Suppression des backups, plugins, data/onedrive_backups
for d in backup backups plugins data/onedrive_backups; do
  if [ -d "$d" ]; then
    echo "[SUPPRIME] $(pwd)/$d" >> $LOG_CLEANUP
    rm -rf "$d"
  fi
done

# 4. Suppression des requirements/logs obsolètes
for f in requirements.txt.bak requirements_tmp.txt diagnostic_jarvis_*.log jarvis_env_audit_*.log; do
  if ls $f 1> /dev/null 2>&1; then
    echo "[SUPPRIME] $(pwd)/$f" >> $LOG_CLEANUP
    rm -f $f
  fi
done

# 5. Suppression des sous-dossiers de test dans site-packages
echo "[VENV] Nettoyage des dossiers de test dans le venv (peut être long)..."
find jarvisenv310/lib/python3.10/site-packages/ -type d \( -name "tests" -o -name "testing" -o -name "_tests" -o -name "test" \) \
  -exec bash -c 'echo "[SUPPRIME] $1" >> '"$LOG_CLEANUP"' && rm -rf "$1"' _ {} \;

# 6. Suppression des tests NodeJS (node_modules)
echo "[NODE] Nettoyage des sous-dossiers de test node_modules..."
find frontend/node_modules/ -type d -name "test" -exec bash -c 'echo "[SUPPRIME] $1" >> '"$LOG_CLEANUP"' && rm -rf "$1"' _ {} \;

# 7. Suppression des vieux scripts ou UI abandonnés
for f in web_ui.py.bak web_ui_streamlit.py.bak web_ui.py web_ui_streamlit.py; do
  if [ -f "$f" ]; then
    echo "[SUPPRIME] $(pwd)/$f" >> $LOG_CLEANUP
    rm -f $f
  fi
done

echo "[FINISHED] Nettoyage terminé ! Log généré : $LOG_CLEANUP"
