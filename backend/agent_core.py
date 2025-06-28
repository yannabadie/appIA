import os
import requests
import openai

def query_openai(prompt, model="gpt-4"):
    client = openai.OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "Tu es Jarvis, assistant cloud/cyber, expert et humain."},
            {"role": "user", "content": prompt}
        ]
    )
    return response.choices[0].message.content.strip()

def query_gemini(prompt):
    # Remplace par l’appel Google Gemini correct
    import requests
    key = os.environ.get("GEMINI_API_KEY")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key={key}"
    body = {"contents":[{"parts":[{"text": prompt}]}]}
    resp = requests.post(url, json=body, timeout=60)
    if resp.ok:
        try:
            return resp.json()['candidates'][0]['content']['parts'][0]['text']
        except Exception:
            return "[Erreur Gemini: parsing réponse]"
    else:
        return f"[Erreur Gemini: {resp.text}]"

def query_ollama_deepseek(prompt, model="deepseek-llm:latest"):
    url = "http://localhost:11434/api/generate"
    payload = {"model": model, "prompt": prompt, "stream": False}
    r = requests.post(url, json=payload, timeout=90)
    if r.ok and "response" in r.json():
        return r.json()["response"]
    else:
        return f"Ollama: {r.text}"

def agent_query(prompt, llm="auto"):
    if llm == "openai":
        return query_openai(prompt)
    if llm == "gemini":
        return query_gemini(prompt)
    if llm in ("deepseek", "ollama"):
        return query_ollama_deepseek(prompt)
    # auto: fallback sur Deepseek, puis OpenAI
    try:
        return query_ollama_deepseek(prompt)
    except Exception:
        try:
            return query_openai(prompt)
        except Exception:
            return "Aucun moteur LLM n'est disponible actuellement."
