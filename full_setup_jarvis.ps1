# --- full_setup_jarvis.ps1 ---

Write-Host "🔧 Initialisation Jarvis AI local/cloud..."
# 1. Activation ou création de l'environnement virtuel Python
if (!(Test-Path ".venv")) {
    Write-Host "Création du venv Python..."
    python -m venv .venv
}
. .\.venv\Scripts\Activate

# 2. Installation des requirements
if (Test-Path "requirements.txt") {
    Write-Host "🛠 Installation des requirements Python..."
    pip install --upgrade pip
    pip install -r requirements.txt
}

# 3. Appel du patcher Python (patch tous les scripts clefs)
Write-Host "🔩 Patch/upgrade auto du code source via patcher_jarvis.py..."
if (!(Test-Path "patcher_jarvis.py")) {
@'
import os, re, shutil

def patch_file(path, pattern, replacement):
    if not os.path.exists(path): return
    with open(path, "r", encoding="utf8") as f:
        data = f.read()
    data_new = re.sub(pattern, replacement, data, flags=re.DOTALL)
    if data != data_new:
        shutil.copy2(path, path + ".bak")
        with open(path, "w", encoding="utf8") as f:
            f.write(data_new)
        print(f"[PATCH] {path} PATCHED")
    else:
        print(f"[PATCH] {path} : already ok")

# PATCHS FONCTIONNELS
patch_file("agent_core.py", r'def ask_agent\(.*?\):[\s\S]+?return .*\n', 'def ask_agent(prompt):\n    # Patched!\n    pass\n')
patch_file("web_ui.py", r'def respond\(.*?\):[\s\S]+?return history, ""', 'def respond(message, history):\n    # Gradio expects a list of dicts\n    history = [{"role": h[0], "content": h[1]} for h in history]\n    return history, ""\n')
# Ajoute ici d'autres patchs auto si besoin (voice, brain...)

# Patch/complète le .env si besoin
if os.path.exists(".env"):
    with open(".env", "r", encoding="utf8") as f:
        env = f.read()
    changed = False
    if "LLM_ROUTING" not in env:
        with open(".env", "a", encoding="utf8") as f:
            f.write('\nLLM_ROUTING={"default":"mistral","code":"gpt-4","google":"gemini-pro","local_action":"mistral"}\n')
            f.write('LLM_FALLBACKS={"default":["openai","gemini"],"code":["gemini"],"google":["openai"]}\n')
            changed = True
    if changed: print("[PATCH] .env complété.")

print("[PATCH] Patch complet terminé.")
'@ | Set-Content -Encoding UTF8 patcher_jarvis.py
}
python patcher_jarvis.py

# 4. Vérifie et lance Ollama (si non déjà lancé)
$ollamaPath = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
if (!(Get-Process -Name "ollama" -ErrorAction SilentlyContinue)) {
    if (Test-Path $ollamaPath) {
        Write-Host "🚀 Démarrage d'Ollama en tâche de fond..."
        Start-Process -FilePath $ollamaPath -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 5
    } else {
        Write-Host "⚠️ Ollama non installé, installe-le d'abord (https://ollama.com/download)"
        exit 1
    }
}

# 5. Vérifie que le modèle Mistral existe
Write-Host "📥 Vérification/téléchargement du modèle Mistral 7B..."
$checkModel = & $ollamaPath list | Select-String "mistral"
if (-not $checkModel) {
    & $ollamaPath pull mistral
}

Write-Host "🏁 Installation complète. Tu peux lancer : python web_ui.py"
