Write-Host "🔧 Correction du module Flask 'web_interface'..." -ForegroundColor Cyan

# Chemin absolu du dossier du script
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# 1. Ajout de __init__.py dans web_interface
$initPath = Join-Path $projectRoot "web_interface\__init__.py"
if (-not (Test-Path $initPath)) {
    New-Item -Path $initPath -ItemType File -Force | Out-Null
    Write-Host "✅ Fichier __init__.py créé dans web_interface/" -ForegroundColor Green
} else {
    Write-Host "ℹ️ Fichier __init__.py déjà présent." -ForegroundColor Yellow
}

# 2. Injection du sys.path.append dans server.py
$serverPath = Join-Path $projectRoot "wsgi\server.py"
if (Test-Path $serverPath) {
    $content = Get-Content $serverPath

    $injection = @(
        "import sys",
        "import os",
        "sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))"
    )

    if (-not ($content -join "`n" -match "sys\.path\.append")) {
        $newContent = @()
        $injected = $false
        foreach ($line in $content) {
            $newContent += $line
            if ($line -match "^import ") {
                if (-not $injected) {
                    $newContent += $injection
                    $injected = $true
                }
            }
        }
        if (-not $injected) { $newContent = $injection + $content }
        $newContent | Set-Content $serverPath -Encoding UTF8
        Write-Host "✅ Correction appliquée dans server.py (sys.path.append ajouté)" -ForegroundColor Green
    } else {
        Write-Host "ℹ️ server.py contient déjà sys.path.append" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ Fichier wsgi/server.py introuvable !" -ForegroundColor Red
}

Write-Host "`n✅ Correction terminée. Tu peux maintenant lancer ton serveur Flask avec : python ./wsgi/server.py" -ForegroundColor Cyan
