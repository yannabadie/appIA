<#
    Exécute depuis la racine du projet :
        .\upgrade_ui.ps1
    Puis lance :
        python web_ui.py
#>

Write-Host "[UP-UI] 🚀 Patch interface Gradio…"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$uiPath = Join-Path $root "web_ui.py"
if (!(Test-Path $uiPath)) { Throw "[UP-UI] ❌ web_ui.py introuvable." }

# ------- 1. Backup ----------
Copy-Item $uiPath "$uiPath.bak" -Force
Write-Host "[UP-UI] 🔒 Backup web_ui.py.bak OK"

# ------- 2. Nouveau code ----
$code = @'
import os, gradio as gr
from agent_core import ask_agent

# ---------- 🎨  Mini-thème ----------
CSS = """
body {font-family: ui-sans-serif, system-ui, sans-serif;}
.gradio-container {max-width: 100% !important;}
#chatbot .message.user       {background:#2563eb;color:white}
#chatbot .message.assistant  {background:#374151;color:white}
"""

# ---------- 🔄  Logic ----------
def respond(msg, history):
    history = history or []
    history.append({"role": "user", "content": msg})
    reply = ask_agent(msg)
    history.append({"role": "assistant", "content": reply})
    return "", history

# ---------- 🖼️  Layout ----------
with gr.Blocks(title="JARVIS-AI", css=CSS) as demo:
    gr.Markdown("## 🤖 **JARVIS-AI : IA Multimodale & Multi-LLM**")
    chatbot = gr.Chatbot(
        label="Chatbot",
        elem_id="chatbot",
        type="messages",
        show_copy_button=True,
        height=500
    )
    with gr.Row():
        txt   = gr.Textbox(
            scale=6,
            placeholder="Tape ton message puis Entrée…",
            show_label=False,
            autofocus=True
        )
        send  = gr.Button("Envoyer", scale=1, variant="primary")

    txt.submit(respond,  [txt, chatbot], [txt, chatbot])
    send.click(respond, [txt, chatbot], [txt, chatbot])

demo.launch(server_port=int(os.getenv("UI_PORT", 7860)))
'@

Set-Content -Path $uiPath -Value $code -Encoding UTF8
Write-Host "[UP-UI] ✅ web_ui.py remplacé."

Write-Host "[UP-UI] 🏁 Termine !  Lance :  python web_ui.py"
