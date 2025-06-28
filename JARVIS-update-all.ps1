# JARVIS-setup-all-CORRIGE.ps1

param(
    [string]$BackupDir = ".\backup"
)

# 1. Lecture .env
$envFile = ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "[JARVIS] Création .env par défaut"
    @"
GOOGLE_APPLICATION_CREDENTIALS=data\google_creds.json
"@ | Out-File $envFile -Encoding utf8
}
Get-Content $envFile | ForEach-Object {
    if ($_ -match "^(.*?)=(.*)$") { [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2]) }
}

# 2. Vérif Google Service Account
$gcpCredsPath = ".\data\google_creds.json"
if (-not (Test-Path $gcpCredsPath)) {
    Copy-Item ".\google_creds.json" $gcpCredsPath
}
Write-Host "[JARVIS] Test GCP Service Account..."
try {
    python -c "from google.oauth2 import service_account; creds = service_account.Credentials.from_service_account_file('$gcpCredsPath'); print('OK')" | Out-Null
    Write-Host "[JARVIS] Google Service Account OK."
} catch { Write-Host "[JARVIS][ERREUR] Problème avec Google Service Account." }

# 3. Vérif login Azure, sinon demande
try {
    $azProfile = az account show 2>$null
    if (-not $azProfile) {
        Write-Host "[JARVIS] Connexion Azure requise, exécution de 'az login'..."
        az login
    }
    Write-Host "[JARVIS] Authentifié sur Azure."
} catch {
    Write-Host "[JARVIS][ERREUR] Impossible de se connecter à Azure. Abandon."
    exit 1
}

# 4. Création application Azure propre et gestion permissions
$azAppName = "JARVIS-AI-Agent"
$app = az ad app create --display-name $azAppName | ConvertFrom-Json
if (!$app.appId) {
    Write-Host "[JARVIS][ERREUR] Echec création app Azure."
    exit 2
}
$sp = az ad sp create --id $app.appId | ConvertFrom-Json
$secret = az ad app credential reset --id $app.appId --append --display-name 'JARVISSecret' | ConvertFrom-Json
# Permissions
az ad app permission add --id $app.appId --api 00000003-0000-0000-c000-000000000000 --api-permissions "Files.ReadWrite.All=Role Sites.FullControl.All=Role User.Read=Scope"
az ad app permission grant --id $app.appId --api 00000003-0000-0000-c000-000000000000
Add-Content $envFile "ONEDRIVE_CLIENT_ID=$($app.appId)"
Add-Content $envFile "ONEDRIVE_CLIENT_SECRET=$($secret.password)"
Add-Content $envFile "AZURE_TENANT_ID=$($sp.appOwnerOrganizationId)"

# 5. Génération clé SSH si besoin
$sshDir = "$env:USERPROFILE\.ssh"
if (-not (Test-Path "$sshDir\id_rsa")) {
    ssh-keygen -t rsa -b 4096 -N "" -f "$sshDir\id_rsa"
    Write-Host "[JARVIS] Clé SSH générée, ajoute la clé publique sur GitHub:"
    Get-Content "$sshDir\id_rsa.pub"
    pause
}

# 6. Init Git
if (-not (Test-Path ".git")) {
    git init
    git branch -M main
    git remote add origin "git@github.com:<YOUR_GITHUB>/<YOUR_REPO>.git"
    git checkout -b jarvis-backup
}

# 7. Backup sans overwrite (on exclut le backup lui-même)
if (-not (Test-Path $BackupDir)) { mkdir $BackupDir }
Get-ChildItem -Recurse -File | Where-Object { $_.FullName -notlike "*$BackupDir*" } | ForEach-Object {
    $dest = Join-Path $BackupDir $_.Name
    Copy-Item $_.FullName $dest -Force
}

# 8. Patch requirements
pip install --upgrade -r requirements.txt

# 9. Test connexions API (si agent_core.py possède la fonction)
try {
    python -c "import agent_core; print(agent_core.test_all_connections())"
} catch {}

# 10. Supervision (idem précédent)
Write-Host "[JARVIS] Démarrage supervisé de l'agent IA..."
Start-Job -ScriptBlock {
    param($BackupDir)
    while ($true) {
        try {
            python ./web_interface/app.py
        } catch {
            Write-Host "[JARVIS] Crash détecté, restauration..."
            Copy-Item "$BackupDir\*" . -Recurse -Force
            Start-Sleep -Seconds 2
        }
    }
} -ArgumentList $BackupDir

Write-Host "`n[JARVIS] 🚀 Installation complète et supervision démarrée !"
