# JARVIS-selfcheck.ps1
# Diagnostic et réparation auto de l’IA Double Numérique

Write-Host "🔎 [JARVIS] Audit & auto-réparation de l’environnement..." -ForegroundColor Cyan

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition

# 1. Structure de dossiers
$dossiers = @(
    "data", "logs", "scripts", "web_interface", "wsgi", "plugins"
)
foreach ($d in $dossiers) {
    $path = Join-Path $root $d
    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
        Write-Host "✅ Dossier créé : $d"
    }
}

# 2. profile.json
$profilePath = Join-Path $root "data\profile.json"
$profileTemplate = @'
{
  "name": "Yann",
  "role": "Architecte Cloud & IA",
  "objectives": [
    "Automatiser les tâches répétitives",
    "Gérer les documents Drive et OneDrive",
    "Planifier des projets techniques",
    "Générer des synthèses et canevas"
  ]
}
'@
try {
    $profile = Get-Content $profilePath -Raw | ConvertFrom-Json
    Write-Host "✅ profile.json OK"
} catch {
    Set-Content $profilePath -Value $profileTemplate -Encoding UTF8
    Write-Host "⚠️ profile.json réparé"
}

# 3. .env
$envPath = Join-Path $root ".env"
if (!(Test-Path $envPath)) {
    Write-Host "⚠️ .env manquant. Création minimal."
    $envBase = @"
OPENAI_API_KEY=
GEMINI_API_KEY=
GOOGLE_SERVICE_ACCOUNT_JSON=data/google_creds.json
SUPABASE_URL=
SUPABASE_KEY=
"@
    Set-Content $envPath -Value $envBase
}
$env = Get-Content $envPath | Out-String
if ($env -notmatch "GOOGLE_SERVICE_ACCOUNT_JSON") {
    Add-Content $envPath "`nGOOGLE_SERVICE_ACCOUNT_JSON=data/google_creds.json"
    Write-Host "✅ GOOGLE_SERVICE_ACCOUNT_JSON ajouté à .env"
}

# 4. google_creds.json
$googleCredsPath = Join-Path $root "data\google_creds.json"
if (!(Test-Path $googleCredsPath)) {
    Write-Host "❌ Fichier google_creds.json absent ou mal placé : place-le dans data/."
} else {
    try {
        $null = Get-Content $googleCredsPath | ConvertFrom-Json
        Write-Host "✅ google_creds.json OK"
    } catch {
        Write-Host "❌ google_creds.json corrompu (non JSON)."
    }
}

# 5. Supabase
$supabaseUrl = ($env -split "`n" | Where-Object { $_ -match "SUPABASE_URL" }) -ne ""
$supabaseKey = ($env -split "`n" | Where-Object { $_ -match "SUPABASE_KEY" }) -ne ""
if ($supabaseUrl -and $supabaseKey) {
    Write-Host "✅ Supabase credentials trouvés dans .env"
} else {
    Write-Host "⚠️ Credentials Supabase manquants dans .env"
}

# 6. requirements.txt et dépendances Python
$reqPath = Join-Path $root "requirements.txt"
if (Test-Path $reqPath) {
    $content = Get-Content $reqPath
    if ($content -match "playsound") {
        $newContent = $content -replace "playsound", "pygame"
        Set-Content $reqPath -Value $newContent
        Write-Host "✅ Remplacement de playsound par pygame dans requirements.txt"
        Write-Host "🔄 Réinstallation des packages requis..."
        pip install -r $reqPath
    } else {
        Write-Host "✅ requirements.txt OK"
    }
} else {
    Write-Host "❌ requirements.txt absent"
}

# 7. Historique et logs
$historyPath = Join-Path $root "data\history.json"
if (!(Test-Path $historyPath)) {
    Set-Content $historyPath -Value "[]" -Encoding UTF8
    Write-Host "✅ Création de data/history.json"
}
$logDir = Join-Path $root "logs"
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$logfile = Join-Path $logDir "audit_log.txt"
Add-Content $logfile "`nAudit JARVIS du $(Get-Date): OK"

# 8. Récapitulatif
Write-Host "`n🟢 [JARVIS] Audit terminé. Consulte logs/audit_log.txt si besoin."
Write-Host "👉 Si tu vois une ❌ ci-dessus, corrige ou place les fichiers comme indiqué."
Write-Host "Lance ensuite ./launch_server.ps1 ou ./wsgi/server.py"

Exit 0
