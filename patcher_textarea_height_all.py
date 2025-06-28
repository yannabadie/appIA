import re

file = "web_ui_streamlit.py"
with open(file, encoding="utf-8") as f:
    code = f.read()

def patch_heights(match):
    params = match.group(1)
    # Cherche l'argument height=xxx dans les paramètres
    patched_params = re.sub(
        r'height\s*=\s*(\d+)',
        lambda m: "height=72" if int(m.group(1)) < 68 else m.group(0),
        params
    )
    return f"st.text_area({patched_params})"

# Patch toutes les occurrences de st.text_area
code_patched = re.sub(
    r'st\.text_area\((.*?)\)',
    patch_heights,
    code,
    flags=re.DOTALL
)

with open(file, "w", encoding="utf-8") as f:
    f.write(code_patched)

print("✅ Patch height=72 appliqué à tous les st.text_area (vérifie toutes tes zones d'input). Relance streamlit !")
