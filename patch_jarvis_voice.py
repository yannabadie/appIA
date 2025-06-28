import re
import shutil
import os

JARVIS_VOICE = "jarvis_voice.py"
BACKUP = "jarvis_voice_backup.py"

def backup_file(src, dst):
    if not os.path.exists(dst):
        shutil.copy(src, dst)
        print(f"[OK] Backup créée : {dst}")
    else:
        print(f"[INFO] Backup déjà existante : {dst}")

def insert_import(data):
    if "from jarvis_speak import speak" not in data:
        # Ajoute juste après les imports standards
        return re.sub(r"^(import .+\n)+", r"\g<0>from jarvis_speak import speak\n", data, count=1, flags=re.MULTILINE)
    return data

def patch_speak_calls(data):
    # Remplace les anciens appels à TTS / synthèse par le nouveau
    # Ajoute d'autres motifs si tu avais plusieurs styles
    motifs = [
        r"engine\.say\((.+?)\)",  # pyttsx3/ancienne synthèse
        r"tts\.tts_to_file\(text=(.+?),\s*file_path=.+?\)",  # coqui direct
        r"synthesiz[ea]_voice?\((.+?)\)",  # nom de fonction custom
        r"speak\((.+?)\)",  # appel à la fonction locale (pour upgrade automatique)
    ]
    for motif in motifs:
        data = re.sub(motif, r"speak(\1, lang='fr')", data)
    return data

def patch_file():
    if not os.path.exists(JARVIS_VOICE):
        print(f"[ERREUR] {JARVIS_VOICE} introuvable.")
        return
    # 1. Sauvegarde
    backup_file(JARVIS_VOICE, BACKUP)
    # 2. Lecture
    with open(JARVIS_VOICE, "r", encoding="utf-8") as f:
        data = f.read()
    original = data

    # 3. Patch import
    data = insert_import(data)
    # 4. Patch appels TTS
    data = patch_speak_calls(data)

    # 5. Si modifié, sauvegarde
    if data != original:
        with open(JARVIS_VOICE, "w", encoding="utf-8") as f:
            f.write(data)
        print("[OK] Patch appliqué à jarvis_voice.py")
    else:
        print("[INFO] Aucun changement détecté.")

    print("\n--- Résumé du patch ---")
    print("1. Ajout import 'from jarvis_speak import speak'")
    print("2. Remplacement des appels vocaux par speak()")
    print("3. Sauvegarde dans jarvis_voice_backup.py")
    print("-----------------------\n")

if __name__ == "__main__":
    patch_file()
