<# patch_jarvis.ps1 — v1.2                   #>
param(
    [string]$AgentCorePath = ".\agent_core.py",        # chemin du fichier à écraser
    [string]$UiPath        = ".\web_interface"         # racine de l’UI
)

Write-Host "[JARVIS-PATCH] 🔄 Mise à jour…" -ForegroundColor Cyan

# 1. (Re)création de l’environnement virtuel
if (-not (Test-Path ".venv")) { python -m venv .venv }
& .\.venv\Scripts\Activate.ps1

# 2. Dépendances minimales (skip si déjà ok)
pip install --upgrade pip | Out-Null
pip install openai==1.25.0 google-api-python-client google-auth `
           google-auth-oauthlib google-auth-httplib2 google-cloud-storage `
           google-cloud-texttospeech google-cloud-vision msal requests `
           python-dotenv gradio==5.34.2 supabase flask | Out-Null

# 3. Sauvegardes rapides
$ts  = Get-Date -Format "yyyyMMdd_HHmmss"
$bak = "backup_$ts"
New-Item -ItemType Directory -Force -Path $bak | Out-Null
Copy-Item $AgentCorePath "$bak\agent_core.py"
Copy-Item "$UiPath\*"    "$bak" -Recurse -ErrorAction SilentlyContinue

# 4. **Injection du nouvel Agent Core**
#    -> on suppose que tu as déjà copié son contenu dans "Agent Core" du canvas
#       ; récupère-le simplement et colle-le ici si besoin.
$canvasCode = @'
‹‹‹ COLLE ICI le contenu complet d’Agent Core (ou importe-le depuis un .py) ›››
'@
if ($canvasCode -match '\bask_agent\b') {           # simple sanity-check
    $canvasCode | Set-Content $AgentCorePath -Encoding UTF8
    Write-Host "[JARVIS-PATCH] ✅ agent_core.py mis à jour"
} else {
    Write-Warning  "[JARVIS-PATCH] !! Le bloc Agent Core semble vide – rien copié."
}

# 5. Patch UI : injection du thème + correctif -replace
$index = "$UiPath\templates\index.html"
if (Test-Path $index) {
    (Get-Content $index -Raw) `
        -replace '<!--THEME-->', '<link rel="stylesheet" href="/static/theme.css" />' `
    | Set-Content $index
    Write-Host "[JARVIS-PATCH] 🎨 UI patchée"
}

Write-Host "[JARVIS-PATCH] 🚀 Terminé ! Lance :  python web_ui.py" -ForegroundColor Green
