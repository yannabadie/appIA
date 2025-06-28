# Chemin du dossier de logs
$logDir = "$PSScriptRoot\..\logs"
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

# Format : logs/install_YYYYMMDD_HHMMSS.txt
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "$logDir\install_$timestamp.txt"

# Fonction de log
function Log {
    param([string]$message)
    $time = Get-Date -Format "HH:mm:ss"
    "$time - $message" | Out-File -FilePath $logFile -Append
}

# Démarrage du log
Log "🔧 Lancement du logger.ps1"
Log "📦 Vérification des composants principaux"

# Composants essentiels
$envPath = "$PSScriptRoot\..\data\.env"
$agentCore = "$PSScriptRoot\..\agent_core.py"
$webApp = "$PSScriptRoot\..\web_interface\app.py"

if (Test-Path $envPath) { Log "✅ Fichier .env trouvé" } else { Log "❌ .env manquant" }
if (Test-Path $agentCore) { Log "✅ agent_core.py OK" } else { Log "❌ agent_core.py manquant" }
if (Test-Path $webApp) { Log "✅ Interface web détectée" } else { Log "❌ Interface web absente" }

Log "🔁 Logger.ps1 terminé"
