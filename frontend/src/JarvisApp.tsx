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
