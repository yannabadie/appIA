#!/bin/bash

set -e

echo "=== [JARVIS AUTO-PATCH] Stack OpenAI / Gemini / Ollama Deepseek + UI ==="

# 1. Sauvegarde des fichiers critiques
cp backend/agent_core.py backend/agent_core.py.bak.$(date +%s) 2>/dev/null || true
cp backend/main.py backend/main.py.bak.$(date +%s) 2>/dev/null || true
cp frontend/src/JarvisApp.tsx frontend/src/JarvisApp.tsx.bak.$(date +%s) 2>/dev/null || true
cp frontend/src/main.tsx frontend/src/main.tsx.bak.$(date +%s) 2>/dev/null || true

# 2. Patch backend/agent_core.py
cat > backend/agent_core.py <<EOF
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
EOF

# 3. Patch backend/main.py pour le routing (extrait standard)
cat > backend/main.py <<EOF
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from agent_core import agent_query
import uvicorn

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"]
)

@app.post("/ask")
async def ask(request: Request):
    data = await request.json()
    prompt = data.get("prompt", "")
    llm = data.get("llm", "auto")
    try:
        response = agent_query(prompt, llm)
        return {"response": response}
    except Exception as e:
        return {"response": f"[Erreur backend]: {e}"}

@app.get("/history")
def history():
    return {"history": []}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
EOF

# 4. Patch Frontend JarvisApp.tsx
cat > frontend/src/JarvisApp.tsx <<EOF
import React, { useState } from "react";

const LLM_OPTIONS = [
  { value: "auto", label: "Auto" },
  { value: "openai", label: "OpenAI (GPT-4)" },
  { value: "gemini", label: "Gemini" },
  { value: "deepseek", label: "Deepseek Ollama" }
];

function formatTime(ts) {
  return new Date(ts).toLocaleTimeString();
}

export default function JarvisApp() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState("");
  const [llm, setLLM] = useState("auto");
  const [loading, setLoading] = useState(false);

  async function sendMessage(e) {
    e.preventDefault();
    if (!input.trim()) return;
    const msg = { role: "user", content: input, time: Date.now(), llm };
    setMessages([...messages, msg]);
    setInput("");
    setLoading(true);
    const res = await fetch("http://localhost:8000/ask", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt: input, llm })
    }).then(r => r.json());
    setMessages(m =>
      [...m, { role: "jarvis", content: res.response, time: Date.now(), llm }]
    );
    setLoading(false);
  }

  return (
    <div style={{
      background: "#23252b",
      minHeight: "100vh",
      display: "flex",
      justifyContent: "center",
      alignItems: "flex-start"
    }}>
      <div style={{
        background: "#23223b",
        borderRadius: "20px",
        boxShadow: "0 6px 30px #0007",
        marginTop: "50px",
        minWidth: "600px",
        padding: "32px"
      }}>
        <h1>
          <span role="img" aria-label="robot">🤖</span> Jarvis AI <span style={{ fontSize: 14, color: "#1affac" }}>Yann</span>
        </h1>
        <div style={{ margin: "8px 0" }}>
          <b>LLM utilisé :</b>
          <select style={{ marginLeft: 8 }} value={llm} onChange={e => setLLM(e.target.value)}>
            {LLM_OPTIONS.map(opt =>
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            )}
          </select>
        </div>
        <div style={{ minHeight: 280, background: "#292941", borderRadius: 10, margin: "18px 0", padding: "12px", color: "#f6fff7" }}>
          {messages.map((msg, idx) => (
            <div key={idx} style={{
              display: "flex", alignItems: "center", margin: "8px 0"
            }}>
              <span style={{ fontSize: 22, marginRight: 7 }}>{msg.role === "user" ? "🧑‍💻" : "🤖"}</span>
              <span style={{ fontWeight: 500 }}>{msg.content}</span>
              <span style={{ marginLeft: 14, fontSize: 12, color: "#83f4b6" }}>
                {msg.llm && <>({msg.llm})</>} {formatTime(msg.time)}
              </span>
            </div>
          ))}
          {loading && <div><span style={{ fontSize: 22 }}>🤖</span> ... <i>Jarvis réfléchit</i></div>}
        </div>
        <form style={{ display: "flex", gap: 8 }} onSubmit={sendMessage}>
          <input
            style={{
              flex: 1, padding: 10, borderRadius: 6,
              border: "1px solid #212", fontSize: 17, background: "#23232c", color: "#fff"
            }}
            placeholder="Pose ta question à Jarvis..."
            value={input}
            onChange={e => setInput(e.target.value)}
            disabled={loading}
            autoFocus
          />
          <button style={{
            background: "#1affac", borderRadius: 7,
            border: "none", padding: "10px 22px", fontWeight: 700
          }} type="submit" disabled={loading}>
            Envoyer
          </button>
        </form>
        <div style={{ marginTop: 12, fontSize: 11, color: "#85ffd5" }}>
          <b>Yann</b> | Proactif, fiable, humain, expert cloud/cyber.<br />
          Assistant IA personnel, version patch automatique.
        </div>
      </div>
    </div>
  );
}
EOF

# 5. Patch Frontend src/main.tsx (pour compatibilité)
cat > frontend/src/main.tsx <<EOF
import React from "react";
import { createRoot } from "react-dom/client";
import JarvisApp from "./JarvisApp";

createRoot(document.getElementById("root")).render(<JarvisApp />);
EOF

# 6. Dépendances Python requises
pip install openai requests --upgrade

echo "=== Patch complet terminé ! ==="
echo "Relance backend et frontend, sélectionne Deepseek ou OpenAI puis pose une question."
