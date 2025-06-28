import os
import sys

AGENT_CORE = "agent_core.py"

PATCH = '''
import os
import json
import requests
try:
    import supabase
except ImportError:
    supabase = None

# ========== Mémoire infinie ==========
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

# ========== LLM & fallback ==========
def local_ollama_chat(prompt, model="mistral"):
    try:
        response = requests.post(
            "http://localhost:11434/api/generate",
            json={"model": model, "prompt": prompt, "stream": False},
            timeout=60
        )
        if response.ok and "response" in response.json():
            return response.json()["response"]
    except Exception as e:
        print("[OLLAMA-ERROR]", e)
    return None

def openai_chat(prompt, api_key):
    import openai
    openai.api_key = api_key
    try:
        res = openai.chat.completions.create(
            model="gpt-4o",
            messages=[{"role": "user", "content": prompt}]
        )
        return res.choices[0].message.content
    except Exception as e:
        print("[OPENAI-ERROR]", e)
    return None

def gemini_chat(prompt, api_key):
    try:
        import google.generativeai as genai
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-1.5-flash')
        r = model.generate_content(prompt)
        return r.text
    except Exception as e:
        print("[GEMINI-ERROR]", e)
    return None

# ========== ASK_AGENT ==========

def ask_agent(
    message,
    multimodal=False,
    history=None,
    memory_mode='local',
    user_id='default',
    canvas=None,
    llm_priority=None,
    **kwargs
):
    """
    Fonction coeur. Extensible à volonté.
    """
    # --- Init mémoire ---
    if history is None or not isinstance(history, list):
        history = get_history(user_id, memory_mode)
    if canvas and not any(m.get("role") == "system" for m in history):
        history.insert(0, {"role": "system", "content": canvas})
    # Ajoute le message courant
    history.append({"role": "user", "content": message})

    # --- Routing LLM ---
    reply = None
    LLM_CHAIN = llm_priority or ["ollama", "openai", "gemini"]
    last_error = None
    prompt = message

    for llm in LLM_CHAIN:
        if llm == "ollama":
            r = local_ollama_chat(prompt)
            if r: reply = r; break
        if llm == "openai":
            r = openai_chat(prompt, os.getenv("OPENAI_API_KEY"))
            if r: reply = r; break
        if llm == "gemini":
            r = gemini_chat(prompt, os.getenv("GEMINI_API_KEY"))
            if r: reply = r; break

    if not reply:
        reply = "Erreur: Aucun LLM n'a répondu !"

    # Stocke la réponse
    history.append({"role": "assistant", "content": reply})
    update_history(user_id, history, memory_mode)
    return reply

# ==== FIN PATCH ====
'''

def patch_agent_core():
    with open(AGENT_CORE, "w", encoding="utf-8") as f:
        f.write(PATCH.strip())
    print(f"✅ Patch complet de {AGENT_CORE} OK.")

if __name__ == "__main__":
    patch_agent_core()
