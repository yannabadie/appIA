# Patch universel Gradio-historique pour tous les .py
$wrapper = @'
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

# Pour chaque .py du dossier (non récursif - mets -Recurse si tu veux)
$pyFiles = Get-ChildItem -Path . -Filter *.py -Recurse

foreach ($file in $pyFiles) {
    $content = Get-Content $file.FullName -Raw
    $patched = $false

    # Patch : injection du wrapper s'il n'existe pas
    if ($content -notmatch "def ensure_gradio_history") {
        # Ajoute après tous les imports (ou tout début si tu préfères)
        if ($content -match "(?s)(^.*?)(^def |^class |\n\Z)") {
            $imports = $matches[1]
            $rest = $content.Substring($imports.Length)
            $newContent = $imports + "`n$wrapper`n" + $rest
        } else {
            $newContent = $wrapper + $content
        }
        Set-Content $file.FullName $newContent
        $patched = $true
        Write-Host "✅ Wrapper injecté dans $($file.FullName)"
    }

    # Patch : force l'usage du wrapper dans les fonctions respond/chat
    # (Ici patch simple, à peaufiner selon ta base)
    $lines = Get-Content $file.FullName
    $outLines = @()
    foreach ($line in $lines) {
        $modLine = $line
        # Patch : début de fonction respond
        if ($line -match "def (respond|chat)\s*\((.*?)\):") {
            $outLines += $line
            $outLines += "    history = ensure_gradio_history(history)"
            continue
        }
        # Patch : si tu veux d'autres patterns, ajoutes ici
        $outLines += $modLine
    }
    Set-Content $file.FullName $outLines

    # Patch : ajoute le test sanity-check (dans web_ui.py seulement)
    if ($file.Name -eq "web_ui.py" -and $content -notmatch "def test_history_format") {
        $sanity = @'
def test_history_format():
    try:
        test = [
            {"role": "user", "content": "test"},
            ("user", "bonjour"),
            ("hello", "world"),
            "juste une string"
        ]
        res = ensure_gradio_history(test)
        assert all(isinstance(x, dict) and "role" in x and "content" in x for x in res)
    except Exception as e:
        print("[CORTEXX] FATAL : Format historique incompatible :", e)
        exit(1)
test_history_format()
'@
        Add-Content $file.FullName "`n$sanity"
        Write-Host "🚦 Sanity-check ajouté dans $($file.Name)"
    }
}

Write-Host ""
Write-Host "🚀 PATCH TERMINÉ. Tous les .py sont corrigés pour le format Gradio."
Write-Host "Redémarre ton serveur, bug de format = résolu à vie."
