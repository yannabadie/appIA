Write-Host "[JARVIS-REPAIR] 🛠 Patch global de l'environnement..."

# 1. Sauvegarde des scripts critiques
$TODAY = Get-Date -Format "yyyyMMdd-HHmmss"
$BKP = "backup-" + $TODAY
New-Item -ItemType Directory -Path $BKP -Force
Copy-Item "agent_core.py" "$BKP\agent_core.py"
Copy-Item "brain.py" "$BKP\brain.py"
Copy-Item "web_ui.py" "$BKP\web_ui.py"

# 2. Ajout du chargement .env au début des scripts critiques (si absent)
$dotenvImport = "`nfrom dotenv import load_dotenv`nload_dotenv()"
foreach ($f in @("agent_core.py", "brain.py")) {
    $c = Get-Content $f -Raw
    if ($c -notmatch "load_dotenv") {
        $c = $c -replace "(import os)", "`$1$dotenvImport"
        Set-Content $f $c
        Write-Host "[JARVIS-REPAIR] ✅ Patched load_dotenv dans $f"
    }
}

# 3. Patch ensure_gradio_history dans agent_core.py & brain.py (remplace la version par la plus moderne compatible Gradio 4)
$ensurePatch = @'
def ensure_gradio_history(history):
    """
    Corrige/convertit n'importe quel historique en format Gradio 4+.
    """
    out = []
    if not history:
        return []
    for h in history:
        if isinstance(h, dict) and "role" in h and "content" in h:
            out.append(h)
        elif isinstance(h, tuple) and len(h) == 2:
            if h[0] in ("user", "assistant", "system"):
                out.append({"role": h[0], "content": h[1]})
            else:
                out.append({"role": "user", "content": str(h[0])})
                out.append({"role": "assistant", "content": str(h[1])})
        elif isinstance(h, str):
            out.append({"role": "user", "content": h})
        else:
            out.append({"role": "assistant", "content": str(h)})
    return out
'@
foreach ($f in @("agent_core.py", "brain.py")) {
    $c = Get-Content $f -Raw
    if ($c -match "def ensure_gradio_history") {
        $c = $c -replace "def ensure_gradio_history(.|\n)*?return out", $ensurePatch
        Set-Content $f $c
        Write-Host "[JARVIS-REPAIR] ✅ Patch ensure_gradio_history dans $f"
    }
}

# 4. Ajoute un print explicite de la clé OPENAI_API_KEY au démarrage (debug)
$debugPatch = @'
if not os.getenv("OPENAI_API_KEY"):
    raise RuntimeError("[JARVIS-REPAIR] ERREUR : Clé OPENAI_API_KEY manquante dans .env ou non chargée !")
else:
    print("[JARVIS-REPAIR] OPENAI_API_KEY chargé.")
'@
foreach ($f in @("agent_core.py", "brain.py")) {
    $c = Get-Content $f -Raw
    if ($c -match "import os") {
        # Ajoute après le bloc import os et load_dotenv
        $c = $c -replace "(import os.*load_dotenv\(\))", "`$1`n$debugPatch"
        Set-Content $f $c
        Write-Host "[JARVIS-REPAIR] ✅ Check OPENAI_API_KEY ajouté à $f"
    }
}

# 5. Corrige ask_agent (format output) dans agent_core.py
$c = Get-Content "agent_core.py" -Raw
$c = $c -replace "(def ask_agent\(.*\):)(.|\n)*?return ", "def ask_agent(prompt, multimodal=False, history=None):`n    # --- LOGIQUE ROUTING/JARVIS ---`n    # [À compléter selon logique projet, retourne la réponse de brain ou autre]`n    from brain import brain`n    rep = brain(prompt, history)`n    return rep"
Set-Content "agent_core.py" $c
Write-Host "[JARVIS-REPAIR] ✅ Patch ask_agent (format et appel brain)"

# 6. Force install python-dotenv si manquant, et requirements.txt update
pip install --upgrade python-dotenv
if (-not (Get-Content "requirements.txt" | Select-String "python-dotenv")) {
    Add-Content requirements.txt "python-dotenv"
    Write-Host "[JARVIS-REPAIR] ✅ requirements.txt corrigé"
}

Write-Host "[JARVIS-REPAIR] 🏁 PATCH FINI. Teste : python web_ui.py"
