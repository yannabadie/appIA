import re
import os

PYFILE = "web_ui.py"
BACKUP = "web_ui.py.bak"

# --- Patch Rules ---
def patch_file():
    if not os.path.exists(PYFILE):
        print("❌ Fichier web_ui.py non trouvé")
        return

    with open(PYFILE, encoding="utf-8") as f:
        code = f.read()

    # Backup safety
    if not os.path.exists(BACKUP):
        with open(BACKUP, "w", encoding="utf-8") as b:
            b.write(code)

    # 1. Supprime tous les `with gr.Row():` et ce qu'ils contiennent (on va replacer à plat)
    code = re.sub(r"with gr\.Row\(\):\s*([\s\S]+?)\n\s*\n", "\n", code)

    # 2. Ajoute les widgets à plat juste après le markdown principal
    code = re.sub(
        r"(gr\.Markdown\([^\n]+?\)\n)",
        r"""\1
    # Patch : widgets mémoire/canevas/user/TTS (à plat)
    memory_mode = gr.Radio(["local", "supabase"], label="Mémoire", value="local")
    user_id = gr.Textbox(label="Utilisateur", value="default")
    canvas = gr.Textbox(label="Canevas/scénario (optionnel)")
    tts = gr.Checkbox(label="TTS (synthèse vocale)", value=False)
    """,
        code,
        count=1,
    )

    # 3. Correction de la signature Gradio : inputs et outputs (ajout des nouveaux)
    code = re.sub(
        r"send\.click\(\s*fn=respond,\s*inputs=\[(prompt),\s*(multimodal),\s*(chatbot)\],\s*outputs=\[(chatbot),\s*(prompt)\]",
        r"send.click(fn=respond, inputs=[prompt, multimodal, chatbot, memory_mode, user_id, canvas, tts], outputs=[chatbot, prompt]",
        code,
    )

    # 4. Ajoute les nouveaux arguments dans la fonction `respond`
    code = re.sub(
        r"def respond\(([^)]*)\):\s*\n\s*# Gradio expects a list of dicts\n\s*history = \[\{\"role\": h\[0\], \"content\": h\[1\]\} for h in history\]",
        (
            "def respond(message, multimodal, history, memory_mode, user_id, canvas, tts):\n"
            "    history = [{" + '"role": h[0], "content": h[1]' + "} for h in history]\n"
            "    try:\n"
            "        # Appel à ask_agent étendu\n"
            "        rep = ask_agent(\n"
            "            message, history=history, multimodal=multimodal, memory_mode=memory_mode, user_id=user_id, canvas=canvas, tts=tts\n"
            "        )\n"
            "        history.append({'role':'assistant','content': rep})\n"
            "        return history, ''\n"
            "    except Exception as e:\n"
            "        history.append({'role':'assistant','content':f'Erreur : {e}'})\n"
            "        return history, ''"
        ),
        code,
        flags=re.DOTALL,
    )

    # 5. Patch launch si tu veux binder à 0.0.0.0 pour réseau local
    code = re.sub(
        r"demo\.launch\(server_port=int\(os\.getenv\([^\)]*\)\)\)",
        r"demo.launch(server_port=int(os.getenv('UI_PORT',7860),), server_name='0.0.0.0')",
        code,
    )

    # 6. Option : désactive la barre footer par CSS si besoin (déjà fait chez toi ?)
    code = re.sub(r'css="footer \{display: none;\}"', 'css="footer {display: none;}"', code)

    with open(PYFILE, "w", encoding="utf-8") as f:
        f.write(code)

    print("✅ Patch complet web_ui.py : widgets + mémoire + TTS + canevas OK !")

if __name__ == "__main__":
    patch_file()
