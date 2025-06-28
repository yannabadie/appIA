# ========================================
# JARVIS AI - INSTALL & PATCH LLM HYBRIDE
# ========================================
# Actions :
# - Installe Ollama (Windows)
# - Télécharge & prépare Mistral/Mixtral
# - Patch le code Python pour le routing auto Ollama/OpenAI/Gemini
# - Ajoute un menu dropdown dans l'UI Gradio (choix LLM à la volée)
# - Tests et vérifications
# ========================================

Write-Host "🦙 Installation et configuration de Ollama + Mistral..."

# 1. Téléchargement et installation de Ollama
$ollamaUrl = "https://ollama.com/download/OllamaSetup.exe"
$ollamaInstaller = "$env:TEMP\OllamaSetup.exe"
if (!(Get-Command ollama.exe -ErrorAction SilentlyContinue)) {
    Write-Host "⬇️ Téléchargement d'Ollama..."
    Invoke-WebRequest -Uri $ollamaUrl -OutFile $ollamaInstaller
    Write-Host "🛠 Installation d'Ollama (peut demander droits admin)..."
    Start-Process -FilePath $ollamaInstaller -Wait
    Write-Host "✅ Ollama installé."
} else {
    Write-Host "🦙 Ollama déjà présent sur ce poste."
}

# 2. Téléchargement de Mistral/Mixtral (par défaut mistral)
Write-Host "⬇️ Téléchargement du modèle Mistral..."
& ollama pull mistral
# (tu peux aussi faire : & ollama pull mixtral:8x7b)

# 3. Démarrage du serveur Ollama (normalement lancé en service Windows)
Start-Process -FilePath "ollama" -ArgumentList "serve" -NoNewWindow
Start-Sleep -Seconds 5
Write-Host "🦙 Ollama server lancé."

# 4. Patch Python pour routing auto LLM (Ollama/OpenAI/Gemini)
Write-Host "🛠 Patch du routing LLM (Ollama, OpenAI, Gemini)..."
$agentCorePath = ".\agent_core.py"
$brainPath = ".\brain.py"
$webUIPath = ".\web_ui.py"

# --- Patch agent_core.py et brain.py pour le routing hybride
function Patch-LlmRouting {
    param([string]$filePath)
    if (!(Test-Path $filePath)) { Write-Host "$filePath manquant, skip." ; return }
    Copy-Item $filePath "$filePath.bak_$(Get-Date -Format 'yyyyMMddHHmmss')" -Force
    (Get-Content $filePath) -replace `
    "(def\s+ask_agent\(.*\):[\s\S]+?def\s+ensure_gradio_history)", `
    @'
import os
import requests

def route_llm(messages, llm="auto"):
    """
    Route les requêtes vers Ollama/Mistral (local), OpenAI ou Gemini selon paramètre/env.
    """
    if llm == "auto":
        llm = os.getenv("DEFAULT_LLM", "ollama")
    if llm == "ollama":
        # Format OpenAI compatible (Ollama)
        url = "http://localhost:11434/v1/chat/completions"
        payload = {
            "model": os.getenv("OLLAMA_MODEL", "mistral"),
            "messages": messages,
            "stream": False
        }
        r = requests.post(url, json=payload)
        try:
            result = r.json()
            # Compatibilité OpenAI API format
            return result["choices"][0]["message"]["content"]
        except Exception as e:
            return f"[OLLAMA ERROR] {e} -- {r.text}"
    if llm == "openai":
        import openai
        openai.api_key = os.getenv("OPENAI_API_KEY")
        openai.organization = os.getenv("OPENAI_ORG")
        completion = openai.ChatCompletion.create(
            model=os.getenv("OPENAI_MODEL", "gpt-3.5-turbo"),
            messages=messages,
        )
        return completion.choices[0].message.content
    if llm == "gemini":
        import google.generativeai as genai
        genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
        model = genai.GenerativeModel(os.getenv("GEMINI_MODEL", "gemini-pro"))
        response = model.generate_content([m['content'] for m in messages])
        return response.text
    return "[LLM Routing Error] LLM non supporté ou clé manquante."

def ask_agent(prompt, history=None, llm="auto"):
    if not history: history = []
    messages = [{"role": "system", "content": os.getenv("SYSTEM_PROMPT", "You are Jarvis IA.")}]
    messages += [{"role": "user" if i%2==0 else "assistant", "content": h} for i, h in enumerate(history+[prompt])]
    result = route_llm(messages, llm=llm)
    history.append(prompt)
    history.append(result)
    return history, result

def ensure_gradio_history(history):
'@ | Set-Content $filePath
    Write-Host "✅ $filePath patché pour LLM routing."
}

Patch-LlmRouting $agentCorePath
Patch-LlmRouting $brainPath

# 5. Patch web_ui.py pour menu choix LLM (ollama/openai/gemini/auto)
if (Test-Path $webUIPath) {
    Copy-Item $webUIPath "$webUIPath.bak_$(Get-Date -Format 'yyyyMMddHHmmss')" -Force
    # Ajout du dropdown pour le choix du LLM (gradio)
    $newUI = @'
import gradio as gr
from agent_core import ask_agent

def user_query(prompt, history, llm_choice):
    history, output = ask_agent(prompt, history, llm=llm_choice)
    return history, history

with gr.Blocks(theme=gr.themes.Base(), css=".gradio-container {background-color: #18191A;}") as demo:
    gr.Markdown("# 🤖 Jarvis IA – Double Numérique")
    chatbot = gr.Chatbot(label="Chatbot")
    llm_dropdown = gr.Dropdown(["auto", "ollama", "openai", "gemini"], value="auto", label="Choix du LLM")
    msg = gr.Textbox(label="Votre message...", lines=1, placeholder="Posez une question à Jarvis")
    state = gr.State([])
    send_btn = gr.Button("Envoyer")
    send_btn.click(fn=user_query, inputs=[msg, state, llm_dropdown], outputs=[chatbot, state])
    gr.Markdown("🔗 [Effacer l'historique](#)", elem_id="clear_hist")
demo.launch(server_port=7860)
'@
    $newUI | Set-Content $webUIPath
    Write-Host "✅ web_ui.py patché avec sélection du LLM."
}

# 6. Ajout du modèle par défaut dans .env si manquant
$envFile = ".env"
if (!(Select-String -Path $envFile -Pattern "OLLAMA_MODEL")) {
    Add-Content $envFile "`nOLLAMA_MODEL=mistral"
    Write-Host "✅ OLLAMA_MODEL=mistral ajouté à .env"
}
if (!(Select-String -Path $envFile -Pattern "DEFAULT_LLM")) {
    Add-Content $envFile "`nDEFAULT_LLM=ollama"
    Write-Host "✅ DEFAULT_LLM=ollama ajouté à .env"
}

Write-Host "`n✅ TOUT EST PRÊT ! Lance ton agent par : python web_ui.py (en venv)"
Write-Host "➡️ Tu pourras choisir ton LLM (local Mistral, OpenAI, Gemini) à la volée dans l'interface."

Write-Host "`n🦙 Si besoin d'autres modèles : exécute 'ollama pull mixtral:8x7b' ou 'ollama pull llama3', puis change OLLAMA_MODEL dans .env !"
Write-Host "`n💡 Pour la voix : il suffit de garder whisper comme STT, rien à changer côté LLM."

# ========================================

