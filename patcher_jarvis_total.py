import os, shutil

# Sauvegarde fichiers
for f in ["web_ui_streamlit.py", "agent_core.py"]:
    if os.path.exists(f):
        shutil.copy2(f, f+".bak")

### --- NOUVEAU agent_core.py ---
agent_core_py = r'''
import os
import json
import requests
from dotenv import load_dotenv
load_dotenv()

try:
    import pyttsx3
    def tts_say(txt): pyttsx3.init().say(txt); pyttsx3.init().runAndWait()
except ImportError:
    def tts_say(txt): pass

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

def get_history(user_id, memory_mode):
    if memory_mode.startswith("supabase"):
        return []  # Option à activer plus tard
    return load_history_locally(user_id)

def update_history(user_id, history, memory_mode):
    if memory_mode.startswith("supabase"):
        pass  # Option à activer plus tard
    else:
        save_history_locally(user_id, history)

def local_ollama_chat(prompt, model="mistral"):
    try:
        r = requests.post("http://localhost:11434/api/generate", json={"model":model, "prompt":prompt, "stream":False}, timeout=120)
        if r.ok and "response" in r.json(): return r.json()["response"]
    except Exception as e:
        print("[OLLAMA-ERROR]", e)
    return None

def openai_chat(prompt, api_key=None):
    try:
        import openai
        api_key = api_key or os.getenv("OPENAI_API_KEY")
        if not api_key: print("[OPENAI-ERROR] clé absente !"); return None
        openai.api_key = api_key
        res = openai.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": prompt}]
        )
        return res.choices[0].message.content
    except Exception as e:
        print("[OPENAI-ERROR]", e)
    return None

def gemini_chat(prompt, api_key=None):
    try:
        import google.generativeai as genai
        api_key = api_key or os.getenv("GEMINI_API_KEY")
        if not api_key: print("[GEMINI-ERROR] clé absente !"); return None
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-1.5-flash')
        r = model.generate_content(prompt)
        return r.text
    except Exception as e:
        print("[GEMINI-ERROR]", e)
    return None

def ask_agent(
    message,
    history=None,
    memory_mode='local',
    user_id='default',
    canvas=None,
    llm_priority=None,
    tts=False,
    **kwargs
):
    # Gestion mémoire
    if history is None or not isinstance(history, list):
        history = get_history(user_id, memory_mode)
    # Scénario/canevas système
    if canvas and not any(m.get("role")=="system" for m in history):
        history.insert(0, {"role":"system","content":canvas})
    # Ajout message utilisateur sans doublon
    if not history or history[-1].get("content") != message or history[-1].get("role") != "user":
        history.append({"role": "user", "content": message})
    # Choix du LLM
    reply = None
    LLM_CHAIN = llm_priority or ["ollama", "openai", "gemini"]
    prompt = message
    for llm in LLM_CHAIN:
        if llm == "ollama":
            r = local_ollama_chat(prompt)
            if r: reply = r; break
        if llm == "openai":
            r = openai_chat(prompt)
            if r: reply = r; break
        if llm == "gemini":
            r = gemini_chat(prompt)
            if r: reply = r; break
    if not reply:
        reply = "Erreur: Aucun LLM n'a répondu !"
    if not history or history[-1].get("content") != reply or history[-1].get("role") != "assistant":
        history.append({"role": "assistant", "content": reply})
    update_history(user_id, history, memory_mode)
    if tts:
        try: tts_say(reply)
        except: pass
    return reply
'''

### --- NOUVEAU web_ui_streamlit.py ---
web_ui_streamlit_py = r'''
import os
from dotenv import load_dotenv
load_dotenv()
import streamlit as st
from agent_core import ask_agent, get_history, update_history

st.set_page_config(
    page_title="🤖 Jarvis IA – Double Numérique",
    layout="wide",
    page_icon="🤖"
)

# Style IronMan/MGXdev
st.markdown("""
    <style>
    body, .main, .stApp, .block-container {background-color: #181b24 !important;}
    .css-18ni7ap, .css-1d391kg, .stChatMessage {background: #222831;}
    .stTextInput>div>div>input, .stTextArea>div>textarea, .stButton>button, .stForm {background: #282c37; color: #FFD369;}
    .stButton>button {border-radius: 12px; border: 1px solid #FFD369; color: #FFD369; font-weight: bold;}
    .st-bb, .st-cq {background: #222831;}
    .css-1qg05tj {color:#FFD369;}
    </style>
""", unsafe_allow_html=True)

st.title("🤖 Jarvis IA – Double Numérique")

# Sidebar configuration
with st.sidebar:
    st.header("⚡ Configuration")
    user_id = st.text_input("ID utilisateur", value="default", max_chars=64)
    memory_mode = st.radio("Mémoire", options=["local", "supabase (bientôt)"], horizontal=False)
    tts_enable = st.checkbox("TTS (Synthèse vocale)")
    canvas = st.text_area("Scénario/canevas (optionnel)", height=72, key="scenario")
    if st.button("🔄 Reset Session", use_container_width=True):
        st.session_state["history"] = []
        update_history(user_id, [], memory_mode)

# Initialisation historique
if "history" not in st.session_state:
    st.session_state["history"] = get_history(user_id, memory_mode)

# Formulaire utilisateur (anti-bug Streamlit)
with st.form(key="chat_form", clear_on_submit=True):
    user_input = st.text_area("Votre message...", key="input_area", height=72)
    multimodal = st.checkbox("Multimodal (texte+image)", key="multimodal")
    submit = st.form_submit_button("Envoyer")

if submit and user_input.strip():
    try:
        reply = ask_agent(
            user_input,
            history=st.session_state["history"],
            memory_mode=memory_mode,
            user_id=user_id,
            canvas=canvas,
            tts=tts_enable
        )
        st.session_state["history"] = get_history(user_id, memory_mode)
    except Exception as e:
        st.session_state["history"].append({"role": "assistant", "content": f"Erreur : {e}"})
        update_history(user_id, st.session_state["history"], memory_mode)
        st.error(f"Erreur : {e}")

# Affichage historique type chat moderne
for msg in st.session_state["history"]:
    if msg["role"] == "user":
        st.markdown(f"<div style='background:#FFD36922;border-radius:10px;padding:8px;margin:3px 0 6px 35vw;color:#fff;text-align:right;font-size:16px'><b>👤</b> {msg['content']}</div>", unsafe_allow_html=True)
    elif msg["role"] == "assistant":
        st.markdown(f"<div style='background:#393E46;border-radius:10px;padding:8px;margin:3px 35vw 6px 0;color:#FFD369;text-align:left;font-size:16px'><b>🤖</b> {msg['content']}</div>", unsafe_allow_html=True)
    elif msg["role"] == "system":
        st.markdown(f"<div style='background:#222831;border-radius:6px;padding:5px 12px;margin:5px 0;color:#00FFD0;font-size:13px'><i>{msg['content']}</i></div>", unsafe_allow_html=True)
'''

# Ecriture fichiers
with open("agent_core.py", "w", encoding="utf-8") as f:
    f.write(agent_core_py.strip() + "\n")

with open("web_ui_streamlit.py", "w", encoding="utf-8") as f:
    f.write(web_ui_streamlit_py.strip() + "\n")

print("✅ Patch TOTAL appliqué. Relance :")
print("    streamlit run web_ui_streamlit.py")
print("Enjoy l'expérience Jarvis IronMan pro 🎉")
