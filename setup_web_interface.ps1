# setup_web_interface.ps1 — Crée l'interface web Flask automatiquement

Write-Host "🔧 Création de l'interface web Flask pour l'agent IA..." -ForegroundColor Cyan

# Création des dossiers requis
$webDir = "web_interface"
$templatesDir = Join-Path $webDir "templates"

New-Item -ItemType Directory -Force -Path $webDir | Out-Null
New-Item -ItemType Directory -Force -Path $templatesDir | Out-Null

# Création du fichier app.py
$appCode = @'
from flask import Flask, render_template, request, jsonify
from agent_core import ask_agent

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/ask", methods=["POST"])
def ask():
    prompt = request.json.get("prompt", "")
    if not prompt:
        return jsonify({"response": "⛔ Prompt vide."})
    response = ask_agent(prompt)
    return jsonify({"response": response})

if __name__ == "__main__":
    app.run(debug=True)
'@
$appPath = Join-Path $webDir "app.py"
Set-Content -Path $appPath -Value $appCode -Encoding UTF8

# Création du fichier index.html
$htmlCode = @'
<!DOCTYPE html>
<html>
<head><title>Double Numérique</title></head>
<body>
  <h1>Agent IA personnel</h1>
  <form id="chat-form">
    <input type="text" id="prompt" placeholder="Pose ta question..." />
    <button type="submit">Envoyer</button>
  </form>
  <pre id="response"></pre>
  <script>
    document.getElementById('chat-form').onsubmit = async (e) => {
      e.preventDefault();
      const prompt = document.getElementById('prompt').value;
      const res = await fetch('/ask', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ prompt })
      });
      const data = await res.json();
      document.getElementById('response').innerText = data.response;
    };
  </script>
</body>
</html>
'@
$htmlPath = Join-Path $templatesDir "index.html"
Set-Content -Path $htmlPath -Value $htmlCode -Encoding UTF8

Write-Host "✅ Interface web Flask créée avec succès dans le dossier 'web_interface'" -ForegroundColor Green
