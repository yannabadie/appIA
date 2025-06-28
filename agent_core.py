import os, json
from dotenv import load_dotenv
import requests

load_dotenv()

# --- Définition des IA disponibles (icônes, id, display name) ---
AGENT_LIST = [
    {"id": "ollama", "name": "Mistral (Ollama)", "icon": "🦙"},
    {"id": "openai", "name": "GPT-4 (OpenAI)", "icon": "🤖"},
    {"id": "gemini", "name": "Gemini (Google)", "icon": "🔷"},
]
AGENT_STATUS = {"ollama": "idle", "openai": "idle", "gemini": "idle"}

def check_status():
    # Test connexion Ollama
    try:
        r = requests.post(os.getenv("OLLAMA_HOST", "http://localhost:11434") + "/api/generate",
                          json={"model": os.getenv("OLLAMA_MODEL", "mistral"), "prompt": "ping", "stream": False}, timeout=7)
        AGENT_STATUS["ollama"] = "ok" if r.status_code == 200 else "error"
    except Exception:
        AGENT_STATUS["ollama"] = "error"
    # Test connexion OpenAI
    try:
        from openai import OpenAI
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        client.chat.completions.create(
            model="gpt-4", messages=[{"role": "user", "content": "ping"}], max_tokens=3)
        AGENT_STATUS["openai"] = "ok"
    except Exception:
        AGENT_STATUS["openai"] = "error"
    # Test connexion Gemini
    try:
        import google.generativeai as genai
        genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
        model = genai.GenerativeModel("gemini-pro")
        _ = model.generate_content("ping")
        AGENT_STATUS["gemini"] = "ok"
    except Exception:
        AGENT_STATUS["gemini"] = "error"
check_status()

def ask_agent(prompt, history, agent="ollama"):
    # Chargement du profil utilisateur
    try:
        with open("user_profile.json", "r", encoding="utf-8") as f:
            profile = json.load(f)
    except Exception:
        profile = None
    if profile:
        user_context = f"Voici le profil de l\'utilisateur : {json.dumps(profile, ensure_ascii=False)}"
    else:
        user_context = ""
    # --- Historique : user/assistant seulement (pas de role/function)
    chat_history = [{"role": h["role"], "content": h["content"]} for h in history if h["role"] in ["user", "assistant"]]
    # --- ROUTAGE ---
    if agent == "ollama":
        url = os.getenv("OLLAMA_HOST", "http://localhost:11434") + "/api/chat"
        payload = {
            "model": os.getenv("OLLAMA_MODEL", "mistral"),
            "messages": chat_history + [{"role": "user", "content": prompt}],
            "stream": False
        }
        r = requests.post(url, json=payload, timeout=120)
        # Certains Ollama répondent avec deux JSON concaténés: "Extra data" -> on ne garde que le 1er
        try:
            lines = r.text.strip().split("\n")
            data = json.loads(lines[0])
            return data.get("message", {}).get("content", "[Ollama: aucune réponse]")
        except Exception:
            return "[Ollama Error] Format réponse inattendu."
    elif agent == "openai":
        from openai import OpenAI
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        completion = client.chat.completions.create(
            model="gpt-4",
            messages=chat_history + [{"role": "user", "content": prompt}],
            max_tokens=1024,
            temperature=0.5,
        )
        return completion.choices[0].message.content
    elif agent == "gemini":
        import google.generativeai as genai
        genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
        model = genai.GenerativeModel("gemini-pro")
        response = model.generate_content(prompt)
        if hasattr(response, "text"):
            return response.text
        return str(response)
    return "[Aucune IA sélectionnée]"

def agent_query(prompt):
    return f'Jarvis a reçu : {prompt}'
