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
