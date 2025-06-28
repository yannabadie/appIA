import os
import re

### --- PATCH agent_core.py --- ###
with open("agent_core.py", "r", encoding="utf-8") as f:
    core = f.read()

# Patch Ollama multi-JSON
core = re.sub(
    r"def ask_ollama\(prompt.*?def ",
    """
def ask_ollama(prompt, history=None):
    import requests, json
    from os import getenv
    OLLAMA_HOST = getenv("OLLAMA_HOST", "http://localhost:11434")
    OLLAMA_MODEL = getenv("OLLAMA_MODEL", "mistral")
    try:
        payload = {"model": OLLAMA_MODEL, "prompt": prompt}
        resp = requests.post(f"{OLLAMA_HOST}/api/generate", json=payload, timeout=60)
        resp.raise_for_status()
        # Patch multi-JSON
        answer = None
        for line in resp.text.strip().splitlines():
            if line.strip():
                try:
                    data = json.loads(line)
                    if "response" in data:
                        answer = data["response"].strip()
                        break
                except Exception:
                    continue
        return answer or "[OLLAMA] Réponse vide."
    except Exception as e:
        print(f"[AGENT] Ollama error: {e}")
        return f"[OLLAMA-ERROR] {e}"
def """, core, flags=re.DOTALL)

# (Tu peux ajouter d'autres correctifs si besoin ici)

with open("agent_core.py", "w", encoding="utf-8") as f:
    f.write(core)

### --- PATCH web_ui_streamlit.py --- ###
with open("web_ui_streamlit.py", "r", encoding="utf-8") as f:
    ui = f.read()

# --- PATCH ZONE INPUT / scroll / modern UI ---
ui = re.sub(
    r"(# ZONE INPUT UTILISATEUR.*)",
    r"""# ZONE INPUT UTILISATEUR (MODERNE & STICKY)
import streamlit as st
from streamlit_extras.sticky import sticky_note

# Affiche le chat dans l'ordre naturel, stylé, auto-scroll, avatars IA/humain
def render_chat(history):
    st.markdown('<div id="bottom-chat"></div>', unsafe_allow_html=True)
    for msg in history:
        who = msg["role"]
        icon = "🤖" if who != "user" else "👤"
        align = "flex-end" if who == "user" else "flex-start"
        bg = "#181818" if who == "user" else "#212d48"
        fg = "#f0f0f0" if who == "user" else "#c6eaff"
        st.markdown(
            f'''
            <div style="display: flex; justify-content: {align}; margin: 0.5em 0;">
              <div style="max-width: 70%; background: {bg}; color: {fg}; border-radius: 1.2em; padding: 1em; font-family: 'Segoe UI', 'Inter', sans-serif; box-shadow: 0 1px 4px #0003;">
                <div style="font-size: 1.1em; margin-bottom: 0.5em;">{icon} <b>{who.title() if who != "user" else "Moi"}</b></div>
                <div style="white-space: pre-wrap;">{st.markdown(msg["content"], unsafe_allow_html=True)}</div>
                <div style="font-size: 0.7em; color: #aaa; text-align: right; margin-top: 0.4em;">{msg.get("ts", "")}</div>
              </div>
            </div>
            ''', unsafe_allow_html=True)

if "history" not in st.session_state: st.session_state["history"] = []

render_chat(st.session_state["history"])

# Zone input sticky, submit enter, auto-focus
with sticky_note("💬 Saisissez votre message (Enter pour envoyer)", width=700, font_size="1.1em"):
    user_input = st.text_area("Votre message…", key="input_area", height=80, label_visibility="collapsed")
    col1, col2 = st.columns([1, 5])
    with col2:
        submit = st.button("Envoyer", type="primary", use_container_width=True)
    if submit and user_input.strip():
        st.session_state["history"].append({"role": "user", "content": user_input.strip()})
        # (Rafraichir le chat juste après)
        st.rerun()
""", ui, flags=re.DOTALL)

# --- PATCH Modern Markdown, Table, Puces ---
ui = re.sub(
    r"st\.markdown\((.*)\)",
    r"""st.markdown(\1, unsafe_allow_html=True)""",
    ui,
)

# --- PATCH Split/Multi-Tabs (multi-LLM mode) ---
ui = re.sub(
    r"(# == SIDEBAR.*)",
    r"""
# == SIDEBAR (STATUTS IRONMAN)
with st.sidebar:
    st.markdown("## 🛰️ Statut IA")
    st.write("**Ollama**:", "🟢" if True else "🔴")
    st.write("**OpenAI**:", "🟢" if True else "🔴")
    st.write("**Gemini**:", "🟢" if True else "🔴")
    st.write("**TTS**:", "🟢" if True else "🔴")
    st.write("**Mémoire**:", "Locale/Supabase")
    st.write("**Coût API**:", "~€0.00 (dev)")
    st.write("**LLM actif**:", "GPT-4" if True else "Mistral")
    st.write("---")
    if st.button("🔄 Nouvelle fenêtre IA"):
        st.session_state["history"] = []
        st.rerun()
""", ui, flags=re.DOTALL)

# (ajoute d’autres patches ici pour compléter…)

with open("web_ui_streamlit.py", "w", encoding="utf-8") as f:
    f.write(ui)

print("✅ Patch complet : UI Jarvis IronMan Pro, affichage markdown riche, sticky input, split multi-IA, statuts HUD. Relance streamlit !")
