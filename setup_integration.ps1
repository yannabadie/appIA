# ⚙️ Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
Write-Host "🚀 Initialisation du setup intelligent pour Double Numérique..." -ForegroundColor Cyan

# 1. Activer l’environnement Python (si virtualenv utilisé, à adapter)
$ErrorActionPreference = "Continue"
$requiredModules = @("google-api-python-client", "openai", "python-dotenv", "google-auth", "google-auth-oauthlib", "google-auth-httplib2", "flask", "waitress")

foreach ($module in $requiredModules) {
    Write-Host "📦 Vérification du module $module..."
    pip show $module | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "➕ Installation de $module..." -ForegroundColor Yellow
        pip install $module
    }
}

# 2. Création des dossiers critiques
$dirs = @("data", "logs", "wsgi", "web_interface")
foreach ($d in $dirs) {
    if (-not (Test-Path -Path $d)) {
        New-Item -ItemType Directory -Path $d | Out-Null
        Write-Host "📁 Dossier $d créé." -ForegroundColor Green
    }
}

# 3. Génération de fichiers essentiels s’ils n’existent pas
if (-not (Test-Path ".env")) {
    Write-Host "⚠️ .env non trouvé. Création d’un modèle..."
    @"
OPENAI_API_KEY=sk-xxxx
GEMINI_API_KEY=AIzaSyC9OXAs_8_0Uex1rHv-vve-zB7u2QDHsoY
GOOGLE_SERVICE_ACCOUNT_JSON=data/google_creds.json
"@ | Out-File ".env" -Encoding UTF8
}

# 4. Placement du modèle de credentials GCP s’il n’existe pas
if (-not (Test-Path "data/google_creds.json")) {
    Write-Host "📥 Télécharge un modèle vide google_creds.json dans data/ (à remplacer manuellement)"
    '{}' | Out-File "data/google_creds.json" -Encoding UTF8
}

# 5. Lancement de l’interface serveur en WSGI (optionnel)
$launch = Read-Host "Souhaites-tu lancer l'interface WSGI maintenant ? (o/n)"
if ($launch -eq "o") {
    python .\wsgi\server.py
}

Write-Host "`n✅ Setup terminé ! Tu peux maintenant utiliser l'interface ou passer en ligne de commande." -ForegroundColor Cyan
