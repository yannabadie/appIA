# install_voice_stack.py
import subprocess
import sys

def pip_install(pkg):
    subprocess.check_call([sys.executable, "-m", "pip", "install", pkg])

# Speech-to-text
pip_install("openai-whisper")
pip_install("sounddevice")
pip_install("numpy")
pip_install("ffmpeg-python")
pip_install("pyaudio")     # pour micro sous Windows
# Synthèse vocale
pip_install("pyttsx3")     # TTS local, simple et rapide (offline)

# Si tu veux une voix plus naturelle : (optionnel, voir étape bonus)
# pip_install("TTS")       # Coqui TTS (open source, voix FR/EN réalistes)
