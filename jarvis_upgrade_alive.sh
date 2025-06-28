#!/bin/bash
set -e
echo "=== [JARVIS UPGRADE ALIVE] ==="

# --- PATCH BACKEND ---

BACKEND="./backend"
AGENT_CORE="$BACKEND/agent_core.py"
MAIN_PY="$BACKEND/main.py"

cat > "$AGENT_CORE" << 'EOF'
import os
import requests
import datetime

def agent_query(question: str, agent: str = "auto", profile: dict = None):
    user_name = "Yann"
    intro = f"Tu es Jarvis, assistant personnel très avancé, expert Cloud, Cyber et IA, loyal à {user_name}. Sois utile, concis, proactif, mais humain."
    if not question.strip():
        return f"Bonjour {user_name}, je suis Jarvis, prêt à t'aider sur le cloud, la sécurité, ou la vie perso !"

    # Route intelligente
    if agent == "openai" or ("azure" in question.lower() or "cloud" in question.lower() or "copilot" in question.lower() or "sécurité" in question.lower()):
        try:
            import openai
            openai.api_key = os.environ.get("OPENAI_API_KEY", "")
            response = openai.ChatCompletion.create(
                model="gpt-4o",
                messages=[{"role":"system", "content": intro}, {"role":"user", "content": question}]
            )
            return response.choices[0].message.content.strip() + "\n\n🤖 [OpenAI]"
        except Exception as e:
            return f"(Erreur OpenAI: {e})"

    if agent == "gemini" or ("gcp" in question.lower() or "google" in question.lower()):
        try:
            GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "")
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key={GEMINI_API_KEY}"
            payload = {"contents":[{"parts":[{"text": f"{intro}\n{question}"}]}]}
            r = requests.post(url, json=payload)
            if r.ok:
                txt = r.json().get("candidates",[{}])[0].get("content",{}).get("parts",[{}])[0].get("text")
                return (txt or "[Gemini: aucune réponse]") + "\n\n🤖 [Gemini]"
            return f"(Erreur Gemini: {r.text})"
        except Exception as e:
            return f"(Erreur Gemini: {e})"

    if agent == "ollama" or agent == "mistral" or "ollama" in question.lower() or "mistral" in question.lower():
        try:
            r = requests.post("http://localhost:11434/api/generate", json={
                "model":"mistral", "prompt": f"{intro}\n{question}"
            })
            if r.ok:
                resp = r.json().get("response", "[Ollama: aucune réponse]")
                return resp.strip() + "\n\n🤖 [Mistral/Ollama]"
            return f"(Erreur Ollama: {r.text})"
        except Exception as e:
            return f"(Erreur Ollama: {e})"

    # AUTO: délégué à openai ou ollama par défaut
    if any(k in question.lower() for k in ["gcp", "gemini", "google"]):
        return agent_query(question, agent="gemini")
    if any(k in question.lower() for k in ["azure", "openai", "copilot", "security", "cloud", "sécurité"]):
        return agent_query(question, agent="openai")
    return agent_query(question, agent="ollama")
EOF

cat > "$MAIN_PY" << 'EOF'
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
    data = await request.json()
    question = data.get("question", "")
    agent = data.get("agent", "auto")
    profile = data.get("profile", {})
    try:
        answer = agent_query(question, agent, profile)
    except Exception as e:
        answer = f"(Erreur Jarvis: {e})"
    return {"answer": answer}
EOF

echo "✅ Backend patché."

# --- PATCH FRONTEND ---

FRONTEND="./frontend"
SRC="$FRONTEND/src"
mkdir -p "$SRC"

cat > "$SRC/main.tsx" << 'EOF'
import React from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import JarvisApp from "./JarvisApp";

createRoot(document.getElementById("root")!).render(<JarvisApp />);
EOF

cat > "$SRC/JarvisApp.tsx" << 'EOF'
import React, { useState, useEffect, useRef } from "react";
interface Message { who: string; text: string; when: string; model?: string }
const agents = [
  { label: "Auto", value: "auto" }, { label: "OpenAI", value: "openai" }, { label: "Gemini", value: "gemini" }, { label: "Mistral", value: "ollama" }
];

const getColor = (model: string) => model === "openai" ? "#34c4fa" : model === "gemini" ? "#ff7f00" : "#a4f" ;

export default function JarvisApp() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [agent, setAgent] = useState("auto");
  const [isLoading, setIsLoading] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => { inputRef.current?.focus(); }, []);
  useEffect(() => { if (!messages.length) setMessages([{who: "jarvis", text: "👋 Bonjour Yann ! Je suis Jarvis, ton assistant IA personnel. Que puis-je faire pour toi aujourd'hui ?", when: new Date().toLocaleTimeString()}]); }, []);

  const sendMessage = async () => {
    if (!input.trim()) return;
    setMessages(m => [...m, { who: "user", text: input, when: new Date().toLocaleTimeString() }]);
    setIsLoading(true);
    try {
      const resp = await fetch("http://localhost:8000/ask", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ question: input, agent })
      });
      const data = await resp.json();
      // Extraction du modèle depuis la réponse
      let usedModel = "auto";
      if (data.answer && data.answer.includes("[OpenAI]")) usedModel = "openai";
      if (data.answer && data.answer.includes("[Gemini]")) usedModel = "gemini";
      if (data.answer && data.answer.includes("[Mistral") || data.answer.includes("[Ollama")) usedModel = "ollama";
      setMessages(msgs =>
        [...msgs, { who: "jarvis", text: data.answer.replace(/\n?🤖.*$/, ""), when: new Date().toLocaleTimeString(), model: usedModel }]
      );
    } catch (err) {
      setMessages(msgs =>
        [...msgs, { who: "jarvis", text: "(Erreur: backend injoignable)", when: new Date().toLocaleTimeString() }]
      );
    }
    setIsLoading(false);
    setInput("");
  };

  return (
    <div className="jarvis-ui">
      <div className="header">
        <div className="avatar animated"></div>
        <div>
          <span className="title">Jarvis AI Console</span>
          <span className="subtitle">Bienvenue, Yann !</span>
        </div>
      </div>
      <div className="chatbox">
        {messages.map((msg, i) => (
          <div key={i} className={"msg " + (msg.who === "jarvis" ? "jarvis" : "user")}>
            <span className="who">{msg.who === "jarvis" ? "🤖 Jarvis" : "🧑 Yann"} <span className="when">{msg.when}</span>
              {msg.model && <span className="model" style={{color: getColor(msg.model)}}>({msg.model})</span>}
            </span>
            <div className="text">{msg.text}</div>
          </div>
        ))}
        {isLoading && <div className="msg jarvis"><span className="who">🤖 Jarvis</span><div className="typing">Jarvis réfléchit<span className="dot">.</span><span className="dot">.</span><span className="dot">.</span></div></div>}
      </div>
      <div className="controls">
        <select value={agent} onChange={e => setAgent(e.target.value)}>
          {agents.map(a => <option key={a.value} value={a.value}>{a.label}</option>)}
        </select>
        <input
          ref={inputRef}
          value={input}
          placeholder="Pose ta question à Jarvis…"
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === "Enter" && sendMessage()}
        />
        <button disabled={isLoading} onClick={sendMessage}>Envoyer</button>
      </div>
    </div>
  );
}
EOF

cat > "$SRC/index.css" << 'EOF'
body { background: #222; color: #f2f2f2; font-family: "Segoe UI", Arial, sans-serif; margin:0; }
.jarvis-ui { max-width: 720px; margin: 30px auto; padding: 24px 16px 24px 16px; background: #23242b; border-radius: 24px; min-height: 500px; box-shadow:0 6px 28px #000a; }
.header { display: flex; align-items: center; margin-bottom: 20px; gap: 18px; }
.avatar { width: 52px; height: 52px; border-radius: 50%; background: linear-gradient(120deg,#09e,#09f,#2f2e5e); border: 2px solid #222; }
.animated { box-shadow: 0 0 20px 3px #1df, 0 0 16px 1px #0ff inset; animation: pulse 1.3s infinite alternate; }
@keyframes pulse { from {box-shadow: 0 0 8px #1df;} to {box-shadow: 0 0 32px 8px #0ff;} }
.title { font-size: 2.1rem; font-weight: bold; margin-bottom: 2px; display: block;}
.subtitle { font-size: 1.1rem; color: #aaa; }
.chatbox { background: #292b32; border-radius: 16px; padding: 18px 18px 8px 18px; min-height: 280px; max-height: 400px; overflow-y: auto; margin-bottom: 14px; }
.msg { margin-bottom: 9px; }
.msg.jarvis .who { color: #6cf; }
.msg.user .who { color: #9f9; }
.who { font-weight: bold; }
.when { font-size: 0.85em; color: #666; margin-left: 6px;}
.model { margin-left: 6px; font-size: 0.93em; }
.text { margin-left: 28px; white-space: pre-line; }
.typing { color: #aaa; margin-left: 20px; font-style: italic; }
.dot { animation: blink 1.1s infinite; }
.dot:nth-child(2) { animation-delay: 0.2s; }
.dot:nth-child(3) { animation-delay: 0.4s; }
@keyframes blink { 0%,100%{opacity:0} 50%{opacity:1} }
.controls { display: flex; gap: 10px; margin-top: 10px; }
.controls input { flex: 1; padding: 7px; border-radius: 5px; border: none; font-size: 1.02rem; }
.controls button { padding: 7px 16px; border-radius: 7px; border: none; background: #26d; color: #fff; font-weight: bold; cursor:pointer; }
.controls select { padding: 5px 8px; border-radius: 6px; background: #191b22; color: #fff; border: none; }
EOF

echo "✅ Frontend vivant, look amélioré, modèle affiché."

echo
echo "=== [JARVIS] Mise à niveau terminée ! ==="
echo "1. (Re)lance backend :"
echo "   cd backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000"
echo "2. Puis le frontend :"
echo "   cd frontend && npm install && npm run dev"
echo "3. Rafraîchis la page http://localhost:5173/"
echo "Tu as maintenant :"
echo "  - VRAIE réponse des modèles (OpenAI, Gemini, Ollama)."
echo "  - Affichage de l’avatar, du modèle utilisé, de l’heure, du contexte."
echo "  - UI vivante, colorée, expérience pro/AI assistant."
echo "Prêt à l’étendre (personnalité, supabase, docs, cloud, voix, etc)."
exit 0
