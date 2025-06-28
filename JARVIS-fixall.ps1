# JARVIS-fixall.ps1 : Répare et optimise tout l’environnement Double Numérique
Write-Host "🛠️ [JARVIS] Audit & Correction en cours..." -ForegroundColor Cyan

# --- 1. Recherche de doublons dans le répertoire principal
$Root = Get-Location
$proj = "my-double-numerique"
$dupes = Get-ChildItem -Path $Root -Directory | Where-Object { $_.Name -match "^$proj(-copy)?$" }
if ($dupes.Count -gt 1) {
    Write-Host "⚠️ Doublons détectés dans : $($dupes | % { $_.FullName } | Out-String)"
    $main = $dupes | Where-Object { $_.Name -eq $proj } | Select-Object -First 1
    $toRemove = $dupes | Where-Object { $_.Name -ne $proj }
    foreach ($d in $toRemove) {
        $dest = Join-Path -Path $main.FullName -ChildPath $d.Name
        Move-Item -Path $d.FullName -Destination $main.FullName -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $d.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "✅ Doublons fusionnés/réparés"
}

# --- 2. Vérifie les fichiers/folders obligatoires
$mandatory = @(
    "data", "logs", "scripts", "plugins", "web_interface", "wsgi", ".env", "profile.json", "requirements.txt", "agent_core.py"
)
foreach ($item in $mandatory) {
    if (-not (Test-Path $item)) {
        if ($item -match "\.") { New-Item $item -ItemType File -Force }
        else { New-Item $item -ItemType Directory -Force }
        Write-Host "🟢 Créé : $item"
    }
}

# --- 3. Vérifie le .env, propose la saisie des clefs si manquantes
$envFile = ".env"
if (-not (Test-Path $envFile)) { New-Item $envFile -ItemType File -Force }
$envLines = Get-Content $envFile
$needed = @("OPENAI_API_KEY", "GEMINI_API_KEY", "SUPABASE_URL", "SUPABASE_KEY", "GOOGLE_SERVICE_ACCOUNT_JSON")
foreach ($var in $needed) {
    if (-not ($envLines -join "`n" -match $var)) {
        $val = Read-Host "⛔ $var manquant, entre la valeur ou laisse vide pour ignorer"
        if ($val) { Add-Content $envFile "$var=$val" }
    }
}

# --- 4. Vérifie que profile.json existe et est valide
try {
    $profile = Get-Content "data/profile.json" | ConvertFrom-Json
    if (-not $profile.name) { throw "Champ 'name' manquant." }
}
catch {
    Write-Host "⚠️ profile.json corrompu. Réinitialisation..."
    Set-Content "data/profile.json" '{ "name": "Yann", "role": "Architecte IA", "objectives": ["..."] }'
}

# --- 5. Installe toutes les dépendances Python
Write-Host "📦 Installation/MAJ des dépendances Python..."
python -m pip install --upgrade pip
pip install -r requirements.txt

# --- 6. Vérifie la connexion Google Drive
Write-Host "🗂️ Test Google Drive API..."
$drive = python scripts/test_gdrive.py
Write-Host $drive

# --- 7. Vérifie la connexion OneDrive (si script dispo)
if (Test-Path "scripts\bind_onedrive.ps1") {
    Write-Host "☁️ Test liaison OneDrive..."
    . scripts\bind_onedrive.ps1
}

# --- 8. Vérifie que l’interface web est prête
if (-not (Test-Path "web_interface\app.py")) {
    Write-Host "🛠️ (Re)création interface web Flask..."
    .\setup_web_interface.ps1
}

Write-Host "`n✅ Tout est prêt ! Lance ./launch_server.ps1 pour démarrer ton JARVIS local." -ForegroundColor Green
