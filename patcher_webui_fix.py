import re

WEBUI = "web_ui.py"
BACK = "web_ui.py.bak2"

with open(WEBUI, encoding="utf-8") as f:
    code = f.read()

# Sauvegarde de sécurité
with open(BACK, "w", encoding="utf-8") as f:
    f.write(code)

# 1. Corrige la fonction respond et son appel :
#   - Fonction prend tous les inputs (7 arguments)
#   - UI structurée et ergonomique
code = re.sub(
    r"def respond\(.*?\):[\s\S]+?return history, ''",
    """
def respond(message, multimodal, history, memory_mode, user_id, canvas, tts):
    try:
        # Compose l'appel à ask_agent
        rep = ask_agent(
            message,
            history=history,
            multimodal=multimodal,
            memory_mode=memory_mode,
            user_id=user_id,
            canvas=canvas,
            tts=tts
        )
        if isinstance(rep, str):
            history.append(('assistant', rep))
        else:
            history.append(('assistant', str(rep)))
        return history, ""
    except Exception as e:
        history.append(('assistant', f"Erreur : {e}"))
        return history, ""
""",
    code
)

# 2. Structure l'UI : champs avancés sous accordéon + champs utilisateur
code = re.sub(
    r"(with gr\.Blocks\(theme=gr\.themes\.Base\(\), css=\"footer \{display: none;\}\"\) as demo:)",
    r"""\1
    gr.Markdown("## Configuration utilisateur", elem_id="subtitle")
    with gr.Row():
        user_id = gr.Textbox(label="ID Utilisateur", value="default", scale=2)
        memory_mode = gr.Radio(["local", "supabase"], label="Mémoire", value="local", scale=1)
    with gr.Accordion("Options avancées", open=False):
        canvas = gr.Textbox(label="Canevas / scénario (optionnel)", lines=2)
        tts = gr.Checkbox(label="Synthèse vocale (TTS)", value=False)
    """,
    code
)

# 3. Aligne les inputs du bouton send.click avec la fonction respond
code = re.sub(
    r"send\.click\(fn=respond, inputs=\[prompt, multimodal, chatbot, memory_mode, user_id, canvas, tts\], outputs=\[chatbot, prompt\]",
    "send.click(fn=respond, inputs=[prompt, multimodal, chatbot, memory_mode, user_id, canvas, tts], outputs=[chatbot, prompt]",
    code
)

with open(WEBUI, "w", encoding="utf-8") as f:
    f.write(code)

print("✅ Patch UX et signature respond : prêt à relancer python web_ui.py")
