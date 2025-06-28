import os
from google.oauth2 import service_account
from googleapiclient.discovery import build

creds_path = os.getenv("GOOGLE_SERVICE_ACCOUNT_JSON", "data/google_creds.json")
parent_id = "1A0PB_7WNCHT6Wr767P_j2-vAyoLZgoPV"

try:
    creds = service_account.Credentials.from_service_account_file(creds_path, scopes=["https://www.googleapis.com/auth/drive"])
    service = build("drive", "v3", credentials=creds, cache_discovery=False)
    results = service.files().list(q=f"'{parent_id}' in parents and trashed=false", pageSize=1, fields="files(id, name)").execute()
    print("OK: Accès Google Drive :", results.get('files', []))
except Exception as e:
    print("ERREUR: Accès Google Drive KO :", e)
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



