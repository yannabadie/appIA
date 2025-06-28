import re

file = "web_ui_streamlit.py"

with open(file, encoding="utf-8") as f:
    code = f.read()

# PATCH toutes les text_area height < 68 en height=72
def patch_height(match):
    # match.group(1) = contenu avant height, match.group(2) = valeur height
    height_value = int(match.group(2))
    if height_value < 68:
        return f'st.text_area({match.group(1)}, height=72,'
    return match.group(0)

# Corrige toute occurrence
code_patched = re.sub(
    r'st\.text_area\((.+?),\s*height\s*=\s*(\d{1,3})\s*,',
    patch_height,
    code
)

# Correction pour les cas sans virgule après height
code_patched = re.sub(
    r'st\.text_area\((.+?),\s*height\s*=\s*(\d{1,3})\s*\)',
    lambda m: f'st.text_area({m.group(1)}, height=72)',
    code_patched
)

with open(file, "w", encoding="utf-8") as f:
    f.write(code_patched)

print("✅ Toutes les zones st.text_area sont maintenant à height=72px minimum. Relance streamlit !")
