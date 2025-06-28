from google.oauth2 import service_account
from googleapiclient.discovery import build
import os, json

def handle_drive_command(prompt):
    try:
        creds = service_account.Credentials.from_service_account_file(
            os.getenv("GOOGLE_APPLICATION_CREDENTIALS"),
            scopes=["https://www.googleapis.com/auth/drive"]
        )
        service = build("drive", "v3", credentials=creds)

        file_metadata = {
            "name": "JarvisIA_Demo.txt",
            "mimeType": "application/vnd.google-apps.document",
            "parents": ["root"]
        }
        file = service.files().create(body=file_metadata, fields="id").execute()

        # Partage avec l'utilisateur Yann
        service.permissions().create(
            fileId=file["id"],
            body={"type": "user", "role": "writer", "emailAddress": "yann.abadie@gmail.com"},
            fields="id"
        ).execute()

        return f"Fichier Google Drive créé avec succès. ID: {file.get('id')}"
    except Exception as e:
        return f"Erreur Google Drive : {e}"
def ensure_gradio_history(history):
    """
    Corrige/convertit n'importe quel historique en format Gradio 4+.
    """
    out = []
    if not history:
        return []
    for h in history:
        if isinstance(h, dict) and "role" in h and "content" in h:
            out.append(h)
        elif isinstance(h, tuple) and len(h) == 2:
            if h[0] in ("user", "assistant", "system"):
                out.append({"role": h[0], "content": h[1]})
            else:
                out.append({"role": "user", "content": str(h[0])})
                out.append({"role": "assistant", "content": str(h[1])})
        elif isinstance(h, str):
            out.append({"role": "user", "content": h})
        else:
            out.append({"role": "assistant", "content": str(h)})
    return out



