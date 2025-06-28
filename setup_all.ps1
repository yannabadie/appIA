# setup_all.ps1 — Bootstrap complet IA JARVIS-Like
$projectRoot = "my-double-numerique"

# 1. Création de l’arborescence complète
$folders = @(
    "data", "data\logs", "data\history", "data\onedrive_backups", 
    "web_interface", "web_interface\templates", "web_interface\static", 
    "wsgi", "scripts"
)
foreach ($f in $folders) { New-Item -ItemType Directory -Path "$projectRoot\$f" -Force | Out-Null }

# 2. profile.json
$profile = @"
{
  ""name"": ""Yann Abadie"",
  ""role"": ""Architecte Cloud & IA"",
  ""objectives"": [
    ""Automatiser tâches répétitives"",
    ""Gérer documents Google Drive/OneDrive"",
    ""Superviser projets IT"",
    ""Suivi forme & santé"",
    ""Générer synthèses et canevas"",
    ""Déployer et monitorer agents IA"",
    ""Assurer backup/sauvegardes"",
    ""Créer et éditer fichiers avancés""
  ]
}
"@
Set-Content "$projectRoot\data\profile.json" -Value $profile -Encoding UTF8

# 3. .env
$envContent = @"
OPENAI_API_KEY=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
GEMINI_API_KEY=AIzaSyC9OXAs_8_0Uex1rHv-vve-zB7u2QDHsoY
GOOGLE_SERVICE_ACCOUNT_JSON=data/google_creds.json
SUPABASE_URL=
SUPABASE_KEY=
"@
Set-Content "$projectRoot\.env" -Value $envContent -Encoding UTF8

# 4. requirements.txt
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
"@
Set-Content "$projectRoot\requirements.txt" -Value $requirements -Encoding UTF8

# 5. logger.ps1
$logger = @"
param([string]`$Message)
`$date = Get-Date -Format ""yyyy-MM-dd HH:mm:ss""
Add-Content -Path ""data\logs\agent.log"" -Value ""`$date `$Message""
"@
Set-Content "$projectRoot\scripts\logger.ps1" -Value $logger -Encoding UTF8

# 6. Web UI (Flask app.py)
$appPy = @"
import os
from flask import Flask, render_template, request, redirect, url_for, send_from_directory
import agent_core

app = Flask(__name__)

@app.route("/", methods=["GET", "POST"])
def home():
    user_input = ""
    response = ""
    model = request.form.get("model", "gpt-4")
    if request.method == "POST":
        user_input = request.form["user_input"]
        response = agent_core.ask_agent(user_input, model)
    return render_template("index.html", user_input=user_input, response=response)

@app.route("/static/<path:filename>")
def custom_static(filename):
    return send_from_directory(os.path.join(app.root_path, "static"), filename)

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
"@
Set-Content "$projectRoot\web_interface\app.py" -Value $appPy -Encoding UTF8

# 7. index.html
$html = @"
<!DOCTYPE html>
<html lang='fr'>
<head>
    <meta charset='UTF-8'>
    <title>Assistant IA Jarvis Yann</title>
    <style>
        body { font-family:sans-serif; margin:40px; background:#121c24; color:#eee; }
        .container { max-width:600px; margin: auto; background: #223344; padding:2em; border-radius:12px; }
        textarea,input,select { width:100%; margin:8px 0; padding:10px; border-radius:6px; border:1px solid #445; background:#1e2a34; color:#fff; }
        .btn { width:100%; padding:12px; background:#40f; color:#fff; border:none; border-radius:7px; font-weight:bold; cursor:pointer; }
        .box { margin-top:1em; padding:1em; background:#222e; border-radius:8px; }
        .model-select { margin-bottom:12px;}
        .logo { font-size:2em; margin-bottom:12px; color:#50fa7b;}
        .footer { margin-top:2em; font-size:0.9em; color:#666; text-align:center;}
    </style>
</head>
<body>
<div class='container'>
    <div class='logo'>🤖 Assistant IA — Double Numérique</div>
    <form method='post' autocomplete='off'>
        <div class='model-select'>
            <label>Modèle&nbsp;: </label>
            <select name='model'>
                <option value='gpt-4'>GPT-4</option>
                <option value='gpt-4o'>GPT-4o</option>
                <option value='gpt-3.5-turbo'>GPT-3.5</option>
                <option value='gemini-pro'>Gemini</option>
            </select>
        </div>
        <textarea name='user_input' rows='3' placeholder='Posez votre question ici...'>{{ user_input }}</textarea>
        <button class='btn' type='submit'>Envoyer</button>
    </form>
    <div class='box'>
        <strong>Réponse :</strong>
        <div>{{ response|safe }}</div>
    </div>
</div>
<div class='footer'>v1.0 — Yann Abadie — Double numérique IA autonome</div>
</body>
</html>
"@
Set-Content "$projectRoot\web_interface\templates\index.html" -Value $html -Encoding UTF8

# 8. Serveur WSGI
$wsgiServer = @"
from web_interface.app import app
from waitress import serve
if __name__ == '__main__':
    serve(app, host='0.0.0.0', port=5000)
"@
Set-Content "$projectRoot\wsgi\server.py" -Value $wsgiServer -Encoding UTF8

# 9. Script de lancement automatique PowerShell
$launch = @"
cd my-double-numerique
pip install -r requirements.txt
python -m flask run --app web_interface.app --host 0.0.0.0 --port 5000
"@
Set-Content "launch_server.ps1" -Value $launch -Encoding UTF8

Write-Host "`n✅ Setup complet JARVIS-like généré. Lance 'launch_server.ps1' ou 'python wsgi/server.py' dans le dossier my-double-numerique."
Write-Host "Ajoute tes clés Google/Microsoft dans data/google_creds.json et .env si besoin."
Write-Host "Logs : data/logs/agent.log | UI web : http://localhost:5000 | Données : data/"
Write-Host "Ajoute/complète agent_core.py pour toutes les commandes avancées IA et cloud."
