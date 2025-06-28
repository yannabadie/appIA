import os

FILE = "web_ui_streamlit.py"

def patch_rerun(filename):
    if not os.path.isfile(filename):
        print(f"❌ Fichier non trouvé : {filename}")
        return
    with open(filename, "r", encoding="utf-8") as f:
        lines = f.readlines()
    patched = []
    nb_removed = 0
    for line in lines:
        if "st.experimental_rerun()" in line:
            nb_removed += 1
            continue  # supprime la ligne
        patched.append(line)
    if nb_removed == 0:
        print("✅ Aucune occurrence trouvée, rien à patcher.")
    else:
        with open(filename, "w", encoding="utf-8") as f:
            f.writelines(patched)
        print(f"✅ Patch appliqué ({nb_removed} occurrence(s) supprimée(s)) dans {filename}")

if __name__ == "__main__":
    patch_rerun(FILE)
