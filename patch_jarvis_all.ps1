# patch_jarvis_all.ps1
Write-Host "[PATCH] 🩹 Patch auto Jarvis IA..."

# Backup sécurisé
$target = "web_ui.py"
$backup = "$target.bak"
if (Test-Path $target) { Copy-Item $target $backup -Force; Write-Host "🔒 Backup créé : $backup" }

# Patch Python (répare indentation + historique Gradio)
$py = @'
import gradio as gr
from agent_core import ask_agent
import os

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
            # Compatibilité anciens tuples (label, msg)
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

with gr.Blocks(theme=gr.themes.Base(), css="footer {display: none;}") as demo:
    gr.Markdown("# 🤖 Jarvis IA – Double Numérique", elem_id="title")
    chatbot = gr.Chatbot(label="Chatbot", type="messages", avatar_images=["🤖","👤"])
    prompt = gr.Textbox(label="Votre message...", placeholder="Posez une question à Jarvis", autofocus=True)
    multimodal = gr.Checkbox(label="Multimodal (texte+image)", value=False)
    send = gr.Button("Envoyer")
    clear = gr.Button("🧹 Effacer l'historique")

    def respond(user_message, multimodal, history):
        history = ensure_gradio_history(history)
        if not user_message:
            return history + [{"role": "user", "content": "⚠️ Message vide"}], ""
        try:
            response = ask_agent(user_message, multimodal)
            history.append({"role": "user", "content": user_message})
            history.append({"role": "assistant", "content": response})
            return history, ""
        except Exception as e:
            history.append({"role": "assistant", "content": f"Erreur : {e}"})
            return history, ""

    send.click(
        fn=respond,
        inputs=[prompt, multimodal, chatbot],
        outputs=[chatbot, prompt],
        show_progress="full"
    )
    clear.click(lambda: ([], ""), outputs=[chatbot, prompt])

demo.launch(server_port=int(os.getenv("UI_PORT",7860)))
'@

# Applique le patch (remplace tout le web_ui.py)
Set-Content -Encoding UTF8 $target $py
Write-Host "✅ Patch appliqué !"
