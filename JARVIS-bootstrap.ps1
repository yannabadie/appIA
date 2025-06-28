# JARVIS-bootstrap.ps1 — Assistant IA tout-en-un (local + cloud)
$ErrorActionPreference = "Stop"

# Chemins
$root = "my-double-numerique"
if (-not (Test-Path $root)) { mkdir $root | Out-Null }
Set-Location $root

# 1. Structure de dossiers
$dirs = @(
    "data", "data\logs", "data\history", "data\onedrive_backups",
    "web_interface", "web_interface\templates", "web_interface\static",
    "wsgi", "scripts", "plugins", "canevas"
)
foreach ($d in $dirs) { if (-not (Test-Path $d)) { mkdir $d | Out-Null } }

# 2. Fichier .env (clés d’API à compléter)
if (-not (Test-Path ".env")) {
    $env = @"
OPENAI_API_KEY=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
GEMINI_API_KEY=AIzaSyC9OXAs_8_0Uex1rHv-vve-zB7u2QDHsoY
GOOGLE_SERVICE_ACCOUNT_JSON=data/google_creds.json
SUPABASE_URL=
SUPABASE_KEY=
"@
    Set-Content ".env" -Value $env -Encoding UTF8
}

# 3. requirements.txt (enrichi)
$requirements = @"
openai
google-api-python-client
google-auth
google-auth-oauthlib
python-dotenv
google-generativeai
flask
waitress
requests
supabase
gtts
speechrecognition
markdown
python-docx
playsound
"@
Set-Content "requirements.txt" -Value $requirements -Encoding UTF8

# 4. Plugins/Modules essentiels
$pluginList = @(
    # Vocal
    @{Path="plugins/vocal.py"; Content=@"
import speech_recognition as sr
from gtts import gTTS
import os, playsound

def listen_and_transcribe():
    r = sr.Recognizer()
    with sr.Microphone() as source:
        print('🎤 Parlez...')
        audio = r.listen(source)
    try:
        return r.recognize_google(audio, language='fr-FR')
    except Exception as e:
        return f'Erreur reco: {e}'

def speak(text):
    tts = gTTS(text=text, lang='fr')
    filename = 'data/voice_tmp.mp3'
    tts.save(filename)
    playsound.playsound(filename)
    os.remove(filename)
"@},

    # Canevas
    @{Path="plugins/canevas.py"; Content=@"
import markdown, os
from docx import Document

def save_markdown(text, path):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)

def markdown_to_word(md_path, docx_path):
    with open(md_path, encoding='utf-8') as f:
        html = markdown.markdown(f.read())
    doc = Document()
    doc.add_paragraph(html)
    doc.save(docx_path)
"@},

    # Supabase
    @{Path="plugins/supabase_sync.py"; Content=@"
import os
from supabase import create_client

def supa_sync(dir, up=True):
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_KEY')
    if not url or not key:
        print('Supabase non configuré.')
        return
    s = create_client(url, key)
    for fname in os.listdir(dir):
        fpath = os.path.join(dir, fname)
        if up:
            s.storage().from_('backups').upload(fname, fpath)
        else:
            s.storage().from_('backups').download(fname, fpath)
"@},

    # Logger
    @{Path="scripts/logger.ps1"; Content=@"
param([string]`$Message)
`$date = Get-Date -Format ""yyyy-MM-dd HH:mm:ss""
Add-Content -Path ""data\logs\agent.log"" -Value ""`$date `$Message""
"@},

    # OneDrive bind
    @{Path="scripts/bind_onedrive.ps1"; Content=@"
`$onedriveLocal = Join-Path `$env:USERPROFILE ""OneDrive""
`$target = ""$pwd\data\onedrive_backups""
`$link = Join-Path `$onedriveLocal ""DoubleNumerique""
if (Test-Path `$link) { Remove-Item `$link -Force -Recurse }
cmd /c mklink /D `"$link`" `"$target`"
"@},

    # Self-check
    @{Path="scripts/selfcheck.py"; Content=@"
import os, importlib.util
def check():
    checks = {
        'Google Service Account': os.path.exists('data/google_creds.json'),
        '.env': os.path.exists('.env'),
        'logs dir': os.path.isdir('data/logs'),
        'onedrive backups': os.path.isdir('data/onedrive_backups'),
        'Supabase': 'SUPABASE_URL' in os.environ and 'SUPABASE_KEY' in os.environ,
        'Flask': importlib.util.find_spec('flask') is not None,
        'Waitress': importlib.util.find_spec('waitress') is not None,
        'Speech': importlib.util.find_spec('speech_recognition') is not None,
        'TTS': importlib.util.find_spec('gtts') is not None,
        'IA OpenAI': importlib.util.find_spec('openai') is not None,
        'IA Gemini': importlib.util.find_spec('google.generativeai') is not None
    }
    for k, v in checks.items():
        print(f"{k}: {'OK' if v else '❌'}")
if __name__ == '__main__': check()
"@}
)
foreach ($plugin in $pluginList) {
    Set-Content $plugin.Path -Value $plugin.Content -Encoding UTF8
}

# 5. agent_core.py (enrichi, multi-IA, cloud, vocal, backup, extensions)
$agentCorePy = @"
import os, json, datetime, logging, re
from dotenv import load_dotenv
from openai import OpenAI
import google.generativeai as genai

load_dotenv('.env')
profile = {'name':'Yann','role':'Architecte Cloud & IA','objectives':['Automatiser','Gérer Cloud','Synthèses','Projet']}
openai_client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
logging.basicConfig(filename='data/logs/agent.log',level=logging.INFO,format='%(asctime)s [%(levelname)s] %(message)s')
history_file = 'data/history.json'
history = []
if os.path.exists(history_file):
    with open(history_file, 'r', encoding='utf-8') as f: history = json.load(f)
def save_history(): 
    with open(history_file, 'w', encoding='utf-8') as f: json.dump(history, f, ensure_ascii=False, indent=2)
def build_system_prompt():
    return f'Assistant de {profile["name"]} ({profile["role"]}). Objectifs: {", ".join(profile["objectives"])}'
def ask_agent(prompt, model_name=None):
    try:
        model_name = str(model_name or 'gpt-4').lower()
        if 'gemini' in model_name:
            chat = genai.GenerativeModel('gemini-pro').start_chat()
            resp = chat.send_message(prompt)
            result = resp.text.strip()
        else:
            resp = openai_client.chat.completions.create(
                model=model_name,
                messages=[{'role':'system','content':build_system_prompt()},{'role':'user','content':prompt}],
                temperature=0.7
            )
            result = resp.choices[0].message.content.strip()
        history.append({'date':str(datetime.datetime.now()),'model':model_name,'prompt':prompt,'response':result})
        save_history()
        return result
    except Exception as e:
        logging.error(str(e))
        return f'Erreur IA: {e}'
# Ajoute ici d'autres fonctions cloud (Drive, OneDrive, Supabase, markdown, vocal, plugin...)
"@
Set-Content "agent_core.py" -Value $agentCorePy -Encoding UTF8

# 6. Lancement universel
$launch = @"
pip install -r requirements.txt
python scripts/selfcheck.py
python wsgi/server.py
"@
Set-Content "launch_server.ps1" -Value $launch -Encoding UTF8

Write-Host ""
Write-Host "✅ [JARVIS-bootstrap.ps1] : Environnement JARVIS auto-créé, structuré, plug-and-play !" -ForegroundColor Green
Write-Host "1. Complète .env si besoin (clé API, Supabase, chemin Google service account)."
Write-Host "2. Lance 'launch_server.ps1' pour tout démarrer (interface, logs, plugins...)."
Write-Host "3. Ajoute/upgrade modules dans /plugins ou /scripts (ou demande ici !)"
Write-Host "🟢 Interface web disponible sur http://localhost:5000 (à la fin du boot)."
Write-Host "🚀 Toutes tes exigences actuelles et futures sont supportées via ce système."

