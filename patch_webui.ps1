# Patch web_ui.py pour compatibilité Gradio 4+ (chatbot)
$target = "web_ui.py"
$backup = "$target.bak"

Write-Host "🩹 Patch auto de $target ..."

if (-not (Test-Path $target)) {
    Write-Host "❌ Fichier $target introuvable, patch annulé."
    exit 1
}

Copy-Item $target $backup -Force
Write-Host "🔒 Backup créé : $backup"

# Correction de la fonction respond
(Get-Content $target) -replace `
    'def respond\(user_message, multimodal, history\):[^\n]*\n((    .*\n)+?)', `
@"
def respond(user_message, multimodal, history):
    if not user_message:
        return (history or []) + [{'role': 'user', 'content': '⚠️ Message vide'}], ''
    try:
        response = ask_agent(user_message, multimodal)
        history = history or []
        history.append({'role': 'user', 'content': user_message})
        history.append({'role': 'assistant', 'content': response})
        return history, ''
    except Exception as e:
        history = history or []
        history.append({'role': 'assistant', 'content': f'Erreur : {e}'})
        return history, ''
"@ | Set-Content $target

Write-Host "✅ Patch appliqué !"
