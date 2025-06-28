#!/bin/bash
# audit_jarvis_stack.sh
# Script d’audit complet du projet Jarvis AI

OUTPUT="audit_jarvis.txt"
echo "=== AUDIT JARVIS AI $(date) ===" > $OUTPUT

echo -e "\n--- Environnement système ---" >> $OUTPUT
echo "Python : $(python3 --version)" >> $OUTPUT
echo "Node   : $(node -v 2>/dev/null)" >> $OUTPUT
echo "npm    : $(npm -v 2>/dev/null)" >> $OUTPUT

echo -e "\n--- Fichiers critiques ---" >> $OUTPUT
for f in .env* backend/agent_core.py backend/main.py backend/requirements.txt frontend/package.json frontend/vite.config.*; do
  if [ -f "$f" ]; then
    echo "$f : OK" >> $OUTPUT
    head -10 "$f" | sed 's/^/   /' >> $OUTPUT
  else
    echo "$f : ABSENT" >> $OUTPUT
  fi
done

echo -e "\n--- Endpoints FastAPI trouvés (backend) ---" >> $OUTPUT
grep -r --include="*.py" "@app.post" backend/ | sed 's/^/   /' >> $OUTPUT

echo -e "\n--- Appels à des APIs IA (backend) ---" >> $OUTPUT
grep -r --include="*.py" -Ei 'openai|ollama|gemini|google|anthropic|supabase' backend/ | sed 's/^/   /' >> $OUTPUT

echo -e "\n--- Configuration Frontend (React/Vite) ---" >> $OUTPUT
ls frontend/src | sed 's/^/   /' >> $OUTPUT
grep -r --include="*.js" --include="*.jsx" --include="*.tsx" "fetch" frontend/src | sed 's/^/   /' >> $OUTPUT

echo -e "\n--- Historique des patchs/scripts ---" >> $OUTPUT
ls | grep -i patch | sed 's/^/   /' >> $OUTPUT

echo -e "\n--- Liste des modules Python installés ---" >> $OUTPUT
pip freeze | sed 's/^/   /' >> $OUTPUT

echo -e "\n--- Liste des modules Node installés (frontend) ---" >> $OUTPUT
cd frontend && npm list --depth=0 2>/dev/null | sed 's/^/   /' >> ../$OUTPUT

echo -e "\n--- .env trouvé ---" >> $OUTPUT
if [ -f ".env" ]; then
    cat .env | sed 's/^/   /' >> $OUTPUT
else
    echo "   Aucun .env trouvé à la racine" >> $OUTPUT
fi

echo -e "\n=== FIN AUDIT ===" >> $OUTPUT

echo -e "\nFichier d'audit généré : $OUTPUT"
