# ==================== JARVIS ULTIMATE SETUP ====================
Write-Host "[JARVIS] 🚀 Initialisation de l'agent ultime..."

# 1. Prérequis Python & pip
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python n'est pas installé. Installe-le puis relance ce script."
    exit 1
}

# 2. Environnement virtuel (optionnel mais recommandé)
if (-not (Test-Path ".venv")) {
    python -m venv .venv
}
& .\.venv\Scripts\Activate.ps1

# 3. Install modules requis (compatibles, clean)
Write-Host "[JARVIS] 📦 Installation des modules requis..."
$reqs = @(
    "openai==1.25.0",
    "google-api-python-client",
    "google-auth",
    "google-auth-oauthlib",
    "google-auth-httplib2",
    "google-cloud-storage",
    "google-cloud-texttospeech",
    "google-cloud-vision",
    "google-cloud-language",
    "gtts",
    "pydub",
    "gradio==5.34.2",
    "supabase",
    "flask",
    "python-dotenv",
    "requests",
    "msal",
    "pandas",
    "fastapi",
    "uvicorn",
    "typer"
)
pip install --upgrade pip
foreach ($req in $reqs) { pip install $req }

# 4. Patch OpenAI API v1.x
Write-Host "[JARVIS] 🧠 Patch OpenAI API v1.x..."
# (patch automatique si nécessaire, laisse les scripts gérer la version de l'API)

# 5. Correction du .env à partir des JSON (sûr et complet)
Write-Host "[JARVIS] 🔐 Mise à jour .env à partir des credentials Google..."

$google_creds = Get-Content ".\data\google_creds.json" | ConvertFrom-Json
$google_oauth = Get-Content ".\data\google_oauth.json" | ConvertFrom-Json

# Backup
if (Test-Path ".env") { Copy-Item ".env" ".env.bak" -Force }

# Extraction et injection automatique (complète)
$env_template = @"
# ==== Microsoft / Entra ID ====
CLIENT_ID=$(Get-Content ".env.bak" | Select-String "^CLIENT_ID=" | ForEach-Object { $_.Line.Split("=")[1] })
CLIENT_SECRET=$(Get-Content ".env.bak" | Select-String "^CLIENT_SECRET=" | ForEach-Object { $_.Line.Split("=")[1] })
TENANT_ID=$(Get-Content ".env.bak" | Select-String "^TENANT_ID=" | ForEach-Object { $_.Line.Split("=")[1] })

# ==== Google Cloud / Drive / Gemini ====
GOOGLE_APPLICATION_CREDENTIALS=data\google_creds.json
GCP_PROJECT_ID=$($google_creds.project_id)
GOOGLE_CLIENT_ID=$($google_oauth.web.client_id)
GOOGLE_CLIENT_SECRET=$($google_oauth.web.client_secret)
GOOGLE_API_KEY=

# ==== Gemini / TTS ====
GEMINI_API_KEY=$(Get-Content ".env.bak" | Select-String "^GEMINI_API_KEY=" | ForEach-Object { $_.Line.Split("=")[1] })
GOOGLE_TTS_API_KEY=$($google_creds.private_key_id)

# ==== OpenAI (GPT, Whisper) ====
OPENAI_API_KEY=$(Get-Content ".env.bak" | Select-String "^OPENAI_API_KEY=" | ForEach-Object { $_.Line.Split("=")[1] })
OPENAI_ORG=$(Get-Content ".env.bak" | Select-String "^OPENAI_ORG=" | ForEach-Object { $_.Line.Split("=")[1] })

# ==== Supabase (mémoire, backup) ====
SUPABASE_URL=$(Get-Content ".env.bak" | Select-String "^SUPABASE_URL=" | ForEach-Object { $_.Line.Split("=")[1] })
SUPABASE_KEY=$(Get-Content ".env.bak" | Select-String "^SUPABASE_KEY=" | ForEach-Object { $_.Line.Split("=")[1] })
SUPABASE_BUCKET=$(Get-Content ".env.bak" | Select-String "^SUPABASE_BUCKET=" | ForEach-Object { $_.Line.Split("=")[1] })

# ==== Autres accès et chemins ====
ONEDRIVE_CLIENT_ID=$(Get-Content ".env.bak" | Select-String "^ONEDRIVE_CLIENT_ID=" | ForEach-Object { $_.Line.Split("=")[1] })
ONEDRIVE_CLIENT_SECRET=$(Get-Content ".env.bak" | Select-String "^ONEDRIVE_CLIENT_SECRET=" | ForEach-Object { $_.Line.Split("=")[1] })
ONEDRIVE_TENANT_ID=$(Get-Content ".env.bak" | Select-String "^ONEDRIVE_TENANT_ID=" | ForEach-Object { $_.Line.Split("=")[1] })

# === SSH / GitHub ===
GITHUB_SSH_KEY_PATH=$(Get-Content ".env.bak" | Select-String "^GITHUB_SSH_KEY_PATH=" | ForEach-Object { $_.Line.Split("=")[1] })

# === App config ===
LANG=fr
AGENT_NAME=JARVIS-AI
UI_PORT=7860
"@

Set-Content ".env" $env_template

# 6. Copier/corriger les fichiers JSON Google si besoin
If (!(Test-Path ".\data")) { New-Item -ItemType Directory -Path ".\data" }
Copy-Item -Path ".\data\google_creds.json" -Destination ".\data\google_creds.json" -Force
Copy-Item -Path ".\data\google_oauth.json" -Destination ".\data\google_oauth.json" -Force

# 7. Patch et fix connus (Gradio, bug avatar, etc)
Write-Host "[JARVIS] 🛠 Correction Gradio (UI, avatars, etc)..."
# Patch UI ici si besoin

# 8. FIN : Lancement du serveur
Write-Host "[JARVIS] ✅ SETUP TERMINÉ !"
Write-Host "[JARVIS] 🚀 Lance l'UI avec : python web_ui.py"
exit 0
