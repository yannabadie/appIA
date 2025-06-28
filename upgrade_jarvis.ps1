<#
.SYNOPSIS
    Patch ultime Jarvis : corrige tout pour le bug OpenAI “proxies”, réinstalle et relance.
#>
Write-Host "[JARVIS-UPGRADE] 🚀 Lancement du patch..."

# 1. Sauvegarde fichiers
$files = @("agent_core.py", "web_ui.py", "requirements.txt")
foreach ($f in $files) {
    if (Test-Path $f) { Copy-Item $f "$f.bak" -Force }
}

# 2. Nouveau agent_core.py (corrigé)
@'
import os
import openai
from openai import BadRequestError
import google.generativeai as genai

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
openai.api_key = OPENAI_API_KEY
genai.configure(api_key=GEMINI_API_KEY)

def cortexx_route(prompt, history=None, files=None, user_id=""):
    try:
        if files:
            model = genai.GenerativeModel("gemini-1.5-pro-latest")
            response = model.generate_content(prompt)
            return response.text
        if len(prompt) > 2000:
            model = genai.GenerativeModel("gemini-1.5-pro-latest")
            response = model.generate_content(prompt)
            return response.text
        # Utilisation directe, SANS client OpenAI !
        response = openai.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=2048,
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"[CORTEXX ROUTING ERROR] {e}"

def ask_agent(prompt, history=None, files=None, user_id=""):
    return cortexx_route(prompt, history, files, user_id)
'@ | Set-Content agent_core.py

# 3. requirements.txt à jour
@'
openai==1.25.0
google-generativeai
gradio==5.34.2
'@ | Set-Content requirements.txt

# 4. Installation/upgrade dépendances
Write-Host "[JARVIS-UPGRADE] 📦 Installation/upgrade des dépendances Python..."
pip install --upgrade pip
pip install -r requirements.txt

Write-Host "[JARVIS-UPGRADE] ✅ Patch terminé ! Lance maintenant : python web_ui.py"
Write-Host "[JARVIS-UPGRADE] ➡️  L’interface est prête sur http://localhost:7860"
