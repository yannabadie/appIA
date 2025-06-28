#!/bin/bash
set -e
echo "=== [JARVIS PATCH] Réparation complète, UI vivante, intelligence auto, mémoire locale ==="

# 1. Backend - Ajout mémoire locale + agent dynamique
cat > backend/profile.json <<EOF
{
  "user": "Yann",
  "about": "Architecte Cloud & Cyber passionné, aime l'IA, l'automatisation et les défis techniques.",
  "personality": "Proactif, fiable, humain, expert cloud/cyber, loyal.",
  "prefs": {
    "lang": "fr",
    "default_agent": "auto"
  }
}
EOF

cat > backend/agent_memory.json <<EOF
[]
EOF

# 2. Patch agent_core.py pour la mémoire + log + agent dynamique
cat > backend/agent_core.py <<'EOF'
import os, requests, datetime, json

PROFILE_PATH = os.path.join(os.path.dirname(__file__), "profile.json")
MEMORY_PATH = os.path.join(os.path.dirname(__file__), "agent_memory.json")
profile = json.load(open(PROFILE_PATH))
user_name = profile.get("user", "Utilisateur")

def agent_query(question: str, agent: str = "auto", context: dict = None):
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    intro = f"Tu es Jarvis, assistant personnel de {user_name}, expert Cloud/Cyber, loyal et humain."
    if not question.strip():
        return {"answer": f"Bonjour {user_name}, je suis Jarvis, prêt à t'aider sur le cloud, la sécurité, ou la vie perso !", "agent": "none", "time": now}
    # Décision de l'agent
    if agent == "auto":
        q = question.lower()
        if any(k in q for k in ["azure", "openai", "copilot", "security", "cloud", "sécurité"]): agent = "openai"
        elif any(k in q for k in ["gcp", "gemini", "google"]): agent = "gemini"
        elif any(k in q for k in ["ollama", "mistral"]): agent = "ollama"
        else: agent = profile.get("prefs", {}).get("default_agent", "openai")
    # Sélection de l'agent IA
    resp, meta = "", ""
    try:
        if agent == "openai":
            import openai
            openai.api_key = os.environ.get("OPENAI_API_KEY", "")
            response = openai.ChatCompletion.create(
                model="gpt-4o",
                messages=[{"role": "system", "content": intro}, {"role": "user", "content": question}]
            )
            resp = response.choices[0].message.content.strip()
            meta = "[OpenAI]"
        elif agent == "gemini":
            GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key={GEMINI_API_KEY}"
            data = {"contents":[{"parts":[{"text": intro + "\n" + question}]}]}
            r = requests.post(url, json=data)
            resp = r.json().get("candidates", [{}])[0].get("content", {}).get("parts", [{}])[0].get("text", "")
            meta = "[Gemini]"
        elif agent == "ollama":
            host = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
            model = os.environ.get("OLLAMA_MODEL", "mistral")
            payload = {"model": model, "prompt": intro + "\n" + question}
            r = requests.post(f"{host}/api/generate", json=payload)
            resp = r.json().get("response", "")
            meta = "[Ollama/Mistral]"
        else:
            resp = "Je n'ai pas compris le moteur à utiliser."
            meta = "[Aucun]"
    except Exception as e:
        resp = f"(Erreur {agent}: {e})"
        meta = f"[{agent}]"
    # Log mémoire locale
    memlog = []
    try:
        if os.path.exists(MEMORY_PATH):
            memlog = json.load(open(MEMORY_PATH))
    except: pass
    memlog.append({"date": now, "question": question, "response": resp, "agent": agent})
    json.dump(memlog[-50:], open(MEMORY_PATH, "w")) # Garde les 50 derniers
    # Return structuré
    return {
        "answer": resp,
        "agent": agent,
        "meta": meta,
        "time": now,
        "profile": profile
    }
EOF

# 3. Patch backend/main.py pour l’API REST évoluée
cat > backend/main.py <<'EOF'
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from agent_core import agent_query

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_methods=["*"], allow_headers=["*"], allow_credentials=True
)

@app.post("/ask")
async def ask(request: Request):
    req = await request.json()
    q = req.get("question", "")
    agent = req.get("agent", "auto")
    r = agent_query(q, agent=agent)
    return r

@app.get("/history")
async def history():
    import os, json
    memfile = os.path.join(os.path.dirname(__file__), "agent_memory.json")
    if os.path.exists(memfile):
        return json.load(open(memfile))
    return []
EOF

# 4. Frontend PATCH
mkdir -p frontend/src/components
cat > frontend/src/index.css <<EOF
body { background: #121218; color: #e5e7ef; font-family: 'Segoe UI', Arial, sans-serif; margin:0; }
#jarvis-root { max-width: 700px; margin: 40px auto; background: #232339; border-radius: 24px; box-shadow: 0 6px 24px #1a1a2a44; padding: 24px; }
.jarvis-message { margin: 12px 0; }
.agent-badge { background: #0fa; color: #123; border-radius: 16px; padding: 0 12px; font-size: 13px; margin-left: 10px;}
.user-question { color: #f8c12b;}
.jarvis-response { color: #47c8ef;}
.time-badge { color: #bcbcd0; font-size: 12px; margin-left: 14px;}
.loader { color: #0fa; font-style: italic;}
EOF

cat > frontend/src/JarvisApp.jsx <<'EOF'
import React, { useState, useEffect, useRef } from "react";

function getNow() {
  return new Date().toLocaleTimeString("fr-FR", { hour: "2-digit", minute: "2-digit" });
}

const API = "http://localhost:8000";

export default function JarvisApp() {
  const [input, setInput] = useState("");
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(false);
  const [llm, setLLM] = useState("auto");
  const [profile, setProfile] = useState({ user: "Yann", personality: "" });
  const endRef = useRef();

  useEffect(() => {
    fetch(API + "/history").then(r => r.json()).then(hist => setMessages(hist || []));
  }, []);

  useEffect(() => { endRef.current?.scrollIntoView({behavior: "smooth"}); }, [messages]);

  async function askJarvis(e) {
    e.preventDefault();
    if (!input.trim()) return;
    setLoading(true);
    const msg = { question: input, time: getNow(), agent: llm, user: profile.user };
    setMessages(m => [...m, { ...msg, response: "..." }]);
    setInput("");
    fetch(API + "/ask", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ question: msg.question, agent: llm })
    }).then(r => r.json()).then(res => {
      setMessages(m => m.map((mm,i) => i === m.length-1 ? { ...mm, response: res.answer, agent: res.agent, time: res.time } : mm));
      setProfile(res.profile || profile);
      setLoading(false);
    }).catch(() => setLoading(false));
  }

  return (
    <div id="jarvis-root">
      <div style={{fontSize:28, fontWeight:700}}>👨‍💻 Jarvis AI <span className="agent-badge">{profile.user}</span></div>
      <div style={{fontSize:14, color:"#ccc"}}>Assistant Cloud, Cyber & Perso</div>
      <hr />
      <div style={{marginBottom:16}}>
        <b>LLM utilisé :</b>
        <select value={llm} onChange={e=>setLLM(e.target.value)}>
          <option value="auto">Auto</option>
          <option value="openai">OpenAI</option>
          <option value="gemini">Gemini</option>
          <option value="ollama">Ollama/Mistral</option>
        </select>
      </div>
      <div style={{minHeight:220}}>
        {messages.map((m, i) => (
          <div className="jarvis-message" key={i}>
            <span className="user-question">⨀ {m.question}</span>
            <span className="time-badge">{m.time}</span>
            <span className="agent-badge">{m.agent}</span>
            <br />
            <span className="jarvis-response">{m.response}</span>
          </div>
        ))}
        {loading && <div className="loader">Jarvis réfléchit...</div>}
        <div ref={endRef}></div>
      </div>
      <form onSubmit={askJarvis} style={{marginTop:18, display:"flex", gap:10}}>
        <input
          autoFocus
          style={{flex:1, padding:10, borderRadius:10, fontSize:16, border:"1px solid #2a2a42", background:"#232339", color:"#fff"}}
          placeholder="Pose une question à Jarvis..."
          value={input}
          onChange={e=>setInput(e.target.value)}
        />
        <button type="submit" style={{padding:"0 24px", borderRadius:10, background:"#0fa", border:"none", color:"#123", fontWeight:600}}>Envoyer</button>
      </form>
      <hr style={{margin:"24px 0 10px 0"}}/>
      <div style={{fontSize:13, color:"#888"}}>
        {profile.user} | {profile.personality} | {profile.about}
      </div>
    </div>
  );
}
EOF

cat > frontend/src/main.jsx <<'EOF'
import React from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import JarvisApp from "./JarvisApp.jsx";
createRoot(document.getElementById("root")).render(<JarvisApp />);
EOF

echo "=== [JARVIS PATCH] Terminé. ==="
echo "1️⃣  cd backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000"
echo "2️⃣  cd frontend && npm run dev"
echo "🚀 UI évoluée, mémoire locale, choix LLM, feedback, personnalité basique !"
