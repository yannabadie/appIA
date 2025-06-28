import re
import shutil

TARGET_FILE = "jarvis_voice.py"
BACKUP_FILE = "jarvis_voice_patch2_backup.py"

def backup_file():
    shutil.copy(TARGET_FILE, BACKUP_FILE)
    print(f"[OK] Backup créée : {BACKUP_FILE}")

def remove_duplicate_lang_args(data):
    # Corrige tous les appels à speak(...) ayant plusieurs lang= dans les arguments
    def repl(match):
        func = match.group(1)
        args = match.group(2)
        # Sépare chaque argument
        seen_lang = False
        new_args = []
        for arg in re.split(r',(?![^\(\)]*\))', args):
            if re.search(r"\blang\s*=", arg):
                if not seen_lang:
                    new_args.append(arg)
                    seen_lang = True
                # On ignore les lang= suivants
            else:
                new_args.append(arg)
        # Nettoie les virgules multiples éventuelles
        return f"{func}({', '.join(a.strip() for a in new_args if a.strip())})"
    # Remplace tous les speak(...)
    return re.sub(r"(speak)\s*\((.*?)\)", repl, data)

def main():
    with open(TARGET_FILE, "r", encoding="utf-8") as f:
        content = f.read()
    backup_file()
    patched = remove_duplicate_lang_args(content)
    with open(TARGET_FILE, "w", encoding="utf-8") as f:
        f.write(patched)
    print("[OK] Suppression des doublons 'lang=' dans speak(...) terminée.")

if __name__ == "__main__":
    main()
