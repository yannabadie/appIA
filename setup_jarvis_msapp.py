import requests, json, os
from dotenv import set_key, load_dotenv

# == Paramètres ==
PERMISSIONS_JSON = "permissions.json"
ENV_PATH = ".env"
APP_NAME = "JARVIS-AI-Agent"

# == Demande tenant ID ==
tenant_id = input("Tenant ID (voir portail Entra ID) : ").strip()
# == Authentification admin (device code) ==
print("[*] Démarrage création/config MS Graph (Entra ID) ...")
device_code_url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/devicecode"
token_url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"
client_id = "04b07795-8ddb-461a-bbee-02f9e1bf7b46"  # client_id Microsoft Graph Explorer

# == Device code flow ==
scope = "https://graph.microsoft.com/.default offline_access openid profile"
r = requests.post(device_code_url, data={"client_id": client_id, "scope": scope})
device = r.json()
print("[*] Pour continuer, va sur %s puis entre le code : %s" % (device['verification_uri'], device['user_code']))
input("Appuie sur Entrée quand tu as autorisé...")

# == Token ==
def get_token():
    for _ in range(30):
        resp = requests.post(token_url, data={
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
            "client_id": client_id,
            "device_code": device['device_code']
        })
        if resp.ok and "access_token" in resp.json():
            return resp.json()["access_token"]
        import time; time.sleep(2)
    raise Exception("Impossible de récupérer un token. As-tu bien autorisé ?")

access_token = get_token()

# == Créer l'application ==
print("[*] Création de l'application Azure AD ...")
headers = {"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"}
app_req = {
    "displayName": APP_NAME,
    "signInAudience": "AzureADMyOrg",
    "web": {"redirectUris": ["http://localhost"]},
    "requiredResourceAccess": []
}
resp = requests.post("https://graph.microsoft.com/v1.0/applications", headers=headers, json=app_req)
resp.raise_for_status()
app = resp.json()
app_id = app["appId"]
object_id = app["id"]
print(f"[*] Application créée: app_id={app_id} object_id={object_id}")

# == Créer secret client ==
print("[*] Création secret client ...")
secret_req = {"passwordCredential": {"displayName": "jarvis-secret"}}
resp = requests.post(f"https://graph.microsoft.com/v1.0/applications/{object_id}/addPassword", headers=headers, json=secret_req)
resp.raise_for_status()
secret = resp.json()["secretText"]
print(f"[*] Secret généré: {secret[:4]}********")

# == Charger les permissions ==
with open(PERMISSIONS_JSON, encoding="utf-8") as f:
    permissions = json.load(f)

# == Mapper tous les scopes/droits ==
resource_access = []
scopes = []
for perm in permissions:
    # Le mapping API Graph nécessite l'id du "Microsoft Graph" resource
    # Microsoft Graph: appId = "00000003-0000-0000-c000-000000000000"
    typ = "Scope" if perm["type"].lower().startswith("delegated") else "Role"
    resource_access.append({"id": perm["value"], "type": typ})
    scopes.append(perm["value"])

# == Attribuer les droits à l'app via requiredResourceAccess ==
print("[*] Configuration des permissions ...")
requiredResourceAccess = [{
    "resourceAppId": "00000003-0000-0000-c000-000000000000",
    "resourceAccess": [{"id": perm["value"], "type": ("Scope" if perm["type"]=="Delegated" else "Role")} for perm in permissions]
}]
patch_req = {"requiredResourceAccess": requiredResourceAccess}
resp = requests.patch(f"https://graph.microsoft.com/v1.0/applications/{object_id}", headers=headers, json=patch_req)
if resp.status_code not in (200, 204):
    print("Erreur config permissions, passe en manuel dans le portail Entra ID si besoin.")
else:
    print("[*] Permissions ajoutées (manque consent admin global, à faire dans le portail Entra ID si blocage).")

# == Consent global (manuel) ==
print("[!] Pour accorder les droits d'accès à l'app, va dans Entra ID > Applications > JARVIS-AI-Agent > API permissions > Grant admin consent.")

# == Sauvegarde dans le .env ==
load_dotenv(ENV_PATH)
set_key(ENV_PATH, "JARVIS_MS_CLIENT_ID", app_id)
set_key(ENV_PATH, "JARVIS_MS_CLIENT_SECRET", secret)
set_key(ENV_PATH, "JARVIS_MS_TENANT_ID", tenant_id)
print(f"[*] Infos enregistrées dans {ENV_PATH} !")

print("\n== Résumé ==")
print(f"CLIENT_ID={app_id}\nCLIENT_SECRET={secret}\nTENANT_ID={tenant_id}\n")
print("Fais le consent admin global puis ton agent_core.py peut utiliser ces credentials !")
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



