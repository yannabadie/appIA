import os
import shutil
import re

SCRIPT_PATH = "jarvis_voice.py"
BACKUP_PATH = "jarvis_voice_backup.py"

# Code à injecter/remplacer pour speak bilingue + fallback
PATCHED_SPEAK = '''
from TTS.api import TTS

# Initialisation : français par défaut, anglais en backup si crash
try:
    tts_fr = TTS("tts_models/fr/mai/tacotron2-DDC")
except Exception as e:
    print("[ERREUR TTS FR] :", e)
    tts_fr = None

try:
    tts_en = TTS("tts_models/en/ljspeech/tacotron2-DDC")
except Exception as e:
    print("[ERREUR TTS EN] :", e)
    tts_en = None

def speak(text, lang="fr"):
    model = tts_fr if lang=="fr" and tts_fr else tts_en
    if not model:
        print("[ERREUR] Aucun modèle vocal disponible.")
        return
    # Génère fichier audio temporaire
    file_path = "tmp_tts.wav"
    try:
        model.tts_to_file(text=text, file_path=file_path)
        import sounddevice as sd
        import soundfile as sf
        audio, sr = sf.read(file_path)
        sd.play(audio, sr)
        sd.wait()
    except Exception as e:
        print("[TTS fallback EN] :", e)
        if model is not tts_en and tts_en:
            # Relance en anglais si le FR a échoué
            speak(text, lang="en")
        else:
            print("[ERREUR CRITIQUE] Impossible de jouer le son.")
    finally:
        try:
            os.remove(file_path)
        except Exception:
            pass
'''

def main():
    # Sauvegarde avant patch
    if not os.path.exists(SCRIPT_PATH):
        print(f"[ERREUR] Fichier {SCRIPT_PATH} introuvable.")
        return
    shutil.copy2(SCRIPT_PATH, BACKUP_PATH)
    print(f"[OK] Sauvegarde créée : {BACKUP_PATH}")

    with open(SCRIPT_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    # Remplace toute définition existante de 'def speak'
    content, n = re.subn(
        r'from TTS\.api import TTS.*?def speak\(.*?\)[\s\S]+?sd\.wait\(\)[\s\S]+?(try:|except|def|#|$)',
        PATCHED_SPEAK.strip() + r"\n\1",
        content,
        flags=re.DOTALL
    )

    if n == 0:
        # Si pas de bloc trouvé, injecte en haut après les imports principaux
        content = re.sub(
            r'(import whisper[\s\S]+tts\.setProperty\(\'rate\', ?\d+\))',
            r'\1\n\n' + PATCHED_SPEAK.strip(),
            content,
            count=1
        )
        print("[OK] Fonction speak bilingue injectée en haut.")
    else:
        print("[OK] Fonction speak remplacée.")

    with open(SCRIPT_PATH, "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Patch vocal Coqui TTS bilingue appliqué.\nRedémarre jarvis_voice.py et teste !")

if __name__ == "__main__":
    main()
