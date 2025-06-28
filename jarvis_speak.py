import torch
import collections
import os

# Patch sécurité PyTorch 2.6+
try:
    from TTS.utils.radam import RAdam
    torch.serialization.add_safe_globals([RAdam, collections.defaultdict, dict])
except Exception as e:
    print("[JARVIS] PyTorch whitelist patch : ", e)

from TTS.api import TTS

# Modèles utilisés
MODEL_FR = "tts_models/fr/mai/tacotron2-DDC"
MODEL_EN = "tts_models/en/ljspeech/tacotron2-DDC"
tts_fr = None
tts_en = None

def get_tts(model_name, lang='fr'):
    global tts_fr, tts_en
    if lang == 'fr':
        if tts_fr is None:
            tts_fr = TTS(model_name=MODEL_FR, progress_bar=False, gpu=False)
        return tts_fr
    else:
        if tts_en is None:
            tts_en = TTS(model_name=MODEL_EN, progress_bar=False, gpu=False)
        return tts_en

def speak(text, file_path="jarvis_speak.wav", lang="fr", fallback=True, autoplay=True):
    """
    Synthétise la voix (fr par défaut), fallback anglais si erreur.
    Génère le fichier .wav et le joue si autoplay.
    """
    tts = get_tts(MODEL_FR, lang) if lang == "fr" else get_tts(MODEL_EN, lang)
    try:
        tts.tts_to_file(text=text, file_path=file_path)
    except Exception as err:
        print(f"[JARVIS] ⚠️ Synthèse {lang.upper()} failed: {err}")
        if fallback and lang == "fr":
            print("[JARVIS] ➡️ Tentative fallback EN...")
            tts = get_tts(MODEL_EN, lang="en")
            tts.tts_to_file(text=text, file_path=file_path)
    # Option lecture directe (ffplay, cross-WSL/Windows)
    if autoplay:
        try:
            os.system(f"ffplay -autoexit -nodisp {file_path} 2>/dev/null")
        except Exception as e:
            print(f"[JARVIS] Playback error: {e}")

# Test en exécution directe
if __name__ == "__main__":
    speak("Bonjour, je suis Jarvis, votre assistant vocal français.", lang="fr")
    speak("Hello, I am Jarvis, your English voice assistant.", lang="en")

