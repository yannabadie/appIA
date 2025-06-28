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
    # Ajoute l'import Coqui si absent
    if "from jarvis_speak import speak" not in data:
        # Juste après tous les imports standards
        return re.sub(r"^(import .+\n)+", r"\g<0>from jarvis_speak import speak\n", data, count=1, flags=re.MULTILINE)
    return data

def patch_speak_calls(data):
    """
    Remplace les anciens appels de synthèse vocale par speak(text, lang='fr')
    mais ne touche pas à la définition de la fonction speak elle-même.
    """
    # Motifs à remplacer (appels dans le code)
    motifs = [
        r"engine\.say\((.+?)\)",
        r"tts\.tts_to_file\(text=(.+?),\s*file_path=.+?\)",
        r"synthesiz[ea]_voice?\((.+?)\)",
        r"(?<!def )speak\((.+?)\)",
    ]
    for motif in motifs:
        def replacer(match):
            args = match.group(1).strip()
            # On ajoute lang='fr' UNIQUEMENT s'il n'est pas déjà dans les arguments
            if "lang=" not in args:
                if args:
                    return f"speak({args}, lang='fr')"
                else:
                    return "speak(lang='fr')"
            else:
                return f"speak({args})"
        data = re.sub(motif, replacer, data)
    return data

def fix_speak_definition(data):
    """
    Corrige la définition de la fonction speak pour éviter les doublons d'arguments lang.
    """
    def replacer_def(match):
        args = match.group(1)
        # Enlève les doublons de 'lang' dans les arguments
        args_list = [a.strip() for a in args.split(",") if a.strip()]
        seen = set()
        clean_args = []
        for arg in args_list:
            key = arg.split("=")[0].strip()
            if key not in seen:
                seen.add(key)
                clean_args.append(arg)
        return f"def speak({', '.join(clean_args)}):"
    # Patch toute définition de speak
    return re.sub(r"def speak\s*\((.*?)\):", replacer_def, data, flags=re.DOTALL)

def patch_file():
    if not os.path.exists(JARVIS_VOICE):
        print(f"[ERREUR] {JARVIS_VOICE} introuvable.")
        return
    backup_file(JARVIS_VOICE, BACKUP)
    with open(JARVIS_VOICE, "r", encoding="utf-8") as f:
        data = f.read()
    original = data

    data = insert_import(data)
    data = patch_speak_calls(data)
    data = fix_speak_definition(data)

    if data != original:
        with open(JARVIS_VOICE, "w", encoding="utf-8") as f:
            f.write(data)
        print("[OK] Patch appliqué à jarvis_voice.py")
    else:
        print("[INFO] Aucun changement détecté.")

    print("\n--- Résumé du patch ---")
    print("1. Import 'from jarvis_speak import speak'")
    print("2. Remplacement des appels vocaux par speak(..., lang='fr')")
    print("3. Correction de la définition de speak (anti-doublon)")
    print("4. Sauvegarde dans jarvis_voice_backup.py")
    print("-----------------------\n")

if __name__ == "__main__":
    patch_file()
