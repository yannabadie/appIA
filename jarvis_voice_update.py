import os
import shutil

# Chemin du script principal
SCRIPT_PATH = "jarvis_voice.py"
BACKUP_PATH = "jarvis_voice_backup.py"

# Fonction patchée (version corrigée)
PATCHED_TRANSCRIBE = '''
def transcribe(audio):
    import tempfile, os, soundfile as sf
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        sf.write(tmp.name, audio, SAMPLE_RATE)
        temp_name = tmp.name  # on retient le nom
    # FICHIER TEMP FERMÉ, Whisper peut l’utiliser
    result = model.transcribe(temp_name, language="fr")
    # Après la transcription, on peut supprimer
    try:
        os.remove(temp_name)
    except Exception as e:
        print(f"Erreur suppression temp : {e}")
    return result["text"].strip().lower()
'''

def main():
    # 1. Sauvegarde de l'ancien fichier
    if not os.path.exists(SCRIPT_PATH):
        print(f"[ERREUR] Fichier {SCRIPT_PATH} introuvable.")
        return
    shutil.copy2(SCRIPT_PATH, BACKUP_PATH)
    print(f"[OK] Sauvegarde créée : {BACKUP_PATH}")

    # 2. Lecture du fichier et remplacement de la fonction
    with open(SCRIPT_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    # Remplacement "intelligent" de la fonction transcribe
    import re
    new_content, n = re.subn(
        r'def transcribe\(audio\):.*?return result\["text"\]\.strip\(\)\.lower\(\)',
        PATCHED_TRANSCRIBE.strip(),
        content,
        flags=re.DOTALL
    )

    if n == 0:
        print("[ERREUR] Fonction transcribe non trouvée ou déjà patchée.")
        return

    # 3. Réécriture du fichier patché
    with open(SCRIPT_PATH, "w", encoding="utf-8") as f:
        f.write(new_content)
    print("[OK] Mise à jour terminée : fonction transcribe corrigée.")

if __name__ == "__main__":
    main()
