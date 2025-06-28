#!/bin/bash
# Analyse complète des venv inutiles et dossiers obsolètes

REPORT="jarvis_env_audit_$(date +%Y%m%d_%H%M%S).log"
echo "=== [JARVIS ENV AUDIT - $(date)] ===" > "$REPORT"

echo "1. Recherche des environnements virtuels hors dossier projet..." | tee -a "$REPORT"
find / -type d \( -name "venv" -o -name ".venv" -o -name ".env" \) 2>/dev/null | grep -v "/my-double-numerique/" | tee -a "$REPORT"
echo " " >> "$REPORT"

echo "2. Recherche des environnements virtuels dans ton dossier projet..." | tee -a "$REPORT"
find ~/my-double-numerique/ -type d \( -name "venv" -o -name ".venv" -o -name ".env" \) | tee -a "$REPORT"
echo " " >> "$REPORT"

echo "3. Recherche de gros dossiers (>200Mo) dans le projet (possible reliquats)..." | tee -a "$REPORT"
du -sh ~/my-double-numerique/* | sort -hr | awk '$1 ~ /[0-9\.]+G|[2-9][0-9][0-9]M/ {print $0}' | tee -a "$REPORT"
echo " " >> "$REPORT"

echo "4. Liste des sous-dossiers suspects (test, backup, vieux plugins, etc.)..." | tee -a "$REPORT"
find ~/my-double-numerique/ -type d \( -iname "*backup*" -o -iname "*bak*" -o -iname "*test*" -o -iname "*old*" -o -iname "*plugin*" \) | tee -a "$REPORT"
echo " " >> "$REPORT"

echo "5. Recherche des projets Flask/Streamlit inactifs (web_ui*, app.py, main.py, requirements*, logs)..." | tee -a "$REPORT"
find ~/my-double-numerique/ -type f \( -iname "web_ui*" -o -iname "app.py" -o -iname "main.py" -o -iname "requirements*" -o -iname "*.log" \) | tee -a "$REPORT"
echo " " >> "$REPORT"

echo "6. Ton venv actif : ~/my-double-numerique/jarvisenv310 (à NE PAS TOUCHER)" | tee -a "$REPORT"
du -sh ~/my-double-numerique/jarvisenv310 | tee -a "$REPORT"

echo "--- FIN DE L'AUDIT ---" | tee -a "$REPORT"
echo "Résultats complets dans : $REPORT"
