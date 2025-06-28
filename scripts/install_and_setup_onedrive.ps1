# install_and_setup_onedrive.ps1
Write-Host "🟦 Initialisation de l'installation OneDrive..." -ForegroundColor Cyan

# Détection de l'architecture
$arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

# URL officielles
$urls = @{
    "x64" = "https://go.microsoft.com/fwlink/?LinkId=248256"
    "x86" = "https://go.microsoft.com/fwlink/?LinkId=248254"
}

# Dossier temporaire
$temp = "$env:TEMP\OneDriveSetup.exe"

# Suppression ancienne version si présente
if (Test-Path $temp) { Remove-Item $temp -Force }

Write-Host "🔽 Téléchargement de OneDrive ($arch) depuis Microsoft..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $urls[$arch] -OutFile $temp -ErrorAction Stop

if (!(Test-Path $temp)) {
    Write-Host "❌ Le fichier n'a pas été téléchargé." -ForegroundColor Red
    exit 1
}

Write-Host "⚙️ Installation de OneDrive..." -ForegroundColor Yellow

# Lancement en mode silencieux avec log
Start-Process -FilePath $temp -ArgumentList "/silent", "/install" -Wait -PassThru | Out-Null

# Vérification de l'installation
Start-Sleep -Seconds 5
$onedrivePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"

if (Test-Path $onedrivePath) {
    Write-Host "✅ OneDrive installé avec succès." -ForegroundColor Green
    Start-Sleep -Seconds 3
    .\setup_onedrive.ps1
} else {
    Write-Host "❌ Échec de l'installation de OneDrive." -ForegroundColor Red
}
