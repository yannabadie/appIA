import os
import re

# Chemin cible
target = "web_ui_streamlit.py"

# Patch de l’UI Streamlit Pro
ui_patch = r'''
import streamlit as st
import os
import json
import datetime
from agent_core import ask_agent
try:
    from tts_module import tts_say
except ImportError:
    tts_say = None

st.set_page_config(
    page_title="🤖 Jarvis IA – Double Numérique",
    layout="wide",
    initial_sidebar_state="expanded",
)

# =========================
# THEMING & CSS
# =========================
st.markdown("""
<style>
body, .stApp {
    background-color: #191b23;
}
[data-testid="stSidebar"] {
    background: linear-gradient(135deg, #23263a 60%, #29334e 100%);
    color: #fff;
}
.stChatMessage {
    border-radius: 1.5rem;
    margin-bottom: 0.75rem;
}
.message-user {
    background: #2e3856;
    color: #ffd700;
    align-self: flex-end;
}
.message-ai {
    background: #1a2037;
    color: #a7cdfa;
    align-self: flex-start;
}
.st-emotion-cache-1v0mbdj, .css-1v0mbdj {
    padding: 0.4rem 1.2rem;
}
.stButton > button {
    background: linear-gradient(90deg, #5763ea, #22d3ee);
    color: white;
    font-weight: 700;
    border-radius: 8px;
}
.scrollbar-custom::-webkit-scrollbar {
    width: 10px;
    background: #2e3856;
}
.scrollbar-custom::-webkit-scrollbar-thumb {
    background: #38456d;
    border-radius: 6px;
}
</style>
""", unsafe_allow_html=True)

# =========================
# UTILITAIRES MEMOIRE/JSON
# =========================
MEMORY_DIR = "conversations"
os.makedirs(MEMORY_DIR, exist_ok=True)

def load_memory(user_id):
    path = os.path.join(MEMORY_DIR, f"{user_id}.json")
    if not os.path.isfile(path):
        return []
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return []

def save_memory(user_id, history):
    path = os.path.join(MEMORY_DIR, f"{user_id}.json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(history, f, ensure_ascii=False, indent=2)

# =========================
# SIDEBAR CONFIG
# =========================
with st.sidebar:
    st.markdown("### ⚡️ Configuration")
    user_id = st.text_input("ID utilisateur", value="default", max_chars=64)
    memtype = st.radio("Mémoire", options=["local", "supabase (bientôt)"], horizontal=True, index=0)
    tts_enable = st.checkbox("TTS (Synthèse vocale)")
    scenario = st.text_area("Scénario/canevas (optionnel)", height=50, key="scenario")
    if st.button("🔄 Reset Session", use_container_width=True):
        st.session_state["history"] = []
        save_memory(user_id, [])
        st.experimental_rerun()
    st.markdown('<span style="font-size:0.8em;color:#999;">Design inspiré par Jarvis/Ironman + Copilot<br>by ChatGPT</span>', unsafe_allow_html=True)

# =========================
# GESTION DE SESSION
# =========================
if "history" not in st.session_state:
    st.session_state["history"] = load_memory(user_id)

# =========================
# ZONE CENTRALE : TITRE & CHAT
# =========================
st.title("🦾 Jarvis IA – Double Numérique")
st.markdown(
    "<div style='margin-bottom:1rem;color:#b2c8ee;'>Un assistant personnel extensible, local ou cloud, avec mémoire, multimodalité, et TTS.<br>Posez une question pour commencer...</div>",
    unsafe_allow_html=True
)

chat_area = st.container()
with chat_area:
    for msg in st.session_state["history"]:
        align = "flex-end" if msg["role"] == "user" else "flex-start"
        bgcolor = "#2e3856" if msg["role"] == "user" else "#1a2037"
        color = "#ffd700" if msg["role"] == "user" else "#a7cdfa"
        avatar = "👤" if msg["role"] == "user" else "🤖"
        st.markdown(
            f"<div style='display:flex;flex-direction:row;align-items:center;justify-content:{align};margin-bottom:4px;'>"
            f"<span style='font-size:1.7em;margin-right:0.5em;'>{avatar}</span>"
            f"<div style='background:{bgcolor};color:{color};border-radius:1.3em;padding:0.9em 1.5em;max-width:75%;box-shadow:0 2px 12px #10101855;font-size:1.05em;'>{msg['content']}</div>"
            "</div>",
            unsafe_allow_html=True
        )

# =========================
# ZONE INPUT UTILISATEUR
# =========================
with st.form(key="chat_form", clear_on_submit=True):
    user_input = st.text_area(
        "Votre message...",
        key="input_area",
        height=60,
        max_chars=2500,
        placeholder="Posez une question à Jarvis"
    )
    multimodal = st.checkbox("Multimodal (texte+image)", value=False)
    submit = st.form_submit_button("Envoyer")
    if submit and user_input.strip():
        try:
            st.session_state["history"].append({"role": "user", "content": user_input})
            agent_reply = ask_agent(user_input, st.session_state["history"], multimodal=multimodal, scenario=scenario, tts=tts_enable)
            # Si doublon, supprime l'avant-dernier
            if len(st.session_state["history"]) > 2 and st.session_state["history"][-1] == st.session_state["history"][-3]:
                del st.session_state["history"][-3]
            st.session_state["history"].append({"role": "assistant", "content": agent_reply})
            save_memory(user_id, st.session_state["history"])
            if tts_enable and tts_say:
                tts_say(agent_reply)
            st.experimental_rerun()
        except Exception as e:
            st.session_state["history"].append({"role": "assistant", "content": f"Erreur : {e}"})
            save_memory(user_id, st.session_state["history"])
            st.error(f"Erreur : {e}")

# =========================
# ASTUCES
# =========================
st.markdown(
    """
    <hr>
    <div style='font-size:0.95em;color:#909bb2;'>💡 <b>Tips :</b> <ul>
    <li>Essayez <i>"Rends-moi la réponse vocale"</i> ou <i>"Active la mémoire sur Supabase"</i></li>
    <li>Pour l’authentification Google/Gemini : Ajoutez <b>http://localhost:8501/</b> dans vos URI OAuth.</li>
    <li>Design inspiré d’études UX AI, Jarvis/Ironman, Copilot, Perplexity AI…</li>
    </ul></div>
    """,
    unsafe_allow_html=True
)
'''

# PATCH ! (remplace tout le web_ui_streamlit.py)
with open(target, "w", encoding="utf-8") as f:
    f.write(ui_patch.strip())

print("✅ Patch complet : UI Jarvis IronMan Pro + mémoire, TTS, anti-duplication, rafraîchissement immédiat.")
print("Lance :")
print("    streamlit run web_ui_streamlit.py")
print("⚡ Enjoy !")
