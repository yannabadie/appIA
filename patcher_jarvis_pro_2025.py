import os
import re

# -- Patch agent_core.py --
with open("agent_core.py", "r", encoding="utf-8") as f:
    agent_core = f.read()

# PATCH OpenAI (migration v1+)
agent_core = re.sub(
    r"import openai\n",
    "import openai\nfrom openai import OpenAI\n",
    agent_core
)
agent_core = re.sub(
    r"openai\.ChatCompletion\.create",
    "OpenAI(api_key=os.getenv('OPENAI_API_KEY')).chat.completions.create",
    agent_core
)
agent_core = re.sub(
    r"openai\.api_key ?= ?([^\n]+)",
    "# Géré via OpenAI(api_key=...)",
    agent_core
)

# PATCH Gemini (correct model + import)
agent_core = re.sub(
    r"import google\.generativeai as genai",
    "import google.generativeai as genai\nGEMINI_MODEL = 'models/gemini-1.5-flash-latest'",
    agent_core
)
agent_core = re.sub(
    r"model\s*=\s*['\"]?gemini-pro['\"]?",
    "model=GEMINI_MODEL",
    agent_core
)

# PATCH Ollama (robust parsing)
agent_core = re.sub(
    r"response\.json\(\)",
    "response.json() if response.content.strip().startswith(b'{') else json.loads(response.content.decode().splitlines()[-1])",
    agent_core
)

with open("agent_core.py", "w", encoding="utf-8") as f:
    f.write(agent_core)

# -- Patch web_ui_streamlit.py --
with open("web_ui_streamlit.py", "r", encoding="utf-8") as f:
    ui = f.read()

# PATCH experimental_rerun -> rerun
ui = re.sub(r"st\.experimental_rerun\(\)", "st.rerun()", ui)

# PATCH design: chat at bottom, input sticky, avatars, dark theme
ui = re.sub(
    r"st\.markdown\(\"# 🤖 Jarvis IA – Double Numérique\",\s*unsafe_allow_html=True\)",
    'st.markdown("""<style>body{background:#181c23;}div[data-testid="stChatMessage"]{margin-bottom:20px;}div[data-testid="stVerticalBlock"]{display:flex;flex-direction:column-reverse;min-height:75vh;}.css-1vq4p4l{background:rgba(24,28,35,0.96);}textarea{background:#22242b;color:#eee;}</style><h1 style="color:#e6b450;font-family:monospace">🤖 Jarvis IA – Double Numérique</h1>""", unsafe_allow_html=True)',
    ui
)
ui = re.sub(
    r"st\.text_area\(",
    "st.text_area(",
    ui
)
# PATCH height for all text_areas >= 72
ui = re.sub(r"height\s*=\s*[0-9]+", "height=80", ui)

with open("web_ui_streamlit.py", "w", encoding="utf-8") as f:
    f.write(ui)

print("✅ Patch complet agent_core + UI Streamlit (OpenAI v1+, Gemini ok, Ollama JSON, UI moderne, rerun). Redémarre Streamlit !")
