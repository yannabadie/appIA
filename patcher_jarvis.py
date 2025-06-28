import os
import re

# 1. Patch agent_core.py : Ajout mémoire infinie (locale+cloud)
def patch_agent_core():
    fname = "agent_core.py"
    with open(fname, encoding="utf-8") as f:
        code = f.read()

    # 1a. Patch : support historique + option supabase
    if "def ask_agent(message, history=None" not in code:
        code = re.sub(
            r"def ask_agent\((.*?)\):",
            "def ask_agent(message, history=None, memory_mode='local', user_id='default', canvas=None):",
            code,
            flags=re.DOTALL
        )
        # Ajout logique de mémoire (exemple simplifié)
        if "# --- PATCH MEMOIRE ---" not in code:
            patch = """
# --- PATCH MEMOIRE ---
import json
try:
    import supabase
except ImportError:
    supabase = None

def save_history_locally(user_id, history):
    os.makedirs("conversations", exist_ok=True)
    with open(f"conversations/{user_id}.json", "w", encoding="utf-8") as f:
        json.dump(history, f, ensure_ascii=False, indent=2)

def load_history_locally(user_id):
    path = f"conversations/{user_id}.json"
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return []

def save_history_supabase(user_id, history):
    if supabase:
        # TODO : adapter à ta config supabase
        pass

def load_history_supabase(user_id):
    if supabase:
        # TODO : adapter à ta config supabase
        return []
    return []

def get_history(user_id, memory_mode):
    if memory_mode == 'supabase':
        return load_history_supabase(user_id)
    return load_history_locally(user_id)

def update_history(user_id, history, memory_mode):
    if memory_mode == 'supabase':
        save_history_supabase(user_id, history)
    else:
        save_history_locally(user_id, history)
# --- FIN PATCH MEMOIRE ---
"""
            code = patch + code

    # 1b. Appel mémoire dans ask_agent (simplifié)
    code = re.sub(
        r"def ask_agent\(message, history=None, memory_mode='local', user_id='default', canvas=None\):([\s\S]+?)# INSERT LLM CALL",
        r"""def ask_agent(message, history=None, memory_mode='local', user_id='default', canvas=None):\1
    # [PATCH] Récupération mémoire
    if history is None:
        history = get_history(user_id, memory_mode)
    # Ajoute la demande courante
    history.append({"role": "user", "content": message})
    # INSERT LLM CALL
""",
        code,
        flags=re.DOTALL,
    )
    # Ajoute un placeholder LLM
    if "# INSERT LLM CALL" in code:
        code = code.replace(
            "# INSERT LLM CALL",
            """
    # TODO: Remplacer ce bloc par un appel à Ollama/Mistral (contexte = history complet)
    answer = "Réponse simulée pour: " + message
    history.append({"role": "assistant", "content": answer})
    update_history(user_id, history, memory_mode)
    return answer
""",
        )

    # Enregistre patch
    with open(fname, "w", encoding="utf-8") as f:
        f.write(code)

# 2. Patch web_ui.py : Ajout contrôle mémoire/conversation/canevas
def patch_web_ui():
    fname = "web_ui.py"
    with open(fname, encoding="utf-8") as f:
        code = f.read()

    # Ajout des nouveaux widgets : mémoire, user, canevas
    if "mémoire" not in code:
        code = code.replace(
            "def respond(",
            """
with gr.Row():
    memory_mode = gr.Radio(["local", "supabase"], label="Mémoire", value="local")
    user_id = gr.Textbox(label="Utilisateur", value="default")
    canvas = gr.Textbox(label="Canevas/scénario (optionnel)")
def respond(
""",
        )
    # Ajout passage de paramètres à ask_agent
    code = re.sub(
        r"answer = ask_agent\(message\)",
        "answer = ask_agent(message, history, memory_mode.value, user_id.value, canvas.value)",
        code,
    )
    # Corrige TTS auto si activé
    if "pyttsx3" not in code:
        code += """
import pyttsx3
def speak(text):
    engine = pyttsx3.init()
    engine.say(text)
    engine.runAndWait()
"""

    # Option TTS
    if "TTS" not in code:
        code = code.replace(
            "clear = gr.Button",
            "tts = gr.Checkbox(label='TTS (synthèse vocale)', value=False)\n    clear = gr.Button"
        )
        code = code.replace(
            "def respond(message, multimodal, history):",
            "def respond(message, multimodal, history, memory_mode, user_id, canvas, tts):"
        )
        code = re.sub(
            r"return gradio_history, \"\"",
            "if tts: speak(answer)\n        return gradio_history, \"\"",
            code,
        )

    # Save
    with open(fname, "w", encoding="utf-8") as f:
        f.write(code)

# 3. Patch requirements.txt si besoin
def patch_requirements():
    fname = "requirements.txt"
    with open(fname, encoding="utf-8") as f:
        txt = f.read()
    add = ""
    if "pyttsx3" not in txt:
        add += "pyttsx3\n"
    if "supabase" not in txt:
        add += "supabase\n"
    if add:
        txt += "\n" + add
        with open(fname, "w", encoding="utf-8") as f:
            f.write(txt)

# PATCH ALL
patch_agent_core()
patch_web_ui()
patch_requirements()

print("✅ Patch Jarvis ALL OK. Redémarre `python web_ui.py`.")

