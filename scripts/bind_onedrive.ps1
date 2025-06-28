# scripts/bind_onedrive.ps1

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$BackupFolder = Join-Path $ProjectRoot "..\data\onedrive_backups" | Resolve-Path -ErrorAction SilentlyContinue

if (-not $BackupFolder) {
    $BackupFolder = Join-Path $ProjectRoot "..\data\onedrive_backups"
    New-Item -ItemType Directory -Path $BackupFolder -Force | Out-Null
}

$OneDriveFolder = "$env:USERPROFILE\OneDrive\DoubleNumerique"
if (Test-Path $OneDriveFolder) {
    Remove-Item $OneDriveFolder -Recurse -Force
}
cmd /c mklink /D "$OneDriveFolder" "$BackupFolder"
if (Test-Path $OneDriveFolder) {
    Write-Host "Lien symbolique créé : $OneDriveFolder -> $BackupFolder"
} else {
    Write-Host "Erreur: lien symbolique non créé."
}
$TestFile = Join-Path $OneDriveFolder "test_sync.txt"
try {
    "Synchronisation OK" | Out-File -Encoding UTF8 $TestFile
    Write-Host "Test écriture réussi dans OneDrive."
} catch {
    Write-Host "Impossible d’écrire dans OneDrive : $_"
}
