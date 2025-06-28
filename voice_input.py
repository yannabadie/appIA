from faster_whisper import WhisperModel
def transcribe_local(audio_path):
    model = WhisperModel("base", device="cpu")
    segments, info = model.transcribe(audio_path)
    return " ".join([s.text for s in segments])
