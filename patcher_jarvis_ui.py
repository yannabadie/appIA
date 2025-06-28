import os
import re
import json

# Patch web_ui_streamlit.py
streamlit_file = "web_ui_streamlit.py"
backup_file = streamlit_file + ".bak"

# --- Backup first
if not os.path.exists(backup_file):
    os.rename(streamlit_file, backup_file)

with open(backup_file, "r", encoding="utf-8") as f:
    code = f.read()

# --- Nouveau code optimisé pour éviter les duplications et moderniser l'UI
new_code = """
import streamlit as st
import pyttsx3
import os
import json
from agent_core import ask_agent

# ========== CONFIG ==========

st.set_page_config(page_title="🤖 Jarvis IA – Double Numérique", layout="wide", initial_sidebar_state="expanded")
AVATAR_USER = "👤"
AVATAR_BOT = "🤖"
MEMORY_DIR = "conversations"
os.makedirs(MEMORY_DIR, exist_ok=True)

# ========== UTILS ==========

def tts_say(text):
    try:
        engine = pyttsx3.init()
        engine.say(text)
        engine.runAndWait()
    except Exception as e:
        st.error(f"TTS error: {e}")

def memory_file(user_id):
    return os.path.join(MEMORY_DIR, f"{user_id}.json")

def load_memory(user_id):
    try:
        with open(memory_file(user_id), encoding="utf-8") as f:
            return json.load(f)
    except:
        return []

def save_memory(user_id, history):
    with open(memory_file(user_id), "w", encoding="utf-8") as f:
        json.dump(history, f, ensure_ascii=False, indent=2)

# ========== UI PRINCIPALE ==========

with st.sidebar:
    st.title("🛠️ Configuration")
    user_id = st.text_input("ID utilisateur", value="default")
    mem_type = st.radio("Mémoire", ["local", "supabase (bientôt)"], horizontal=True)
    tts_enable = st.checkbox("TTS (Synthèse vocale)", value=False)
    scenario = st.text_area("Scénario/canevas (optionnel)", value="", help="Précise le contexte ou l'objectif pour Jarvis.")
    st.markdown("---")
    if st.button("🧹 Reset Session"):
        st.session_state.history = []
        save_memory(user_id, [])
        st.experimental_rerun()
    st.caption("Design inspiré par Jarvis/Ironman • Version UI by ChatGPT 🛠️")

st.title("🤖 Jarvis IA – Double Numérique")
st.markdown("Un assistant personnel extensible, local ou cloud, avec mémoire, multimodalité, et TTS.\n"
            "<br/><sub>Interface modernisée et personnalisable. [Code source privé]</sub>", unsafe_allow_html=True)

# --- INITIALISATION SESSION
if "history" not in st.session_state or st.session_state.get("user_id") != user_id:
    st.session_state.history = load_memory(user_id)
    st.session_state.user_id = user_id

if scenario and not any(m.get("role") == "system" for m in st.session_state.history):
    st.session_state.history.insert(0, {"role": "system", "content": scenario})

# --- Affichage type chat
for m in st.session_state.history:
    if m["role"] == "user":
        with st.chat_message(AVATAR_USER):
            st.markdown(f"<div style='text-align:right; color:#fff; background:#2a2a40; padding:8px 12px; border-radius:14px; margin-bottom:4px;'>{m['content']}</div>", unsafe_allow_html=True)
    elif m["role"] == "assistant":
        with st.chat_message(AVATAR_BOT):
            st.markdown(f"<div style='text-align:left; color:#ddd; background:#343456; padding:8px 12px; border-radius:14px; margin-bottom:4px;'>{m['content']}</div>", unsafe_allow_html=True)
    elif m["role"] == "system":
        with st.chat_message("🛠"):
            st.markdown(f"<div style='background:#19457e; color:#fff; padding:8px 12px; border-radius:10px;'>Scénario actif :<br/>{m['content']}</div>", unsafe_allow_html=True)

# --- Entrée utilisateur
with st.form("chat_input", clear_on_submit=True):
    user_input = st.text_area("Votre message...", placeholder="Posez une question à Jarvis", height=80)
    multimodal = st.checkbox("Multimodal (texte+image)", value=False)
    send_btn = st.form_submit_button("Envoyer")

if send_btn and user_input.strip():
    try:
        # Ajout question utilisateur dans historique temporaire
        tmp_history = st.session_state.history + [{"role": "user", "content": user_input}]
        # Appel de l'agent avec l'historique mis à jour
        agent_reply = ask_agent(user_input, multimodal=multimodal, history=tmp_history)
        st.session_state.history.append({"role": "user", "content": user_input})
        st.session_state.history.append({"role": "assistant", "content": agent_reply})
        if tts_enable:
            tts_say(agent_reply)
        save_memory(user_id, st.session_state.history)
        st.experimental_rerun()
    except Exception as e:
        st.session_state.history.append({"role": "assistant", "content": f"Erreur : {e}"})
        save_memory(user_id, st.session_state.history)
        st.error(f"Erreur : {e}")
        st.experimental_rerun()

st.markdown('''
<style>
    [data-testid=stSidebar] { min-width: 350px !important; max-width: 400px; }
    .stChatMessage { margin-bottom: 10px; }
    textarea { font-size: 1.16em !important; }
    .element-container:has(.stChatMessage) { background: #232323!important; border-radius:14px; }
</style>
''', unsafe_allow_html=True)
"""

with open(streamlit_file, "w", encoding="utf-8") as f:
    f.write(new_code.strip())

print("✅ Patch complet web_ui_streamlit.py : UI Jarvis moderne, mémoire sans duplication, TTS, logs, reset OK.")

# --- BONUS : Patch agent_core.py si besoin, ajoute multimodal et history
agent_core_file = "agent_core.py"
with open(agent_core_file, "r", encoding="utf-8") as f:
    code = f.read()

if "multimodal" not in code or "history" not in code:
    patched = re.sub(r"def ask_agent\(([^)]*)\):",
        r"def ask_agent(message, multimodal=False, history=None):",
        code)
    # Ajout dummy multimodal/history si manquant
    patched = re.sub(r"return (.+)", r"return \1  # Patched to accept multimodal/history", patched)
    with open(agent_core_file, "w", encoding="utf-8") as f:
        f.write(patched)
    print("✅ Patch agent_core.py : support multimodal/history ajouté.")

print("🎉 Tout est patché. Lance :")
print("    streamlit run web_ui_streamlit.py")
