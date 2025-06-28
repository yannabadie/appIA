import os
import shutil
import re

SCRIPT_PATH = "jarvis_voice.py"
BACKUP_PATH = "jarvis_voice_backup.py"

IS_WAKE_WORD_CODE = '''
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
'''

def main():
    if not os.path.exists(SCRIPT_PATH):
        print(f"[ERREUR] Fichier {SCRIPT_PATH} introuvable.")
        return
    # Sauvegarde
    shutil.copy2(SCRIPT_PATH, BACKUP_PATH)
    print(f"[OK] Sauvegarde créée : {BACKUP_PATH}")

    with open(SCRIPT_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    # Ajoute ou remplace le bloc is_wake_word + WAKE_WORDS en haut
    if "def is_wake_word" in content:
        content = re.sub(
            r'import difflib.*?def is_wake_word[\s\S]+?return False', 
            IS_WAKE_WORD_CODE.strip(),
            content,
            count=1
        )
        print("[OK] Fonction is_wake_word mise à jour.")
    else:
        # Ajoute juste après les imports principaux
        content = re.sub(
            r'(import whisper[\s\S]+tts\.setProperty\(\'rate\', ?\d+\))',
            r'\1\n\n' + IS_WAKE_WORD_CODE.strip(),
            content,
            count=1
        )
        print("[OK] Fonction is_wake_word et liste WAKE_WORDS ajoutées.")

    # Remplace tous les 'if WAKE_WORD in text:' par 'if is_wake_word(text):'
    content, n = re.subn(
        r'if +WAKE_WORD +in +text *:',
        'if is_wake_word(text):',
        content
    )
    if n:
        print("[OK] Condition mot-clé remplacée dans la boucle.")
    else:
        print("[INFO] Condition mot-clé déjà patchée ou non trouvée.")

    with open(SCRIPT_PATH, "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Patch vocal fuzzy appliqué ! Relance le script et teste les variantes d'appel.")

if __name__ == "__main__":
    main()
