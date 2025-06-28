# patch_drive.ps1
$app = "agent_core.py"
$content = Get-Content $app -Raw

if ($content -notmatch "def init_google_drive_service") {
    $patch = @'
import os
def init_google_drive_service():
    from googleapiclient.discovery import build
    from google_auth_oauthlib.flow import InstalledAppFlow
    from google.auth.transport.requests import Request
    import pickle
    SCOPES = ['https://www.googleapis.com/auth/drive']
    creds = None
    token_path = "token.pickle"
    creds_path = "credentials.json"
    if os.path.exists(token_path):
        with open(token_path, 'rb') as token:
            creds = pickle.load(token)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(creds_path, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(token_path, 'wb') as token:
            pickle.dump(creds, token)
    service = build('drive', 'v3', credentials=creds)
    return service
try:
    service_drive = init_google_drive_service()
except Exception as e:
    print(f"[Jarvis] Impossible d'initialiser le service Google Drive: {e}")
    service_drive = None
'@
    $content = $patch + "`n" + $content
    Set-Content $app -Value $content -Encoding UTF8
    Write-Host "✅ Patch Google Drive appliqué. Relance le serveur pour tester !"
} else {
    Write-Host "🔹 Patch déjà appliqué, aucune modification."
}
