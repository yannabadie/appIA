import pyttsx3
def speak_local(text):
    engine = pyttsx3.init()
    engine.say(text)
    engine.runAndWait()
