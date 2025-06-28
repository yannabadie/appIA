<<<<<<< HEAD
# appI
# 🤖 JARVIS IA – Assistant Numérique Personnel & Pro

**Projet open-source de double numérique IA modulaire, local+cloud, orchestré autour d’un backend Python (FastAPI), d’un frontend moderne (React/Streamlit), et d’un cerveau LLM hybride (Ollama local + OpenAI GPT-4o + Gemini 2.5 Pro).**

## 🚀 Objectifs

- **Avoir un assistant numérique réellement utile, personnel ET pro**
    - Orchestration locale/hybride, gestion complète via Ollama local et LLM cloud
    - Interaction vocale, texte, fichiers, API, multi-agents si besoin
- **Mémoire contextuelle persistante & vectorielle** (prévu : remplacement progressif de Supabase si GitHub + VSCode suffisent)
- **Automatisation de tâches (perso/pro, script, cloud, API, local)**
- **Amélioration continue : intégration native avec Copilot, Codex, GitHub, VSCode**
- **IA proactive, peut déranger/alerter sur détection intelligente**
- **Plug-and-play, déploiement facile sur PC ou serveur local (Linux/WSL)**
- **Support complet des modèles open et commerciaux** (Ollama, OpenAI, Gemini…)

---

## 🧠 Modèles IA Utilisés

- **LLM locaux via Ollama** :
    - **Deepseek LLM** (principal)
    - **Mixtral** (multilingue, résumé)
    - **Phi-3** (compact, rapide)
    - **StarCoder** (génération de code)
    - *(autres modèles installables à la volée)*
- **Cloud LLM** :
    - **OpenAI GPT-4o / GPT-4.1** (abonnement Plus, toutes API dispo)
    - **Gemini 2.5 Pro** (API vocale, multimodale, via Google One)
    - *(Routing automatique selon besoins/charge)*

---

## 🏗️ Structure du Projet

appIA/
├── backend/ # API Python (FastAPI), logique, orchestration, routes, sécurité
│ ├── main.py # Point d’entrée de l’API backend
│ └── ...
├── frontend/ # Interface utilisateur (React, Next.js, Streamlit…)
│ └── ... # UI Chat, paramétrage, monitoring, etc.
├── jarvisenv310/ # Environnement Python virtuel dédié
├── requirements.txt # Dépendances Python backend
├── package.json # Dépendances frontend
├── ollama/ # Scripts/gestion modèles LLM locaux (Deepseek, Mixtral…)
├── scripts/ # Outils automation, setup, devops, push GitHub…
├── README.md # Ce fichier (documentation centrale)


---

## 🛠️ Stack Technique

- **Backend** : Python 3.10+, FastAPI, Flask (legacy), orchestrations LLM/API, stockage contextuel (Git, vector DB…)
- **Frontend** : React (Next.js), Streamlit (debug/monitoring rapide), Web UI custom, support TTS/vocal
- **LLM locaux** : Ollama (Deepseek, Mixtral, etc. ; GPU ou CPU)
- **LLM cloud** : OpenAI GPT-4o/4.1, Gemini 2.5 Pro (API), routing automatique selon tâches
- **Automatisation & DevOps** : Bash/Python scripts, push auto GitHub, update auto dépendances, logging continu, monitoring (à venir)
- **Persistance/contextualisation** : Vector DB (initial : Supabase ; migration progressive vers GitHub+VSCode), journaux auto, logs structurés

---

## 🔄 Déploiement & Installation

### 1. **Clonage du repo & initialisation**

```bash
git clone https://github.com/yannabadie/appIA.git
cd appIA
# Création de l’environnement Python dédié
python3 -m venv jarvisenv310
source jarvisenv310/bin/activate
pip install -r requirements.txt
# Frontend
cd frontend
npm install
npm run dev
# Backend (autre terminal)
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
# LLM local (Ollama)
ollama serve
ollama pull deepseek-llm:latest


2. Automatisation GitHub (push/pull)
⚡️ Tout est automatisé via scripts/auto_github_push.sh ou équivalent.

Configure ton TOKEN GitHub (accès push/pull : GitHub PAT)

Le script s’occupe des conflits, merge, rebase, et push auto

Tout changement (code, config, data) est tracé par Git (plus de perte de contexte)

🏢 Utilisation et Tests
Lance backend & frontend en parallèle (de préférence via deux terminaux)

Accède à l’interface web http://localhost:3000 (si Next.js/React)

Dialogue IA : chat, voix, prompts, fichiers…

Suivi des logs : dans logs/, terminal, ou dashboard web (à venir)

Tests et évolutions :

Propose tes prompt/commandes dans le chat ou via scripts

Les suggestions d’amélioration sont directement prises en compte via Codex/Copilot (voir ci-dessous)

🤝 Collaboration Codex/Copilot/ChatGPT
Codex/Copilot/ChatGPT sont tous capables de lire ce README

Objectifs, structure, et workflow sont documentés ici

Tout nouveau dev doit commencer par ce README

Suggestions ou améliorations peuvent être proposées dans Issues ou PR

Logs d’automatisation et rapports d’erreurs sont accessibles pour débogage/évolution

🔔 Points d’évolution & exigences utilisateur (rappel)
Interaction fluide multi-modalités (vocal, texte, API, fichiers)

Prise en compte du contexte long-terme : mémoire vectorielle, historique, journal utilisateur

Routing LLM intelligent : choix du moteur IA selon la tâche, charge, coût, confidentialité

Plug-and-play, 100% autonome sur une seule machine (support complet WSL/Windows/Linux)

Sécurité : pas d’expo API non-authentifiée, tokens chiffrés, isolation du venv

IA proactive, peut “déranger” l’utilisateur si urgence/détection critique

Évolution continue du codebase, monitoring santé du système, suggestions IA

Reste évolutif/flexible sur les dépendances (ne JAMAIS tout figer, support des dernières versions)

[OPTION] Stockage persistant : migration vector DB → GitHub/VSCode si possible

🔗 Liens utiles
Repo GitHub : https://github.com/yannabadie/appIA

Support IA local : https://ollama.com/library

Docs API OpenAI : https://platform.openai.com/docs

Docs API Gemini : https://ai.google.dev/

VSCode + Copilot : https://github.com/features/copilot

📝 Auteur & Contact
Yann Abadie — Architecte Cloud/Cyber Microsoft, expert IA, contact via GitHub

Ce README doit toujours être mis à jour avant toute évolution majeure

