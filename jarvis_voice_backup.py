import sounddevice as sd
import numpy as np
import whisper
import queue
import time
import pyttsx3
import threading

# Configuration
WAKE_WORD = "hey jarvis"  # tu peux mettre "hey jarvis" si tu veux
SAMPLE_RATE = 16000
DURATION = 5  # durée max de l'enregistrement (en secondes)
MODEL = "base"  # ou "small", "medium", "large", plus rapide = "base" ou "small"

# Initialise Whisper (local)
model = whisper.load_model(MODEL)
# Initialise TTS (pyttsx3)
tts = pyttsx3.init()
tts.setProperty('rate', 170)

import difflib

WAKE_WORDS = ["jarvis", "jarlis", "hey jarvis", "hé jarvis", "hé", "hey"]

def is_wake_word(text, wake_words=WAKE_WORDS):
    text = text.lower()
    for ww in wake_words:
        # Similitude globale, et mot à mot
        if difflib.SequenceMatcher(None, text, ww).ratio() >= 0.7:
            return True
        for word in text.split():
            if difflib.SequenceMatcher(None, word, ww).ratio() >= 0.7:
                return True
    return False

q = queue.Queue()

def record_audio(duration=DURATION):
    print("🎤 Prêt à écouter...")
    audio = sd.rec(int(duration * SAMPLE_RATE), samplerate=SAMPLE_RATE, channels=1, dtype=np.float32)
    sd.wait()
    audio = np.squeeze(audio)
    return audio

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

def speak(text):
    print(f"💬 Jarvis : {text}")
    tts.say(text)
    tts.runAndWait()

def listen_loop():
    while True:
        audio = record_audio()
        text = transcribe(audio)
        print(f"🔎 Entendu : {text}")
        if is_wake_word(text):
            speak("Oui, je t'écoute.")
            # On attend la question
            audio2 = record_audio(7)
            question = transcribe(audio2)
            print(f"➡️ Question : {question}")
            if question.strip():
                q.put(question)
            else:
                speak("Je n'ai pas compris, peux-tu répéter ?")
        else:
            print("(mot-clé non détecté)")
        time.sleep(0.5)

def main():
    # Thread de reconnaissance vocale
    t = threading.Thread(target=listen_loop, daemon=True)
    t.start()
    while True:
        try:
            question = q.get(timeout=60)
        except queue.Empty:
            continue
        # Ici tu appelles ton LLM/Cloud habituel (openai, ollama, gemini…)
        # Par exemple :
        from agent_core import ask_agent  # adapte selon ton archi !
        answer = ask_agent(question, history=[], agent="openai")  # ou "ollama", "gemini"…
        speak(answer)

if __name__ == "__main__":
    main()
