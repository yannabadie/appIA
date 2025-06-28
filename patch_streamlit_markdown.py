import re

FILENAME = "web_ui_streamlit.py"

def patch_streamlit_markdown(filename):
    with open(filename, "r", encoding="utf-8") as f:
        code = f.read()
    # Corrige la ligne fautive : on supprime tout ce qui suit st.markdown(...)
    # et on enlève la concaténation (+)
    pattern = r'st\.markdown\((.*)\)\._repr_markdown_\(\)\s*\+'
    code_new = re.sub(pattern, r'st.markdown(\1)\n', code)
    if code != code_new:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(code_new)
        print("✅ Patch appliqué : suppression de ._repr_markdown_() sur st.markdown")
    else:
        print("✅ Rien à patcher (aucune occurrence trouvée).")

if __name__ == "__main__":
    patch_streamlit_markdown(FILENAME)
