import React, { useState, useEffect, useRef } from "react";

const LLM_ENGINES = [
  { key: "openai", label: "OpenAI" },
  { key: "gemini", label: "Gemini" },
  { key: "deepseek", label: "Deepseek (Ollama)" }
];

export default function App() {
  const [messages, setMessages] = useState([]);
  const [userInput, setUserInput] = useState("");
  const [currentLLM, setCurrentLLM] = useState("deepseek");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const chatEndRef = useRef(null);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  // Fetch historique au chargement (optionnel)
  useEffect(() => {
    fetch("/history")
      .then(res => res.json())
      .then(hist => setMessages(hist || []))
      .catch(() => {});
  }, []);

  const handleSend = async () => {
    if (!userInput.trim()) return;
    setLoading(true);
    setError("");
    try {
      const response = await fetch("/ask", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ prompt: userInput, llm: currentLLM })
      });
      if (!response.ok) throw new Error("Erreur API");
      const data = await response.json();
      setMessages(msgs => [
        ...msgs,
        {
          role: "user",
          content: userInput,
          timestamp: new Date().toISOString(),
        },
        {
          role: "jarvis",
          content: data.response || "(Pas de réponse du LLM)",
          llm: data.llm || currentLLM,
          timestamp: new Date().toISOString(),
        }
      ]);
      setUserInput("");
    } catch (err) {
      setError("Erreur de connexion au backend ou au LLM.");
    }
    setLoading(false);
  };

  return (
    <div className="flex flex-col min-h-screen bg-zinc-900 text-zinc-100 p-0">
      {/* Barre supérieure */}
      <div className="flex items-center p-4 border-b border-zinc-700 bg-zinc-800 shadow-lg">
        <span className="text-xl font-bold tracking-wide flex-1">🤖 Jarvis AI (Cloud/Cyber/Perso)</span>
        <select
          value={currentLLM}
          onChange={e => setCurrentLLM(e.target.value)}
          className="bg-zinc-700 rounded p-2 text-lg ml-4"
        >
          {LLM_ENGINES.map(llm => (
            <option key={llm.key} value={llm.key}>{llm.label}</option>
          ))}
        </select>
      </div>

      {/* Fenêtre chat */}
      <div className="flex-1 overflow-y-auto p-6" style={{ minHeight: 0 }}>
        {messages.map((msg, idx) => (
          <div key={idx} className={`mb-6 flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}>
            <div className={`max-w-lg px-4 py-3 rounded-2xl shadow ${msg.role === "user" ? "bg-indigo-700 text-white" : "bg-zinc-800 text-zinc-100"}`}>
              <div className="text-xs opacity-70 mb-1">{msg.role === "user" ? "Toi" : "Jarvis"} · {msg.timestamp && new Date(msg.timestamp).toLocaleTimeString()} {msg.llm ? `· ${msg.llm}` : ""}</div>
              <div className="whitespace-pre-wrap">{msg.content}</div>
            </div>
          </div>
        ))}
        <div ref={chatEndRef} />
      </div>

      {/* Zone de saisie */}
      <form
        className="flex gap-2 p-4 border-t border-zinc-700 bg-zinc-800"
        onSubmit={e => {
          e.preventDefault();
          handleSend();
        }}
      >
        <input
          className="flex-1 bg-zinc-700 rounded-xl px-4 py-2 text-lg outline-none"
          placeholder="Pose une question à Jarvis..."
          value={userInput}
          onChange={e => setUserInput(e.target.value)}
          disabled={loading}
        />
        <button
          type="submit"
          className="bg-indigo-600 hover:bg-indigo-700 rounded-xl px-6 py-2 font-bold"
          disabled={loading}
        >
          Envoyer
        </button>
      </form>
      {error && (
        <div className="absolute bottom-24 left-1/2 transform -translate-x-1/2 bg-red-700 text-white rounded-xl px-4 py-2 shadow-lg">
          {error}
        </div>
      )}
    </div>
  );
}
