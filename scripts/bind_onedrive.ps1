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
    Write-Host "Lien symbolique cr�� : $OneDriveFolder -> $BackupFolder"
} else {
    Write-Host "Erreur: lien symbolique non cr��."
}
$TestFile = Join-Path $OneDriveFolder "test_sync.txt"
try {
    "Synchronisation OK" | Out-File -Encoding UTF8 $TestFile
    Write-Host "Test �criture r�ussi dans OneDrive."
} catch {
    Write-Host "Impossible d��crire dans OneDrive : $_"
}
