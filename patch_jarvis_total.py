import re
import json

# Chargement du profil utilisateur, auto-création si besoin
PROFILE_PATH = "user_profile.json"
default_profile = {
    "name": "Yann",
    "tech_skills": [
        "Microsoft Cloud (Azure, 365, Entra, Intune, Defender)",
        "GCP, OneDrive, Supabase",
        "Python, PowerShell, Terraform",
        "Automatisation, sécurité, IA"
    ],
    "goals": ["Avoir un assistant personnel type Jarvis", "Optimiser la productivité", "Sécurité et automatisation"],
    "preferences": ["Interface sobre", "Rafraîchissement immédiat", "Mémoire évolutive"],
    "personality": "Proactif, analytique, s’adapte à mon style, fait des suggestions",
    "health": {"sleep": "fragile", "sports": ["muscu", "randonnée"], "epilepsy": True}
}
try:
    with open(PROFILE_PATH, "r", encoding="utf-8") as f:
        profile = json.load(f)
except Exception:
    with open(PROFILE_PATH, "w", encoding="utf-8") as f:
        json.dump(default_profile, f, indent=2)
    profile = default_profile

# Patch UI (web_ui_streamlit.py)
with open("web_ui_streamlit.py", "r", encoding="utf-8") as f:
    code = f.read()

# Correction input (max_chars, meilleur prompt, etc.)
code = re.sub(r'max_chars\s*=\s*\d+', 'max_chars=2000', code)
code = re.sub(r'(st\.text_area\(.+?)max_chars=2000(.+?\))', r'\1max_chars=2000\2, height=96', code)

# Ajout IA dans chaque message (si pas déjà fait)
if '"agent": agent_id' not in code:
    code = code.replace(
        'st.session_state["history"].append({',
        'st.session_state["history"].append({\n        "agent": agent_id,'
    )

# Ajout meta enrichi : heure + agent + statut
code = re.sub(
    r'meta = m.get\("timestamp", ""\)',
    'meta = f"{m.get(\'timestamp\', \'\')} · {m.get(\'agent\', \'\').capitalize()}"',
    code
)

# Correction du rafraîchissement (st.rerun pour toutes versions récentes)
code = code.replace('st.experimental_rerun()', 'st.rerun()')

# Ajout section profil utilisateur (sidebar)
if "## PROFIL UTILISATEUR" not in code:
    code = (
        "## PROFIL UTILISATEUR\n"
        "import json\n"
        "try:\n"
        "    with open('user_profile.json', 'r', encoding='utf-8') as f:\n"
        "        profile = json.load(f)\n"
        "except:\n"
        "    profile = None\n"
        "if profile:\n"
        "    st.sidebar.markdown(f\"\"\"\n"
        "    <div style='background:#1a1a1a;padding:10px;border-radius:10px;margin-bottom:10px;'>\n"
        "    <b>👤 {profile['name']}</b><br/>\n"
        "    <i>Skills:</i> {', '.join(profile['tech_skills'])}<br/>\n"
        "    <i>Préférences:</i> {', '.join(profile['preferences'])}<br/>\n"
        "    <i>Objectifs:</i> {', '.join(profile['goals'])}<br/>\n"
        "    <i>Santé:</i> {json.dumps(profile['health'])}<br/>\n"
        "    </div>\n"
        "    \"\"\", unsafe_allow_html=True)\n"
        "else:\n"
        "    st.sidebar.info('Profil utilisateur non chargé.')\n"
    ) + code

with open("web_ui_streamlit.py", "w", encoding="utf-8") as f:
    f.write(code)

# Patch agent_core.py pour enrichir le contexte envoyé à chaque IA
with open("agent_core.py", "r", encoding="utf-8") as f:
    agent = f.read()

# Injection du profil utilisateur dans chaque prompt (adapter selon structure)
agent = re.sub(
    r'(def ask_agent\(.+?:\n)',
    r'\1    # Chargement du profil utilisateur\n'
    r'    try:\n'
    r'        with open("user_profile.json", "r", encoding="utf-8") as f:\n'
    r'            profile = json.load(f)\n'
    r'    except Exception:\n'
    r'        profile = None\n'
    r'    if profile:\n'
    r'        user_context = f"Voici le profil de l\'utilisateur : {json.dumps(profile, ensure_ascii=False)}"\n'
    r'    else:\n'
    r'        user_context = ""\n',
    agent
)
# Ajoute le profil dans chaque prompt
agent = re.sub(
    r'(prompt\s*=\s*.+)',
    r'\1 + "\\n\\n" + user_context',
    agent
)

with open("agent_core.py", "w", encoding="utf-8") as f:
    f.write(agent)

print("✅ Patch complet appliqué : Jarvis avec mémoire profonde, IA/UX améliorée, chat comme ChatGPT.")
