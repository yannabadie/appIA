#!/bin/bash
echo "=== [PATCH JARVIS LLM + UI] ==="
# (1) Upgrade OpenAI et fix API
pip install --upgrade openai
sed -i 's/openai.ChatCompletion.create/openai.OpenAI(api_key=os.environ.get("OPENAI_API_KEY")).chat.completions.create/g' backend/agent_core.py

# (2) Ajoute Deepseek dans agent_core.py si absent
if ! grep -q "deepseek" backend/agent_core.py; then
cat <<EOF >> backend/agent_core.py

def query_deepseek(prompt, model="deepseek-llm:latest"):
    import requests
    url = "http://localhost:11434/api/generate"
    payload = {"model": model, "prompt": prompt, "stream": False}
    r = requests.post(url, json=payload, timeout=90)
    if r.status_code == 200:
        return r.json().get("response", "Aucune réponse.")
    else:
        return f"Ollama: {r.text}"
EOF
fi

# (3) Patch le frontend (sélecteur LLM Deepseek + UI)
if [ -d frontend/src ]; then
    # Ajoute "Deepseek" dans le select LLM
    sed -i 's/\(openai", "gemini", "ollama"\)/\1, "deepseek"/g' frontend/src/JarvisApp.tsx 2>/dev/null
    # (TODO : améliorer la classe CSS + état UI)
fi

echo "=== Patch appliqué ! Relance backend puis frontend ==="
