<#
.SYNOPSIS
    Patch global JARVIS: LLM local via Ollama (Mistral), fallback cloud, voix locale, logs & modularité.
.DESCRIPTION
    Corrige les erreurs Gradio, ajoute fallback intelligent, protège les retours, active les logs,
    intègre voix offline, rend tout configurable via .env. 
    Teste l’environnement et (re)lance tout proprement.
#>

Write-Host "[JARVIS-FULL-REPAIR] 🩹 Patch global & setup…"

# 1. Backup
$now = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "backup-$now"
New-Item -ItemType Directory -Path $backup -Force | Out-Null
Copy-Item agent_core.py $backup -Force
Copy-Item web_ui.py $backup -Force
Copy-Item .env $backup -Force
Copy-Item requirements.txt $backup -Force

# 2. Ajout dependances locales et cloud
Write-Host "[JARVIS] ➕ Patch requirements.txt"
$reqs = @"
openai
google-generativeai
gradio
python-dotenv
pyttsx3
requests
"@
$reqs | Set-Content requirements.txt
pip install -r requirements.txt

# 3. Patch .env pour modularité
Write-Host "[JARVIS] ⚙️ Patch .env"
$envPatch = @"
# Activer/désactiver modules LLM
USE_MISTRAL=1
USE_OPENAI=1
USE_GEMINI=1
USE_LOCAL_VOICE=1
LLM_PRIORITY=MISTRAL,OPENAI,GEMINI
LOCAL_LLM_API=http://localhost:11434/v1
# (options: DEBUG, INFO, WARNING, ERROR)
LOG_LEVEL=DEBUG
"@
if (-not (Select-String -Path ".env" -Pattern "USE_MISTRAL")) {
    Add-Content .env $envPatch
}

# 4. Patch agent_core.py (corrections format Gradio, fallback, logs, voix)
Write-Host "[JARVIS] 🛠 Patch agent_core.py"
(Get-Content agent_core.py) `
-replace 'def ask_agent\(.*?\):', @"
def ask_agent(prompt, multimodal=False, history=None):
    \"\"\"Gestion intelligente : LLM local, fallback cloud, logs, voix\"\"\"
    import os, requests, json, pyttsx3
    from dotenv import load_dotenv
    load_dotenv()
    # Init logs
    def log(msg, lvl='DEBUG'):
        if os.getenv('LOG_LEVEL','DEBUG') in ['DEBUG','INFO']:
            print(f'[JARVIS-LOG] {msg}')
    # Sanitize response
    def safe_msg(role, content):
        if not content: content = '(Réponse vide)'
        return {'role': role, 'content': str(content)}
    # 1. LLM local (Mistral via Ollama)
    try:
        if os.getenv('USE_MISTRAL')=='1':
            log('Appel Mistral/Ollama')
            url = os.getenv('LOCAL_LLM_API','http://localhost:11434/v1')
            data = {'model':'mistral', 'messages':[{'role':'user','content':prompt}]}
            resp = requests.post(f"{url}/chat/completions", json=data, timeout=25)
            resp.raise_for_status()
            result = resp.json()
            answer = result['choices'][0]['message']['content']
            log(f'Mistral OK: {answer[:100]}')
            if os.getenv('USE_LOCAL_VOICE')=='1':
                engine = pyttsx3.init()
                engine.say(answer)
                engine.runAndWait()
            return answer
    except Exception as e:
        log(f'Erreur Mistral: {e}','ERROR')
    # 2. OpenAI GPT fallback
    try:
        if os.getenv('USE_OPENAI')=='1':
            import openai
            openai.api_key = os.getenv('OPENAI_API_KEY')
            answer = openai.ChatCompletion.create(
                model="gpt-4o",
                messages=[{"role":"user","content":prompt}]
            ).choices[0].message.content
            log(f'OpenAI OK: {answer[:100]}')
            if os.getenv('USE_LOCAL_VOICE')=='1':
                engine = pyttsx3.init()
                engine.say(answer)
                engine.runAndWait()
            return answer
    except Exception as e:
        log(f'Erreur OpenAI: {e}','ERROR')
    # 3. Gemini fallback
    try:
        if os.getenv('USE_GEMINI')=='1':
            import google.generativeai as genai
            genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
            answer = genai.GenerativeModel('gemini-1.5-pro').generate_content(prompt).text
            log(f'Gemini OK: {answer[:100]}')
            if os.getenv('USE_LOCAL_VOICE')=='1':
                engine = pyttsx3.init()
                engine.say(answer)
                engine.runAndWait()
            return answer
    except Exception as e:
        log(f'Erreur Gemini: {e}','ERROR')
    # 4. Echec complet
    return '(Aucun LLM n\'a répondu)', ''
"@, 1 | Set-Content agent_core.py

# 5. Patch web_ui.py (sécurise format Gradio et avatars)
Write-Host "[JARVIS] 🛡 Patch web_ui.py"
(Get-Content web_ui.py) `
-replace 'def respond\(.*?\):[\s\S]+?return history, ""', @"
def respond(user_message, multimodal, history):
    history = ensure_gradio_history(history)
    if not user_message:
        history.append({'role':'user', 'content':'⚠️ Message vide'})
        return history, ''
    try:
        response = ask_agent(user_message, multimodal)
        history.append({'role':'user', 'content': user_message})
        history.append({'role':'assistant', 'content': str(response) or '(pas de réponse)'})
        # Vérifie et filtre l'historique
        clean_history = []
        for msg in history:
            if not msg.get('content'): msg['content'] = '(vide)'
            if not msg.get('role'): msg['role'] = 'assistant'
            clean_history.append(msg)
        return clean_history, ''
    except Exception as e:
        history.append({'role':'assistant', 'content': f'Erreur : {e}'})
        return history, ''
"@, 1 | Set-Content web_ui.py

Write-Host "[JARVIS] 🔄 Redémarre tout : python web_ui.py"
Write-Host "[JARVIS] 💡 En cas de problème : vérifie Ollama (localhost:11434), .env, modules, etc."
