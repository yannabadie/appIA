# JARVIS-AI: Assistant Multimodal et Multi-IA
- Agent IA personnel, multimodal, multi-LLM, multi-cloud (OpenAI, Gemini, Google, Microsoft)
- UI moderne (ChatGPT-like), mémoire locale/cloud (Supabase), édition docs/drive/vision
- Pour lancer : python web_ui.py (http://localhost:7860)
- Adapter .env si besoin de changer des clés/tokens.

# 🚀 JARVIS IA - Digital Assistant Project

Ce repo vise à créer un assistant personnel et professionnel IA, extensible et multi-agent, s’appuyant sur :

- **Python 3.10+ (backend FastAPI)**
- **Frontend React ou Streamlit** (selon version)
- **LLM hybrides : OpenAI GPT-4.1/4o, Gemini 2.5 Pro, Deepseek, Ollama (local)**
- **Moteur de routing IA pour déléguer à l’agent le plus pertinent**
- **Mémoire vectorielle personnalisée, stockée localement (faiss, chromadb, etc.)**
- **Persistance : stockage sécurisé (Vault Copilot, fichiers cryptés, ou cloud sécurisé)**
- **Automatisation : scripts pour maintenance, onboarding, CI/CD**
- **Tests automatiques (GitHub Actions, Codespaces, pytest, etc.)**
- **Gestion vocale Whisper/TTS, support web/vocal/CLI**
- **Intégration VSCode, Copilot, Codex**
- **Sécurité des données (chiffrement, logs contrôlés, audit, .gitignore strict)**

---

## 🧑‍💻 **TODO & Roadmap immédiate**

1. **Nettoyer et documenter la racine du projet**
2. **Supprimer scripts inutiles (.ps1, .sh sauf maintenance)**
3. **Mise à jour complète du README et création de `FEATURES.md`**
4. **Initialiser la mémoire vectorielle locale**
5. **Automatiser le test d’intégration dans Codespaces**
6. **Documenter le process d’onboarding pour Codex/Copilot**
7. **Sécuriser le vault de secrets (Copilot Vault, .env.local)**
8. **Ajout badge build, feedback, logs CI/CD**

---

## 📡 **Suivi LIVE**

- **Actions/CI** : [https://github.com/yannabadie/appIA/actions](https://github.com/yannabadie/appIA/actions)
- **Codespaces** : [https://github.com/yannabadie/appIA/codespaces](https://github.com/yannabadie/appIA/codespaces)
- **Issues/Feedback** : [https://github.com/yannabadie/appIA/issues](https://github.com/yannabadie/appIA/issues)

---

## ⚙️ **Commandes utiles**

```bash
# Cloner et lancer en local
git clone https://github.com/yannabadie/appIA.git
cd appIA
# Pour démarrer backend
cd backend && uvicorn main:app --reload
# Pour lancer le frontend (React ou Streamlit)
cd frontend && npm install && npm start
