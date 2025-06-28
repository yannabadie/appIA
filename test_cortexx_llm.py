import os
from dotenv import load_dotenv; load_dotenv()
import openai
import requests

ok = True

# Test OpenAI
try:
    openai.api_key = os.getenv("OPENAI_API_KEY")
    resp = openai.chat.completions.create(model="gpt-3.5-turbo", messages=[{"role":"user","content":"ping"}])
    print("[OK] OpenAI fonctionne (gpt-3.5-turbo).")
except Exception as e:
    print("[FAIL] OpenAI:", e)
    ok = False

# Test Gemini (optionnel)
try:
    import google.generativeai as genai
    genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    r = genai.GenerativeModel("gemini-pro").generate_content("ping")
    print("[OK] Gemini fonctionne.")
except Exception as e:
    print("[FAIL] Gemini:", e)
    ok = False

if not ok:
    print("[CORTEXX ROUTING ERROR] Corrige les clés API ou connexion internet, puis relance le script.")
def ensure_gradio_history(history):
    """
    Corrige/convertit n'importe quel historique en format Gradio 4+.
    """
    out = []
    if not history:
        return []
    for h in history:
        if isinstance(h, dict) and "role" in h and "content" in h:
            out.append(h)
        elif isinstance(h, tuple) and len(h) == 2:
            if h[0] in ("user", "assistant", "system"):
                out.append({"role": h[0], "content": h[1]})
            else:
                out.append({"role": "user", "content": str(h[0])})
                out.append({"role": "assistant", "content": str(h[1])})
        elif isinstance(h, str):
            out.append({"role": "user", "content": h})
        else:
            out.append({"role": "assistant", "content": str(h)})
    return out



