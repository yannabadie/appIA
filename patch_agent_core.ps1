# patch_agent_core.ps1
$target = ".\agent_core.py"
$patchContent = @"
# agent_core.py — Double Numérique IA Multimodal, patch full “function calling” & routage intelligent

import os
import json
import uuid
import datetime
import re
import shutil
import subprocess
import logging
import base64
from pathlib import Path
from dotenv import load_dotenv
from openai import OpenAI
import google.generativeai as genai
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# === Initialisation des logs ===
os.makedirs("data", exist_ok=True)
logging.basicConfig(
    filename="data/agent.log",
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

load_dotenv(".env")

def load_profile():
    try:
        with open("data/profile.json", "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return {
            "name": "Yann",
            "role": "Architecte cloud et IA",
            "objectives": [
                "Automatiser les tâches répétitives",
                "Gérer les documents Drive et OneDrive",
                "Planifier des projets techniques",
                "Générer des synthèses et canevas"
            ]
        }

profile = load_profile()

openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))

history_file = Path("data/history.json")
history = []
if history_file.exists():
    try:
        with open(history_file, "r", encoding="utf-8") as f:
            history = json.load(f)
    except Exception as e:
        logging.warning(f"Erreur lecture mémoire : {e}")

def save_history():
    try:
        with open(history_file, "w", encoding="utf-8") as f:
            json.dump(history, f, ensure_ascii=False, indent=2)
    except Exception as e:
        logging.error(f"Erreur sauvegarde mémoire : {e}")

def build_system_prompt():
    return (
        f"Tu es l'assistant personnel de {profile['name']} ({profile['role']})\n"
        f"Objectifs : {', '.join(profile['objectives'])}\n"
        f"Utilise la bonne IA (GPT-4, Gemini, etc.) selon le besoin.\n"
        f"Interface enrichie, historique, markdown, fichiers, canevas."
    )

def is_task_suitable_for_gemini(prompt):
    keywords = ["image", "graphique", "plan", "photo", "schéma"]
    return any(k in prompt.lower() for k in keywords)

# === Services Google ===
GDRIVE_SCOPES = ["https://www.googleapis.com/auth/drive"]
GMAIL_SCOPES = ["https://www.googleapis.com/auth/gmail.send"]
GCREDS_PATH = os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON", "data/google_creds.json")
PARENT_FOLDER_ID = "1A0PB_7WNCHT6Wr767P_j2-vAyoLZgoPV"
cached_services = {}

def get_google_service(api, version, scopes):
    if api in cached_services:
        return cached_services[api]
    try:
        creds = service_account.Credentials.from_service_account_file(GCREDS_PATH, scopes=scopes)
        service = build(api, version, credentials=creds, cache_discovery=False)
        cached_services[api] = service
        return service
    except Exception as e:
        logging.error(f"Service {api} KO : {e}")
        return None

# === INTELLIGENT FILE/DIR MANAGEMENT (MULTI-SERVICE) ===

def create_file(filename, storage="local", folderpath=None):
    # Gère création fichier local/OneDrive/Drive
    if storage == "local":
        script_path = f"scripts/create_file_{uuid.uuid4().hex[:6]}.ps1"
        file_full = f"{folderpath}\\{filename}" if folderpath else filename
        with open(script_path, "w", encoding="utf-8") as f:
            f.write(f'New-Item -Path "{file_full}" -ItemType "file" -Force | Out-Null\n')
        try:
            subprocess.run(["powershell", "-ExecutionPolicy", "Bypass", "-File", script_path], check=True)
            os.remove(script_path)
            return f"✅ Fichier créé : {file_full}"
        except Exception as e:
            logging.error(f"Erreur création fichier : {e}")
            return f"Erreur création fichier : {e}"
    elif storage == "onedrive":
        ps_script = f"scripts/create_onedrive_file_{uuid.uuid4().hex[:6]}.ps1"
        onepath = os.path.expandvars(r"$env:USERPROFILE\OneDrive\DoubleNumerique")
        with open(ps_script, "w", encoding="utf-8") as f:
            f.write(f'New-Item -Path "{onepath}\\{filename}" -ItemType "file" -Force | Out-Null\n')
        try:
            subprocess.run(["powershell", "-ExecutionPolicy", "Bypass", "-File", ps_script], check=True)
            os.remove(ps_script)
            return f"✅ Fichier OneDrive créé: {filename}"
        except Exception as e:
            logging.error(f"Erreur création fichier OneDrive : {e}")
            return f"Erreur création fichier OneDrive : {e}"
    elif storage == "drive":
        return upload_file_to_drive(filename, create_empty=True)
    else:
        return f"❌ Stockage inconnu: {storage}"

def create_google_drive_folder(folder_name):
    try:
        service = get_google_service("drive", "v3", GDRIVE_SCOPES)
        if not service:
            return "Erreur : Service Drive indisponible."
        check = service.files().list(q=f"name='{folder_name}' and '{PARENT_FOLDER_ID}' in parents and trashed=false", spaces='drive', fields='files(id)').execute()
        if check.get('files'):
            return f"✅ Dossier '{folder_name}' déjà existant."
        file_metadata = {"name": folder_name, "mimeType": "application/vnd.google-apps.folder", "parents": [PARENT_FOLDER_ID]}
        folder = service.files().create(body=file_metadata, fields="id").execute()
        return f"✅ Dossier '{folder_name}' créé."
    except Exception as e:
        logging.error(f"Erreur création dossier : {e}")
        return f"Erreur création dossier : {e}"

def upload_file_to_drive(filepath, create_empty=False):
    try:
        service = get_google_service("drive", "v3", GDRIVE_SCOPES)
        if not service:
            return "Erreur : Service Drive non initialisé."
        if create_empty:
            # Crée un fichier vide avant upload
            open(filepath, 'a').close()
        meta = {"name": os.path.basename(filepath), "parents": [PARENT_FOLDER_ID]}
        media = MediaFileUpload(filepath, resumable=True)
        file = service.files().create(body=meta, media_body=media, fields="id").execute()
        return f"✅ Fichier uploadé : {filepath}"
    except Exception as e:
        logging.error(f"Erreur upload fichier : {e}")
        return f"Erreur upload fichier : {e}"

def list_files_in_drive():
    try:
        service = get_google_service("drive", "v3", GDRIVE_SCOPES)
        results = service.files().list(q=f"'{PARENT_FOLDER_ID}' in parents and trashed = false", fields="files(id, name)").execute()
        files = results.get("files", [])
        return "\n".join([f"- {f['name']} (ID: {f['id']})" for f in files]) or "Aucun fichier."
    except Exception as e:
        logging.error(f"Erreur listing : {e}")
        return f"Erreur listing : {e}"

def delete_file(filename, storage="local"):
    try:
        if storage == "local":
            os.remove(filename)
            return f"🗑️ Fichier supprimé : {filename}"
        # TODO: Onedrive et Drive : delete par API/scripting
        return f"❌ Suppression pour {storage} à implémenter"
    except Exception as e:
        return f"Erreur suppression fichier : {e}"

# === INTENT/PARSING INTELLIGENT ÉTENDU ===

def parse_intent(prompt):
    """Retourne dict: {'action': ..., 'target': ..., 'params': {...}}"""
    prompt_l = prompt.lower()
    # Création de fichier (Drive, OneDrive ou local)
    m_file = re.search(r"cr[ée]e?r? (un )?fichier.*(?:appel[ée]?|nomm[ée]?|de nom)?[ :]*\"?([\w\-\. ]+)\"?(?: dans (mon )?(google ?drive|onedrive))?", prompt_l)
    if m_file:
        filename = m_file.group(2).strip()
        stockage = "local"
        if m_file.group(3):
            if "drive" in m_file.group(3):
                stockage = "drive"
            elif "onedrive" in m_file.group(3):
                stockage = "onedrive"
        return {"action": "create_file", "target": stockage, "params": {"filename": filename}}
    # Suppression de fichier
    m_del = re.search(r"(supprimer|delete) (le )?fichier.*\"?([\w\-\. ]+)\"?", prompt_l)
    if m_del:
        filename = m_del.group(3).strip()
        return {"action": "delete_file", "target": "local", "params": {"filename": filename}}
    # Création de dossier Drive
    m_dfolder = re.search(r"cr[ée]e?r? (un )?dossier.*(?:appel[ée]?|nomm[ée]?|de nom)?[ :]*\"?([\w\-\. ]+)\"?(?:.*drive)?", prompt_l)
    if m_dfolder:
        folder = m_dfolder.group(2).strip()
        return {"action": "create_folder", "target": "drive", "params": {"foldername": folder}}
    # Listing fichiers
    if "lister" in prompt_l and "fichiers" in prompt_l and ("drive" in prompt_l or "onedrive" in prompt_l):
        return {"action": "list_files", "target": "drive", "params": {}}
    # Email
    if "envoyer" in prompt_l and "email" in prompt_l:
        match_email = re.search(r"à ([\w\.-]+@[\w\.-]+)", prompt_l)
        mail = match_email.group(1) if match_email else "yann.abadie@gmail.com"
        return {"action": "send_email", "target": "gmail", "params": {"to": mail, "subject": "IA", "message": prompt}}
    # Backup
    if "backup" in prompt_l or "sauvegarde" in prompt_l:
        return {"action": "backup_all", "target": "drive", "params": {}}
    # Onedrive init
    if "onedrive" in prompt_l and ("init" in prompt_l or "liaison" in prompt_l):
        return {"action": "init_onedrive", "target": "onedrive", "params": {}}
    # Sinon : passthrough
    return {"action": "ask_ai", "target": "auto", "params": {"prompt": prompt}}

# === FUNCTION CALLING POUR OPENAI (ÉTENDU) ===

def get_functions_openai():
    return [
        {
            "name": "create_file",
            "description": "Crée un fichier sur le support voulu (local, Drive, OneDrive).",
            "parameters": {
                "type": "object",
                "properties": {
                    "filename": {"type": "string", "description": "Nom du fichier à créer"},
                    "storage": {"type": "string", "enum": ["local", "drive", "onedrive"], "description": "Où créer"}
                },
                "required": ["filename", "storage"]
            }
        },
        {
            "name": "create_google_drive_folder",
            "description": "Crée un dossier dans Google Drive.",
            "parameters": {
                "type": "object",
                "properties": {
                    "folder_name": {"type": "string", "description": "Nom du dossier à créer"}
                },
                "required": ["folder_name"]
            }
        },
        {
            "name": "upload_file_to_drive",
            "description": "Upload un fichier local vers Google Drive.",
            "parameters": {
                "type": "object",
                "properties": {
                    "filepath": {"type": "string"}
                },
                "required": ["filepath"]
            }
        },
        {
            "name": "delete_file",
            "description": "Supprime un fichier donné.",
            "parameters": {
                "type": "object",
                "properties": {
                    "filename": {"type": "string"},
                    "storage": {"type": "string", "enum": ["local", "drive", "onedrive"]}
                },
                "required": ["filename", "storage"]
            }
        }
        # Ajouter autres actions ici
    ]

def call_function(name, args):
    if name == "create_file":
        return create_file(args["filename"], storage=args.get("storage", "local"))
    if name == "create_google_drive_folder":
        return create_google_drive_folder(args["folder_name"])
    if name == "upload_file_to_drive":
        return upload_file_to_drive(args["filepath"])
    if name == "delete_file":
        return delete_file(args["filename"], storage=args.get("storage", "local"))
    return f"❌ Fonction inconnue : {name}"

# === LOGIQUE PRINCIPALE ===

def ask_agent(prompt, model_name=None):
    try:
        # Détection d’intention
        intent = parse_intent(prompt)
        logging.info(f"Intent détectée: {intent}")

        if intent["action"] == "create_file":
            return create_file(intent["params"]["filename"], storage=intent["target"])
        if intent["action"] == "delete_file":
            return delete_file(intent["params"]["filename"], storage=intent["target"])
        if intent["action"] == "create_folder" and intent["target"] == "drive":
            return create_google_drive_folder(intent["params"]["foldername"])
        if intent["action"] == "upload_file":
            return upload_file_to_drive(intent["params"]["filepath"])
        if intent["action"] == "list_files":
            return list_files_in_drive()
        if intent["action"] == "send_email":
            return send_email(
                intent["params"]["to"],
                intent["params"]["subject"],
                intent["params"]["message"]
            )
        if intent["action"] == "init_onedrive":
            return initialize_onedrive()
        if intent["action"] == "backup_all":
            return backup_all_to_drive()

        # Routage IA (OpenAI function calling prioritaire)
        model = (model_name or "gpt-4o").lower()
        if model.startswith("gemini") or is_task_suitable_for_gemini(prompt):
            chat = genai.GenerativeModel("gemini-pro").start_chat()
            response = chat.send_message(prompt)
            result = response.text.strip()
            history.append({"time": datetime.datetime.now().isoformat(), "model": "gemini-pro", "prompt": prompt, "response": result})
            save_history()
            return result

        try:
            response = openai_client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": build_system_prompt()},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.5,
                tools=[{"type": "function", "function": func} for func in get_functions_openai()],
                tool_choice="auto"
            )
            msg = response.choices[0].message
            if hasattr(msg, "tool_calls") and msg.tool_calls:
                call = msg.tool_calls[0]
                fn_name = call.function.name
                args = json.loads(call.function.arguments)
                result = call_function(fn_name, args)
            else:
                result = msg.content.strip()
            history.append({"time": datetime.datetime.now().isoformat(), "model": model, "prompt": prompt, "response": result})
            save_history()
            return result
        except Exception as e:
            logging.error(f"Erreur function calling : {e}")

        res = openai_client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": build_system_prompt()},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7
        )
        result = res.choices[0].message.content.strip()
        history.append({"time": datetime.datetime.now().isoformat(), "model": model, "prompt": prompt, "response": result})
        save_history()
        return result

    except Exception as e:
        logging.error(f"Erreur traitement IA : {e}")
        return f"Erreur IA : {e}"

"@

Set-Content -Path $target -Value $patchContent -Encoding UTF8

Write-Host "Patch appliqué à agent_core.py."
